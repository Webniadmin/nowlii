"""
Pure analytics logic.
Reads Quest + SubTask data and returns structured dicts
that are then passed to the AI for reflection generation.
"""
from datetime import date, timedelta
from collections import defaultdict, Counter

from django.utils import timezone

from Apps.quests.models import Quests   # adjust import path if needed


# ─────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────

def _week_bounds(ref: date):
    """Return (monday, sunday) for the ISO week containing ref."""
    monday = ref - timedelta(days=ref.weekday())
    sunday = monday + timedelta(days=6)
    return monday, sunday


def _month_bounds(ref: date):
    """Return (first_day, last_day) for the month containing ref."""
    first = ref.replace(day=1)
    if ref.month == 12:
        last = ref.replace(year=ref.year + 1, month=1, day=1) - timedelta(days=1)
    else:
        last = ref.replace(month=ref.month + 1, day=1) - timedelta(days=1)
    return first, last


def _all_subtasks_done(quest) -> bool:
    subs = list(quest.subtasks.all())
    return bool(subs) and all(s.task_done for s in subs)


# ─────────────────────────────────────────────
#  Calendar Helper
# ─────────────────────────────────────────────

def _get_rest_weekdays(user) -> set:
    """The weekday names the user marked as intentional rest days (from their profile).

    Returns an empty set when there's no profile or nothing marked. Normalized to
    capitalized names ("Sunday") to match WEEKDAY_NAMES / strftime("%A").
    """
    try:
        profile = getattr(user, "profile", None)
        days = getattr(profile, "rest_days", None) or []
        return {str(d).strip().capitalize() for d in days if str(d).strip()}
    except Exception:
        return set()


def _generate_calendar(start_date: date, end_date: date, quests: list, ref_date: date,
                       rest_weekdays: set = None) -> list:
    """
    Generates a list of day statuses for the range [start_date, end_date].
    Status can be: consistent, skipped, streak, none.

    ``rest_weekdays`` (capitalized weekday names) are treated as intentional days off: a
    day with incomplete quests that falls on a rest weekday is 'none', not 'skipped'.
    """
    rest_weekdays = rest_weekdays or set()
    days_with_quests: dict[date, list] = defaultdict(list)
    for q in quests:
        if q.select_a_date:
            days_with_quests[q.select_a_date].append(q)

    # streak detection: consecutive days where all tasks done
    # we need a bit more context for streaks (e.g. some days before start_date)
    # but for simplicity let's just use what's in the 'quests' list
    sorted_days = sorted(days_with_quests.keys())
    streak_days: set[date] = set()
    run, run_days = 0, []
    for d in sorted_days:
        day_qs = days_with_quests[d]
        all_done = all(_all_subtasks_done(q) or q.task_done for q in day_qs)
        if all_done:
            run += 1
            run_days.append(d)
            if run >= 7:
                streak_days.update(run_days[-7:])
        else:
            run, run_days = 0, []

    calendar = []
    current = start_date
    while current <= end_date:
        if current > ref_date:
            # Future days should probably be 'none'
            status = "none"
            assigned = 0
            completed = 0
        elif current in streak_days:
            day_qs = days_with_quests[current]
            assigned = len(day_qs)
            completed = sum(1 for q in day_qs if _all_subtasks_done(q) or q.task_done)
            status = "streak"
        elif current in days_with_quests:
            day_qs = days_with_quests[current]
            assigned = len(day_qs)
            completed = sum(1 for q in day_qs if _all_subtasks_done(q) or q.task_done)
            if completed == assigned and assigned > 0:
                status = "consistent"
            elif current.strftime("%A") in rest_weekdays:
                # Intentional rest day — don't flag it as a miss.
                status = "none"
            else:
                status = "skipped"
        else:
            status = "none"
            assigned = 0
            completed = 0
        
        calendar.append({
            "date": current.isoformat(), 
            "status": status,
            "assigned": assigned,
            "completed": completed
        })
        current += timedelta(days=1)
    
    return calendar


