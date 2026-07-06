from django.conf import settings
from django.db import models


class VoiceCall(models.Model):
    """One AI voice-call session for a user.

    The row is created the moment a call *starts* — that is what the per-user daily
    limit counts, so a user cannot bypass the limit by force-quitting mid-call. It is
    finalized (``ended_at``, ``duration_seconds``, ``extension_used``, ``status``) when
    the call ends. The daily count is derived by querying rows for the current day, so
    there is no counter to reset and no scheduled job is needed.
    """

    class Status(models.TextChoices):
        ACTIVE = 'active', 'Active'
        COMPLETED = 'completed', 'Completed'

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='voice_calls',
    )
    # nowli-ai session id (that service keeps sessions in memory only); optional,
    # stored here purely for cross-referencing a call with its AI session.
    session_id = models.CharField(max_length=64, blank=True, null=True)
    started_at = models.DateTimeField(auto_now_add=True)
    ended_at = models.DateTimeField(blank=True, null=True)
    duration_seconds = models.PositiveIntegerField(default=0)
    extension_used = models.BooleanField(default=False)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)

    class Meta:
        ordering = ['-started_at']
        verbose_name = 'Voice call'
        verbose_name_plural = 'Voice calls'
        indexes = [
            models.Index(fields=['user', 'started_at']),
        ]

    def __str__(self):
        return f"user {self.user_id} @ {self.started_at:%Y-%m-%d %H:%M} ({self.status})"
