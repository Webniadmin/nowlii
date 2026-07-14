import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/services/quest_service.dart';
import 'package:intl/intl.dart';

class Today extends StatefulWidget {
  const Today({super.key});

  @override
  State<Today> createState() => _TodayState();
}

class _TodayState extends State<Today> {
  List<Quest> quests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayQuests();
  }

  Future<void> _loadTodayQuests() async {
    final questService = QuestService();
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    
    final allQuests = await questService.fetchAllQuests();
    
    // Filter only today's quests
    final todayQuests = allQuests.where((quest) {
      return quest.selectADate == todayStr;
    }).toList();
    
    if (mounted) {
      setState(() {
        quests = todayQuests;
        _isLoading = false;
      });
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
            onToggle: () async {
              final questService = QuestService();
              await questService.updateQuestStatus(quest.id, !quest.taskDone);
              _loadTodayQuests();
            },
            onEdit: () {
              context.push(
                AppRoutespath.editQuestPage,
                extra: {
                  'taskId': quest.id,
                  'taskData': {
                    'title': quest.task,
                    'zone': quest.zone,
                    'selectADate': quest.selectADate,
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

  const QuestCard({
    super.key,
    required this.quest,
    required this.onToggle,
    required this.onEdit,
  });

  Color _getLevelColor(String zone) {
    switch (zone) {
      case 'Soft steps':
        return const Color(0xFFA0E871);
      case 'Elevated':
        return const Color(0xFFFF8F26);
      case 'Stretch zone':
        return const Color(0xFF3D87F5);
      case 'Power move':
        return const Color(0xFFD53D40);
      default:
        return const Color(0xFFA0E871);
    }
  }

  Color _getTextColor(Color levelColor) {
    if (levelColor == const Color(0xFFA0E871)) {
      return const Color(0xFF011F54);
    } else if (levelColor == const Color(0xFFFF8F26)) {
      return const Color(0xFF011F54);
    } else if (levelColor == const Color(0xFF3D87F5)) {
      return const Color(0xFFEEEEEE);
    } else if (levelColor == const Color(0xFFD53D40)) {
      return const Color(0xFFFFFDF7);
    }
    return const Color(0xFF011F54);
  }

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
                    color: _getTextColor(levelColor),
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
          // "Enable call" quest flag: when on, offer a real 5-min AI call for this quest.
          // The quest title is passed as conversation context to the companion.
          if (quest.enableCall) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                context.push(
                  AppRoutespath.aiVoice,
                  extra: {'questTitle': quest.task},
                );
              },
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
                      'Call Nowlii (5 min)',
                      style: GoogleFonts.workSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