# ─────────────────────────────────────────────
#  Monthly Analytics
# ─────────────────────────────────────────────

def get_monthly_analytics(user, ref: date = None) -> dict:
    ref = ref or date.today()
    first, last = _month_bounds(ref)

    qs = (
        Quests.objects
        .filter(user=user, select_a_date__gte=first, select_a_date__lte=last)
        .prefetch_related('subtasks')
    )

    quests = list(qs)

    # ── 1. Most completed quests ────────────────────────────────────────
    task_counter: Counter = Counter()
    for q in quests:
        if _all_subtasks_done(q) or q.task_done:
            task_counter[q.task] += 1

    most_completed = [
        {
            "task": task,
            "completed_count": count,
            "repeat_quest": any(
                q.repeat_quest for q in quests if q.task == task
            ),
        }
        for task, count in task_counter.most_common(3)
    ]

    # ── 2. Most productive day (most tasks added AND completed) ─────────
    day_scores: Counter = Counter()
    for q in quests:
        if q.select_a_date:
            day_scores[q.select_a_date] += 1
            if _all_subtasks_done(q) or q.task_done:
                day_scores[q.select_a_date] += 1   # bonus for completion

    most_productive_day = ""
    if day_scores:
        best_date = day_scores.most_common(1)[0][0]
        most_productive_day = best_date.strftime("%A")

    # ── 2b. Most productive hour (by the scheduled quest time) ──────────
    # Only signal we have for time-of-day is Quests.select_a_time; weight completed quests
    # double, same as the day scoring. Empty string when no quest has a time set.
    hour_scores: Counter = Counter()
    for q in quests:
        if q.select_a_time:
            hour = q.select_a_time.hour
            hour_scores[hour] += 1
            if _all_subtasks_done(q) or q.task_done:
                hour_scores[hour] += 1

    most_productive_hour = ""
    if hour_scores:
        best_hour = hour_scores.most_common(1)[0][0]
        most_productive_hour = f"{best_hour:02d}:00"

    # ── 3. Preferred quest types (Soft steps vs Power moves) ────────────
    soft_count  = sum(1 for q in quests if q.zone == "Soft steps")
    power_count = sum(1 for q in quests if q.zone == "Power move")
    total_sp    = soft_count + power_count or 1

    soft_pct  = round(soft_count / total_sp * 100, 1)
    power_pct = round(100 - soft_pct, 1)

    preferred_quest_types = {
        "soft_steps_pct":  soft_pct,
        "power_moves_pct": power_pct,
        "summary": (
            f"You complete more Soft Moves than Power Moves ({soft_pct}% vs {power_pct}%)."
            if soft_pct >= power_pct
            else f"You complete more Power Moves than Soft Moves ({power_pct}% vs {soft_pct}%)."
        ),
    }

    # ── 4. Quests completed (assigned vs finished) ───────────────────────
    assigned  = len(quests)
    completed = sum(1 for q in quests if _all_subtasks_done(q) or q.task_done)
    quests_completed = {"assigned": assigned, "completed": completed}

    # ── 4b. Zone progress (real per-zone assigned/completed for the month,
    #        same shape as the weekly zone_progress) ──────────────────────
    ZONES = ["Soft steps", "Stretch zone", "Elevated", "Power move"]
    zone_map: dict[str, dict] = {z: {"assigned": 0, "completed": 0} for z in ZONES}
    for q in quests:
        if q.zone in zone_map:
            zone_map[q.zone]["assigned"] += 1
            if _all_subtasks_done(q) or q.task_done:
                zone_map[q.zone]["completed"] += 1

    zone_progress = [
        {
            "zone":      zone,
            "assigned":  data["assigned"],
            "completed": data["completed"],
            "ratio":     f"{data['completed']}/{data['assigned']}" if data["assigned"] else "0/0",
        }
        for zone, data in zone_map.items()
    ]

    # ── 5. Calendar (consistent / skipped / streak) ──────────────────────
    calendar = _generate_calendar(first, last, quests, ref, _get_rest_weekdays(user))

    # ── 6. Milestones ────────────────────────────────────────────────────
    days_with_quests: dict[date, list] = defaultdict(list)
    for q in quests:
        if q.select_a_date:
            days_with_quests[q.select_a_date].append(q)
    sorted_days = sorted(days_with_quests.keys())

    # longest streak (all-time for this user or just this month)
    longest_streak = 0
    run = 0
    for d in sorted_days:
        day_qs = days_with_quests[d]
        all_done = all(_all_subtasks_done(q) or q.task_done for q in day_qs)
        if all_done:
            run += 1
            longest_streak = max(longest_streak, run)
        else:
            run = 0

    milestones = {
        "quests_completed_this_month": completed,
        "longest_streak_days": longest_streak,
    }

    return {
        "most_completed_quests": most_completed,
        "most_productive_day":   most_productive_day,
        "most_productive_hour":  most_productive_hour,
        "preferred_quest_types": preferred_quest_types,
        "quests_completed":      quests_completed,
        "zone_progress":         zone_progress,
        "calendar":              calendar,
        "milestones":            milestones,
    }


