from django.conf import settings
from django.db import models
from django.utils import timezone


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


class ScheduledCall(models.Model):
    """A call the user has planned for a future moment, via a quest's "Enable call" toggle.

    **A plan, never a booking.** The daily limit (``VOICE_CALL_DAILY_LIMIT``) is enforced at
    ``VoiceCallStartView`` and is deliberately *not* reserved ahead of time — scheduling three
    calls in one day does not make three calls possible, and spending the day's last call by
    swiping on the home screen leaves a later scheduled call unable to run. The UI resolves
    that into a "locked" state rather than pretending the slot is held.

    Rows are created, moved and cancelled by a ``post_save`` signal on ``Quests`` (see
    ``signals.py``) so the quest stays the single thing the user edits.
    """

    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        COMPLETED = 'completed', 'Completed'
        CANCELLED = 'cancelled', 'Cancelled'

    # Resolved on read, never stored — see `resolved_status`.
    MISSED = 'missed'

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='scheduled_calls',
    )
    # The quest this call belongs to. Nullable so a schedule can outlive its quest, and so
    # scheduled calls that are not tied to a quest remain possible later.
    quest = models.ForeignKey(
        'quests.Quests',
        on_delete=models.CASCADE,
        related_name='scheduled_calls',
        null=True,
        blank=True,
    )
    # Timezone-aware instant the call is due. The app sends ISO-8601 *with* an offset, so the
    # server never has to guess the user's timezone.
    scheduled_for = models.DateTimeField()
    # The user's own calendar day for `scheduled_for`. Stored because the server runs on UTC
    # (see docs/system-constraints.md SC-001): grouping by the UTC date would show a call as
    # belonging to the wrong day for users far enough from UTC. Always group by this.
    local_date = models.DateField()
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    # Set when the call is actually taken, linking the plan to what happened.
    call = models.OneToOneField(
        VoiceCall,
        on_delete=models.SET_NULL,
        related_name='scheduled_call',
        null=True,
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['scheduled_for']
        verbose_name = 'Scheduled call'
        verbose_name_plural = 'Scheduled calls'
        indexes = [
            models.Index(fields=['user', 'local_date']),
            models.Index(fields=['user', 'status', 'scheduled_for']),
        ]

    def __str__(self):
        return f"user {self.user_id} @ {self.scheduled_for:%Y-%m-%d %H:%M} ({self.status})"

    @property
    def resolved_status(self):
        """Status as the user should see it, with ``missed`` derived rather than stored.

        There is no scheduler anywhere in this project — the streak and the daily quota are
        both derived on read for the same reason. A ``pending`` row whose time has passed is
        simply missed; nothing has to run at midnight for that to become true.
        """
        if self.status == self.Status.PENDING and self.scheduled_for < timezone.now():
            return self.MISSED
        return self.status

    @property
    def is_actionable(self):
        """Whether starting this call still makes sense (quota aside)."""
        return self.status == self.Status.PENDING


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


class CallSummary(models.Model):
    """The conversational summary of a single voice call, captured at call end.

    ``nowli-ai`` generates this summary (``mood_detected`` / ``focus_topic`` /
    ``energy_shift`` / ``next_step``) with a GPT pass over the whole transcript when the
    call ends, then shows it on the call-summary screen. That service keeps sessions in
    memory only, so the summary would be lost on restart — the app persists it here, tied
    to the user, right after it is displayed. Storing it per user gives each call a lasting
    record and lets us look back across a user's calls to see how they progress over time.
    One summary per call.
    """

    call = models.OneToOneField(
        VoiceCall,
        on_delete=models.CASCADE,
        related_name='summary',
    )
    # Denormalized from ``call.user`` so a user's call history can be queried/ordered by
    # date without joining through VoiceCall (mirrors CallEmotionSnapshot).
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='call_summaries',
    )
    # The four friend-voice summary sentences shown on the call-summary screen.
    mood_detected = models.TextField(blank=True)
    focus_topic   = models.TextField(blank=True)
    energy_shift  = models.TextField(blank=True)
    next_step     = models.TextField(blank=True)
    # The call's dominant emotion + the full 5-category split (happy/motivated/angry/tired/sad),
    # kept alongside the text so history/progress views don't need CallEmotionSnapshot too.
    dominant_emotion = models.CharField(max_length=20, blank=True)
    top_emotions     = models.JSONField(default=dict, blank=True)
    # Words the user themselves kept returning to, verbatim from the transcript, e.g.
    # ``["should", "later", "honestly"]``. Extracted by the same GPT pass that writes the
    # sentences above — no extra model call, so no extra cost. Shown back on the call
    # summary as "Words you circled around". Empty is a valid, honest answer: a short call
    # has no pattern, and the UI hides the section rather than inventing one.
    words_circled = models.JSONField(default=list, blank=True)
    language     = models.CharField(max_length=8, blank=True)
    total_turns  = models.PositiveIntegerField(default=0)
    created_at   = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Call summary'
        verbose_name_plural = 'Call summaries'
        indexes = [
            models.Index(fields=['user', 'created_at']),
        ]

    def __str__(self):
        return f"summary for call {self.call_id} ({self.dominant_emotion or 'n/a'})"


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
