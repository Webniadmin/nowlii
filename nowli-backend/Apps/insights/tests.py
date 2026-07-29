from datetime import date
from unittest.mock import patch

from django.test import TestCase, override_settings
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

User = get_user_model()

INSIGHT_URL = "/api/insights/"

MOCK_REFLECTIONS = [
    "You've been most consistent on Thursdays 🌿",
    "You tend to complete more tasks on days you feel focused",
    "Your Power Move completion rate improved by 20% this week",
]

MOCK_ANALYTICS = {
    "weekly": {
        "quests_completed": 7,
        "total_quests": 10,
        "zone_progress": [
            {"zone": "Soft steps",  "assigned": 3, "completed": 2, "ratio": "2/3"},
            {"zone": "Stretch zone","assigned": 2, "completed": 1, "ratio": "1/2"},
            {"zone": "Elevated",    "assigned": 3, "completed": 2, "ratio": "2/3"},
            {"zone": "Power move",  "assigned": 2, "completed": 1, "ratio": "1/2"},
        ],
        "quest_suggestions": [
            {
                "task": "Test Quest",
                "description": "Motivational text",
                "zone": "Soft steps",
                "suggested_time": "12:00"
            }
        ],
        "skipped_days": ["Wednesday"],
        "top_emotions": [
            {"key": "happy",     "label": "Happy",     "pct": 34.0},
            {"key": "sad",       "label": "Sad",       "pct": 28.0},
            {"key": "motivated", "label": "Motivated", "pct": 12.0},
            {"key": "angry",     "label": "Angry",     "pct": 12.0},
            {"key": "tired",     "label": "Tired",     "pct": 14.0},
        ],
        "emotions_summary": "You feel mostly calm and positive this week.",
        "low_mood_phrases": ["I can't", "It's too much", "I should", "Later", "I don't know"],
        "low_mood_summary": "You tend to feel overwhelmed when tasks pile up.",
        "low_mood_recommendation": "→ Try breaking tasks into smaller steps.",
        "calendar": [
            {"date": "2026-04-06", "status": "consistent", "assigned": 2, "completed": 2},
            {"date": "2026-04-07", "status": "consistent", "assigned": 1, "completed": 1},
            {"date": "2026-04-08", "status": "skipped",    "assigned": 3, "completed": 1},
            {"date": "2026-04-09", "status": "consistent", "assigned": 2, "completed": 2},
            {"date": "2026-04-10", "status": "consistent", "assigned": 1, "completed": 1},
            {"date": "2026-04-11", "status": "consistent", "assigned": 2, "completed": 2},
            {"date": "2026-04-12", "status": "consistent", "assigned": 1, "completed": 1},
        ],
    },
    "monthly": {
        "most_completed_quests": [
            {"task": "workout", "completed_count": 4, "repeat_quest": True},
            {"task": "study",   "completed_count": 3, "repeat_quest": False},
            {"task": "cooking", "completed_count": 2, "repeat_quest": True},
        ],
        "most_productive_day": "Sunday",
        "most_productive_hour": "10:00",
        "preferred_quest_types": {
            "soft_steps_pct":  72.0,
            "power_moves_pct": 28.0,
            "summary": "You complete more Soft Moves than Power Moves (72.0% vs 28.0%).",
        },
        "quests_completed": {"assigned": 20, "completed": 14},
        "zone_progress": [
            {"zone": "Soft steps",   "assigned": 10, "completed": 8, "ratio": "8/10"},
            {"zone": "Stretch zone", "assigned": 4,  "completed": 3, "ratio": "3/4"},
            {"zone": "Elevated",     "assigned": 3,  "completed": 2, "ratio": "2/3"},
            {"zone": "Power move",   "assigned": 3,  "completed": 1, "ratio": "1/3"},
        ],
        "calendar": [
            {"date": "2026-04-01", "status": "consistent", "assigned": 2, "completed": 2},
            {"date": "2026-04-02", "status": "skipped",    "assigned": 1, "completed": 0},
        ],
        "milestones": {
            "quests_completed_this_month": 14,
            "longest_streak_days": 5,
        },
    },
    "ref_date": "2026-04-12",
}