# ─────────────────────────────────────────────
#  Weekly Analytics
# ─────────────────────────────────────────────

# ─────────────────────────────────────────────
#  Top Emotions (Insights) — aggregated from voice-call snapshots
# ─────────────────────────────────────────────

_EMOTION_KEYS = ["happy", "motivated", "angry", "tired", "sad"]
_EMOTION_LABELS = {
    "happy": "Happy", "motivated": "Motivated", "angry": "Angry",
    "tired": "Tired", "sad": "Sad",
}

# TEMPORARY placeholder copy for the "What this means" card — two variants per
# dominant emotion. The variant is picked deterministically from the ISO week so it
# stays stable within a week but varies week to week.
# TODO(insights-emotions): replace this table with an AI-generated summary (we deliberately
# do NOT call the AI on every Insights load for now). See docs/insights-emotions.md.
_EMOTION_SUMMARY_VARIANTS = {
    "happy": [
        "You feel mostly calm and positive — it's been a good week for your mood.",
        "Happiness led your conversations this week. Keep leaning into what lifts you.",
    ],
    "motivated": [
        "Motivation ran high this week — you sounded driven and focused.",
        "You showed a lot of drive lately. Channel it into your next quests.",
    ],
    "angry": [
        "Frustration showed up often this week. It may help to name what's setting it off.",
        "Anger came through in your talks — a short reset might ease the tension.",
    ],
    "tired": [
        "You sounded tired this week — rest may matter more than pushing harder.",
        "Low energy came up a lot lately. Be gentle with your pace.",
    ],
    "sad": [
        "Sadness appeared often this week. Be kind to yourself — small steps count.",
        "You carried some heavy feelings lately. Reaching out can lighten the load.",
    ],
}


def _build_top_emotions(user, start: date, end: date):
    """Average the 5 Top-Emotion categories across the user's call snapshots in
    [start, end] and return (top_emotions_sorted_desc, summary_text).

    Returns ([], "") when there are no snapshots so the UI can hide the section.
    """
    # Local import avoids an app-load-time cycle (insights ↔ voice_calls).
    from Apps.voice_calls.models import CallEmotionSnapshot

    snaps = list(
        CallEmotionSnapshot.objects.filter(
            user=user, created_at__date__gte=start, created_at__date__lte=end
        )
    )
    if not snaps:
        return [], ""

    avg = {
        key: round(sum(getattr(s, key) for s in snaps) / len(snaps), 1)
        for key in _EMOTION_KEYS
    }
    top_emotions = [
        {"key": key, "label": _EMOTION_LABELS[key], "pct": avg[key]}
        for key in sorted(_EMOTION_KEYS, key=lambda e: avg[e], reverse=True)
    ]
    dominant = top_emotions[0]["key"]
    variants = _EMOTION_SUMMARY_VARIANTS.get(dominant) or [""]
    summary = variants[end.isocalendar()[1] % len(variants)]
    return top_emotions, summary


