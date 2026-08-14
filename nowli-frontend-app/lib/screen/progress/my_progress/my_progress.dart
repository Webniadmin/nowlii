import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/create_qutes.dart';
import 'package:nowlii/themes/text_styles.dart';
import 'package:nowlii/services/insights_service.dart';
import 'package:nowlii/services/streak_service.dart';
import 'package:nowlii/models/insights_models.dart';
import 'package:nowlii/models/streak_model.dart';

class MyProgress extends StatefulWidget {
  const MyProgress({super.key});

  @override
  State<MyProgress> createState() => _MyProgressState();
}

class _MyProgressState extends State<MyProgress> {
  final InsightsService _insightsService = InsightsService();
  final StreakService _streakService = StreakService();
  InsightsResponse? _insights;
  StreakResponse? _streak;
  bool _isLoading = true;

  // 1B: selected period for the "Your moves" section (This week / This month).
  String _movesPeriod = 'This week';

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
    });

    final insights = await _insightsService.getInsights();
    final streak = await _streakService.getStreak();
    
    setState(() {
      _insights = insights;
      _streak = streak;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF4542EB),
          ),
        ),
      );
    }

    if (_insights == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Unable to load insights',
                style: GoogleFonts.workSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadInsights,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4542EB),
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadInsights,
          color: const Color(0xFF4542EB),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStreakCard(),
                const SizedBox(height: 16),
                _buildWeeklyStreak(),
                const SizedBox(height: 24),
                _buildMovesSection(),
                const SizedBox(height: 24),
                _buildActivityTrend(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Milestone thresholds a streak can reach; the card targets the next one up and tints
  // its background by tier so it visibly "levels up" as the streak grows.
  static const List<int> _streakMilestones = [3, 7, 14, 30, 60, 90, 120, 180, 365];

  // The streak card used to change colour by tier — blue at a day, peach at a week, gold
  // at 120. The design gives it one background instead (see _buildStreakCard), so this is
  // unused. Kept rather than deleted: the tiers are a product idea, not a mistake, and if
  // they come back this is what they looked like.
  /*
  LinearGradient _streakGradient(int days) {
    List<Color> colors;
    if (days >= 120) {
      colors = [const Color(0xFFFFE39A), const Color(0xFFFFB74D)]; // gold
    } else if (days >= 30) {
      colors = [const Color(0xFFFFE3C2), const Color(0xFFFFC078)]; // warm orange
    } else if (days >= 7) {
      colors = [const Color(0xFFFFF1DD), const Color(0xFFFFD9A8)]; // peach
    } else if (days >= 1) {
      colors = [const Color(0xFFEAF1FF), const Color(0xFFC3DBFF)]; // light blue
    } else {
      colors = [const Color(0xFFF2F4F8), const Color(0xFFE2E8F2)]; // neutral
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
  */

  Widget _buildStreakCard() {
    // Use streak API data, fallback to insights data
    final streakDays = _streak?.streak ?? _insights?.monthly.milestones.longestStreakDays ?? 0;

    // Next milestone above the current streak (0 = already past the last one), plus the
    // baseline milestone below it, to draw real progress toward the next badge.
    final nextMilestone =
        _streakMilestones.firstWhere((m) => m > streakDays, orElse: () => 0);
    final prevMilestone =
        _streakMilestones.lastWhere((m) => m <= streakDays, orElse: () => 0);
    final daysToGo = nextMilestone > 0 ? nextMilestone - streakDays : 0;
    final span = nextMilestone > prevMilestone ? nextMilestone - prevMilestone : 1;
    final milestoneProgress = nextMilestone > 0
        ? ((streakDays - prevMilestone) / span).clamp(0.0, 1.0)
        : 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // The card's own background, from Figma 15:1933 — a peach ground washed to
          // orange, with two green blooms bleeding off the edges. Positioned.fill so the
          // decoration takes its size from the content in the stack below.
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFAE3CE), Color(0xFFFF8F26)],
                ),
              ),
            ),
          ),
          // The same flower the home screen uses, tinted to the design's green rather than
          // shipped a second time: the two SVGs are the identical path, and differ only in
          // fill.
          Positioned(left: -307, top: -366, child: _streakBloom()),
          Positioned(left: -16, top: 201, child: _streakBloom()),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
          SizedBox(
            width: 302,
            child: Text(
              'Daily streak',
              style: GoogleFonts.workSans(
                color: const Color(0xFF011F54),
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 302,
            child: Text(
              streakDays <= 0
                  ? "Start your streak today!"
                  : nextMilestone > 0
                      ? "You've stayed consistent for $streakDays days!\n$daysToGo to go to your $nextMilestone-day badge."
                      : "Legendary — $streakDays days and counting!",
              style: GoogleFonts.workSans(
                color: const Color(0xFF011F54),
                fontSize: 18,
                fontWeight: FontWeight.w400,
                height: 1.4,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: ShapeDecoration(
              color: const Color(0xFFFF8F26),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(Assets.svgIcons.fire.path, width: 40, height: 40),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$streakDays DAYS',
                    style: TextStyle(
                      color: const Color(0xFF3F3CD6),
                      fontSize: 48,
                      fontFamily: 'Wosker',
                      fontWeight: FontWeight.w400,
                      height: 0.80,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Progress toward the next milestone badge (real streak data).
          if (nextMilestone > 0) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: 302,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: milestoneProgress,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.6),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Color(0xFF4542EB)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$streakDays / $nextMilestone days',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF011F54),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // 1A: "Share" button hidden per request — commented out (not deleted).
          /*
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 80,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: Image.asset(
                Assets.svgIcons.shareMySuccess.path,
                width: 24,
                height: 24,
              ),
              label: Text(
                'Share',
                textAlign: TextAlign.center,
                style: GoogleFonts.workSans(
                  color: const Color(0xFFFFFDF7),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 0.80,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
          */
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One of the two green blooms behind the streak card.
  ///
  /// Figma wraps the 431px flower in a 574.594px box and rotates it 64.49° about that
  /// box's centre; reproduced here rather than pre-rotating, so the two Positioned offsets
  /// are the design's own numbers and stay comparable to it.
  Widget _streakBloom() {
    return IgnorePointer(
      child: SizedBox(
        width: 574.594,
        height: 574.594,
        child: Center(
          child: Transform.rotate(
            angle: 64.49 * pi / 180,
            child: Assets.svgIcons.homeFlower.svg(
              width: 431,
              height: 431,
              colorFilter: const ColorFilter.mode(
                Color(0xFFA0E871),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyStreak() {
    final weeklyCalendar = _insights?.weekly.calendar ?? [];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    int completedDays = weeklyCalendar.where((day) => day.status == 'consistent').length;
    double progressPercentage = weeklyCalendar.isNotEmpty ? (completedDays / 7.0) : 0.0;
    // "% to 30 days" = how far the real current streak is toward a 30-day streak (not this
    // week's completion). Uses the same streak source as the streak card.
    final streakDays = _streak?.streak ?? _insights?.monthly.milestones.longestStreakDays ?? 0;
    int percentTo30Days = ((streakDays / 30.0) * 100).clamp(0, 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              7,
              (index) {
                final dayData = index < weeklyCalendar.length ? weeklyCalendar[index] : null;
                final isCompleted = dayData?.status == 'consistent';
                
                return Column(
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: Image.asset(
                          isCompleted ? Assets.svgIcons.blue.path : Assets.svgIcons.sunButton.path,
                          width: 60,
                          height: 60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      index < days.length ? days[index] : '',
                      style: AppTextStylesQutes.workSansSemiBold18,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 24,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFC3DBFF),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: constraints.maxWidth * progressPercentage,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFFDFEFFF), Color(0xFF4542EB)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedDays-Day Streak',
                style: GoogleFonts.workSans(
                  color: const Color(0xFF4C586E),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: -0.9,
                ),
              ),
              Text(
                '$percentTo30Days% to 30 days',
                style: GoogleFonts.workSans(
                  color: const Color(0xFF4542EB),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovesSection() {
    int softSteps = 0;
    int powerMoves = 0;
    int softAssigned = 0;
    int powerAssigned = 0;

    // Real per-zone completed counts from the backend — weekly or monthly zone_progress
    // (both have the same shape). No client-side approximation.
    final zoneProgress = _movesPeriod == 'This month'
        ? (_insights?.monthly.zoneProgress ?? [])
        : (_insights?.weekly.zoneProgress ?? []);
    for (var zone in zoneProgress) {
      if (zone.zone == 'Soft steps') {
        softSteps = zone.completed;
        softAssigned = zone.assigned;
      } else if (zone.zone == 'Power move') {
        powerMoves = zone.completed;
        powerAssigned = zone.assigned;
      }
    }

    // Ring fill = completed / assigned for that zone (real ratio, not a fixed fraction).
    final softFraction =
        softAssigned > 0 ? (softSteps / softAssigned).clamp(0.0, 1.0) : 0.0;
    final powerFraction =
        powerAssigned > 0 ? (powerMoves / powerAssigned).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFFCB9B)),
        color: const Color(0xFFFFFCF1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your moves', style: AppTextStylesQutes.workSansBlack20),
              // 1B: the pill is now a period selector (This week / This month).
              // Same pill design — only behavior added (tap to open menu).
              PopupMenuButton<String>(
                onSelected: (value) => setState(() => _movesPeriod = value),
                padding: EdgeInsets.zero,
                tooltip: '',
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'This week',
                    child: Text('This week'),
                  ),
                  PopupMenuItem<String>(
                    value: 'This month',
                    child: Text('This month'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFFAE3CE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _movesPeriod,
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF011F54),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMoveCircle(
                '$softSteps',
                'Soft Moves',
                const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3BB64B), Color(0x003BB64B)],
                  stops: [0.0, 1.075],
                ),
                softFraction,
                isPartial: true,
                trackColor: const Color(0xFFE8EDE0),
                assigned: softAssigned,
              ),
              _buildMoveCircle(
                '$powerMoves',
                'Power moves',
                const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4542EB), Color(0x004542EB)],
                  stops: [0.0, 1.075],
                ),
                // Was `powerMoves > 0 ? 1.0 : 0.0` — one completed Power move out of five
                // drew a full ring. Same real ratio as the other one.
                powerFraction,
                isPartial: true,
                trackColor: const Color(0xFFE4E4F8),
                assigned: powerAssigned,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoveCircle(
    String count,
    String label,
    LinearGradient gradient,
    double sweepFraction, {
    bool isPartial = true,
    Color trackColor = const Color(0xFFE8EDE0),
    int assigned = 0,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GradientRingCircle(
                label: count,
                gradient: gradient,
                labelColor: gradient.colors.first,
                sweepFraction: sweepFraction,
                trackColor: trackColor,
                isPartial: isPartial,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        // The ring shows what was finished. On its own a "0" is indistinguishable from
        // having no quests at all — which is exactly how a week with two unfinished ones
        // read. The denominator is the difference between "nothing there" and "not yet".
        const SizedBox(height: 2),
        Text(
          assigned > 0 ? 'of $assigned' : 'none set',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTrend() {
    final weeklyCalendar = _insights?.weekly.calendar ?? [];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    List<double> completedCounts = [];
    for (int i = 0; i < 7; i++) {
      if (i < weeklyCalendar.length) {
        completedCounts.add(weeklyCalendar[i].completed.toDouble());
      } else {
        completedCounts.add(0);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDFEFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC3DBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: Color(0xFF1E3A8A), size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Activity trend',
                        style: AppsTextStyles.black24Uppercase,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // 1C: Activity Trend "This week" label hidden per request —
              // commented out (not deleted). Rest of the section is untouched.
              /*
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: ShapeDecoration(
                  color: const Color(0xFFC3DBFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'This week',
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF011F54),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              */
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Completed quests per day',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          days[value.toInt()],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  7,
                  (index) => _buildBar(index, completedCounts[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFFDFEFFF), Color(0xFF4542EB)],
          ),
          width: 34.14,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
}

class GradientRingCircle extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final Color labelColor;
  final double sweepFraction;
  final Color trackColor;
  final bool isPartial;

  const GradientRingCircle({
    super.key,
    required this.label,
    required this.gradient,
    required this.labelColor,
    required this.sweepFraction,
    required this.trackColor,
    required this.isPartial,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: CustomPaint(
        painter: GradientRingPainter(
          gradient: gradient,
          strokeWidth: 15,
          sweepFraction: sweepFraction,
          trackColor: trackColor,
          isPartial: isPartial,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.workSans(
              color: labelColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.20,
              letterSpacing: -0.50,
            ),
          ),
        ),
      ),
    );
  }
}

class GradientRingPainter extends CustomPainter {
  final LinearGradient gradient;
  final double strokeWidth;
  final double sweepFraction;
  final Color trackColor;
  final bool isPartial;

  GradientRingPainter({
    required this.gradient,
    required this.strokeWidth,
    required this.sweepFraction,
    required this.trackColor,
    required this.isPartial,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (trackColor != Colors.transparent) {
      final trackPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius, trackPaint);
    }

    final gradientPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (isPartial) {
      final startAngle = (-220) * (pi / 180);
      final sweepAngle = sweepFraction * 2 * pi;
      canvas.drawArc(rect, startAngle, sweepAngle, false, gradientPaint);
    } else {
      gradientPaint.strokeCap = StrokeCap.butt;
      canvas.drawCircle(center, radius, gradientPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GradientRingPainter oldDelegate) {
    return oldDelegate.sweepFraction != sweepFraction ||
        oldDelegate.gradient != gradient;
  }
}
