from django.conf import settings
from django.contrib.auth import get_user_model
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.utils import timezone

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema

from .models import CallEmotionSnapshot, CallLowMoodSnapshot, VoiceCall
from .serializers import VoiceCallSerializer

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


def _calls_used_today(user):
    """Number of voice calls the user has *started* today (server timezone).

    The daily limit is derived from this count, so it resets naturally at 00:00 with no
    counter and no scheduled job. Counting by ``started_at`` (creation) rather than by
    completion means a force-quit mid-call still consumes one of the daily calls.
    """
    today = timezone.localdate()
    return VoiceCall.objects.filter(user=user, started_at__date=today).count()


class VoiceCallQuotaView(APIView):
    """`GET /api/voice-calls/quota/` — how many AI voice calls the user has left today."""

    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_summary="My AI voice-call quota for today",
        tags=['Voice calls'],
    )
    def get(self, request):
        used = _calls_used_today(request.user)
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

    permission_classes = [IsAuthenticated]

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

        with transaction.atomic():
            # Race protection: serialize concurrent start requests for THIS user so two
            # calls cannot both pass the limit check. Locking the user row is a no-op on
            # SQLite (dev) but correct on PostgreSQL (prod) — see docs/technical-debt.md.
            User = get_user_model()
            User.objects.select_for_update().filter(pk=request.user.pk).first()

            used = _calls_used_today(request.user)
            if used >= limit:
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

        data = VoiceCallSerializer(call).data
        data['limit'] = limit
        data['remaining'] = max(0, limit - (used + 1))
        return Response(data, status=status.HTTP_201_CREATED)


class VoiceCallEndView(APIView):
    """`POST /api/voice-calls/<id>/end/` — finalize a call (duration + whether extended).

    Idempotent: ending an already-completed call just returns it unchanged. Does not
    affect the daily count (which is based on the start).
    """

    permission_classes = [IsAuthenticated]

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
