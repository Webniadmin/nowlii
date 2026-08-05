"""Keep each quest's scheduled call in step with the quest itself.

The user only ever edits a quest — its time, its date, its "Enable call" toggle. Deriving the
``ScheduledCall`` from that with a signal means there is no second thing to keep in sync and
no way for the app to create a quest but fail to create its schedule.

Lives in ``voice_calls`` rather than ``quests`` so the dependency points one way: calls know
about quests, quests know nothing about calls.
"""
import logging
from datetime import date, datetime, time

from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from django.utils.dateparse import parse_date, parse_time

from Apps.quests.models import Quests
from Apps.users.timezones import user_timezone

from .models import ScheduledCall

logger = logging.getLogger(__name__)


def _as_time(value):
    """Coerce whatever is on the instance into a ``time``, or ``None``.

    ``post_save`` sees the in-memory Python value, which is only a ``time`` once something
    has coerced it. DRF does that before saving, so the API path is fine — but a management
    command, fixture or seed doing ``select_a_time='16:30'`` hands us the raw string, and
    ``datetime.combine`` would raise on it.
    """
    if isinstance(value, time):
        return value
    if isinstance(value, str):
        return parse_time(value)
    return None


def _as_date(value):
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    if isinstance(value, str):
        return parse_date(value)
    return None


def _quest_due_at(quest):
    """The instant a quest's call is due, or ``None`` if it cannot be scheduled.

    ``Quests.select_a_date`` / ``select_a_time`` are naive wall-clock fields holding what the
    user picked on their phone, to the minute. They are read **in that phone's timezone**,
    which the profile carries — not the server's. The server runs on UTC, so interpreting
    them here meant a call set for 11:20 in Belgrade became 11:20 UTC and reached the phone
    as 13:20; every reminder fired late by the user's whole offset. See
    ``Apps/users/timezones.py`` for why the zone is stored by name rather than as an offset.

    A quest with no time cannot be scheduled: "sometime today" is not a reminder.
    """
    due_date = _as_date(quest.select_a_date)
    due_time = _as_time(quest.select_a_time)
    if due_date is None or due_time is None:
        return None

    naive = datetime.combine(due_date, due_time)
    if timezone.is_naive(naive):
        return timezone.make_aware(naive, user_timezone(quest.user))
    return naive


def _local_date_for(quest, due_at):
    """The user's own calendar day for [due_at].

    This is what "today" means for the daily call limit, so it has to be the user's day and
    not the server's — otherwise an evening call in a zone ahead of UTC belongs to tomorrow.
    """
    return due_at.astimezone(user_timezone(quest.user)).date()


@receiver(post_save, sender=Quests, dispatch_uid='voice_calls.sync_scheduled_call')
def sync_scheduled_call(sender, instance, **kwargs):
    """Create, move or cancel the quest's scheduled call whenever the quest is saved.

    Failures are swallowed on purpose: a quest is the user's actual work, a call reminder is
    a convenience attached to it. Letting this raise would make an unschedulable quest
    impossible to save at all, which is a far worse outcome than a missing reminder — and
    the next save (or the app's next sync) gets another chance.
    """
    try:
        _sync_scheduled_call(instance)
    except Exception:
        logger.exception(
            'Could not sync the scheduled call for quest %s; the quest itself is unaffected.',
            instance.pk,
        )


def _sync_scheduled_call(instance):
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
            local_date=_local_date_for(instance, due_at),
        )
        return

    # A call that already happened is history — moving the quest does not rewrite it.
    if existing.status == ScheduledCall.Status.COMPLETED:
        return

    # Re-enabling the toggle revives a cancelled row instead of leaving a second one behind.
    changed = []
    if existing.scheduled_for != due_at:
        existing.scheduled_for = due_at
        existing.local_date = _local_date_for(instance, due_at)
        changed += ['scheduled_for', 'local_date']
    if existing.status != ScheduledCall.Status.PENDING:
        existing.status = ScheduledCall.Status.PENDING
        changed.append('status')
    if changed:
        existing.save(update_fields=changed + ['updated_at'])
