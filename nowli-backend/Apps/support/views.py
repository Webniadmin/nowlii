from django.conf import settings
from django.core.mail import send_mail
from django.utils.decorators import method_decorator

from rest_framework import mixins, viewsets
from rest_framework.permissions import IsAuthenticated

from drf_yasg.utils import swagger_auto_schema

from .models import SupportMessage
from .serializers import SupportMessageSerializer


@method_decorator(name='list', decorator=swagger_auto_schema(
    operation_summary="List my support conversation",
    operation_description="Returns the authenticated user's support messages (oldest first), "
                          "both their own and the support team's replies.",
    tags=['Support'],
))
@method_decorator(name='create', decorator=swagger_auto_schema(
    operation_summary="Send a support message",
    operation_description="Send a message to NOWLII support. Stored on the thread and emailed "
                          "to the support inbox.",
    tags=['Support'],
))
class SupportMessageViewSet(mixins.ListModelMixin,
                            mixins.CreateModelMixin,
                            viewsets.GenericViewSet):
    """`GET /api/support/messages/` — my thread. `POST` — send a message.

    Users can only read/create their own messages; admin replies are added from the
    Django admin panel (sender='admin')."""

    serializer_class = SupportMessageSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        if getattr(self, 'swagger_fake_view', False):
            return SupportMessage.objects.none()
        return SupportMessage.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        message = serializer.save(user=self.request.user, sender='user')
        self._notify_support(message)

    def _notify_support(self, message):
        """Email the support inbox so the team is alerted to a new message."""
        user = self.request.user
        try:
            send_mail(
                subject=f"[NOWLII Support] {message.category or 'Message'} — {user.email}",
                message=(
                    f"New support message from {user.email} (user id {user.id}).\n"
                    f"Category: {message.category or '-'}\n\n"
                    f"{message.body}\n\n"
                    f"— Reply from the Django admin: Support messages → Add support message → "
                    f"pick this user, set sender = admin, type your reply. It appears in their app."
                ),
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[settings.SUPPORT_EMAIL],
                fail_silently=True,
            )
        except Exception:
            pass
