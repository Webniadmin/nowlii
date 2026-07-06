import 'package:flutter/material.dart';

import 'package:nowlii/custom_code/bottom_nav.dart';
import 'package:nowlii/screen/progress/insights/insights.dart';
import 'package:nowlii/screen/progress/my_progress/my_progress.dart';
import 'package:nowlii/themes/text_styles.dart';

class Progress extends StatefulWidget {
  const Progress({super.key});

  @override
  State<Progress> createState() => _ProgressState();
}

class _ProgressState extends State<Progress> with TickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ---------------- APP BAR ----------------
      backgroundColor: Color(0xFFFFFEF8),

      appBar: AppBar(
        backgroundColor: Color(0xFFFFFEF8),
        elevation: 0,
        toolbarHeight: 90,
        title: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("PROGRESS", style: AppsTextStyles.saimTitle),
              const SizedBox(height: 4),
              Text(
                "Track your growth and reflections",
                style: AppsTextStyles.workSansRegularF16,
              ),
            ],
          ),
        ),
      ),

      // ---------------- BODY ----------------
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFEF8),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            TabBar(
              controller: mainTab,
              // Custom indicator with underline
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 5.0, color: Colors.black),
                insets: EdgeInsets.symmetric(horizontal: 0.0),
              ),
              // REMOVE hover / overlay
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              // REMOVE splash effect
              splashFactory: NoSplash.splashFactory,
              labelStyle: AppsTextStyles.workSansExtraBold20,
              unselectedLabelStyle: AppsTextStyles.workSansy6ExtraBold20,
              tabs: const [
                Tab(text: "My progress"),
                Tab(text: "Insights"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: mainTab,
                children: [MyProgress(), InsightsScreen()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          // Handle navigation tap
        },
      ),
    );
  }
}
