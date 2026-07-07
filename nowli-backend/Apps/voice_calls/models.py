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


class CallEmotionSnapshot(models.Model):
    """The AI Top-Emotion breakdown for a single voice call, captured at call end.

    ``nowli-ai`` keeps conversation sessions in memory only, so the app fetches the
    5-category emotion breakdown while the session is still alive (right when the call
    ends) and hands it to the end endpoint, which stores it here. Persisting it means it
    survives ``nowli-ai`` restarts and lets the Insights "Top Emotions" section aggregate
    across a user's calls over time. One snapshot per call.
    """

    call = models.OneToOneField(
        VoiceCall,
        on_delete=models.CASCADE,
        related_name='emotion_snapshot',
    )
    # Denormalized from ``call.user`` so the Insights aggregation can filter by user
    # and date without joining through VoiceCall.
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='call_emotion_snapshots',
    )
    # Percentages (0–100) for the five Insights categories; they sum to ~100.
    happy     = models.FloatField(default=0)
    motivated = models.FloatField(default=0)
    angry     = models.FloatField(default=0)
    tired     = models.FloatField(default=0)
    sad       = models.FloatField(default=0)
    dominant_emotion = models.CharField(max_length=20, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Call emotion snapshot'
        verbose_name_plural = 'Call emotion snapshots'
        indexes = [
            models.Index(fields=['user', 'created_at']),
        ]

    def __str__(self):
        return f"emotions for call {self.call_id} ({self.dominant_emotion or 'n/a'})"


class CallLowMoodSnapshot(models.Model):
    """Recurring low-mood phrases detected in a single voice call, captured at call end.

    Feeds the Insights "When feeling low, you often say things like:" section. Like the
    emotion snapshot, this is stored per call/user because the ``nowli-ai`` transcript is
    in-memory only. ``phrases`` holds the canonical, deduped phrases for this call with a
    per-turn count, e.g. ``[{"phrase": "I can't", "category": "helplessness", "count": 2}]``;
    Django aggregates frequency across the week. Kept separate from ``CallEmotionSnapshot``
    (different concern). One snapshot per call.
    """

    call = models.OneToOneField(
        VoiceCall,
        on_delete=models.CASCADE,
        related_name='low_mood_snapshot',
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='call_low_mood_snapshots',
    )
    # List of {"phrase": str, "category": str, "count": int} (canonical, deduped per call).
    phrases = models.JSONField(default=list)
    # Most frequent phrase category in this call — used to pick placeholder "what this means".
    dominant_category = models.CharField(max_length=32, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Call low-mood snapshot'
        verbose_name_plural = 'Call low-mood snapshots'
        indexes = [
            models.Index(fields=['user', 'created_at']),
        ]

    def __str__(self):
        return f"low-mood for call {self.call_id} ({len(self.phrases or [])} phrases)"