# ─────────────────────────────────────────────
#  When feeling low (Insights) — recurring low-mood phrases from voice calls
# ─────────────────────────────────────────────

# TEMPORARY placeholder "What this means" copy, keyed by the dominant low-mood category.
# TODO(insights-emotions): replace with an AI-generated summary (we do NOT call the AI on
# Insights load). Each entry is (summary, recommendation). See docs/insights-emotions.md.
_LOW_MOOD_MEANING_DEFAULT = (
    "You tend to feel overwhelmed when tasks pile up, "
    "and your language becomes more self-critical.",
    "→ Try breaking tasks into smaller steps.",
)
_LOW_MOOD_MEANING = {
    "overwhelm": _LOW_MOOD_MEANING_DEFAULT,
    "self-criticism": (
        "When things get hard, your words turn more self-critical.",
        "→ Try speaking to yourself like you would to a friend.",
    ),
    "helplessness": (
        "When things feel stuck, your language leans toward “I can’t”.",
        "→ Try naming one small thing you can control.",
    ),
    "avoidance": (
        "You tend to put things off when they feel heavy.",
        "→ Try starting with a two-minute version of the task.",
    ),
    "exhaustion": (
        "Tiredness shows up a lot in how you talk lately.",
        "→ Try protecting a little rest before pushing on.",
    ),
    "stress": (
        "Stress comes through strongly in your words.",
        "→ Try a slow breath and one task at a time.",
    ),
    "hopelessness": (
        "Some of your phrasing sounds hopeless when you’re low.",
        "→ Consider reaching out to someone you trust.",
    ),
}


def _build_low_mood(user, start: date, end: date):
    """Aggregate recurring low-mood phrases across the user's call snapshots in
    [start, end] and return (top_phrases, summary, recommendation).

    Top 5 phrases by total frequency, ties broken alphabetically. Returns ([], "", "")
    when there are no snapshots (the UI still shows the section with an empty-state).
    """
    # Local import avoids an app-load-time cycle (insights ↔ voice_calls).
    from Apps.voice_calls.models import CallLowMoodSnapshot

    snaps = list(
        CallLowMoodSnapshot.objects.filter(
            user=user, created_at__date__gte=start, created_at__date__lte=end
        )
    )
    if not snaps:
        return [], "", ""

    phrase_counts: dict[str, int] = {}
    cat_counts: dict[str, int] = {}
    for s in snaps:
        for item in (s.phrases or []):
            phrase = (item.get("phrase") or "").strip()
            if not phrase:
                continue
            try:
                count = int(item.get("count") or 1)
            except (TypeError, ValueError):
                count = 1
            phrase_counts[phrase] = phrase_counts.get(phrase, 0) + count
            category = item.get("category") or ""
            if category:
                cat_counts[category] = cat_counts.get(category, 0) + count

    if not phrase_counts:
        return [], "", ""

    # Top 5: frequency descending, ties alphabetical.
    top = sorted(phrase_counts.items(), key=lambda kv: (-kv[1], kv[0]))[:5]
    phrases = [p for p, _ in top]
    dominant_cat = max(cat_counts, key=cat_counts.get) if cat_counts else ""
    summary, recommendation = _LOW_MOOD_MEANING.get(dominant_cat, _LOW_MOOD_MEANING_DEFAULT)
    return phrases, summary, recommendation


# ─────────────────────────────────────────────
#  "Your mood" weekly chart — one bar per weekday from voice-call snapshots
# ─────────────────────────────────────────────

_WEEKDAY_ABBR = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]