class AIInsightViewTest(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username="testuser", password="testpass")
        self.client.force_authenticate(user=self.user)

        # MOCK_ANALYTICS carries emotion data, so the view would call the real provider for
        # the "What this means" copy on every test. Stub it out — returning {} keeps the
        # static placeholder copy, which is what these tests assert against.
        patcher = patch("Apps.insights.views.generate_emotion_meaning", return_value={})
        self.mock_emotion_meaning = patcher.start()
        self.addCleanup(patcher.stop)

    @override_settings(ANTHROPIC_API_KEY="fake-key", OPENAI_API_KEY=None, GOOGLE_AI_API_KEY=None)
    @patch("Apps.insights.views.generate_quest_suggestions")
    @patch("Apps.insights.views.generate_weekly_reflections")
    @patch("Apps.insights.views.build_analytics_summary")
    def test_insight_returns_200(self, mock_analytics, mock_reflect, mock_quest):
        mock_analytics.return_value = MOCK_ANALYTICS
        mock_reflect.return_value  = MOCK_REFLECTIONS
        mock_quest.return_value    = MOCK_ANALYTICS["weekly"]["quest_suggestions"]

        res = self.client.get(INSIGHT_URL)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn("weekly",  res.data)
        self.assertIn("monthly", res.data)
        # Top Emotions section flows through the weekly serializer.
        self.assertEqual(len(res.data["weekly"]["top_emotions"]), 5)
        self.assertEqual(res.data["weekly"]["top_emotions"][0]["key"], "happy")
        # "When feeling low" section flows through too.
        self.assertEqual(len(res.data["weekly"]["low_mood_phrases"]), 5)
        self.assertEqual(res.data["weekly"]["low_mood_recommendation"],
                         "→ Try breaking tasks into smaller steps.")

    @override_settings(ANTHROPIC_API_KEY="fake-key", OPENAI_API_KEY=None, GOOGLE_AI_API_KEY=None)
    @patch("Apps.insights.views.generate_quest_suggestions")
    @patch("Apps.insights.views.generate_weekly_reflections")
    @patch("Apps.insights.views.build_analytics_summary")
    def test_weekly_contains_ai_reflections(self, mock_analytics, mock_reflect, mock_quest):
        mock_analytics.return_value = MOCK_ANALYTICS
        mock_reflect.return_value  = MOCK_REFLECTIONS
        mock_quest.return_value    = MOCK_ANALYTICS["weekly"]["quest_suggestions"]

        res = self.client.get(INSIGHT_URL)
        self.assertEqual(len(res.data["weekly"]["ai_reflections"]), 3)

    @override_settings(ANTHROPIC_API_KEY="fake-key", OPENAI_API_KEY=None, GOOGLE_AI_API_KEY=None)
    @patch("Apps.insights.views.generate_quest_suggestions")
    @patch("Apps.insights.views.generate_weekly_reflections")
    @patch("Apps.insights.views.build_analytics_summary")
    def test_cache_prevents_second_ai_call(self, mock_analytics, mock_reflect, mock_quest):
        mock_analytics.return_value = MOCK_ANALYTICS
        mock_reflect.return_value  = MOCK_REFLECTIONS
        mock_quest.return_value    = MOCK_ANALYTICS["weekly"]["quest_suggestions"]

        self.client.get(INSIGHT_URL)   # first call — hits AI
        self.client.get(INSIGHT_URL)   # second call — should use cache

        # AI called only once
        self.assertEqual(mock_reflect.call_count, 1)

    @override_settings(ANTHROPIC_API_KEY="fake-key", OPENAI_API_KEY=None, GOOGLE_AI_API_KEY=None)
    @patch("Apps.insights.views.generate_quest_suggestions")
    @patch("Apps.insights.views.generate_weekly_reflections")
    @patch("Apps.insights.views.build_analytics_summary")
    def test_refresh_bypasses_cache(self, mock_analytics, mock_reflect, mock_quest):
        mock_analytics.return_value = MOCK_ANALYTICS
        mock_reflect.return_value  = MOCK_REFLECTIONS
        mock_quest.return_value    = MOCK_ANALYTICS["weekly"]["quest_suggestions"]

        self.client.get(INSIGHT_URL)                    # prime cache
        self.client.get(INSIGHT_URL + "?refresh=true")  # force refresh

        self.assertEqual(mock_reflect.call_count, 2)

    # ── Graceful degradation when the AI provider is unavailable ─────────────────
    #
    # Only ai_reflections / quest_suggestions need the AI; the rest of the payload is
    # real DB analytics. A provider failure must still return 200 so the screen renders.

    @override_settings(ANTHROPIC_API_KEY=None, OPENAI_API_KEY=None, GOOGLE_AI_API_KEY=None)
    @patch("Apps.insights.views.build_analytics_summary")
    def test_no_api_key_falls_back_instead_of_failing(self, mock_analytics):
        mock_analytics.return_value = MOCK_ANALYTICS
        res = self.client.get(INSIGHT_URL)

        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data["ai_degraded"])
        # Fallback copy is present and shaped like the AI output.
        self.assertEqual(len(res.data["weekly"]["ai_reflections"]), 3)
        self.assertEqual(len(res.data["weekly"]["quest_suggestions"]), 5)
        # The real analytics are untouched.
        self.assertEqual(res.data["weekly"]["quests_completed"], 7)
        self.assertEqual(len(res.data["weekly"]["top_emotions"]), 5)

    @override_settings(ANTHROPIC_API_KEY="fake-key", OPENAI_API_KEY=None, GOOGLE_AI_API_KEY=None)
    @patch("Apps.insights.views.generate_weekly_reflections")
    @patch("Apps.insights.views.build_analytics_summary")
    def test_provider_error_falls_back(self, mock_analytics, mock_reflect):
        mock_analytics.return_value = MOCK_ANALYTICS
        mock_reflect.side_effect = RuntimeError("insufficient_quota")

        res = self.client.get(INSIGHT_URL)

        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data["ai_degraded"])
        self.assertEqual(len(res.data["weekly"]["ai_reflections"]), 3)
        # The fallback reflection leads with the real completion numbers.
        self.assertIn("7 of 10", res.data["weekly"]["ai_reflections"][0])

    @override_settings(ANTHROPIC_API_KEY="fake-key", OPENAI_API_KEY=None, GOOGLE_AI_API_KEY=None)
    @patch("Apps.insights.views.generate_quest_suggestions")
    @patch("Apps.insights.views.generate_weekly_reflections")
    @patch("Apps.insights.views.build_analytics_summary")
    def test_fallback_is_not_cached(self, mock_analytics, mock_reflect, mock_quest):
        """A degraded response must not poison the cache — the next load retries the AI."""
        mock_analytics.return_value = MOCK_ANALYTICS
        mock_quest.return_value     = MOCK_ANALYTICS["weekly"]["quest_suggestions"]
        mock_reflect.side_effect    = RuntimeError("provider down")

        first = self.client.get(INSIGHT_URL)
        self.assertTrue(first.data["ai_degraded"])

        # Provider recovers — the second load must call it again and serve real AI copy.
        mock_reflect.side_effect  = None
        mock_reflect.return_value = MOCK_REFLECTIONS

        second = self.client.get(INSIGHT_URL)
        self.assertEqual(mock_reflect.call_count, 2)
        self.assertFalse(second.data["ai_degraded"])
        self.assertEqual(list(second.data["weekly"]["ai_reflections"]), MOCK_REFLECTIONS)

    @override_settings(ANTHROPIC_API_KEY="fake-key", OPENAI_API_KEY=None, GOOGLE_AI_API_KEY=None)
    @patch("Apps.insights.views.generate_quest_suggestions")
    @patch("Apps.insights.views.generate_weekly_reflections")
    @patch("Apps.insights.views.build_analytics_summary")
    def test_partial_failure_keeps_the_half_that_worked(self, mock_analytics, mock_reflect, mock_quest):
        """Reflections succeed, suggestions fail — the good reflections must survive."""
        mock_analytics.return_value = MOCK_ANALYTICS
        mock_reflect.return_value   = MOCK_REFLECTIONS
        mock_quest.side_effect      = RuntimeError("provider down")

        res = self.client.get(INSIGHT_URL)

        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data["ai_degraded"])
        self.assertEqual(list(res.data["weekly"]["ai_reflections"]), MOCK_REFLECTIONS)
        self.assertEqual(len(res.data["weekly"]["quest_suggestions"]), 5)  # fallback

        # The real reflections are cached; the fallback suggestions are not, so the next
        # load retries only the half that failed.
        mock_quest.side_effect  = None
        mock_quest.return_value = MOCK_ANALYTICS["weekly"]["quest_suggestions"]

        self.client.get(INSIGHT_URL)
        self.assertEqual(mock_reflect.call_count, 1)
        self.assertEqual(mock_quest.call_count, 2)

    @override_settings(ANTHROPIC_API_KEY="fake-key", OPENAI_API_KEY=None, GOOGLE_AI_API_KEY=None)
    @patch("Apps.insights.views.generate_quest_suggestions")
    @patch("Apps.insights.views.generate_weekly_reflections")
    @patch("Apps.insights.views.build_analytics_summary")
    def test_healthy_response_is_not_flagged_degraded(self, mock_analytics, mock_reflect, mock_quest):
        mock_analytics.return_value = MOCK_ANALYTICS
        mock_reflect.return_value   = MOCK_REFLECTIONS
        mock_quest.return_value     = MOCK_ANALYTICS["weekly"]["quest_suggestions"]

        res = self.client.get(INSIGHT_URL)
        self.assertFalse(res.data["ai_degraded"])

    def test_unauthenticated_returns_401(self):
        self.client.force_authenticate(user=None)
        res = self.client.get(INSIGHT_URL)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)


