"""Tests for Apps.voice_calls — scheduled calls and how they meet the daily limit.

The point of most of these is the seam between a *plan* and the *quota*: a scheduled call
never reserves a slot, so the interesting cases are the ones where the user has fewer calls
left than they have planned.
"""
from datetime import time, timedelta
from unittest import mock

from django.contrib.auth import get_user_model
from django.test import TestCase, override_settings
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient

from Apps.quests.models import Quests

from .models import ScheduledCall, VoiceCall

User = get_user_model()


def _make_user(username, **extra):
    return User.objects.create_user(
        username=username, email=f'{username}@example.com',
        password='pw-for-tests-123', **extra,
    )


def _quest(user, *, enable_call=True, days_ahead=0, at=time(16, 0), task='Go for a walk'):
    return Quests.objects.create(
        user=user,
        task=task,
        zone='Soft steps',
        select_a_date=timezone.localdate() + timedelta(days=days_ahead),
        select_a_time=at,
        enable_call=enable_call,
    )


class ScheduledCallSignalTests(TestCase):
    """The schedule is derived from the quest, so the quest is the only thing to edit."""

    def setUp(self):
        self.user = _make_user('walker')

    def test_quest_with_call_enabled_creates_a_schedule(self):
        quest = _quest(self.user, days_ahead=1)
        scheduled = ScheduledCall.objects.get(quest=quest)
        self.assertEqual(scheduled.user, self.user)
        self.assertEqual(scheduled.status, ScheduledCall.Status.PENDING)
        self.assertEqual(scheduled.local_date, quest.select_a_date)

    def test_quest_without_call_enabled_creates_nothing(self):
        quest = _quest(self.user, enable_call=False, days_ahead=1)
        self.assertFalse(ScheduledCall.objects.filter(quest=quest).exists())

    def test_quest_without_a_time_cannot_be_scheduled(self):
        """"Sometime today" is not a reminder."""
        quest = Quests.objects.create(
            user=self.user, task='Vague plan', zone='Soft steps',
            select_a_date=timezone.localdate() + timedelta(days=1),
            select_a_time=None, enable_call=True,
        )
        self.assertFalse(ScheduledCall.objects.filter(quest=quest).exists())

    def test_the_exact_minute_survives_the_whole_chain(self):
        """16:30 must stay 16:30 — not round to the hour anywhere.

        The time crosses several conversions on its way to a reminder: an "HH:MM" string
        from the picker, a TimeField, `datetime.combine`, timezone-awareness, then ISO-8601
        for the app. Any one of them silently dropping minutes would put every reminder on
        the hour.
        """
        for hh, mm in [(16, 30), (6, 5), (23, 59), (9, 1), (18, 42)]:
            quest = _quest(self.user, days_ahead=1, at=time(hh, mm), task=f'{hh}:{mm}')
            local = timezone.localtime(ScheduledCall.objects.get(quest=quest).scheduled_for)
            self.assertEqual(
                (local.hour, local.minute), (hh, mm),
                msg=f'{hh:02d}:{mm:02d} came back as {local.hour:02d}:{local.minute:02d}',
            )

    def test_a_time_string_from_the_picker_keeps_its_minutes(self):
        """The picker sends "HH:MM".

        post_save sees whatever is in memory, so a caller that assigns the raw string (a
        management command, a fixture, a seed) hands us a str rather than a time. It must
        still schedule 16:30, not blow up.
        """
        quest = Quests.objects.create(
            user=self.user, task='Half past four', zone='Soft steps',
            select_a_date=str(timezone.localdate() + timedelta(days=1)),
            select_a_time='16:30',  # exactly what TimePickerCard emits
            enable_call=True,
        )
        local = timezone.localtime(ScheduledCall.objects.get(quest=quest).scheduled_for)
        self.assertEqual((local.hour, local.minute), (16, 30))

    def test_a_quest_still_saves_when_scheduling_its_call_blows_up(self):
        """The reminder is a convenience; the quest is the user's actual work.

        Whatever goes wrong while scheduling, it must not make the quest impossible to
        create — that would turn a missing reminder into lost work.
        """
        with mock.patch(
            'Apps.voice_calls.signals._sync_scheduled_call',
            side_effect=RuntimeError('scheduling exploded'),
        ):
            quest = _quest(self.user, days_ahead=1)

        self.assertIsNotNone(quest.pk)
        self.assertFalse(ScheduledCall.objects.filter(quest=quest).exists())

    def test_moving_the_quest_moves_the_call(self):
        quest = _quest(self.user, days_ahead=1)
        original = ScheduledCall.objects.get(quest=quest).scheduled_for

        quest.select_a_time = time(18, 30)
        quest.save()

        scheduled = ScheduledCall.objects.get(quest=quest)
        self.assertNotEqual(scheduled.scheduled_for, original)
        self.assertEqual(timezone.localtime(scheduled.scheduled_for).hour, 18)

    def test_turning_the_toggle_off_cancels_the_call(self):
        quest = _quest(self.user, days_ahead=1)
        quest.enable_call = False
        quest.save()
        self.assertEqual(
            ScheduledCall.objects.get(quest=quest).status,
            ScheduledCall.Status.CANCELLED,
        )

    def test_turning_the_toggle_back_on_revives_the_same_row(self):
        """Re-enabling must not leave two schedules behind for one quest."""
        quest = _quest(self.user, days_ahead=1)
        quest.enable_call = False
        quest.save()
        quest.enable_call = True
        quest.save()

        rows = ScheduledCall.objects.filter(quest=quest)
        self.assertEqual(rows.count(), 1)
        self.assertEqual(rows.first().status, ScheduledCall.Status.PENDING)

    def test_deleting_the_quest_removes_the_schedule(self):
        quest = _quest(self.user, days_ahead=1)
        quest.delete()
        self.assertFalse(ScheduledCall.objects.filter(user=self.user).exists())

    def test_a_repeated_quest_schedules_each_day(self):
        """"Repeat quest" materializes one row per day; each must get its own reminder."""
        for day in range(7):
            _quest(self.user, days_ahead=day, task=f'Day {day}')
        self.assertEqual(ScheduledCall.objects.filter(user=self.user).count(), 7)

    def test_completed_calls_are_not_rewritten_by_editing_the_quest(self):
        quest = _quest(self.user, days_ahead=0, at=time(9, 0))
        scheduled = ScheduledCall.objects.get(quest=quest)
        scheduled.status = ScheduledCall.Status.COMPLETED
        scheduled.save(update_fields=['status'])

        quest.select_a_time = time(21, 0)
        quest.save()

        scheduled.refresh_from_db()
        self.assertEqual(scheduled.status, ScheduledCall.Status.COMPLETED)