def _build_mood_week(user, monday: date, ref: date) -> list:
    """Per-day mood for the ISO week starting ``monday`` (Mon..Sun).

    For each day we average the 5 emotion categories across that day's call snapshots and
    take the dominant one; ``level`` is its intensity (0–100), ``emotion`` its key. Days with
    no calls — or future days — get ``level=0, emotion=None, has_data=False`` so the UI can
    render a neutral stub (or hide the section when the whole week is empty).
    """
    # Local import avoids an app-load-time cycle (insights ↔ voice_calls).
    from Apps.voice_calls.models import CallEmotionSnapshot

    sunday = monday + timedelta(days=6)
    snaps = list(
        CallEmotionSnapshot.objects.filter(
            user=user, created_at__date__gte=monday, created_at__date__lte=sunday
        )
    )
    by_day: dict[date, list] = defaultdict(list)
    for s in snaps:
        # localtime keeps day-bucketing consistent with the __date filter above.
        by_day[timezone.localtime(s.created_at).date()].append(s)

    mood_week = []
    for i in range(7):
        d = monday + timedelta(days=i)
        day_snaps = by_day.get(d, [])
        if not day_snaps or d > ref:
            mood_week.append({
                "day": _WEEKDAY_ABBR[i], "date": d.isoformat(),
                "level": 0, "emotion": None, "has_data": False,
            })
            continue
        avg = {
            key: sum(getattr(s, key) for s in day_snaps) / len(day_snaps)
            for key in _EMOTION_KEYS
        }
        dominant = max(_EMOTION_KEYS, key=lambda e: avg[e])
        mood_week.append({
            "day": _WEEKDAY_ABBR[i], "date": d.isoformat(),
            "level": round(avg[dominant]), "emotion": dominant, "has_data": True,
        })
    return mood_week


def get_weekly_analytics(user, ref: date = None) -> dict:
    ref = ref or date.today()
    monday, sunday = _week_bounds(ref)

    qs = (
        Quests.objects
        .filter(user=user, select_a_date__gte=monday, select_a_date__lte=sunday)
        .prefetch_related('subtasks')
    )

    quests = list(qs)

    # ── Quests completed ─────────────────────────────────────────────────
    total_quests     = len(quests)
    completed_quests = sum(1 for q in quests if _all_subtasks_done(q) or q.task_done)

    # ── Zone progress ────────────────────────────────────────────────────
    ZONES = ["Soft steps", "Stretch zone", "Elevated", "Power move"]
    zone_map: dict[str, dict] = {z: {"assigned": 0, "completed": 0} for z in ZONES}

    for q in quests:
        if q.zone in zone_map:
            zone_map[q.zone]["assigned"] += 1
            if _all_subtasks_done(q) or q.task_done:
                zone_map[q.zone]["completed"] += 1

    zone_progress = [
        {
            "zone":      zone,
            "assigned":  data["assigned"],
            "completed": data["completed"],
            "ratio":     f"{data['completed']}/{data['assigned']}" if data["assigned"] else "0/0",
        }
        for zone, data in zone_map.items()
    ]

    # ── Skipped days ─────────────────────────────────────────────────────
    WEEKDAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    days_with_quests: dict[date, list] = defaultdict(list)
    for q in quests:
        if q.select_a_date:
            days_with_quests[q.select_a_date].append(q)

    rest_weekdays = _get_rest_weekdays(user)
    skipped_days = []
    for i in range(7):
        d = monday + timedelta(days=i)
        if d > ref:
            break
        if d in days_with_quests:
            day_qs = days_with_quests[d]
            all_done = all(_all_subtasks_done(q) or q.task_done for q in day_qs)
            weekday_name = WEEKDAY_NAMES[d.weekday()]
            # A day the user marked as a rest day is not a "skip".
            if not all_done and weekday_name not in rest_weekdays:
                skipped_days.append(weekday_name)
        # days with no quests at all are not "skipped" — just empty

    # ── Calendar ─────────────────────────────────────────────────────────
    calendar = _generate_calendar(monday, sunday, quests, ref, rest_weekdays)

    # ── Top Emotions + When-feeling-low (from voice-call snapshots this week) ──
    top_emotions, emotions_summary = _build_top_emotions(user, monday, sunday)
    low_mood_phrases, low_mood_summary, low_mood_recommendation = _build_low_mood(user, monday, sunday)

    # ── "Your mood" weekly chart (one bar per weekday) ────────────────────────
    mood_week = _build_mood_week(user, monday, ref)

    return {
        "quests_completed":  completed_quests,
        "total_quests":      total_quests,
        "zone_progress":     zone_progress,
        "skipped_days":      skipped_days,
        "calendar":          calendar,
        "top_emotions":      top_emotions,
        "emotions_summary":  emotions_summary,
        "low_mood_phrases":  low_mood_phrases,
        "low_mood_summary":  low_mood_summary,
        "low_mood_recommendation": low_mood_recommendation,
        "mood_week":         mood_week,
        # ai_reflections is filled in by the AI layer
    }


