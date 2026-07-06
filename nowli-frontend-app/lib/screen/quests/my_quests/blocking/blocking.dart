import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/services/quest_service.dart';
import 'package:intl/intl.dart';
import 'package:nowlii/themes/text_styles.dart';

class Blockng extends StatefulWidget {
  const Blockng({super.key});

  @override
  State<Blockng> createState() => _BlockngState();
}

class _BlockngState extends State<Blockng> {
  List<Quest> quests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBacklogQuests();
  }

  Future<void> _loadBacklogQuests() async {
    final questService = QuestService();
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    
    final allQuests = await questService.fetchAllQuests();
    
    // Filter quests before today that are not completed
    final backlogQuests = allQuests.where((quest) {
      final questDate = DateTime.parse(quest.selectADate);
      final todayDate = DateTime.parse(todayStr);
      return questDate.isBefore(todayDate) && quest.taskDone == false;
    }).toList();
    
    // Sort by date (oldest first)
    backlogQuests.sort((a, b) => a.selectADate.compareTo(b.selectADate));
    
    if (mounted) {
      setState(() {
        quests = backlogQuests;
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
        onRefresh: _loadBacklogQuests,
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
                        height: 62,
                        width: 62,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "No backlog quests",
                      textAlign: TextAlign.center,
                      style: AppsTextStyles.workSansExtraBold20Center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Look at you — on top of everything!\nIf you ever miss a quest, it\'ll show up here.',
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
                            const Icon(Icons.add, color: Colors.white, size: 24),
                            const SizedBox(width: 6),
                            Text(
                              "Create quest",
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
      onRefresh: _loadBacklogQuests,
      color: const Color(0xFF4542EB),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: quests.map((quest) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: BacklogQuestCard(
                  quest: quest,
                  onMarkDone: () async {
                    final questService = QuestService();
                    await questService.updateQuestStatus(quest.id, true);
                    _loadBacklogQuests();
                  },
                  onSkip: () async {
                    final questService = QuestService();
                    await questService.deleteQuest(quest.id);
                    _loadBacklogQuests();
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class BacklogQuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback onMarkDone;
  final VoidCallback onSkip;

  const BacklogQuestCard({
    super.key,
    required this.quest,
    required this.onMarkDone,
    required this.onSkip,
  });

  Color _getLevelColor(String zone) {
    switch (zone) {
      case 'Soft steps':
        return const Color(0xFFA0E871);
      case 'Elevated':
        return const Color(0xFFF7A94B);
      case 'Stretch zone':
        return const Color(0xFF6AA7FF);
      case 'Power move':
        return const Color(0xFFFF5A5A);
      default:
        return const Color(0xFFA0E871);
    }
  }

  Color _getTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  String _getDateLabel() {
    final questDate = DateTime.parse(quest.selectADate);
    return DateFormat('MMM d, yyyy').format(questDate);
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor(quest.zone);
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEDCC5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_box_outline_blank,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Quest missed",
                    style: TextStyle(
                      color: Color(0xFFCC2B2B),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            quest.task,
            style: AppsTextStyles.regularResponsive(context),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onMarkDone,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFF5C3DFF)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Actually, I did this',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF4542EB),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 0.80,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: onSkip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFF5C3DFF)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Skip',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF4542EB),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 0.80,
                      ),
                    ),
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
