import json
import logging
from datetime import date

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from .services import (
    build_analytics_summary,
    build_fallback_reflections,
    build_fallback_quest_suggestions,
)
from .ai_client import (
    generate_weekly_reflections,
    generate_quest_suggestions,
    generate_emotion_meaning,
    get_active_provider,
)
from .serializers import AIInsightResponseSerializer
from .models import InsightCache
from Apps.users.models import Profile

logger = logging.getLogger(__name__)

_WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
_WEEKDAYS_LOWER = {d.lower(): d for d in _WEEKDAYS}


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

    @staticmethod
    def _call_ai(label: str, fn, *args):
        """Run one AI generator, turning any failure into ``(None, False)``.

        Insights is a screen load, not a batch job — a provider failure has to degrade
        that one block instead of failing the whole request.
        """
        try:
            return fn(*args), True
        except EnvironmentError:
            logger.warning("No AI provider configured — falling back for %s", label)
        except json.JSONDecodeError:
            logger.warning("AI returned non-JSON — falling back for %s", label)
        except Exception:
            # Quota, network, timeout, provider outage — all degrade the same way.
            logger.exception("AI generation failed — falling back for %s", label)
        return None, False

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
        ai_degraded = False
        # Tracked separately so a partial failure (reflections fine, suggestions down)
        # keeps the half that worked — both for the response and for the cache write.
        reflections_ok = bool(ai_reflections)
        suggestions_ok = bool(quest_suggestions)

        # Reflections + quest suggestions — the only two AI-backed blocks in the response;
        # everything else is real DB analytics. So a provider failure must NOT fail the
        # whole screen: each block falls back to data-derived copy independently and we
        # still return 200. Fallbacks are never cached, so the next load retries the AI.
        if not reflections_ok or not suggestions_ok:
            # Get current time/day for suggestions
            from django.utils import timezone
            now = timezone.now()
            current_time = now.strftime("%H:%M")
            day_of_week  = now.strftime("%A")

            if not reflections_ok:
                result, reflections_ok = self._call_ai(
                    "weekly reflections", generate_weekly_reflections, weekly_data
                )
                ai_reflections = result if reflections_ok else build_fallback_reflections(weekly_data)

            if not suggestions_ok:
                result, suggestions_ok = self._call_ai(
                    "quest suggestions", generate_quest_suggestions,
                    weekly_data, current_time, day_of_week,
                )
                quest_suggestions = result if suggestions_ok else build_fallback_quest_suggestions(
                    weekly_data, current_time, day_of_week
                )

            cache_dirty = reflections_ok or suggestions_ok
            ai_degraded = not (reflections_ok and suggestions_ok)

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
        #
        # The offline fallback is never cached: it's stored as empty so the next load sees a
        # miss and retries the real AI. Anything that DID succeed this pass (e.g. the emotion
        # meaning) is still cached, so a partial failure doesn't cost us the whole write.
        if cache_dirty:
            InsightCache.objects.update_or_create(
                user=user, period="weekly", period_key=week_key,
                defaults={
                    "payload": {
                        "ai_reflections":    ai_reflections if reflections_ok else [],
                        "quest_suggestions": quest_suggestions if suggestions_ok else [],
                        "emotion_meaning":   emotion_meaning,
                    }
                }
            )

        # ── 4. Assemble final response ────────────────────────────────────
        weekly_data["ai_reflections"]    = ai_reflections
        weekly_data["quest_suggestions"] = quest_suggestions

        payload = {
            "weekly":  weekly_data,
            "monthly": monthly_data,
            # True when the AI provider failed and the reflections/suggestions above are
            # the offline fallback. Everything else in the response is still real data.
            "ai_degraded": ai_degraded,
        }

        serializer = AIInsightResponseSerializer(data=payload)
        if not serializer.is_valid():
            logger.error("Serializer errors: %s", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        return Response(serializer.data, status=status.HTTP_200_OK)


class RestDaysView(APIView):
    """`/api/insights/rest-days/` — the weekdays the user marks as intentional rest days.

    Those days are excluded from Insights "skipped days" so a deliberate day off isn't
    counted as a miss. GET returns the current list; POST updates it.

    POST body: {"days": ["Sunday", ...], "action": "add" | "remove" | "set"} (default "add").
    Weekday names are validated + normalized (case-insensitive). Returns the updated list.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, _ = Profile.objects.get_or_create(user=request.user)
        return Response({"rest_days": list(profile.rest_days or [])})

    def post(self, request):
        raw_days = request.data.get("days") or []
        if not isinstance(raw_days, list):
            return Response({"detail": "`days` must be a list of weekday names."},
                            status=status.HTTP_400_BAD_REQUEST)

        # Validate + normalize each requested weekday (case-insensitive → canonical name).
        normalized = []
        for d in raw_days:
            key = str(d).strip().lower()
            if key not in _WEEKDAYS_LOWER:
                return Response({"detail": f"Invalid weekday: {d!r}."},
                                status=status.HTTP_400_BAD_REQUEST)
            canonical = _WEEKDAYS_LOWER[key]
            if canonical not in normalized:
                normalized.append(canonical)

        action = str(request.data.get("action") or "add").lower()
        profile, _ = Profile.objects.get_or_create(user=request.user)
        current = [d for d in (profile.rest_days or []) if d in _WEEKDAYS]

        if action == "set":
            updated = normalized
        elif action == "remove":
            updated = [d for d in current if d not in normalized]
        else:  # add (default)
            updated = current + [d for d in normalized if d not in current]

        # Keep them in canonical weekday order for a stable response.
        updated = [d for d in _WEEKDAYS if d in updated]
        profile.rest_days = updated
        profile.save(update_fields=["rest_days"])
        return Response({"rest_days": updated}, status=status.HTTP_200_OK)
