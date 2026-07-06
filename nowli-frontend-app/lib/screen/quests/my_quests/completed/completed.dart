import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/services/quest_service.dart';
import 'package:intl/intl.dart';
import 'package:nowlii/themes/text_styles.dart';

class Completed extends StatefulWidget {
  const Completed({super.key});

  @override
  State<Completed> createState() => _CompletedState();
}

class _CompletedState extends State<Completed> {
  List<Quest> quests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedQuests();
  }

  Future<void> _loadCompletedQuests() async {
    final questService = QuestService();
    final allQuests = await questService.fetchAllQuests();
    
    // Filter only completed quests
    final completedQuests = allQuests.where((quest) {
      return quest.taskDone == true;
    }).toList();
    
    // Sort by date (newest first)
    completedQuests.sort((a, b) => b.selectADate.compareTo(a.selectADate));
    
    if (mounted) {
      setState(() {
        quests = completedQuests;
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
        onRefresh: _loadCompletedQuests,
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
                    Text(
                      "No quests completed yet.",
                      textAlign: TextAlign.center,
                      style: AppsTextStyles.workSansExtraBold20Center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Progress comes in small wins — start today and this list will grow.\nYou've got this.",
                      textAlign: TextAlign.center,
                      style: AppsTextStyles.workSansRegularAdd16,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 210,
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
                            const Icon(Icons.add, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              "Start quest",
                              style: AppsTextStyles.workSansBlack18Center,
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
      onRefresh: _loadCompletedQuests,
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
                  _loadCompletedQuests();
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
          child: CompletedQuestCard(quest: quest),
        );
      },
      ),
    );
  }
}

class CompletedQuestCard extends StatelessWidget {
  final Quest quest;

  const CompletedQuestCard({
    super.key,
    required this.quest,
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

  String _getDateLabel() {
    final questDate = DateTime.parse(quest.selectADate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final questDay = DateTime(questDate.year, questDate.month, questDate.day);
    
    if (questDay == today) {
      return 'Today';
    }
    return DateFormat('MMM d, yyyy').format(questDate);
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor(quest.zone);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF0F9FF),
        border: Border.all(color: const Color(0xFFC3DBFF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF4542EB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    width: 2,
                    color: const Color(0xFF4542EB),
                  ),
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  quest.task,
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.20,
                    letterSpacing: -1,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Image.asset(Assets.images.today.path, height: 20, width: 20),
              const SizedBox(width: 10),
              Text(
                _getDateLabel(),
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
            ],
          ),
        ],
      ),
    );
  }
}
