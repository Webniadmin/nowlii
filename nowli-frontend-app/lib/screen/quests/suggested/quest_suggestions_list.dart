import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/models/quest_suggestion_model.dart';
import 'package:nowlii/services/quest_suggestion_service.dart';

class QuestSuggestionsList extends StatefulWidget {
  const QuestSuggestionsList({super.key});

  @override
  State<QuestSuggestionsList> createState() => _QuestSuggestionsListState();
}

class _QuestSuggestionsListState extends State<QuestSuggestionsList> {
  final QuestSuggestionService _service = QuestSuggestionService();
  QuestSuggestionResponse? _suggestions;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final suggestions = await _service.getQuestSuggestions();
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final baseScale = width / 390.0;

    return Scaffold(
      backgroundColor: const Color(0xFF89B6F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(baseScale),
            
            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _error != null
                      ? _buildError()
                      : _buildSuggestionsList(baseScale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double s) {
    return Padding(
      padding: EdgeInsets.all(16.0 * s),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40 * s,
              height: 40 * s,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back,
                color: const Color(0xFF011F54),
                size: 24 * s,
              ),
            ),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quest Suggestions',
                  style: GoogleFonts.workSans(
                    fontSize: 24 * s,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF011F54),
                  ),
                ),
                if (_suggestions != null)
                  Text(
                    '${_suggestions!.weekly.questsCompleted}/${_suggestions!.weekly.totalQuests} completed this week',
                    style: GoogleFonts.workSans(
                      fontSize: 14 * s,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF011F54),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'Loading suggestions...',
            style: GoogleFonts.workSans(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Failed to load suggestions',
              style: GoogleFonts.workSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: GoogleFonts.workSans(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSuggestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4542EB),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(double s) {
    if (_suggestions == null || _suggestions!.weekly.questSuggestions.isEmpty) {
      return Center(
        child: Text(
          'No suggestions available',
          style: GoogleFonts.workSans(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 8 * s),
      itemCount: _suggestions!.weekly.questSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions!.weekly.questSuggestions[index];
        return _buildSuggestionCard(suggestion, s);
      },
    );
  }

  Widget _buildSuggestionCard(QuestSuggestion suggestion, double s) {
    return GestureDetector(
      onTap: () {
        // Navigate to suggestion detail with the suggestion data
        context.push('/suggestedTaskOverview', extra: suggestion);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12 * s),
        padding: EdgeInsets.all(16 * s),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEF8),
          borderRadius: BorderRadius.circular(16 * s),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone badge and time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 4 * s),
                  decoration: BoxDecoration(
                    color: _getZoneColor(suggestion.zone),
                    borderRadius: BorderRadius.circular(12 * s),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        suggestion.getZoneEmoji(),
                        style: TextStyle(fontSize: 14 * s),
                      ),
                      SizedBox(width: 4 * s),
                      Text(
                        suggestion.zone,
                        style: GoogleFonts.workSans(
                          fontSize: 12 * s,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF011F54),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16 * s,
                      color: const Color(0xFF4C586E),
                    ),
                    SizedBox(width: 4 * s),
                    Text(
                      suggestion.suggestedTime,
                      style: GoogleFonts.workSans(
                        fontSize: 14 * s,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4C586E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12 * s),
            
            // Task title
            Text(
              suggestion.task,
              style: GoogleFonts.workSans(
                fontSize: 20 * s,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF011F54),
              ),
            ),
            SizedBox(height: 8 * s),
            
            // Description
            Text(
              suggestion.description,
              style: GoogleFonts.workSans(
                fontSize: 14 * s,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF4C586E),
                height: 1.4,
              ),
            ),
            SizedBox(height: 12 * s),
            
            // Add button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 8 * s),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4542EB),
                    borderRadius: BorderRadius.circular(20 * s),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16 * s),
                      SizedBox(width: 4 * s),
                      Text(
                        'Add Quest',
                        style: GoogleFonts.workSans(
                          fontSize: 14 * s,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getZoneColor(String zone) {
    switch (zone.toLowerCase()) {
      case 'soft steps':
        return const Color(0xFFA0E871);
      case 'stretch zone':
        return const Color(0xFFFFB84D);
      case 'power move':
        return const Color(0xFFFF6B6B);
      case 'elevated':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFFA0E871);
    }
  }
}