class ResolvedStatusTests(TestCase):
    """`missed` is derived on read — nothing has to run at midnight for it to be true."""

    def setUp(self):
        self.user = _make_user('sleeper')

    def _scheduled(self, *, offset):
        when = timezone.now() + offset
        return ScheduledCall.objects.create(
            user=self.user, scheduled_for=when,
            local_date=timezone.localtime(when).date(),
        )

    def test_future_pending_call_is_pending(self):
        self.assertEqual(
            self._scheduled(offset=timedelta(hours=2)).resolved_status,
            ScheduledCall.Status.PENDING,
        )

    def test_past_pending_call_reads_as_missed(self):
        self.assertEqual(
            self._scheduled(offset=timedelta(hours=-2)).resolved_status,
            ScheduledCall.MISSED,
        )

    def test_past_completed_call_is_still_completed(self):
        scheduled = self._scheduled(offset=timedelta(hours=-2))
        scheduled.status = ScheduledCall.Status.COMPLETED
        scheduled.save(update_fields=['status'])
        self.assertEqual(scheduled.resolved_status, ScheduledCall.Status.COMPLETED)


@override_settings(VOICE_CALL_DAILY_LIMIT=2, VOICE_CALL_UNLIMITED_USERS=[],
                   SUBSCRIPTION_ENFORCED=False)
