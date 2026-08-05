"""The clock a user actually reads.

Quests store naive wall-clock fields — ``select_a_date`` and ``select_a_time`` hold what the
user tapped on their phone, with no offset attached. Turning that into an instant needs a
timezone, and the server's is the wrong one: ``TIME_ZONE = 'UTC'``, so a call the user set
for 11:20 in Belgrade was stored as 11:20 UTC and came back to the phone as 13:20. Every
reminder fired late by the device's whole UTC offset.

The phone reports its own zone (see ``Profile.timezone``) and everything derived from a
wall-clock time reads it from here.

**Why an IANA name and not a UTC offset.** An offset is only true on the day it was
measured. Save "+02:00" in August and a quest set for December is an hour out, because the
zone has moved to +01:00 by then — and a user who flies somewhere is wrong immediately.
A zone name resolves per date, so DST and travel both come out right.
"""
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError, available_timezones

from django.utils import timezone as django_timezone


def is_valid_timezone(name) -> bool:
    """True for an IANA zone this machine actually knows (e.g. ``Europe/Belgrade``)."""
    if not name:
        return False
    return str(name) in available_timezones()


def resolve_timezone(name):
    """The zone for [name], or the server's when it is missing or unrecognised.

    Falling back rather than raising is deliberate: an unknown zone should cost a user a
    correct reminder time, not the ability to save a quest at all. It is also what every
    row created before this field existed relies on.
    """
    if not name:
        return django_timezone.get_current_timezone()
    try:
        return ZoneInfo(str(name))
    except (ZoneInfoNotFoundError, ValueError):
        return django_timezone.get_current_timezone()


def user_timezone(user):
    """The zone this user's phone last reported, or the server's if it never has."""
    profile = getattr(user, 'profile', None) if user else None
    return resolve_timezone(getattr(profile, 'timezone', None))


def user_localdate(user, at=None):
    """Today, on the user's calendar rather than the server's.

    The daily call limit resets at the user's midnight, not UTC's — otherwise a user two
    hours ahead gets their new sparks at 02:00.
    """
    moment = at or django_timezone.now()
    return moment.astimezone(user_timezone(user)).date()