# ─────────────────────────────────────────────
#  Combined summary for AI prompt
# ─────────────────────────────────────────────

def build_analytics_summary(user, ref: date = None) -> dict:
    ref = ref or date.today()
    return {
        "weekly":  get_weekly_analytics(user, ref),
        "monthly": get_monthly_analytics(user, ref),
        "ref_date": ref.isoformat(),
    }


# ─────────────────────────────────────────────
#  Offline fallbacks — used when the AI provider is unavailable
# ─────────────────────────────────────────────
#
# The Insights screen is mostly real DB analytics (streak, rings, calendar, emotions,
# mood chart); only `ai_reflections` and `quest_suggestions` need the AI. When the
# provider fails (no key, out of quota, timeout, bad JSON) the view degrades to these
# instead of returning 500, so the rest of the screen still renders. The copy is
# derived from the user's real numbers — it never invents data.

def build_fallback_reflections(weekly: dict) -> list[str]:
    """Three reflection sentences computed from the real weekly numbers (no AI).

    Mirrors the shape `generate_weekly_reflections` returns: a list of 3 strings.
    """
    completed = int(weekly.get("quests_completed") or 0)
    total     = int(weekly.get("total_quests") or 0)
    skipped   = list(weekly.get("skipped_days") or [])
    zones     = list(weekly.get("zone_progress") or [])

    lines = []

    # 1. Completion — the headline number, stated plainly.
    if total == 0:
        lines.append("No quests are on this week's board yet — adding one is the whole first step.")
    else:
        pct = round(completed / total * 100)
        lines.append(f"You completed {completed} of {total} quests this week ({pct}%).")

    # 2. Zones — where the effort actually landed.
    worked = [z for z in zones if (z.get("assigned") or 0) > 0]
    if worked:
        best = max(worked, key=lambda z: (z.get("completed") or 0) / (z.get("assigned") or 1))
        busiest = max(worked, key=lambda z: z.get("assigned") or 0)
        if (best.get("completed") or 0) > 0:
            lines.append(f"Your strongest zone was {best['zone']} at {best['ratio']}.")
        else:
            lines.append(f"Most of your quests sat in {busiest['zone']} — none finished there yet.")
    else:
        lines.append("No zone has any quests yet — pick one zone and start there.")

    # 3. Consistency — skipped days, minus the ones marked as rest days.
    if total == 0:
        lines.append("Insights get sharper once you've logged a few days of quests.")
    elif not skipped:
        lines.append("You didn't skip a single planned day this week.")
    elif len(skipped) == 1:
        lines.append(f"{skipped[0]} was the one day that slipped — worth a look at what got in the way.")
    else:
        lines.append(f"{len(skipped)} days slipped this week ({', '.join(skipped)}).")

    return lines


