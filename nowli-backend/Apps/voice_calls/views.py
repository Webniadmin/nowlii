from django.conf import settings
from django.contrib.auth import get_user_model
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.dateparse import parse_date, parse_datetime

from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from Apps.subscriptions.permissions import HasProAccess
from rest_framework.response import Response
from rest_framework.views import APIView

from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema

from .models import (
    CallEmotionSnapshot,
    CallLowMoodSnapshot,
    CallSummary,
    ScheduledCall,
    VoiceCall,
)
from .serializers import (
    CallSummarySerializer,
    ScheduledCallSerializer,
    VoiceCallSerializer,
)

# The five Insights "Top Emotions" categories (must match nowli-ai's breakdown keys).
_EMOTION_KEYS = ('happy', 'motivated', 'angry', 'tired', 'sad')


def _persist_emotion_snapshot(call, data):
    """Store the AI Top-Emotion breakdown for a call if the app sent one.

    Best-effort: a missing or malformed ``emotion_breakdown`` just skips the snapshot —
    the call itself still finalizes normally. Idempotent (one snapshot per call).
    """
    breakdown = data.get('emotion_breakdown')
    if not isinstance(breakdown, dict):
        return
    values = {}
    for key in _EMOTION_KEYS:
        try:
            values[key] = max(0.0, float(breakdown.get(key, 0) or 0))
        except (TypeError, ValueError):
            values[key] = 0.0
    if not any(values.values()):
        return
    dominant = data.get('dominant_emotion') or max(values, key=values.get)
    CallEmotionSnapshot.objects.update_or_create(
        call=call,
        defaults={'user': call.user, 'dominant_emotion': str(dominant)[:20], **values},
    )


def _persist_low_mood_snapshot(call, data):
    """Store the canonical low-mood phrases for a call if the app sent any.

    Best-effort: a missing/malformed/empty ``low_mood_phrases`` just skips the snapshot.
    Idempotent (one snapshot per call). Expects a list of
    ``{"phrase": str, "category": str, "count": int}``.
    """
    raw = data.get('low_mood_phrases')
    if not isinstance(raw, list):
        return
    phrases = []
    cat_counts = {}
    for item in raw:
        if not isinstance(item, dict):
            continue
        phrase = str(item.get('phrase') or '').strip()
        if not phrase:
            continue
        category = str(item.get('category') or '').strip()[:32]
        try:
            count = max(1, int(item.get('count') or 1))
        except (TypeError, ValueError):
            count = 1
        phrases.append({'phrase': phrase[:80], 'category': category, 'count': count})
        if category:
            cat_counts[category] = cat_counts.get(category, 0) + count
    if not phrases:
        return
    dominant_category = max(cat_counts, key=cat_counts.get) if cat_counts else ''
    CallLowMoodSnapshot.objects.update_or_create(
        call=call,
        defaults={'user': call.user, 'phrases': phrases, 'dominant_category': dominant_category},
    )


# The five Insights "Top Emotions" categories used inside the summary's emotion split.
_TOP_EMOTION_KEYS = ('happy', 'motivated', 'angry', 'tired', 'sad')


#: Shown back to the user as their own words, so anything that does not look like a
#: word the user said is dropped rather than cleaned up into something plausible.
_WORDS_CIRCLED_MAX = 5
_WORDS_CIRCLED_MAX_CHARS = 32


def _clean_words_circled(raw):
    """Normalise the client's ``words_circled`` list. Never trusts it blindly.

    The app forwards whatever nowli-ai's GPT pass produced, so this re-validates on
    the way in: wrong types, blanks, and anything long enough to be a sentence are
    discarded, duplicates collapse case-insensitively, and the list is capped.
    """
    if not isinstance(raw, list):
        return []

    cleaned, seen = [], set()
    for item in raw:
        if not isinstance(item, str):
            continue
        word = item.strip().strip('"').strip("'").strip()
        if not word or len(word) > _WORDS_CIRCLED_MAX_CHARS:
            continue
        key = word.lower()
        if key in seen:
            continue
        seen.add(key)
        cleaned.append(word)
        if len(cleaned) >= _WORDS_CIRCLED_MAX:
            break
    return cleaned


_TINY_QUESTION_MAX_CHARS = 120


def _clean_tiny_question(raw):
    """Normalise the client's ``tiny_question``. Never trusts it blindly.

    Same reasoning as ``_clean_words_circled``: nowli-ai already sanitises this, but the
    value reaches us through the app, so a caller could send anything. A receipt line
    that is not a short question is dropped — the card hides rather than printing a
    paragraph, or a statement the model slipped in where a question was asked for.
    """
    if not isinstance(raw, str):
        return ''

    question = raw.strip().strip('"').strip("'").strip()
    if not question or len(question) > _TINY_QUESTION_MAX_CHARS:
        return ''
    if '?' not in question:
        return ''
    return question


