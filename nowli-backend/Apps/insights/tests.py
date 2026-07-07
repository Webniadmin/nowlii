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

    @override_settings(ANTHROPIC_API_KEY=None, OPENAI_API_KEY=None, GOOGLE_AI_API_KEY=None)
    @patch("Apps.insights.views.build_analytics_summary")
    def test_no_api_key_returns_503(self, mock_analytics):
        mock_analytics.return_value = MOCK_ANALYTICS
        res = self.client.get(INSIGHT_URL)
        self.assertEqual(res.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)

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
