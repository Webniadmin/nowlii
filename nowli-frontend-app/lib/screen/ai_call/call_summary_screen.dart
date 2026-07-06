import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/services/call_summary_service.dart';
import 'package:nowlii/models/call_summary_model.dart';

class CallSummaryScreen extends StatefulWidget {
  final String? sessionId;
  
  const CallSummaryScreen({
    super.key,
    this.sessionId,
  });

  @override
  State<CallSummaryScreen> createState() => _CallSummaryScreenState();
}

class _CallSummaryScreenState extends State<CallSummaryScreen> {
  final CallSummaryService _summaryService = CallSummaryService();
  final TextEditingController _noteController = TextEditingController();
  
  CallSummaryResponse? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    if (widget.sessionId == null || widget.sessionId!.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No session ID provided';
      });
      return;
    }

    try {
      final summary = await _summaryService.getSummary(widget.sessionId!);
      
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
          if (summary == null) {
            _errorMessage = 'Could not load summary. Please try again.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading summary: $e';
        });
      }
    }
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
                          
                          // Avatar
                          Container(
                            width: 100,
                            height: 100,
                            decoration: ShapeDecoration(
                              color: const Color(0xFF4542EB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.check_circle,
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
                            description: _summary?.moodDetected ?? 'You sounded calm and optimistic',
                            backgroundColor: const Color(0xFFFAE3CE),
                            icon: Icons.mood,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          _buildInsightCard(
                            title: 'Focus topic',
                            description: _summary?.focusTopic ?? 'You talked about staying consistent.',
                            backgroundColor: const Color(0xFFDFEFFF),
                            icon: Icons.book,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          _buildInsightCard(
                            title: 'Energy shift',
                            description: _summary?.energyShift ?? 'You started tired but ended excited',
                            backgroundColor: const Color(0xFFDFEFFF),
                            icon: Icons.bolt,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          _buildInsightCard(
                            title: 'Next step',
                            description: _summary?.nextStep ?? 'Plan your next quest!',
                            backgroundColor: const Color(0xFFDFEFFF),
                            icon: Icons.trending_up,
                          ),
                          
                          const SizedBox(height: 32),
                          
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
                                  onPressed: () {
                                    // Save reflection logic
                                    final note = _noteController.text.trim();
                                    if (note.isNotEmpty) {
                                      print('💾 Saving note: $note');
                                      // TODO: Save to backend or local storage
                                    }
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Reflection saved!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    
                                    Future.delayed(Duration(seconds: 1), () {
                                      context.go(AppRoutespath.homeScreen);
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

  Widget _buildInsightCard({
    required String title,
    required String description,
    required Color backgroundColor,
    required IconData icon,
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
            child: Icon(
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
