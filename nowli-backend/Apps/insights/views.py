import json
import logging
from datetime import date

import anthropic
import openai
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from .services import build_analytics_summary
from .ai_client import (
    generate_weekly_reflections,
    generate_quest_suggestions,
    generate_emotion_meaning,
    get_active_provider,
)
from .serializers import AIInsightResponseSerializer
from .models import InsightCache

logger = logging.getLogger(__name__)


class AIInsightView(APIView):
    """
    GET /api/insights/

    Returns full AI-powered insight report for the authenticated user:
      - Weekly reflection (quests completed, zone progress, skipped days, AI reflections)
      - Monthly overview  (most completed quests, productive day, quest types, calendar, milestones)

    Query params:
      ?refresh=true   → bypass cache and regenerate AI reflections
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user    = request.user
        ref     = date.today()
        refresh = request.query_params.get("refresh", "false").lower() == "true"

        # ── 1. Compute analytics from DB ─────────────────────────────────
        try:
            analytics = build_analytics_summary(user, ref)
        except Exception as e:
            logger.exception("Analytics computation failed")
            return Response(
                {"error": f"Failed to compute analytics: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        weekly_data  = analytics["weekly"]
        monthly_data = analytics["monthly"]

        # ── 2. Cache key ──────────────────────────────────────────────────
        week_key  = ref.strftime("W%Y-%W")
        month_key = ref.strftime("%Y-%m")

        # ── 3. AI reflections, Quest suggestions & emotion "What this means" — cached ──
        ai_reflections    = []
        quest_suggestions = []
        emotion_meaning   = {}

        if not refresh:
            try:
                cache_obj = InsightCache.objects.get(
                    user=user, period="weekly", period_key=week_key
                )
                ai_reflections    = cache_obj.payload.get("ai_reflections", [])
                quest_suggestions = cache_obj.payload.get("quest_suggestions", [])
                emotion_meaning   = cache_obj.payload.get("emotion_meaning", {}) or {}
            except InsightCache.DoesNotExist:
                pass

        cache_dirty = False

        # Reflections + quest suggestions (regenerate both if either is missing).
        if not ai_reflections or not quest_suggestions:
            try:
                # Get current time/day for suggestions
                from django.utils import timezone
                now = timezone.now()
                current_time = now.strftime("%H:%M")
                day_of_week  = now.strftime("%A")

                # Parallel-ready calls (sequential for now)
                ai_reflections    = generate_weekly_reflections(weekly_data)
                quest_suggestions = generate_quest_suggestions(weekly_data, current_time, day_of_week)
                cache_dirty = True
            except EnvironmentError as e:
                return Response({"error": str(e)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
            except json.JSONDecodeError:
                return Response(
                    {"error": "AI returned an unexpected response. Please try again."},
                    status=status.HTTP_502_BAD_GATEWAY
                )
            except Exception as e:
                logger.exception("AI generation failed")
                return Response(
                    {"error": f"Unexpected error: {str(e)}"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

        # "What this means" for the emotion sections — generated only when the user has
        # voice-call data. Best-effort: on ANY failure we keep the static placeholder copy
        # already in weekly_data (services.py) rather than failing the whole response.
        has_emotion_data = bool(weekly_data.get("top_emotions")) or bool(weekly_data.get("low_mood_phrases"))
        if has_emotion_data and not emotion_meaning:
            try:
                emotion_meaning = generate_emotion_meaning(
                    weekly_data.get("top_emotions", []),
                    weekly_data.get("low_mood_phrases", []),
                )
                cache_dirty = True
            except Exception:
                logger.exception("Emotion-meaning AI generation failed; using placeholder copy")
                emotion_meaning = {}

        # Apply the AI meaning over the static placeholders when present.
        if emotion_meaning:
            if emotion_meaning.get("emotions_summary"):
                weekly_data["emotions_summary"] = emotion_meaning["emotions_summary"]
            if emotion_meaning.get("low_mood_summary"):
                weekly_data["low_mood_summary"] = emotion_meaning["low_mood_summary"]
            if emotion_meaning.get("low_mood_recommendation"):
                weekly_data["low_mood_recommendation"] = emotion_meaning["low_mood_recommendation"]

        # Save to cache (single write covering all three).
        if cache_dirty:
            InsightCache.objects.update_or_create(
                user=user, period="weekly", period_key=week_key,
                defaults={
                    "payload": {
                        "ai_reflections": ai_reflections,
                        "quest_suggestions": quest_suggestions,
                        "emotion_meaning": emotion_meaning,
                    }
                }
            )

        # ── 4. Assemble final response ────────────────────────────────────
        weekly_data["ai_reflections"]    = ai_reflections
        weekly_data["quest_suggestions"] = quest_suggestions

        payload = {
            "weekly":  weekly_data,
            "monthly": monthly_data,
        }

        serializer = AIInsightResponseSerializer(data=payload)
        if not serializer.is_valid():
            logger.error("Serializer errors: %s", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        return Response(serializer.data, status=status.HTTP_200_OK)