def _persist_call_summary(call, data):
    """Store the conversational summary for a call if the app sent one.

    Best-effort and idempotent (one summary per call, upserted). The summary text comes
    from nowli-ai's GPT pass over the transcript at call end; the app fetches it to show
    the call-summary screen and hands the same payload here so it survives nowli-ai
    restarts and builds the user's call history.
    """
    mood = str(data.get('mood_detected') or '').strip()
    focus = str(data.get('focus_topic') or '').strip()
    energy = str(data.get('energy_shift') or '').strip()
    nxt = str(data.get('next_step') or '').strip()
    # Nothing worth saving if all four summary sentences are empty.
    if not any((mood, focus, energy, nxt)):
        return None

    raw_top = data.get('top_emotions')
    top_emotions = {}
    if isinstance(raw_top, dict):
        for key in _TOP_EMOTION_KEYS:
            try:
                top_emotions[key] = max(0.0, float(raw_top.get(key, 0) or 0))
            except (TypeError, ValueError):
                top_emotions[key] = 0.0

    try:
        total_turns = max(0, int(data.get('total_turns') or 0))
    except (TypeError, ValueError):
        total_turns = 0

    summary, _ = CallSummary.objects.update_or_create(
        call=call,
        defaults={
            'user': call.user,
            'mood_detected': mood,
            'focus_topic': focus,
            'energy_shift': energy,
            'next_step': nxt,
            'dominant_emotion': str(data.get('dominant_emotion') or '')[:20],
            'top_emotions': top_emotions,
            'words_circled': _clean_words_circled(data.get('words_circled')),
            'tiny_question': _clean_tiny_question(data.get('tiny_question')),
            'language': str(data.get('language') or '')[:8],
            'total_turns': total_turns,
        },
    )
    return summary


def _calls_used_today(user):
    """Number of voice calls the user has *started* today (server timezone).

    The daily limit is derived from this count, so it resets naturally at 00:00 with no
    counter and no scheduled job. Counting by ``started_at`` (creation) rather than by
    completion means a force-quit mid-call still consumes one of the daily calls.
    """
    today = timezone.localdate()
    return VoiceCall.objects.filter(user=user, started_at__date=today).count()


def _is_unlimited_user(user):
    """True if this user bypasses the daily voice-call limit (QA/test accounts).

    Matches the user's username OR email (case-insensitively) against
    ``settings.VOICE_CALL_UNLIMITED_USERS``. Used to let dev/test accounts (e.g. "pavle")
    make unlimited AI voice calls without changing the limit for real users.
    """
    allowlist = getattr(settings, 'VOICE_CALL_UNLIMITED_USERS', None) or []
    if not allowlist:
        return False
    identifiers = {
        str(getattr(user, 'username', '') or '').strip().lower(),
        str(getattr(user, 'email', '') or '').strip().lower(),
    }
    identifiers.discard('')
    return bool(identifiers & set(allowlist))


class VoiceCallQuotaView(APIView):
    """`GET /api/voice-calls/quota/` — how many AI voice calls the user has left today."""

    permission_classes = [IsAuthenticated, HasProAccess]

    @swagger_auto_schema(
        operation_summary="My AI voice-call quota for today",
        tags=['Voice calls'],
    )
    def get(self, request):
        used = _calls_used_today(request.user)
        if _is_unlimited_user(request.user):
            # Test/QA account: report an effectively unlimited quota so the app never
            # blocks the call button. -1 signals "no limit" to the frontend.
            return Response({'limit': -1, 'used': used, 'remaining': -1, 'unlimited': True})
        limit = settings.VOICE_CALL_DAILY_LIMIT
        return Response({
            'limit': limit,
            'used': used,
            'remaining': max(0, limit - used),
        })


