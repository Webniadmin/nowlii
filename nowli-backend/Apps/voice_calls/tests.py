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

from .models import CallSummary, ScheduledCall, VoiceCall
from .views import VoiceCallSummaryNoteView, _clean_tiny_question, _clean_words_circled

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


class WordsCircledTests(TestCase):
    """"Words you circled around" — the user's own words, handed back to them.

    Because they are presented as verbatim quotes, anything that does not look
    like something a person said is dropped rather than tidied into shape.
    """

    def test_a_normal_list_survives_intact(self):
        self.assertEqual(
            _clean_words_circled(['should', 'later', 'honestly']),
            ['should', 'later', 'honestly'],
        )

    def test_non_list_input_yields_nothing(self):
        for junk in (None, 'should', 42, {'a': 1}):
            self.assertEqual(_clean_words_circled(junk), [])

    def test_non_string_entries_are_dropped(self):
        self.assertEqual(_clean_words_circled(['should', 7, None, 'later']),
                         ['should', 'later'])

    def test_blank_entries_are_dropped(self):
        self.assertEqual(_clean_words_circled(['should', '   ', '', 'later']),
                         ['should', 'later'])

    def test_a_whole_sentence_is_rejected(self):
        """Guards against the model writing prose instead of quoting a word."""
        sentence = 'you kept saying you should do it later on in the evening'
        self.assertEqual(_clean_words_circled(['should', sentence]), ['should'])

    def test_duplicates_collapse_case_insensitively_keeping_the_first(self):
        self.assertEqual(_clean_words_circled(['Should', 'should', 'SHOULD']),
                         ['Should'])

    def test_the_list_is_capped(self):
        many = [f'word{i}' for i in range(20)]
        self.assertEqual(len(_clean_words_circled(many)), 5)

    def test_surrounding_quotes_are_stripped(self):
        # The UI adds its own quotation marks; doubling them looks like a bug.
        self.assertEqual(_clean_words_circled(['"should"', "'later'"]),
                         ['should', 'later'])


class CallSummaryWordsPersistenceTests(TestCase):
    """The words have to survive the round trip, since nowli-ai forgets them."""

    def setUp(self):
        self.user = User.objects.create_user(
            username='wordsuser', email='words@example.com', password='pw-for-tests-123',
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)
        self.call = VoiceCall.objects.create(user=self.user)

    def _save(self, payload):
        return self.client.post(
            reverse('voice_calls:voice-call-summary', args=[self.call.pk]), payload, format='json',
        )

    def test_words_are_stored_and_returned(self):
        response = self._save({
            'mood_detected': 'You sounded tired.',
            'focus_topic': 'We talked a lot about work.',
            'energy_shift': 'You started out flat.',
            'next_step': 'Rest tonight!',
            'words_circled': ['should', 'later', 'honestly'],
        })
        self.assertIn(response.status_code, (200, 201))

        summary = CallSummary.objects.get(call=self.call)
        self.assertEqual(summary.words_circled, ['should', 'later', 'honestly'])

    def test_a_summary_without_words_is_still_saved(self):
        """A short call has no pattern — that must not block the summary."""
        response = self._save({
            'mood_detected': 'You sounded tired.',
            'focus_topic': 'We talked a lot about work.',
            'energy_shift': 'You started out flat.',
            'next_step': 'Rest tonight!',
        })
        self.assertIn(response.status_code, (200, 201))
        self.assertEqual(CallSummary.objects.get(call=self.call).words_circled, [])

    def test_junk_from_the_model_is_not_persisted(self):
        self._save({
            'mood_detected': 'You sounded tired.',
            'focus_topic': 'We talked a lot about work.',
            'energy_shift': 'You started out flat.',
            'next_step': 'Rest tonight!',
            'words_circled': 'should, later',
        })
        self.assertEqual(CallSummary.objects.get(call=self.call).words_circled, [])


