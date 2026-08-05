import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/models/scheduled_call.dart';
import 'package:nowlii/services/call_reminder_service.dart';
import 'package:nowlii/services/quest_service.dart';
import 'package:nowlii/services/scheduled_call_state.dart';
import 'package:nowlii/services/voice_call_service.dart';
import 'package:intl/intl.dart';
import 'package:nowlii/utils/color_palette/zone_colors.dart';

class Today extends StatefulWidget {
  const Today({super.key});

  @override
  State<Today> createState() => _TodayState();
}

class _TodayState extends State<Today> {
  List<Quest> quests = [];
  bool _isLoading = true;

  final VoiceCallService _voiceCalls = VoiceCallService();

  /// Today's planned calls, keyed by quest id, so a quest card can show whether its call is
  /// still ahead, already done, or stranded by the daily limit.
  Map<int, ScheduledCall> _scheduledByQuest = {};

  /// Calls left today. `-1` means unlimited (QA accounts). Defaults to 1 so a failed fetch
  /// shows the call as available rather than falsely locking it — the backend is the
  /// authority and will refuse it properly if it really is gone.
  int _remainingCalls = 1;

  @override
  void initState() {
    super.initState();
    _loadTodayQuests();
  }

  Future<void> _loadTodayQuests() async {
    final questService = QuestService();
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    // Quests, plans and quota together: the state of a call is a function of all three.
    final results = await Future.wait([
      questService.fetchAllQuests(),
      _voiceCalls.getScheduledCalls(),
      _voiceCalls.getQuota(),
    ]);

    final allQuests = results[0] as List<Quest>;
    final scheduled = results[1] as List<ScheduledCall>;
    final quota = results[2] as VoiceCallQuota?;

    // Filter only today's quests
    final todayQuests = allQuests.where((quest) {
      return quest.selectADate == todayStr;
    }).toList();

    final byQuest = <int, ScheduledCall>{};
    for (final call in scheduled) {
      if (call.questId != null) byQuest[call.questId!] = call;
    }

    if (mounted) {
      setState(() {
        quests = todayQuests;
        _scheduledByQuest = byQuest;
        _remainingCalls = quota?.remaining ?? 1;
        _isLoading = false;
      });
    }
  }

