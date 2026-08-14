import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/utils/mood_icons.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/services/call_summary_service.dart';
import 'package:nowlii/services/voice_call_service.dart';
import 'package:nowlii/services/personal_notes_service.dart';
import 'package:nowlii/models/call_summary_model.dart';

class CallSummaryScreen extends StatefulWidget {
  final String? sessionId;
  // Backend VoiceCall id for this call. When present, the generated summary is persisted
  // to the backend for this user (so it can be reviewed later to track progress).
  final int? callId;

  const CallSummaryScreen({
    super.key,
    this.sessionId,
    this.callId,
  });

  @override
  State<CallSummaryScreen> createState() => _CallSummaryScreenState();
}

class _CallSummaryScreenState extends State<CallSummaryScreen> {
  final CallSummaryService _summaryService = CallSummaryService();
  final VoiceCallService _voiceCallService = VoiceCallService();
  final PersonalNotesService _notesService = PersonalNotesService();
  final TextEditingController _noteController = TextEditingController();
  
  CallSummaryResponse? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  /// Whether the summary itself was sent to the backend. The "Save reflection" button
  /// only ever handled the optional personal note, so with the note box empty it
  /// answered "Nothing to save yet" — while the summary had already been saved on load
  /// and duly appeared in Call History. The button was contradicting the app.
  bool _summaryPersisted = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    if (widget.sessionId == null || widget.sessionId!.isEmpty) {
      // No AI session (e.g. the :8001 AI service wasn't reachable during the call).
      // Don't show an error — fall back to the friendly default summary below
      // (the insight cards already render sensible placeholder text when _summary
      // is null).
      setState(() {
        _isLoading = false;
        _summary = null;
        _errorMessage = null;
      });
      return;
    }

