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

from .models import VoiceCall
from .serializers import VoiceCallSerializer


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

        return Response(VoiceCallSerializer(call).data, status=status.HTTP_200_OK)