from .services import get_weekly_analytics, get_monthly_analytics
from Apps.quests.models import Quests

class ServiceLogicTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="logicuser", password="testpass")
        # Create a quest for today
        Quests.objects.create(
            user=self.user,
            task="Test Task",
            select_a_date=date.today(),
            task_done=True
        )

    def test_weekly_analytics_includes_calendar(self):
        data = get_weekly_analytics(self.user, date.today())
        self.assertIn("calendar", data)
        self.assertEqual(len(data["calendar"]), 7)
        # Check if today is "consistent"
        today_iso = date.today().isoformat()
        today_data = next(d for d in data["calendar"] if d["date"] == today_iso)
        self.assertEqual(today_data["status"], "consistent")
        self.assertEqual(today_data["assigned"], 1)
        self.assertEqual(today_data["completed"], 1)

    def test_monthly_analytics_includes_calendar(self):
        data = get_monthly_analytics(self.user, date.today())
        self.assertIn("calendar", data)
        self.assertTrue(len(data["calendar"]) >= 28)


from .services import build_fallback_reflections, build_fallback_quest_suggestions


class FallbackCopyTest(TestCase):
    """The offline copy served when the AI provider is down — must be derived from the
    user's real numbers and match the shape the AI would have returned."""

    def test_reflections_use_real_numbers(self):
        lines = build_fallback_reflections(MOCK_ANALYTICS["weekly"])
        self.assertEqual(len(lines), 3)
        self.assertIn("7 of 10", lines[0])       # completion
        self.assertIn("70%", lines[0])
        self.assertIn("Wednesday", lines[2])     # the single skipped day

    def test_reflections_handle_an_empty_week(self):
        lines = build_fallback_reflections(
            {"quests_completed": 0, "total_quests": 0, "skipped_days": [], "zone_progress": []}
        )
        self.assertEqual(len(lines), 3)
        self.assertTrue(all(isinstance(line, str) and line for line in lines))

    def test_reflections_handle_a_perfect_week(self):
        lines = build_fallback_reflections({
            "quests_completed": 5, "total_quests": 5, "skipped_days": [],
            "zone_progress": [{"zone": "Soft steps", "assigned": 5, "completed": 5, "ratio": "5/5"}],
        })
        self.assertIn("100%", lines[0])
        self.assertIn("didn't skip", lines[2])

    def test_quest_suggestions_shape_and_variety(self):
        for hour in ("09:00", "14:00", "19:00"):
            items = build_fallback_quest_suggestions(MOCK_ANALYTICS["weekly"], hour, "Monday")
            self.assertEqual(len(items), 5)
            for item in items:
                self.assertEqual(
                    set(item.keys()), {"task", "description", "zone", "suggested_time"}
                )
            # Daytime sets carry the variety the AI prompt asks for. (Night is
            # deliberately all-gentle — see the note on _FALLBACK_QUESTS.)
            zones = {i["zone"] for i in items}
            self.assertIn("Soft steps", zones, hour)
            self.assertIn("Power move", zones, hour)
            self.assertIn("Stretch zone", zones, hour)

    def test_quest_suggestions_follow_time_of_day(self):
        morning = build_fallback_quest_suggestions({}, "08:00", "Monday")
        night   = build_fallback_quest_suggestions({}, "23:00", "Monday")
        self.assertNotEqual(
            [i["task"] for i in morning], [i["task"] for i in night]
        )
        # Night suggestions should all be scheduled late.
        for item in night:
            self.assertGreaterEqual(int(item["suggested_time"].split(":")[0]), 21)

    def test_quest_suggestions_soften_after_a_rough_week(self):
        rough = build_fallback_quest_suggestions(
            {"skipped_days": ["Monday", "Tuesday", "Wednesday"]}, "09:00", "Thursday"
        )
        self.assertEqual(rough[0]["zone"], "Soft steps")

    def test_quest_suggestions_survive_a_bad_time_string(self):
        items = build_fallback_quest_suggestions({}, "not-a-time", "Monday")
        self.assertEqual(len(items), 5)