    try {
      final summary = await _summaryService.getSummary(widget.sessionId!);

      // Persist the generated summary for this user so it survives nowli-ai restarts and
      // can be reviewed later to track progress. Best-effort; never blocks the UI.
      _persistSummary(summary);

      if (mounted) {
        setState(() {
          // summary may be null (e.g. nowli-ai 422 for an empty session, or the AI
          // service was unreachable). Never surface a technical error — fall back to the
          // friendly default insight cards below (they render sensible placeholder text
          // when _summary is null). Unifies with the missing-sessionId branch above.
          _summary = summary;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _summary = null;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    }
  }

  /// Save the generated summary to the backend for this user. Only runs when we have a
  /// backend call id and a summary with real content. Fire-and-forget: the backend upsert
  /// is idempotent, so a retry (or a re-open of this screen) won't create duplicates.
  void _persistSummary(CallSummaryResponse? summary) {
    final callId = widget.callId;
    if (callId == null || summary == null) return;
    final hasContent = summary.moodDetected.isNotEmpty ||
        summary.focusTopic.isNotEmpty ||
        summary.energyShift.isNotEmpty ||
        summary.nextStep.isNotEmpty;
    if (!hasContent) return;

    _summaryPersisted = true;
    _voiceCallService.saveSummary(
      callId: callId,
      moodDetected: summary.moodDetected,
      focusTopic: summary.focusTopic,
      energyShift: summary.energyShift,
      nextStep: summary.nextStep,
      dominantEmotion: summary.dominantEmotion,
      topEmotions: summary.topEmotions,
      wordsCircled: summary.wordsCircled,
      tinyQuestion: summary.tinyQuestion,
      language: summary.language,
      totalTurns: summary.totalTurns,
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: const Color(0xFF4542EB),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing your conversation...',
                      style: TextStyle(
                        color: const Color(0xFF4C586E),
                        fontSize: 16,
                        fontFamily: 'Work Sans',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF4C586E),
                              fontSize: 16,
                              fontFamily: 'Work Sans',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              context.go(AppRoutespath.homeScreen);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3F3CD6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            child: Text(
                              'Go to Home',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Work Sans',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 54),
                          
                          // Avatar — reflects the call's dominant emotion (falls back to a
                          // neutral happy face when there's no summary yet).
                          Container(
                            width: 100,
                            height: 100,
                            decoration: ShapeDecoration(
                              color: _emotionColor(_summary?.dominantEmotion),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                _emotionIcon(_summary?.dominantEmotion),
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Title
                          Text(
                            'GREAT JOB!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF011F54),
                              fontSize: 52,
                              fontFamily: 'Wosker',
                              fontWeight: FontWeight.w400,
                              height: 0.8,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Subtitle
                          Text(
                            'You nailed it! Here\'s what ${_summary?.systemName ?? 'Fuzzy'} noticed during chat.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF4C586E),
                              fontSize: 18,
                              fontFamily: 'Work Sans',
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                              letterSpacing: -0.5,
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Insights
                          _buildInsightCard(
                            title: 'Mood detected',
                            description: _summary?.moodDetected ?? "I didn't quite catch your mood this time.",
                            backgroundColor: const Color(0xFFFAE3CE),
                            icon: Icons.mood,
                            // The face follows the mood. It was a fixed `Icons.mood`, so
                            // a call that ended in tears and one that ended laughing
                            // carried the same smile.
                            iconAsset: moodIconAsset(
                              category: _summary?.dominantEmotion,
                              text: _summary?.moodDetected,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          _buildInsightCard(
                            title: 'Focus topic',
                            description: _summary?.focusTopic ?? "We didn't land on a specific topic this time.",
                            backgroundColor: const Color(0xFFDFEFFF),
                            icon: Icons.book,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          _buildInsightCard(
                            title: 'Energy shift',
                            description: _summary?.energyShift ?? "Too short a chat for me to tell.",
                            backgroundColor: const Color(0xFFDFEFFF),
                            icon: Icons.bolt,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          _buildInsightCard(
                            title: 'Next step',
                            description: _summary?.nextStep ?? "Let's have a proper chat next time. 💜",
                            backgroundColor: const Color(0xFFDFEFFF),
                            icon: Icons.trending_up,
                          ),
                          
                          _buildWordsCircledSection(),

                          const SizedBox(height: 32),

                          _buildEmotionsSection(),

                          // Personal note section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'Add personal note',
                                  style: TextStyle(
                                    color: const Color(0xFF011F54),
                                    fontSize: 16,
                                    fontFamily: 'Work Sans',
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                height: 87,
                                padding: const EdgeInsets.all(24),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFFFFDF7),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 2,
                                      color: const Color(0xFFC3DBFF),
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: TextField(
                                  controller: _noteController,
                                  decoration: InputDecoration(
                                    hintText: 'Write short note to yourself...',
                                    hintStyle: TextStyle(
                                      color: const Color(0xFF4C586E),
                                      fontSize: 16,
                                      fontFamily: 'Work Sans',
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                      letterSpacing: -0.5,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: OutlinedButton(
                                  onPressed: () {
                                    context.go(AppRoutespath.homeScreen);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      width: 2,
                                      color: const Color(0xFF6A68EF),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                  ),
                                  child: Text(
                                    'Dismiss',
                                    style: TextStyle(
                                      color: const Color(0xFF4542EB),
                                      fontSize: 20,
                                      fontFamily: 'Work Sans',
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // Persist the reflection as a personal note (per user,
                                    // via the same store the Insights screen reads), so it
                                    // survives and shows up there. Empty note → just leave.
                                    final note = _noteController.text.trim();
                                    if (note.isNotEmpty) {
                                      await _notesService.addNote(note);
                                    }
                                    if (!mounted) return;

                                    // Three honest outcomes, where there used to be two
                                    // and one of them was wrong: the note was saved, or
                                    // there was no note but the summary is safely stored
                                    // anyway, or genuinely nothing was kept.
                                    final saved = note.isNotEmpty || _summaryPersisted;
                                    final message = note.isNotEmpty
                                        ? 'Reflection saved!'
                                        : _summaryPersisted
                                            ? 'Summary saved to your history.'
                                            : 'Nothing to save yet.';

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(message),
                                        backgroundColor:
                                            saved ? Colors.green : Colors.orange,
                                      ),
                                    );

                                    Future.delayed(const Duration(seconds: 1), () {
                                      if (mounted) context.go(AppRoutespath.homeScreen);
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3F3CD6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                  ),
                                  child: Text(
                                    'Save reflection',
                                    style: TextStyle(
                                      color: const Color(0xFFFFFDF7),
                                      fontSize: 20,
                                      fontFamily: 'Work Sans',
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // Emotions detected across this call (5-category split from the summary GPT pass over the
  // whole transcript). Hidden when there's no data. Sorted most-present first.
  /// "Words you circled around" — the user's own words, handed back.
  ///
  /// Renders nothing when the list is empty. A short call genuinely has no
  /// pattern, and an empty state here would either lie or draw attention to a
  /// gap; the onboarding preview already set the expectation, so silence is the
  /// honest option.
  Widget _buildWordsCircledSection() {
    final words = _summary?.wordsCircled ?? const <String>[];
    if (words.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: ShapeDecoration(
          color: const Color(0xFFFFFCF1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Words you circled around',
              style: GoogleFonts.workSans(
                color: const Color(0xFF4C586E),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final word in words)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFE6F0FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      '“$word”',
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF011F54),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionsSection() {
    final emotions = _summary?.topEmotions ?? const <String, double>{};
    final entries = emotions.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return const SizedBox.shrink();

    const labels = {
      'happy': 'Happy', 'motivated': 'Motivated', 'angry': 'Angry',
      'tired': 'Tired', 'sad': 'Sad',
    };
    const colors = {
      'happy': Color(0xFF3BB64B), 'motivated': Color(0xFF4542EB), 'angry': Color(0xFFE5484D),
      'tired': Color(0xFF8B7DF6), 'sad': Color(0xFF3E7BFA),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCB9B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emotions in this chat',
            style: TextStyle(
              color: const Color(0xFF011F54),
              fontSize: 18,
              fontFamily: 'Work Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...entries.map((e) {
            final c = colors[e.key] ?? const Color(0xFF4542EB);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        labels[e.key] ?? e.key,
                        style: TextStyle(
                          color: const Color(0xFF011F54),
                          fontSize: 14,
                          fontFamily: 'Work Sans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${e.value.round()}%',
                        style: TextStyle(
                          color: c,
                          fontSize: 14,
                          fontFamily: 'Work Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: (e.value / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: const Color(0xFFFAE3CE),
                      valueColor: AlwaysStoppedAnimation<Color>(c),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Map the call's dominant emotion (happy/motivated/angry/tired/sad) to a face/icon shown
  // on the summary avatar. Unknown/empty → a warm neutral face.
  IconData _emotionIcon(String? emotion) {
    switch ((emotion ?? '').toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'motivated':
        return Icons.local_fire_department;
      case 'angry':
        return Icons.sentiment_very_dissatisfied;
      case 'tired':
        return Icons.bedtime;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.sentiment_satisfied;
    }
  }

  // Avatar background colour per emotion — matches the bars in "Emotions in this chat".
  Color _emotionColor(String? emotion) {
    switch ((emotion ?? '').toLowerCase()) {
      case 'happy':
        return const Color(0xFF3BB64B);
      case 'motivated':
        return const Color(0xFF4542EB);
      case 'angry':
        return const Color(0xFFE5484D);
      case 'tired':
        return const Color(0xFF8B7DF6);
      case 'sad':
        return const Color(0xFF3E7BFA);
      default:
        return const Color(0xFF4542EB);
    }
  }

  Widget _buildInsightCard({
    required String title,
    required String description,
    required Color backgroundColor,
    required IconData icon,
    /// An SVG to draw instead of [icon]. Used by "Mood detected", whose face changes
    /// with the mood; [icon] stays the fallback for a mood nothing recognised.
    String? iconAsset,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: iconAsset != null
                ? Padding(
                    // The faces are drawn to the edge of their own 64 box, so they need
                    // a little breathing room inside the 50 circle; a Material glyph
                    // carries its own padding and does not.
                    padding: const EdgeInsets.all(9),
                    child: SvgPicture.asset(iconAsset),
                  )
                : Icon(
                    icon,
                    color: const Color(0xFF4542EB),
                    size: 24,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF011F54),
                    fontSize: 18,
                    fontFamily: 'Work Sans',
                    fontWeight: FontWeight.w900,
                    height: 0.8,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: TextStyle(
                    color: const Color(0xFF011F54),
                    fontSize: 16,
                    fontFamily: 'Work Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
