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

  Widget _buildStreakCard() {
    // Use streak API data, fallback to insights data
    final streakDays = _streak?.streak ?? _insights?.monthly.milestones.longestStreakDays ?? 0;
    
    return Container(
      height: 410,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage("assets/svg_icons/120Days.png"),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
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
              streakDays > 0
                  ? "You've stayed consistent for \n$streakDays days straight!"
                  : "Start your streak today!",
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
    );
  }

  Widget _buildWeeklyStreak() {
    final weeklyCalendar = _insights?.weekly.calendar ?? [];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    int completedDays = weeklyCalendar.where((day) => day.status == 'consistent').length;
    double progressPercentage = weeklyCalendar.isNotEmpty ? (completedDays / 7.0) : 0.0;
    int percentTo30Days = (progressPercentage * 100).toInt();

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

    // Real per-zone completed counts from the backend — weekly or monthly zone_progress
    // (both have the same shape). No client-side approximation.
    final zoneProgress = _movesPeriod == 'This month'
        ? (_insights?.monthly.zoneProgress ?? [])
        : (_insights?.weekly.zoneProgress ?? []);
    for (var zone in zoneProgress) {
      if (zone.zone == 'Soft steps') {
        softSteps = zone.completed;
      } else if (zone.zone == 'Power move') {
        powerMoves = zone.completed;
      }
    }

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
                softSteps > 0 ? 0.75 : 0.0,
                isPartial: true,
                trackColor: const Color(0xFFE8EDE0),
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
                powerMoves > 0 ? 1.0 : 0.0,
                isPartial: false,
                trackColor: Colors.transparent,
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