  /// Push a call the user can no longer take to the same time tomorrow.
  Future<void> _moveToTomorrow(ScheduledCall call) async {
    final tomorrow = call.scheduledFor.add(const Duration(days: 1));
    final moved = await _voiceCalls.rescheduleCall(call.id, tomorrow);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(moved
            ? 'Moved to tomorrow at ${DateFormat('HH:mm').format(tomorrow)}.'
            : "Couldn't move the call. Please try again."),
        backgroundColor: moved ? Colors.green : Colors.red,
      ),
    );
    if (moved) {
      await CallReminderService.instance.sync();
      await _loadTodayQuests();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (quests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTodayQuests,
        color: const Color(0xFF4542EB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.asset(
                        "assets/svg_images/Button Calendar.png",
                        height: 64,
                        width: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 222,
                      child: Text(
                        'No quests yet, but your journey starts here.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF011F54),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.20,
                          letterSpacing: -0.50,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 335,
                      child: Text(
                        'Add your first quest and take the smallest possible step — we\'re not chasing perfection, just progress.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF4C586E),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.40,
                          letterSpacing: -0.50,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 230,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push(AppRoutespath.createQuestPage);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4C46F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, color: Colors.white, size: 24),
                            const SizedBox(width: 6),
                            Text(
                              'Create quest',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.workSans(
                                color: const Color(0xFFFFFDF7),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                height: 0.80,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTodayQuests,
      color: const Color(0xFF4542EB),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: quests.length,
        itemBuilder: (context, index) {
          final quest = quests[index];
          return Slidable(
            key: ValueKey(quest.id),
            endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.20,
            children: [
              CustomSlidableAction(
                onPressed: (context) async {
                  final questService = QuestService();
                  await questService.deleteQuest(quest.id);
                  _loadTodayQuests();
                },
                backgroundColor: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  Assets.images.buttonCalendarDelate.path,
                  height: 42,
                  width: 42,
                ),
              ),
            ],
          ),
          child: QuestCard(
            quest: quest,
            scheduledCall: _scheduledByQuest[quest.id],
            remainingCalls: _remainingCalls,
            onStartCall: (scheduledCallId) {
              context.push(
                AppRoutespath.aiVoice,
                extra: {
                  'questTitle': quest.task,
                  if (scheduledCallId != null) 'scheduledCallId': scheduledCallId,
                },
              ).then((_) {
                // Back from a call: the quota moved, so this quest's state may have too.
                if (mounted) _loadTodayQuests();
              });
            },
            onMoveToTomorrow: _moveToTomorrow,
            onToggle: () async {
              final questService = QuestService();
              await questService.updateQuestStatus(quest.id, !quest.taskDone);
              _loadTodayQuests();
            },
            onEdit: () async {
              // Awaited: an edit can move the call, and the reminder for it is local. Not
              // waiting left the list stale and the reminder pointing at the old time.
              final changed = await context.push<bool>(
                AppRoutespath.editQuestPage,
                extra: {
                  'taskId': quest.id,
                  'taskData': {
                    'title': quest.task,
                    'zone': quest.zone,
                    'selectADate': quest.selectADate,
                    // The edit screen reads 'time'; without it the picker opened on the
                    // current clock and the quest's own time was nowhere on the screen.
                    'time': quest.selectATime,
                    'enableCall': quest.enableCall,
                    'repeatQuest': quest.repeatQuest,
                    'setAlarm': quest.setAlarm,
                    'taskDone': quest.taskDone,
                    'subtasks': quest.subtasks.map((s) => {
                      'id': s.id,
                      'title': s.title,
                      'task_done': s.taskDone,
                    }).toList(),
                  },
                },
              );

              if (changed == true && mounted) {
                // Rebuild the local reminders before the list: the schedule is what the
                // user just changed, and it is the half nothing else would catch up on.
                await CallReminderService.instance.sync();
                await _loadTodayQuests();
              }
            },
          ),
        );
      },
      ),
    );
  }
}

class QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  /// This quest's planned call, if it has one. Null for quests created before scheduling
  /// existed, or with no time set.
  final ScheduledCall? scheduledCall;

  /// Calls left today; `-1` means unlimited. Together with [scheduledCall] this decides
  /// whether the call reads as upcoming, startable, or stranded by the daily limit.
  final int remainingCalls;

  /// Start the call. Receives the scheduled-call id when there is one, so the backend can
  /// close that plan out.
  final void Function(int? scheduledCallId) onStartCall;

  /// Push a call the user can no longer take to tomorrow.
  final void Function(ScheduledCall call) onMoveToTomorrow;

  const QuestCard({
    super.key,
    required this.quest,
    required this.onToggle,
    required this.onEdit,
    required this.onStartCall,
    required this.onMoveToTomorrow,
    this.scheduledCall,
    this.remainingCalls = 1,
  });

  Color _getLevelColor(String zone) => zoneColor(zone);

  Color _getTextColor(String zone) => zoneTextColor(zone);

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor(quest.zone);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFFFFEF8),
        border: Border.all(color: const Color(0xFFFFCB9B), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: quest.taskDone
                        ? const Color(0xFF4542EB)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      width: 2,
                      color: const Color(0xFF4542EB),
                    ),
                  ),
                  child: quest.taskDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    Assets.images.buttonCalendar.path,
                    height: 48,
                    width: 48,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quest.task,
            style: GoogleFonts.workSans(
              color: const Color(0xFF011F54),
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.20,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Image.asset(Assets.images.today.path, height: 20, width: 20),
              const SizedBox(width: 10),
              Text(
                "Today",
                style: GoogleFonts.workSans(
                  color: const Color(0xFF011F54),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: ShapeDecoration(
                  color: levelColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  quest.zone,
                  style: GoogleFonts.workSans(
                    color: _getTextColor(quest.zone),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.40,
                    letterSpacing: -0.40,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: ShapeDecoration(
                  color: const Color(0xFFFAE3CE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  "10 mins",
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: -0.40,
                  ),
                ),
              ),
            ],
          ),
          // "Enable call" quest flag: schedules a call at the quest's time AND keeps a
          // button so the user can talk to Nowlii earlier if they want to.
          if (quest.enableCall) ...[
            const SizedBox(height: 16),
            _buildCallSection(quest),
          ],
        ],
      ),
    );
  }

  /// What the quest's call looks like right now.
  ///
  /// A scheduled call is a plan, not a booking — the daily limit of two is only enforced
  /// when a call actually starts. So the same row can be "coming up at 17:00" or "you have
  /// no calls left" depending on what the user has done since, and the card has to say
  /// which. The rules live in `scheduled_call_state.dart`; this only renders them.
  Widget _buildCallSection(Quest quest) {
    final scheduled = scheduledCall;

    // No plan (an older quest, or one with no time set) — just the manual button.
    if (scheduled == null) return _buildCallButton(quest);

    final state = resolveScheduledCallState(
      serverStatus: scheduled.status,
      scheduledFor: scheduled.scheduledFor,
      now: DateTime.now(),
      remainingCalls: remainingCalls,
    );
    final at = DateFormat('HH:mm').format(scheduled.scheduledFor);

    switch (state) {
      case ScheduledCallState.completed:
        return _buildCallNote(
          icon: Icons.check_circle_outline,
          color: const Color(0xFF2E7D32),
          text: 'Call done',
        );

      case ScheduledCallState.cancelled:
        return _buildCallButton(quest);

      case ScheduledCallState.locked:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCallNote(
              icon: Icons.lock_clock,
              color: const Color(0xFF8A6D3B),
              text: "Call at $at — you've used both calls today",
            ),
            const SizedBox(height: 8),
            _buildMoveToTomorrow(scheduled),
          ],
        );

      case ScheduledCallState.missed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCallNote(
              icon: Icons.notifications_off_outlined,
              color: const Color(0xFF8A6D3B),
              text: 'Missed your $at call',
            ),
            const SizedBox(height: 8),
            _buildMoveToTomorrow(scheduled),
          ],
        );

      case ScheduledCallState.dueNow:
        return _buildCallButton(quest,
            label: 'Start your call', scheduledCallId: scheduled.id);

      case ScheduledCallState.upcoming:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCallNote(
              icon: Icons.schedule,
              color: const Color(0xFF4542EB),
              text: 'Call scheduled for $at',
            ),
            const SizedBox(height: 8),
            // Still offered: the plan is a reminder, not a restriction.
            _buildCallButton(quest,
                label: 'Call now instead', scheduledCallId: scheduled.id),
          ],
        );
    }
  }

  Widget _buildCallButton(Quest quest, {String? label, int? scheduledCallId}) {
    return GestureDetector(
      onTap: () => onStartCall(scheduledCallId),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF4542EB),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label ?? 'Call Nowlii (5 min)',
              style: GoogleFonts.workSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallNote({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.workSans(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveToTomorrow(ScheduledCall scheduled) {
    return GestureDetector(
      onTap: () => onMoveToTomorrow(scheduled),
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF4542EB), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          'Move to tomorrow',
          style: GoogleFonts.workSans(
            color: const Color(0xFF4542EB),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