class VoiceCallStartView(APIView):
    """`POST /api/voice-calls/start/` — register the start of a call and enforce the limit.

    The daily limit is enforced here on the server — the frontend is never the authority.
    Returns 429 when the user is out of calls for the day, otherwise 201 with the new
    call id and the remaining count.
    """

    permission_classes = [IsAuthenticated, HasProAccess]

    @swagger_auto_schema(
        operation_summary="Start an AI voice call (enforces the daily limit)",
        tags=['Voice calls'],
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                'session_id': openapi.Schema(type=openapi.TYPE_STRING,
                                             description='Optional nowli-ai session id.'),
            },
        ),
        responses={201: VoiceCallSerializer, 429: 'Daily limit reached'},
    )
    def post(self, request):
        limit = settings.VOICE_CALL_DAILY_LIMIT
        unlimited = _is_unlimited_user(request.user)

        with transaction.atomic():
            # Race protection: serialize concurrent start requests for THIS user so two
            # calls cannot both pass the limit check. Locking the user row is a no-op on
            # SQLite (dev) but correct on PostgreSQL (prod) — see docs/technical-debt.md.
            User = get_user_model()
            User.objects.select_for_update().filter(pk=request.user.pk).first()

            used = _calls_used_today(request.user)
            if not unlimited and used >= limit:
                return Response(
                    {
                        'detail': 'Daily AI voice-call limit reached.',
                        'limit': limit,
                        'used': used,
                        'remaining': 0,
                    },
                    status=status.HTTP_429_TOO_MANY_REQUESTS,
                )

            call = VoiceCall.objects.create(
                user=request.user,
                session_id=(request.data.get('session_id') or None),
            )

            # If this call was started from a scheduled reminder, close that plan out. Done
            # inside the same transaction so a call can never exist with its schedule still
            # showing as pending. Silently ignored if the id is unknown or someone else's —
            # a bad id must not cost the user a call they already started.
            self._complete_scheduled_call(request, call)

        data = VoiceCallSerializer(call).data
        if unlimited:
            data['limit'] = -1
            data['remaining'] = -1
            data['unlimited'] = True
        else:
            data['limit'] = limit
            data['remaining'] = max(0, limit - (used + 1))
        return Response(data, status=status.HTTP_201_CREATED)

    @staticmethod
    def _complete_scheduled_call(request, call):
        """Mark the plan this call came from as done, if the app named one."""
        raw = request.data.get('scheduled_call_id')
        if raw in (None, ''):
            return
        try:
            scheduled_id = int(raw)
        except (TypeError, ValueError):
            return

        scheduled = ScheduledCall.objects.filter(
            pk=scheduled_id,
            user=request.user,
            status=ScheduledCall.Status.PENDING,
        ).first()
        if scheduled is None:
            return

        scheduled.status = ScheduledCall.Status.COMPLETED
        scheduled.call = call
        scheduled.save(update_fields=['status', 'call', 'updated_at'])


class VoiceCallEndView(APIView):
    """`POST /api/voice-calls/<id>/end/` — finalize a call (duration + whether extended).

    Idempotent: ending an already-completed call just returns it unchanged. Does not
    affect the daily count (which is based on the start).
    """

    permission_classes = [IsAuthenticated, HasProAccess]

    @swagger_auto_schema(
        operation_summary="End an AI voice call",
        tags=['Voice calls'],
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                'duration_seconds': openapi.Schema(type=openapi.TYPE_INTEGER),
                'extension_used': openapi.Schema(type=openapi.TYPE_BOOLEAN),
                'emotion_breakdown': openapi.Schema(
                    type=openapi.TYPE_OBJECT,
                    description='Optional AI Top-Emotion percentages: '
                                'happy/motivated/angry/tired/sad.',
                ),
                'dominant_emotion': openapi.Schema(type=openapi.TYPE_STRING),
                'low_mood_phrases': openapi.Schema(
                    type=openapi.TYPE_ARRAY,
                    items=openapi.Schema(type=openapi.TYPE_OBJECT),
                    description='Optional canonical low-mood phrases: '
                                '[{phrase, category, count}].',
                ),
            },
        ),
        responses={200: VoiceCallSerializer},
    )
    def post(self, request, pk):
        call = get_object_or_404(VoiceCall, pk=pk, user=request.user)

        if call.status != VoiceCall.Status.COMPLETED:
            try:
                duration = int(request.data.get('duration_seconds') or 0)
            except (TypeError, ValueError):
                duration = 0
            call.ended_at = timezone.now()
            call.duration_seconds = max(0, duration)
            call.extension_used = bool(request.data.get('extension_used') or False)
            call.status = VoiceCall.Status.COMPLETED
            call.save(update_fields=['ended_at', 'duration_seconds', 'extension_used', 'status'])

        # Persist the AI Top-Emotion breakdown + low-mood phrases if the app captured them at
        # call end. Done outside the status guard so a late/retried payload still lands even
        # after the call was already finalized.
        _persist_emotion_snapshot(call, request.data)
        _persist_low_mood_snapshot(call, request.data)

        return Response(VoiceCallSerializer(call).data, status=status.HTTP_200_OK)


