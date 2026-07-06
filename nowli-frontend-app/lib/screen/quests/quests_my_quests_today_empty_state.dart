import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/custom_code/bottom_nav.dart';
import 'package:nowlii/screen/quests/my_quests/blocking/blocking.dart';
import 'package:nowlii/screen/quests/my_quests/completed/completed.dart';
import 'package:nowlii/screen/quests/my_quests/scheduled/scheduled.dart';
import 'package:nowlii/screen/quests/my_quests/today/today.dart';
import 'package:nowlii/screen/quests/suggested/soft_steps/soft_steps.dart';
import 'package:nowlii/themes/text_styles.dart';

class QuestHomePage extends StatefulWidget {
  const QuestHomePage({super.key});

  @override
  State<QuestHomePage> createState() => _QuestHomePageState();
}

class _QuestHomePageState extends State<QuestHomePage>
    with TickerProviderStateMixin {
  late TabController mainTab;
  late TabController myQuestsTab;
  late TabController suggestedTab;

  @override
  void initState() {
    super.initState();
    mainTab = TabController(length: 2, vsync: this);
    myQuestsTab = TabController(length: 4, vsync: this);
    suggestedTab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    mainTab.dispose();
    myQuestsTab.dispose();
    suggestedTab.dispose();
    super.dispose();
  }

  int _currentIndex = 1;

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        context.go(AppRoutespath.homeScreen);
        break;
      case 1:
        context.go(AppRoutespath.questHomePage);
        break;
      case 2:
        context.go(AppRoutespath.progress);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFEFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDFEFFF),
        elevation: 0,
        toolbarHeight: 120,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'QUESTS',
              style: TextStyle(
                color: const Color(0xFF011F54),
                fontSize: 52,
                fontFamily: 'Wosker',
                fontWeight: FontWeight.w400,
                height: 0.80,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Small steps, big progress.',
              textAlign: TextAlign.center,
              style: GoogleFonts.workSans(
                color: const Color(0xFF4C586E),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.40,
                letterSpacing: -0.50,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              context.push("/createQuestPage");
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.asset(
                Assets.svgIcons.quests.path,
                width: 60,
                height: 60,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFEF8),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TabBar(
                controller: mainTab,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(width: 5.0, color: Color(0xFF4542EB)),
                  insets: EdgeInsets.symmetric(horizontal: 0.0),
                ),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                labelColor: const Color(0xFF011F54),
                unselectedLabelColor: const Color(0xFFADB2BC),
                labelStyle: AppsTextStyles.workSansExtraBold20,
                unselectedLabelStyle: AppsTextStyles.workSansy6ExtraBold20,
                tabs: const [
                  Tab(text: "My quests"),
                  Tab(text: "Suggested"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: mainTab,
                  children: [_buildMyQuestSection(), _buildSuggestedSection()],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  // ---------------- MY QUESTS SECTION ----------------
  Widget _buildMyQuestSection() {
    return Column(
      children: [
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: TabBar(
            controller: myQuestsTab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: const BoxDecoration(),
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            tabs: List.generate(4, (index) {
              final titles = [
                'Todays',
                'Scheduled',
                'Completed',
                'Backlog',
              ];

              return Tab(
                child: AnimatedBuilder(
                  animation: myQuestsTab,
                  builder: (context, child) {
                    bool isCurrentlySelected = myQuestsTab.index == index;
                    return Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentlySelected
                            ? const Color(0xFFC3DBFF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: isCurrentlySelected
                              ? const Color(0xFFC3DBFF)
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        titles[index],
                        style: AppsTextStyles.workSansSemiBold18.copyWith(
                          color: isCurrentlySelected
                              ? Color(0xFF011F54)
                              : Colors.grey[600],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: myQuestsTab,
            children: const [Today(), Scheduled(), Completed(), Blockng()],
          ),
        ),
      ],
    );
  }

  // ---------------- SUGGESTED SECTION ----------------
  Widget _buildSuggestedSection() {
    return Column(
      children: [
        Container(
          // height: 0,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
          child: TabBar(
            controller: suggestedTab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: const BoxDecoration(),
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            tabs: List.generate(3, (index) {
              final titles = ['Soft steps', 'Stretch zone', 'Elevated'];
              return Tab(
                child: AnimatedBuilder(
                  animation: suggestedTab,
                  builder: (context, child) {
                    bool isSelected = suggestedTab.index == index;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 35,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFC3DBFF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFC3DBFF)
                              : Color(0xFFC3DBFF),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        titles[index],
                        style: AppsTextStyles.workSansSemiBold18.copyWith(
                          color: isSelected
                              ? Color(0xFF011F54)
                              : Colors.grey[600],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: suggestedTab,
            children: const [
              ShuffleScreen(filterZone: 'Soft steps'),
              ShuffleScreen(filterZone: 'Stretch zone'),
              ShuffleScreen(filterZone: 'Elevated'),
            ],
          ),
        ),
      ],
    );
  }
}
