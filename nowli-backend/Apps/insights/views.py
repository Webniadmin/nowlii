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
from .ai_client import generate_weekly_reflections, generate_quest_suggestions, get_active_provider
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

        # ── 3. AI reflections & Quest suggestions — with cache ────────────────
        ai_reflections    = []
        quest_suggestions = []
        cache_obj         = None

        if not refresh:
            try:
                cache_obj = InsightCache.objects.get(
                    user=user, period="weekly", period_key=week_key
                )
                ai_reflections    = cache_obj.payload.get("ai_reflections", [])
                quest_suggestions = cache_obj.payload.get("quest_suggestions", [])
            except InsightCache.DoesNotExist:
                pass

        # If either is missing, we regenerate both (or we could be more granular, 
        # but for simplicity let's regenerate both if one is missing or expired)
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

            # Save to cache
            InsightCache.objects.update_or_create(
                user=user, period="weekly", period_key=week_key,
                defaults={
                    "payload": {
                        "ai_reflections": ai_reflections,
                        "quest_suggestions": quest_suggestions
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