# Static quest suggestions per part of the day. Same shape the AI returns:
# task / description / zone / suggested_time.
#
# Morning/afternoon/evening carry the zone variety the AI prompt asks for (at least one
# Soft step, Power move and Stretch zone). **Night deliberately does not** — proposing a
# "Deep focus" Power move at 23:00 is bad advice, so the late set stays gentle.
_FALLBACK_QUESTS = {
    "morning": [
        {"task": "Morning walk",   "description": "Ten minutes outside to wake your body up.",      "zone": "Soft steps"},
        {"task": "Plan the day",   "description": "Write down the three things that actually matter.", "zone": "Soft steps"},
        {"task": "Deep focus",     "description": "One uninterrupted block on your hardest task.",   "zone": "Power move"},
        {"task": "Clear the inbox", "description": "Handle what's waiting before it piles up.",      "zone": "Elevated"},
        {"task": "Start the hard one", "description": "Begin the task you've been circling for days.", "zone": "Stretch zone"},
    ],
    "afternoon": [
        {"task": "Stretch break",  "description": "Stand up and move for five minutes.",            "zone": "Soft steps"},
        {"task": "Focus sprint",   "description": "Twenty-five minutes, one task, no tabs.",         "zone": "Power move"},
        {"task": "Tidy one spot",  "description": "Reset a single surface — desk, sink, or bag.",    "zone": "Elevated"},
        {"task": "Finish something", "description": "Close out a task that's been almost-done.",     "zone": "Elevated"},
        {"task": "Send the message", "description": "Make the call or reply you've been putting off.", "zone": "Stretch zone"},
    ],
    "evening": [
        {"task": "Short reflection", "description": "Note one thing that went well today.",          "zone": "Soft steps"},
        {"task": "Prep tomorrow",  "description": "Set out what you'll need in the morning.",        "zone": "Soft steps"},
        {"task": "Screen-free hour", "description": "Put the phone down and let your head settle.",  "zone": "Elevated"},
        {"task": "Wrap the day",   "description": "Finish the last open loop, then stop.",           "zone": "Power move"},
        {"task": "Reach out",      "description": "Message someone you've been meaning to talk to.", "zone": "Stretch zone"},
    ],
    "night": [
        {"task": "Wind down",      "description": "Dim the lights and slow your breathing.",         "zone": "Soft steps"},
        {"task": "Lights out",     "description": "Head to bed at a time that's kind to tomorrow.",  "zone": "Soft steps"},
        {"task": "Note one worry", "description": "Write down what's on your mind so it can wait.",  "zone": "Soft steps"},
        {"task": "Tidy for morning", "description": "Two minutes now saves a rushed start.",         "zone": "Elevated"},
        {"task": "Read a few pages", "description": "Something on paper, away from screens.",        "zone": "Soft steps"},
    ],
}

_FALLBACK_TIMES = {
    "morning":   ["08:00", "08:30", "09:00", "10:00", "11:00"],
    "afternoon": ["13:00", "14:00", "15:00", "16:00", "17:00"],
    "evening":   ["18:30", "19:00", "20:00", "20:30", "21:00"],
    "night":     ["21:30", "22:00", "22:15", "22:30", "23:00"],
}


def _part_of_day(current_time: str) -> str:
    """Map an 'HH:MM' string to morning / afternoon / evening / night."""
    try:
        hour = int(str(current_time).split(":")[0])
    except (ValueError, IndexError, AttributeError):
        hour = 12
    if 5 <= hour < 12:
        return "morning"
    if 12 <= hour < 18:
        return "afternoon"
    if 18 <= hour < 22:
        return "evening"
    return "night"


def build_fallback_quest_suggestions(weekly: dict, current_time: str, day_of_week: str) -> list[dict]:
    """Five static quest suggestions matched to the time of day (no AI).

    Mirrors `generate_quest_suggestions`: a list of 5 dicts with task / description /
    zone / suggested_time. When the user skipped days this week the set is biased
    toward "Soft steps" — the same rule the AI prompt uses.
    """
    part = _part_of_day(current_time)
    items = list(_FALLBACK_QUESTS[part])
    times = _FALLBACK_TIMES[part]

    # Struggling week → lead with the gentlest options instead of the stretch ones.
    if len(weekly.get("skipped_days") or []) >= 2:
        items.sort(key=lambda q: 0 if q["zone"] == "Soft steps" else 1)

    return [
        {**item, "suggested_time": times[i % len(times)]}
        for i, item in enumerate(items)
    ]
