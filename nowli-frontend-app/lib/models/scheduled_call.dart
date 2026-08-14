import 'package:nowlii/services/api_date.dart';

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
    // Put the instant on the device's clock — the only clock the reminder and the quest
    // card care about.
    //
    // This used to be a bare `DateTime.parse`, on the assumption that the API sent
    // ISO-8601. It did not: the project-wide DRF DATETIME_FORMAT produced
    // "02-08-2026 18:00:00", so this threw for every row, the service caught it and
    // returned an empty list, and planned calls silently did not exist. See parseApiDate.
    final parsed = parseApiDate(json['scheduled_for']);
    if (parsed == null) {
      throw FormatException(
        'Unparseable scheduled_for: ${json['scheduled_for']}',
      );
    }
    return ScheduledCall(
      id: json['id'] as int,
      questId: json['quest_id'] as int?,
      questTitle: (json['quest_title'] ?? '') as String,
      scheduledFor: parsed,
      // A DateField, which DRF still renders as plain ISO ("2026-08-02").
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