class CallReceiptNoteTests(TestCase):
    """The note is the one field on a receipt the user writes themselves.

    Everything else is generated at call end, which is exactly what makes this risky: the
    app re-posts the summary whenever the summary screen is shown, and that must not take
    the user's own words with it.
    """

    def setUp(self):
        self.user = _make_user('noteuser')
        self.other = _make_user('notestranger')
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)
        self.call = VoiceCall.objects.create(user=self.user)
        self.summary = CallSummary.objects.create(
            call=self.call,
            user=self.user,
            mood_detected='You sounded tired.',
            focus_topic='Work came up a lot.',
            energy_shift='You started out flat.',
            next_step='Rest tonight!',
        )

    def _url(self, call_id=None):
        return reverse(
            'voice_calls:voice-call-summary-note', args=[call_id or self.call.pk],
        )

    def _patch(self, payload, url=None):
        return self.client.patch(url or self._url(), payload, format='json')

    def test_a_note_is_saved_and_returned(self):
        response = self._patch({'note': 'Felt better after this one.'})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['note'], 'Felt better after this one.')

        self.summary.refresh_from_db()
        self.assertEqual(self.summary.note, 'Felt better after this one.')
        self.assertIsNotNone(self.summary.note_updated_at)

    def test_editing_replaces_the_note(self):
        self._patch({'note': 'First thought.'})
        self._patch({'note': 'Actually, second thought.'})
        self.summary.refresh_from_db()
        self.assertEqual(self.summary.note, 'Actually, second thought.')

    def test_an_empty_note_clears_it_and_its_timestamp(self):
        self._patch({'note': 'Something.'})
        response = self._patch({'note': ''})
        self.assertEqual(response.status_code, 200)

        self.summary.refresh_from_db()
        self.assertEqual(self.summary.note, '')
        # "edited just now" under an empty note would read as though something was saved.
        self.assertIsNone(self.summary.note_updated_at)

    def test_whitespace_only_counts_as_clearing(self):
        self._patch({'note': 'Something.'})
        self._patch({'note': '   \n  '})
        self.summary.refresh_from_db()
        self.assertEqual(self.summary.note, '')

    def test_resaving_the_summary_keeps_the_note(self):
        """The whole reason the note has its own endpoint."""
        self._patch({'note': 'Do not lose me.'})

        self.client.post(
            reverse('voice_calls:voice-call-summary', args=[self.call.pk]),
            {
                'mood_detected': 'You sounded tired.',
                'focus_topic': 'Work came up a lot.',
                'energy_shift': 'You started out flat.',
                'next_step': 'Rest tonight!',
            },
            format='json',
        )

        self.summary.refresh_from_db()
        self.assertEqual(self.summary.note, 'Do not lose me.')

    def test_another_users_receipt_is_not_found(self):
        self.client.force_authenticate(user=self.other)
        self.assertEqual(self._patch({'note': 'mine now'}).status_code, 404)
        self.summary.refresh_from_db()
        self.assertEqual(self.summary.note, '')

    def test_a_call_with_no_summary_is_not_found(self):
        bare_call = VoiceCall.objects.create(user=self.user)
        self.assertEqual(
            self._patch({'note': 'hello'}, url=self._url(bare_call.pk)).status_code, 404,
        )

    def test_a_missing_note_field_is_rejected(self):
        # Distinct from an empty string, which deliberately means "delete it".
        self.assertEqual(self._patch({}).status_code, 400)

    def test_a_non_string_note_is_rejected(self):
        self.assertEqual(self._patch({'note': {'text': 'nope'}}).status_code, 400)

    def test_an_over_long_note_is_rejected(self):
        too_long = 'x' * (VoiceCallSummaryNoteView.MAX_NOTE_LENGTH + 1)
        self.assertEqual(self._patch({'note': too_long}).status_code, 400)
        self.summary.refresh_from_db()
        self.assertEqual(self.summary.note, '')

    def test_a_note_at_the_limit_is_accepted(self):
        at_limit = 'x' * VoiceCallSummaryNoteView.MAX_NOTE_LENGTH
        self.assertEqual(self._patch({'note': at_limit}).status_code, 200)

    def test_the_note_appears_in_the_receipts_list(self):
        self._patch({'note': 'Shows up in the list.'})
        response = self.client.get(reverse('voice_calls:voice-call-summaries'))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data[0]['note'], 'Shows up in the list.')


class TinyQuestionTests(TestCase):
    """The receipt prints this verbatim, so a non-question must never reach the card."""

    def test_a_short_question_is_kept(self):
        self.assertEqual(
            _clean_tiny_question("What's the first click?"), "What's the first click?",
        )

    def test_surrounding_quotes_are_stripped(self):
        self.assertEqual(_clean_tiny_question('"What is next?"'), 'What is next?')

    def test_a_statement_is_dropped(self):
        # The model was asked for a question; a sentence means it did something else.
        self.assertEqual(_clean_tiny_question('You should open the file.'), '')

    def test_a_paragraph_is_dropped(self):
        rambling = 'What is the first click? ' + ('and then what happens ' * 20)
        self.assertEqual(_clean_tiny_question(rambling), '')

    def test_junk_types_are_dropped(self):
        for junk in (None, 42, ['What?'], {'q': 'What?'}):
            self.assertEqual(_clean_tiny_question(junk), '')

    def test_empty_stays_empty(self):
        # An honest "nothing to ask here" — the card hides.
        self.assertEqual(_clean_tiny_question('   '), '')


class TinyQuestionPersistenceTests(TestCase):
    """It has to survive the round trip, since nowli-ai forgets the session."""

    def setUp(self):
        self.user = _make_user('tinyq')
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)
        self.call = VoiceCall.objects.create(user=self.user)

    def _save(self, extra):
        payload = {
            'mood_detected': 'You sounded tired.',
            'focus_topic': 'Work came up a lot.',
            'energy_shift': 'You started out flat.',
            'next_step': 'Open the file.',
        }
        payload.update(extra)
        return self.client.post(
            reverse('voice_calls:voice-call-summary', args=[self.call.pk]),
            payload, format='json',
        )

    def test_it_is_stored_and_returned(self):
        response = self._save({'tiny_question': "What's the first click?"})
        self.assertIn(response.status_code, (200, 201))
        self.assertEqual(
            CallSummary.objects.get(call=self.call).tiny_question,
            "What's the first click?",
        )

    def test_a_summary_without_one_is_still_saved(self):
        response = self._save({})
        self.assertIn(response.status_code, (200, 201))
        self.assertEqual(CallSummary.objects.get(call=self.call).tiny_question, '')

    def test_a_statement_from_the_model_is_not_persisted(self):
        self._save({'tiny_question': 'Just open the file.'})
        self.assertEqual(CallSummary.objects.get(call=self.call).tiny_question, '')

    def test_it_appears_in_the_receipts_list(self):
        self._save({'tiny_question': 'What is the first click?'})
        response = self.client.get(reverse('voice_calls:voice-call-summaries'))
        self.assertEqual(response.data[0]['tiny_question'], 'What is the first click?')