class ScheduledCallApiTests(TestCase):
    def setUp(self):
        self.user = _make_user('planner')
        self.other = _make_user('stranger')
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)
        self.list_url = reverse('voice_calls:scheduled-call-list')
        self.start_url = reverse('voice_calls:voice-call-start')

    def test_list_returns_only_my_calls(self):
        _quest(self.user, days_ahead=1)
        _quest(self.other, days_ahead=1)
        response = self.client.get(self.list_url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)

    def test_list_hides_cancelled_calls(self):
        quest = _quest(self.user, days_ahead=1)
        quest.enable_call = False
        quest.save()
        self.assertEqual(len(self.client.get(self.list_url).data), 0)

    def test_list_carries_the_quest_title_for_the_reminder(self):
        _quest(self.user, days_ahead=1, task='Call about the interview')
        row = self.client.get(self.list_url).data[0]
        self.assertEqual(row['quest_title'], 'Call about the interview')

    def test_starting_a_call_completes_its_schedule(self):
        quest = _quest(self.user, days_ahead=0, at=time(23, 59))
        scheduled = ScheduledCall.objects.get(quest=quest)

        response = self.client.post(
            self.start_url, {'scheduled_call_id': scheduled.pk}, format='json',
        )
        self.assertEqual(response.status_code, 201)

        scheduled.refresh_from_db()
        self.assertEqual(scheduled.status, ScheduledCall.Status.COMPLETED)
        self.assertEqual(scheduled.call_id, response.data['id'])

    def test_someone_elses_schedule_is_not_completed(self):
        quest = _quest(self.other, days_ahead=0, at=time(23, 59))
        scheduled = ScheduledCall.objects.get(quest=quest)

        response = self.client.post(
            self.start_url, {'scheduled_call_id': scheduled.pk}, format='json',
        )
        # The call still starts — a bad id must not cost the caller one of their calls.
        self.assertEqual(response.status_code, 201)
        scheduled.refresh_from_db()
        self.assertEqual(scheduled.status, ScheduledCall.Status.PENDING)

    def test_a_junk_schedule_id_does_not_break_the_call(self):
        response = self.client.post(
            self.start_url, {'scheduled_call_id': 'not-a-number'}, format='json',
        )
        self.assertEqual(response.status_code, 201)

    # ── the whole point: plans do not reserve quota ──────────────────────────
    def test_scheduling_three_calls_does_not_raise_the_daily_limit(self):
        for hour in (9, 13, 17):
            _quest(self.user, days_ahead=0, at=time(hour, 0), task=f'Quest {hour}')
        rows = list(ScheduledCall.objects.filter(user=self.user).order_by('scheduled_for'))
        self.assertEqual(len(rows), 3)

        for row in rows[:2]:
            self.assertEqual(
                self.client.post(self.start_url, {'scheduled_call_id': row.pk},
                                 format='json').status_code,
                201,
            )

        third = self.client.post(
            self.start_url, {'scheduled_call_id': rows[2].pk}, format='json',
        )
        self.assertEqual(third.status_code, 429)
        rows[2].refresh_from_db()
        self.assertEqual(rows[2].status, ScheduledCall.Status.PENDING,
                         msg='a call that never happened must not be marked completed')

    def test_a_spontaneous_call_can_strand_a_scheduled_one(self):
        """The client's exact scenario: one call used, one scheduled, then a swipe.

        The swipe spends the last call, so the scheduled one can no longer run. The backend
        leaves it pending — it is the app that renders this as "locked".
        """
        quest = _quest(self.user, days_ahead=0, at=time(23, 59))
        scheduled = ScheduledCall.objects.get(quest=quest)

        self.client.post(self.start_url, {}, format='json')  # earlier call
        self.client.post(self.start_url, {}, format='json')  # the swipe

        blocked = self.client.post(
            self.start_url, {'scheduled_call_id': scheduled.pk}, format='json',
        )
        self.assertEqual(blocked.status_code, 429)
        self.assertEqual(blocked.data['remaining'], 0)
        scheduled.refresh_from_db()
        self.assertEqual(scheduled.status, ScheduledCall.Status.PENDING)


@override_settings(SUBSCRIPTION_ENFORCED=False)
class ScheduledCallDetailTests(TestCase):
    def setUp(self):
        self.user = _make_user('rescheduler')
        self.other = _make_user('nosy')
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)
        self.quest = _quest(self.user, days_ahead=0, at=time(9, 0))
        self.scheduled = ScheduledCall.objects.get(quest=self.quest)
        self.url = reverse('voice_calls:scheduled-call-detail', args=[self.scheduled.pk])

    def _tomorrow_at(self, hour):
        local = timezone.localtime(timezone.now()) + timedelta(days=1)
        return local.replace(hour=hour, minute=0, second=0, microsecond=0).isoformat()

    def test_moving_to_tomorrow_also_moves_the_quest(self):
        response = self.client.patch(
            self.url, {'scheduled_for': self._tomorrow_at(16)}, format='json',
        )
        self.assertEqual(response.status_code, 200)

        self.scheduled.refresh_from_db()
        self.quest.refresh_from_db()
        self.assertEqual(self.scheduled.status, ScheduledCall.Status.PENDING)
        self.assertEqual(self.quest.select_a_date, self.scheduled.local_date)
        self.assertEqual(self.quest.select_a_time.hour, 16)

    def test_cancelling(self):
        response = self.client.patch(self.url, {'cancel': True}, format='json')
        self.assertEqual(response.status_code, 200)
        self.scheduled.refresh_from_db()
        self.assertEqual(self.scheduled.status, ScheduledCall.Status.CANCELLED)

    def test_a_time_without_an_offset_is_rejected(self):
        """Guessing the user's timezone would put the reminder an hour out."""
        response = self.client.patch(
            self.url, {'scheduled_for': '2026-12-31T16:00:00'}, format='json',
        )
        self.assertEqual(response.status_code, 400)

    def test_the_past_is_rejected(self):
        past = (timezone.now() - timedelta(hours=1)).isoformat()
        response = self.client.patch(self.url, {'scheduled_for': past}, format='json')
        self.assertEqual(response.status_code, 400)

    def test_an_empty_body_explains_itself(self):
        response = self.client.patch(self.url, {}, format='json')
        self.assertEqual(response.status_code, 400)

    def test_a_completed_call_cannot_be_moved(self):
        self.scheduled.status = ScheduledCall.Status.COMPLETED
        self.scheduled.save(update_fields=['status'])
        response = self.client.patch(
            self.url, {'scheduled_for': self._tomorrow_at(16)}, format='json',
        )
        self.assertEqual(response.status_code, 400)

    def test_cannot_touch_someone_elses_call(self):
        self.client.force_authenticate(user=self.other)
        response = self.client.patch(self.url, {'cancel': True}, format='json')
        self.assertEqual(response.status_code, 404)
