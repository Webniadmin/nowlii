import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/models/call_summary_history.dart';
import 'package:nowlii/services/voice_call_service.dart';

/// Shows the user's saved AI voice-call summaries, newest first, so they can look back over
/// past calls and see how they've been progressing. Reads GET /api/voice-calls/summaries/.
class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final VoiceCallService _voiceCallService = VoiceCallService();
  List<CallSummaryHistoryItem> _summaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final summaries = await _voiceCallService.getSummaries();
    if (mounted) {
      setState(() {
        _summaries = summaries;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDF7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF011F54)),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutespath.homeScreen),
        ),
        title: Text(
          'Call history',
          style: TextStyle(
            color: const Color(0xFF011F54),
            fontSize: 20,
            fontFamily: 'Work Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4542EB)))
            : _summaries.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _load,
                    color: const Color(0xFF4542EB),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      itemCount: _summaries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _buildCard(_summaries[i]),
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined,
                size: 64, color: const Color(0xFF4542EB).withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'No calls yet',
              style: TextStyle(
                color: const Color(0xFF011F54),
                fontSize: 20,
                fontFamily: 'Work Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your call summaries will show up here so you can look back on how you’ve been doing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF4C586E),
                fontSize: 15,
                fontFamily: 'Work Sans',
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(CallSummaryHistoryItem s) {
    final date = s.startedAt ?? s.createdAt;
    final dateLabel = date != null ? DateFormat('MMM d, y • h:mm a').format(date) : '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE3CE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _emotionColor(s.dominantEmotion),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_emotionIcon(s.dominantEmotion),
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: const Color(0xFF011F54),
                        fontSize: 14,
                        fontFamily: 'Work Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (s.durationSeconds > 0)
                      Text(
                        '${_fmtDuration(s.durationSeconds)}'
                        '${s.totalTurns > 0 ? ' • ${s.totalTurns} exchanges' : ''}',
                        style: TextStyle(
                          color: const Color(0xFF4C586E),
                          fontSize: 12,
                          fontFamily: 'Work Sans',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (s.moodDetected.isNotEmpty) ...[
            const SizedBox(height: 12),
            _row('Mood', s.moodDetected),
          ],
          if (s.focusTopic.isNotEmpty) ...[
            const SizedBox(height: 8),
            _row('Focus', s.focusTopic),
          ],
          if (s.energyShift.isNotEmpty) ...[
            const SizedBox(height: 8),
            _row('Energy', s.energyShift),
          ],
          if (s.nextStep.isNotEmpty) ...[
            const SizedBox(height: 8),
            _row('Next step', s.nextStep),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF4542EB),
            fontSize: 12,
            fontFamily: 'Work Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF011F54),
            fontSize: 14,
            fontFamily: 'Work Sans',
            height: 1.35,
          ),
        ),
      ],
    );
  }

  String _fmtDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  IconData _emotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
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

  Color _emotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
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
}
