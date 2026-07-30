/// A call the user planned by turning on "Enable call" on a quest.
///
/// Mirrors `ScheduledCall` in the Django `voice_calls` app. `status` is the status the
/// backend already resolved (`pending` / `dueNow` is not a server concept — the server says
/// `pending`, `completed`, `cancelled` or `missed`); the app narrows it further against the
/// remaining daily quota via `resolveScheduledCallState`.
class ScheduledCall {
  final int id;
  final int? questId;
  final String questTitle;

  /// When the call is due, in the device's local time.
  final DateTime scheduledFor;

  /// The user's own calendar day for [scheduledFor] — the server runs on UTC, so this is
  /// what "today" means to them.
  final DateTime localDate;

  final String status;
  final int? callId;

  const ScheduledCall({
    required this.id,
    required this.questId,
    required this.questTitle,
    required this.scheduledFor,
    required this.localDate,
    required this.status,
    required this.callId,
  });

  factory ScheduledCall.fromJson(Map<String, dynamic> json) {
    // The API sends an offset-bearing ISO-8601 instant; toLocal() puts it on the device's
    // clock, which is the only clock the reminder and the quest card care about.
    final parsed = DateTime.parse(json['scheduled_for'] as String).toLocal();
    return ScheduledCall(
      id: json['id'] as int,
      questId: json['quest_id'] as int?,
      questTitle: (json['quest_title'] ?? '') as String,
      scheduledFor: parsed,
      localDate: DateTime.parse(json['local_date'] as String),
      status: (json['status'] ?? 'pending') as String,
      callId: json['call_id'] as int?,
    );
  }

  bool get isPending => status == 'pending';

  /// True when this call falls on the given local day.
  bool isOn(DateTime day) =>
      scheduledFor.year == day.year &&
      scheduledFor.month == day.month &&
      scheduledFor.day == day.day;
}
