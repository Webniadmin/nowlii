"""Tests for the quest streak.

The streak endpoint used to count consecutive days ending at the *latest completed date*
and never compare that date to now, so a streak could only grow or hold — never lapse. Two
finished days last January still reported a streak of 2 in August. These pin the rule that
replaced it: a streak has to reach today or yesterday, it is counted on the user's own
calendar, and days in the future do not count at all.
"""
from datetime import date, timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient

from Apps.quests.models import Quests

User = get_user_model()


class StreakTests(TestCase):
    """`GET /api/quests/streak/` — what counts as a day, and when the run has ended."""

    def setUp(self):
        self.user = User.objects.create_user(
            username='streaker',
            email='streaker@example.com',
            password='not-a-real-password',
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)
        # Anchored to the user's own calendar; the profile carries no zone, so this is the
        # server's, which is what `user_localdate` falls back to.
        self.today = date.today()

    # -- helpers ---------------------------------------------------------------

    def _quest(self, day, done=True):
        return Quests.objects.create(
            user=self.user, task='Walk the dog', select_a_date=day, task_done=done
        )

    def _streak(self):
        response = self.client.get(reverse('quests-streak'))
        self.assertEqual(response.status_code, 200)
        return response.data['streak']

    # -- the run is current ----------------------------------------------------

    def test_no_quests_at_all(self):
        self.assertEqual(self._streak(), 0)

    def test_counts_consecutive_days_up_to_today(self):
        for offset in (0, 1, 2):
            self._quest(self.today - timedelta(days=offset))
        self.assertEqual(self._streak(), 3)

    def test_yesterday_still_counts_because_today_is_not_over(self):
        # Today's quests may simply not be finished yet. Ending the streak at midday would
        # punish a user for a day that is still running.
        self._quest(self.today - timedelta(days=1))
        self._quest(self.today - timedelta(days=2))
        self.assertEqual(self._streak(), 2)

    def test_a_run_that_ended_days_ago_is_over(self):
        # The whole point of the fix: this used to answer 2, forever.
        self._quest(self.today - timedelta(days=8))
        self._quest(self.today - timedelta(days=9))
        self.assertEqual(self._streak(), 0)

    def test_a_gap_ends_the_count(self):
        self._quest(self.today)
        self._quest(self.today - timedelta(days=1))
        # Nothing on day 2 — the run stops here rather than jumping the hole.
        self._quest(self.today - timedelta(days=3))
        self.assertEqual(self._streak(), 2)

    # -- what makes a day count ------------------------------------------------

    def test_one_unfinished_quest_disqualifies_the_whole_day(self):
        self._quest(self.today, done=True)
        self._quest(self.today, done=False)
        self._quest(self.today - timedelta(days=1), done=True)
        # Today is not a streak day, but yesterday is, and yesterday still counts.
        self.assertEqual(self._streak(), 1)

    def test_several_quests_all_done_is_still_one_day(self):
        for _ in range(3):
            self._quest(self.today)
        self.assertEqual(self._streak(), 1)

    def test_quests_without_a_date_are_ignored(self):
        Quests.objects.create(user=self.user, task='Someday', task_done=True)
        self.assertEqual(self._streak(), 0)

    # -- the future ------------------------------------------------------------

    def test_a_finished_quest_in_the_future_does_not_extend_the_streak(self):
        # Ticking tomorrow's quest today would otherwise award two days at once.
        self._quest(self.today + timedelta(days=1))
        self._quest(self.today)
        self.assertEqual(self._streak(), 1)

    def test_the_future_alone_is_not_a_streak(self):
        self._quest(self.today + timedelta(days=1))
        self.assertEqual(self._streak(), 0)

    # -- isolation -------------------------------------------------------------

    def test_another_user_s_days_do_not_count(self):
        other = User.objects.create_user(
            username='someone-else',
            email='else@example.com',
            password='not-a-real-password',
        )
        Quests.objects.create(
            user=other, task='Theirs', select_a_date=self.today, task_done=True
        )
        self.assertEqual(self._streak(), 0)
