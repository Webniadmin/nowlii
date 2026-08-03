import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/models/call_summary_history.dart';
import 'package:nowlii/services/receipt_format.dart';
import 'package:nowlii/services/voice_call_service.dart';

/// The receipt library: every saved voice-call summary, newest first.
///
/// Supersedes the old Call History screen (relocated to `lib/experimental/`). Same data —
/// `GET /api/voice-calls/summaries/` — presented as paper receipts, because the point is
/// for someone to notice their own repeated words across calls rather than to browse a log.
///
/// Result contract: popping with `true` asks the Insights screen to scroll to the section
/// that aggregates those repeated words, which is what the bottom button promises.
class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  static const Color _bg = Color(0xFFDFEFFF);
  static const Color _card = Color(0xFFFFFEF8);
  static const Color _ink = Color(0xFF011F54);
  static const Color _muted = Color(0xFF4C586E);

  /// Serial-number colours, cycled so the list does not read as one grey block.
  static const List<Color> _numberColours = [
    Color(0xFF8C4F15),
    Color(0xFF4542EB),
    Color(0xFF4C586E),
  ];

  /// Chip fills, cycled per word.
  static const List<Color> _chipColours = [
    Color(0xFFFAE3CE),
    Color(0xFFDFEFFF),
    Color(0xFFECECFD),
  ];

  final VoiceCallService _service = VoiceCallService();

  List<CallSummaryHistoryItem> _receipts = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final receipts = await _service.getSummaries();
    if (!mounted) return;
    setState(() {
      _receipts = receipts;
      _loading = false;
    });
  }

  /// The oldest receipt's date, for "since 3 July". The list is newest-first, so that is
  /// the last entry — and the field can be null, so fall back through the ones that exist.
  DateTime? get _earliest {
    for (final receipt in _receipts.reversed) {
      final when = receipt.startedAt ?? receipt.createdAt;
      if (when != null) return when;
    }
    return null;
  }

  void _openReceipt(int index) {
    final total = _receipts.length;
    context.push(
      AppRoutespath.receiptDetail,
      extra: {
        'receipt': _receipts[index],
        'number': receiptNumber(index: index, total: total),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 13, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR WORDS,\nKEPT.',
                        style: TextStyle(
                          fontFamily: 'Wosker',
                          color: _ink,
                          fontSize: 52,
                          fontWeight: FontWeight.w400,
                          height: 0.8,
                        ),
                      ),
                      const SizedBox(height: 11),
                      Text(
                        _loading
                            ? 'Loading your receipts…'
                            : receiptsSummaryLine(
                                count: _receipts.length,
                                earliest: _earliest,
                              ),
                        style: GoogleFonts.workSans(
                          color: _muted,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(child: _buildBody()),
              ],
            ),

            // Only offer the aggregate view once there is something to aggregate.
            if (!_loading && _receipts.isNotEmpty)
              Positioned(left: 0, right: 0, bottom: 0, child: _buildFooterButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4542EB)),
      );
    }
    if (_receipts.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF4542EB),
      backgroundColor: _card,
      child: ListView.separated(
        // Room for the button floating over the end of the list.
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _receipts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildReceiptCard(index),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'No receipts yet.\nEvery call leaves one behind.',
          textAlign: TextAlign.center,
          style: GoogleFonts.workSans(
            color: _muted,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptCard(int index) {
    final receipt = _receipts[index];
    final number = receiptNumber(index: index, total: _receipts.length);
    final title = receiptCardTitle(receipt.nextStep);
    final when = receipt.startedAt ?? receipt.createdAt;

    return GestureDetector(
      onTap: () => _openReceipt(index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${receiptDateLabel(when)} · '
                            '${callLengthLabel(receipt.durationSeconds)}'
                        .toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.martianMono(
                      color: _muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.05,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'no. ${receiptNumberLabel(number)}',
                  style: GoogleFonts.martianMono(
                    color: _numberColours[index % _numberColours.length],
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.6),
            // A call can end without a next step; falling back to the mood keeps the card
            // from being a headline-shaped hole.
            Text(
              title.isNotEmpty
                  ? title
                  : (receipt.moodDetected.trim().isNotEmpty
                      ? receipt.moodDetected.toUpperCase()
                      : 'A CALL, KEPT.'),
              style: GoogleFonts.workSans(
                color: _ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 0.9,
                letterSpacing: -0.5,
              ),
            ),
            if (receipt.wordsCircled.isNotEmpty) ...[
              const SizedBox(height: 13),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (int i = 0; i < receipt.wordsCircled.length; i++)
                    _WordChip(
                      word: receipt.wordsCircled[i],
                      background: _chipColours[i % _chipColours.length],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooterButton() {
    return IgnorePointer(
      ignoring: false,
      child: Container(
        height: 150,
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        // Fades the list out under the button instead of letting cards collide with it.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00DFEFFF), _bg],
            stops: [0.0, 0.42],
          ),
        ),
        child: GestureDetector(
          // Insights already aggregates the words that repeat across calls; this hands the
          // user back to it rather than duplicating that work on a second screen.
          onTap: () => context.pop(true),
          child: Container(
            height: 64,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: const ShapeDecoration(
              color: Color(0xFF4542EB),
              shape: StadiumBorder(),
            ),
            child: Text(
              'See what keeps coming back',
              style: GoogleFonts.workSans(
                color: _card,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final String word;
  final Color background;

  const _WordChip({required this.word, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
      child: Text(
        receiptWordLabel(word),
        style: GoogleFonts.workSans(
          color: const Color(0xFF011F54),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }
}