class VoiceCallSummaryView(APIView):
    """`POST /api/voice-calls/<id>/summary/` — save the call's conversational summary.

    The app generates the summary via nowli-ai at call end (to show the summary screen)
    and posts it here so it is persisted per user. Idempotent: re-posting upserts the one
    summary for the call. Separate from the `end` endpoint because the summary is produced
    by (and posted from) the summary screen, after the call has already been finalized.
    """

    permission_classes = [IsAuthenticated, HasProAccess]

    @swagger_auto_schema(
        operation_summary="Save an AI voice call's summary",
        tags=['Voice calls'],
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                'mood_detected': openapi.Schema(type=openapi.TYPE_STRING),
                'focus_topic': openapi.Schema(type=openapi.TYPE_STRING),
                'energy_shift': openapi.Schema(type=openapi.TYPE_STRING),
                'next_step': openapi.Schema(type=openapi.TYPE_STRING),
                'dominant_emotion': openapi.Schema(type=openapi.TYPE_STRING),
                'top_emotions': openapi.Schema(
                    type=openapi.TYPE_OBJECT,
                    description='5-category split: happy/motivated/angry/tired/sad.',
                ),
                'words_circled': openapi.Schema(
                    type=openapi.TYPE_ARRAY,
                    items=openapi.Schema(type=openapi.TYPE_STRING),
                    description="The user's own repeated words, verbatim.",
                ),
                'tiny_question': openapi.Schema(
                    type=openapi.TYPE_STRING,
                    description='One short question printed on the receipt.',
                ),
                'language': openapi.Schema(type=openapi.TYPE_STRING),
                'total_turns': openapi.Schema(type=openapi.TYPE_INTEGER),
            },
        ),
        responses={200: CallSummarySerializer, 201: CallSummarySerializer},
    )
    def post(self, request, pk):
        call = get_object_or_404(VoiceCall, pk=pk, user=request.user)
        existed = CallSummary.objects.filter(call=call).exists()
        summary = _persist_call_summary(call, request.data)
        if summary is None:
            # Nothing worth saving (empty payload) — surface it without erroring the app.
            return Response(
                {'detail': 'No summary content to save.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        code = status.HTTP_200_OK if existed else status.HTTP_201_CREATED
        return Response(CallSummarySerializer(summary).data, status=code)


class VoiceCallSummaryNoteView(APIView):
    """`PATCH /api/voice-calls/<id>/summary/note/` — the user's own note on a receipt.

    Separate from the summary upsert above because the two have opposite owners: that one
    is written by the app from generated content at call end, this one is written by the
    user, later, and must never be clobbered by a re-post of the summary.

    An empty string is a valid value — it is how a note gets deleted.
    """

    permission_classes = [IsAuthenticated, HasProAccess]

    #: Long enough for a real reflection, short enough that the column is not an open door.
    MAX_NOTE_LENGTH = 2000

    @swagger_auto_schema(
        operation_summary="Add, edit or clear the note on a call receipt",
        tags=['Voice calls'],
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={'note': openapi.Schema(type=openapi.TYPE_STRING)},
            required=['note'],
        ),
        responses={200: CallSummarySerializer, 404: 'No summary for this call'},
    )
    def patch(self, request, pk):
        # Filtering on the user here is what makes another account's receipt a 404 rather
        # than something this endpoint will happily annotate.
        summary = get_object_or_404(CallSummary, call_id=pk, user=request.user)

        if 'note' not in request.data:
            return Response(
                {'detail': "Field 'note' is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        note = request.data.get('note')
        if note is None:
            note = ''
        if not isinstance(note, str):
            return Response(
                {'detail': "Field 'note' must be a string."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        note = note.strip()
        if len(note) > self.MAX_NOTE_LENGTH:
            return Response(
                {
                    'detail': f'Note is too long (max {self.MAX_NOTE_LENGTH} characters).',
                    'max_length': self.MAX_NOTE_LENGTH,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        summary.note = note
        # Cleared notes carry no timestamp — "edited just now" under an empty note reads
        # as though something was saved.
        summary.note_updated_at = timezone.now() if note else None
        summary.save(update_fields=['note', 'note_updated_at'])

        return Response(CallSummarySerializer(summary).data)


class VoiceCallSummaryListView(APIView):
    """`GET /api/voice-calls/summaries/` — the current user's saved call summaries.

    Newest first, for the user's call history and to review progress over time.
    """

    permission_classes = [IsAuthenticated, HasProAccess]

    @swagger_auto_schema(
        operation_summary="My saved AI voice-call summaries",
        tags=['Voice calls'],
        responses={200: CallSummarySerializer(many=True)},
    )
    def get(self, request):
        summaries = (
            CallSummary.objects
            .filter(user=request.user)
            .select_related('call')
        )
        return Response(CallSummarySerializer(summaries, many=True).data)


class ScheduledCallListView(APIView):
    """`GET /api/voice-calls/scheduled/` — the user's planned calls.

    Defaults to today and everything ahead, which is all the app needs to render the quest
    cards and lay down local reminders. Pass ``?from=YYYY-MM-DD`` to look further back.

    These are plans, not bookings: nothing here reserves a slot against the daily limit. Two
    calls a day remain two calls a day no matter how many are scheduled, and the app resolves
    the shortfall into a "locked" state on the quest.
    """

    permission_classes = [IsAuthenticated, HasProAccess]

    @swagger_auto_schema(
        operation_summary="My scheduled AI voice calls",
        tags=['Voice calls'],
        manual_parameters=[
            openapi.Parameter(
                'from', openapi.IN_QUERY,
                description='Earliest local date to include (YYYY-MM-DD). Defaults to today.',
                type=openapi.TYPE_STRING,
            ),
        ],
        responses={200: ScheduledCallSerializer(many=True)},
    )
    def get(self, request):
        start = parse_date(request.query_params.get('from') or '') or timezone.localdate()
        scheduled = (
            ScheduledCall.objects
            .filter(user=request.user, local_date__gte=start)
            .exclude(status=ScheduledCall.Status.CANCELLED)
            .select_related('quest', 'call')
        )
        return Response(ScheduledCallSerializer(scheduled, many=True).data)


class ScheduledCallDetailView(APIView):
    """`PATCH /api/voice-calls/scheduled/<id>/` — move or cancel a planned call.

    The two things a user can do with a call they cannot take right now: push it to another
    time (typically tomorrow, when the daily limit has reset) or drop it.

    Body: ``{"scheduled_for": "<ISO-8601 with offset>"}`` to move, or ``{"cancel": true}``.
    Moving also moves the quest's own time, so the two never disagree — the quest is what the
    user sees and edits.
    """

    permission_classes = [IsAuthenticated, HasProAccess]

    @swagger_auto_schema(
        operation_summary="Move or cancel a scheduled AI voice call",
        tags=['Voice calls'],
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                'scheduled_for': openapi.Schema(
                    type=openapi.TYPE_STRING,
                    description='New time, ISO-8601 WITH a UTC offset, e.g. '
                                '2026-07-31T16:00:00+02:00.',
                ),
                'cancel': openapi.Schema(type=openapi.TYPE_BOOLEAN),
            },
        ),
        responses={200: ScheduledCallSerializer, 400: 'Bad request', 404: 'Not found'},
    )
    def patch(self, request, pk):
        scheduled = get_object_or_404(ScheduledCall, pk=pk, user=request.user)

        if scheduled.status == ScheduledCall.Status.COMPLETED:
            return Response(
                {'detail': 'This call already happened.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if request.data.get('cancel'):
            scheduled.status = ScheduledCall.Status.CANCELLED
            scheduled.save(update_fields=['status', 'updated_at'])
            return Response(ScheduledCallSerializer(scheduled).data)

        raw = request.data.get('scheduled_for')
        if not raw:
            return Response(
                {'detail': 'Provide "scheduled_for" to move the call, or "cancel": true.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        new_time = parse_datetime(str(raw))
        if new_time is None:
            return Response(
                {'detail': 'scheduled_for must be an ISO-8601 datetime.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if timezone.is_naive(new_time):
            # Without an offset we would be guessing the user's timezone — and guessing wrong
            # puts the reminder an hour out. Make the app say what it means.
            return Response(
                {'detail': 'scheduled_for must include a UTC offset, e.g. '
                           '2026-07-31T16:00:00+02:00.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if new_time <= timezone.now():
            return Response(
                {'detail': 'Pick a time in the future.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        scheduled.scheduled_for = new_time
        scheduled.local_date = timezone.localtime(new_time).date()
        scheduled.status = ScheduledCall.Status.PENDING
        scheduled.save(update_fields=['scheduled_for', 'local_date', 'status', 'updated_at'])

        # Keep the quest in step. Saving it re-fires the sync signal, which is harmless: it
        # sees the row already matches and changes nothing.
        quest = scheduled.quest
        if quest is not None:
            local = timezone.localtime(new_time)
            quest.select_a_date = local.date()
            quest.select_a_time = local.time().replace(microsecond=0)
            quest.save(update_fields=['select_a_date', 'select_a_time'])

        return Response(ScheduledCallSerializer(scheduled).data)
