"""
Pure analytics logic.
Reads Quest + SubTask data and returns structured dicts
that are then passed to the AI for reflection generation.
"""
from datetime import date, timedelta
from collections import defaultdict, Counter

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

def _generate_calendar(start_date: date, end_date: date, quests: list, ref_date: date) -> list:
    """
    Generates a list of day statuses for the range [start_date, end_date].
    Status can be: consistent, skipped, streak, none.
    """
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
            status = "consistent" if (completed == assigned and assigned > 0) else "skipped"
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

    # ── 5. Calendar (consistent / skipped / streak) ──────────────────────
    calendar = _generate_calendar(first, last, quests, ref)

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
        "preferred_quest_types": preferred_quest_types,
        "quests_completed":      quests_completed,
        "calendar":              calendar,
        "milestones":            milestones,
    }


# ─────────────────────────────────────────────
#  Weekly Analytics
# ─────────────────────────────────────────────

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

    skipped_days = []
    for i in range(7):
        d = monday + timedelta(days=i)
        if d > ref:
            break
        if d in days_with_quests:
            day_qs = days_with_quests[d]
            all_done = all(_all_subtasks_done(q) or q.task_done for q in day_qs)
            if not all_done:
                skipped_days.append(WEEKDAY_NAMES[d.weekday()])
        # days with no quests at all are not "skipped" — just empty

    # ── Calendar ─────────────────────────────────────────────────────────
    calendar = _generate_calendar(monday, sunday, quests, ref)

    return {
        "quests_completed":  completed_quests,
        "total_quests":      total_quests,
        "zone_progress":     zone_progress,
        "skipped_days":      skipped_days,
        "calendar":          calendar,
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
