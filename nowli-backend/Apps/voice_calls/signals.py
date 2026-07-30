"""Keep each quest's scheduled call in step with the quest itself.

The user only ever edits a quest — its time, its date, its "Enable call" toggle. Deriving the
``ScheduledCall`` from that with a signal means there is no second thing to keep in sync and
no way for the app to create a quest but fail to create its schedule.

Lives in ``voice_calls`` rather than ``quests`` so the dependency points one way: calls know
about quests, quests know nothing about calls.
"""
from datetime import datetime, time

from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone

from Apps.quests.models import Quests

from .models import ScheduledCall


def _quest_due_at(quest):
    """The instant a quest's call is due, or ``None`` if it cannot be scheduled.

    ``Quests.select_a_date`` / ``select_a_time`` are naive wall-clock fields holding what the
    user picked on their phone. We interpret them in the server's timezone — the same reading
    the rest of the app already applies to them (the Insights "most productive hour" does the
    same). A quest with no time cannot be scheduled: "sometime today" is not a reminder.
    """
    if not quest.select_a_date or not quest.select_a_time:
        return None

    naive = datetime.combine(quest.select_a_date, quest.select_a_time)
    if timezone.is_naive(naive):
        return timezone.make_aware(naive, timezone.get_current_timezone())
    return naive


@receiver(post_save, sender=Quests, dispatch_uid='voice_calls.sync_scheduled_call')
def sync_scheduled_call(sender, instance, **kwargs):
    """Create, move or cancel the quest's scheduled call whenever the quest is saved."""
    due_at = _quest_due_at(instance)
    wanted = bool(instance.enable_call) and due_at is not None

    existing = ScheduledCall.objects.filter(quest=instance).first()

    if not wanted:
        # The toggle went off, or the time was cleared. Cancel rather than delete, so a call
        # that already happened keeps its record.
        if existing and existing.status == ScheduledCall.Status.PENDING:
            existing.status = ScheduledCall.Status.CANCELLED
            existing.save(update_fields=['status', 'updated_at'])
        return

    if existing is None:
        ScheduledCall.objects.create(
            user=instance.user,
            quest=instance,
            scheduled_for=due_at,
            local_date=timezone.localtime(due_at).date(),
        )
        return

    # A call that already happened is history — moving the quest does not rewrite it.
    if existing.status == ScheduledCall.Status.COMPLETED:
        return

    # Re-enabling the toggle revives a cancelled row instead of leaving a second one behind.
    changed = []
    if existing.scheduled_for != due_at:
        existing.scheduled_for = due_at
        existing.local_date = timezone.localtime(due_at).date()
        changed += ['scheduled_for', 'local_date']
    if existing.status != ScheduledCall.Status.PENDING:
        existing.status = ScheduledCall.Status.PENDING
        changed.append('status')
    if changed:
        existing.save(update_fields=changed + ['updated_at'])
