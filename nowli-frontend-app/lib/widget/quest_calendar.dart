/// The one calendar in the app.
///
/// Two screens draw the same grid of days and had no business each owning a copy: Insights
/// shows the whole month, My Progress shows the current week under the streak card. Both
/// are this widget — a month is five rows of it, a week is one — so the day a colour or an
/// icon changes, it changes in both places.
///
/// From Figma `53:10201` ("Datepickers"). The three states are the whole vocabulary:
/// a day you finished, a day you did not, and a day that has not happened yet.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nowlii/core/gen/assets.gen.dart';

/// What a single day looks like.
///
/// There is deliberately no `streak` member. The backend still reports one — a day inside a
/// run of seven — but the design has no separate mark for it, and a streak day *is* a day
/// where everything got done, so it draws as [consistent]. Callers map it; see
/// [questCalendarStatus].
enum QuestCalendarStatus {
  /// Every quest for that day was finished. Peach circle, orange check.
  consistent,

  /// The day came and went with something unfinished. Pale blue circle, blue minus.
  /// Rest days are **not** skipped — the backend already reports those as `none`.
  skipped,

  /// Nothing to say: a day still ahead, a day with no quests, or a rest day.
  none,
}

/// The backend's status string as a mark on the grid.
///
/// Anything unrecognised is [QuestCalendarStatus.none] rather than an error — a calendar
/// with a blank day is a smaller failure than a Progress tab that will not open.
QuestCalendarStatus questCalendarStatus(String? raw) {
  switch (raw) {
    case 'consistent':
    case 'streak':
      return QuestCalendarStatus.consistent;
    case 'skipped':
      return QuestCalendarStatus.skipped;
    default:
      return QuestCalendarStatus.none;
  }
}

class QuestCalendar extends StatelessWidget {
  const QuestCalendar({
    super.key,
    required this.cells,
    this.monthLabel,
    this.showWeekdayHeader = true,
    this.showLegend = true,
  });

  /// One entry per grid cell, read left-to-right, top-to-bottom, Monday-first.
  ///
  /// A `null` is a blank before the 1st of the month — not a day with nothing on it, so it
  /// draws no circle at all. Callers building a month get this shape from `monthGridCells`;
  /// a week is simply seven non-null entries.
  final List<QuestCalendarStatus?> cells;

  /// Printed above the grid, centred. Null on the week strip, which sits under a heading
  /// that already says what it is.
  final String? monthLabel;

  final bool showWeekdayHeader;
  final bool showLegend;

  // Straight from the design's tokens. The project has no token layer, so these are
  // literals here and nowhere else — that is the point of the widget.
  static const Color _consistentFill = Color(0xFFFAE3CE); // bg/bg-secondary-level-2
  static const Color _skippedFill = Color(0xFFDFEFFF); // bg/bg-primary-light
  static const Color _emptyFill = Color(0xFFF5F5F5);
  static const Color _headerInk = Color(0xFFADB2BC); // text/text-primary-placeholder
  static const Color _monthInk = Color(0xFF011F54);
  static const Color _skippedInk = Color(0xFF3D87F5); // text/text-blue
  static const Color _consistentInk = Color(0xFFFF8F26); // text/text-secondary

  /// The designed circle. Cells shrink below this on a narrow screen rather than overflow,
  /// but never grow past it — at full width a seven-column grid would otherwise blow the
  /// circles up to twice the size the design draws.
  static const double _cellSize = 40.5;

  /// The glyph inside the circle. Fixed, not a fraction of the circle: the two SVGs are
  /// drawn on a 20px canvas and carry their own fill (`#FF8F26`, `#89B6F8`), so they are
  /// rendered untinted at their own size.
  static const double _iconSize = 20;

  static const double _gap = 6.5;

  static const List<String> _weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (monthLabel != null) ...[
          Text(
            monthLabel!,
            textAlign: TextAlign.center,
            style: GoogleFonts.workSans(
              color: _monthInk,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: _gap),
        ],
        if (showWeekdayHeader) ...[
          Row(
            children: [
              for (final day in _weekdays)
                Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: _headerInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: _gap),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: _gap,
            crossAxisSpacing: _gap,
          ),
          itemCount: cells.length,
          itemBuilder: (context, index) => _buildCell(cells[index]),
        ),
        if (showLegend) ...[
          const SizedBox(height: 24),
          _buildLegend(),
        ],
      ],
    );
  }

  Widget _buildCell(QuestCalendarStatus? status) {
    // A blank before the 1st. Not a day, so not a circle.
    if (status == null) return const SizedBox.shrink();

    final Color fill;
    final Widget? glyph;

    switch (status) {
      case QuestCalendarStatus.consistent:
        fill = _consistentFill;
        glyph = Assets.svgIcons.calendarCheckCircle
            .svg(width: _iconSize, height: _iconSize);
        break;
      case QuestCalendarStatus.skipped:
        fill = _skippedFill;
        glyph = Assets.svgIcons.calendarMinusCircle
            .svg(width: _iconSize, height: _iconSize);
        break;
      case QuestCalendarStatus.none:
        fill = _emptyFill;
        glyph = null;
        break;
    }

    return Center(
      child: SizedBox(
        width: _cellSize,
        height: _cellSize,
        child: DecoratedBox(
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: glyph == null ? null : Center(child: glyph),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        _legendItem(
          icon: Assets.svgIcons.calendarMinusCircle
              .svg(width: _iconSize, height: _iconSize),
          label: 'Skipped',
          color: _skippedInk,
        ),
        _legendItem(
          icon: Assets.svgIcons.calendarCheckCircle
              .svg(width: _iconSize, height: _iconSize),
          label: 'Consistent',
          color: _consistentInk,
        ),
      ],
    );
  }

  Widget _legendItem({
    required Widget icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.workSans(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.4,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
