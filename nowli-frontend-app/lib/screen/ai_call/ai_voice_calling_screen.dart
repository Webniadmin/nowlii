import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AiVoiceCallingScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final Duration totalDuration;

  const AiVoiceCallingScreen({
    super.key,
    this.title = 'Answer emails',
    this.subtitle = "You're doing great – keep it going",
    this.totalDuration = const Duration(minutes: 10),
  });

  @override
  State<AiVoiceCallingScreen> createState() => _AiVoiceCallingScreenState();
}

class _AiVoiceCallingScreenState extends State<AiVoiceCallingScreen>
    with TickerProviderStateMixin {
  // Timer management
  late Duration _totalDuration;
  late Duration _remainingTime;
  Timer? _timer;
  bool _isPaused = false;
  bool _isMuted = false;
  
  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _pulseController;
  
  // State flags
  bool _showTimeWarning = false;
  bool _showMuteWarning = false;
  bool _showNetworkError = false;
  bool _showWrapUpDialog = false;
  bool _questCompleted = false;
  
  // Typing animation
  bool _showTypingAnimation = false;
  String _typedText = '';
  Timer? _typingTimer;
  int _typingIndex = 0;
  final String _typingMessage = "You're doing great – keep it going";

  @override
  void initState() {
    super.initState();
    _totalDuration = widget.totalDuration;
    _remainingTime = _totalDuration;
    
    // Progress animation
    _progressController = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );
    
    // Pulse animation for avatar
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _startCall();
  }

  void _startCall() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
            
            // Update progress
            final elapsed = _totalDuration.inSeconds - _remainingTime.inSeconds;
            _progressController.value = elapsed / _totalDuration.inSeconds;
            
            // Check for 5 minute mark to show typing animation
            if (elapsed == 300 && !_showTypingAnimation) {
              _startTypingAnimation();
            }
            
            // Check for 8 minute mark (2 minutes remaining in 10 min call)
            final minutesRemaining = _remainingTime.inMinutes;
            if (minutesRemaining == 2 && !_showTimeWarning) {
              _showTimeWarning = true;
            }
            
            // Quest completed
            if (_remainingTime.inSeconds == 0) {
              _onQuestComplete();
            }
          }
        });
      }
    });
  }

  void _startTypingAnimation() {
    setState(() {
      _showTypingAnimation = true;
      _typedText = '';
      _typingIndex = 0;
    });
    
    _typingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_typingIndex < _typingMessage.length) {
        setState(() {
          _typedText = _typingMessage.substring(0, _typingIndex + 1);
          _typingIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_isMuted) {
        _showMuteWarning = true;
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showMuteWarning = false;
            });
          }
        });
      }
    });
  }

  void _addTenMinutes() {
    setState(() {
      _totalDuration = Duration(minutes: _totalDuration.inMinutes + 10);
      _remainingTime = Duration(seconds: _remainingTime.inSeconds + 600);
      _showTimeWarning = false;
      
      // Show success message
      _showSnackBar('10 more minutes added\nYou can now talk to me 10 more minutes!');
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4542EB),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onQuestComplete() {
    setState(() {
      _questCompleted = true;
    });
    _timer?.cancel();
    
    // Navigate to summary after showing completion
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Navigate to call summary screen
        context.go('/callSummary');
      }
    });
  }

  void _markAsDone() {
    _showWrapUpDialog = true;
    setState(() {});
  }

  void _onWrapUpYes() {
    _timer?.cancel();
    _onQuestComplete();
  }

  void _onWrapUpContinue() {
    setState(() {
      _showWrapUpDialog = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _typingTimer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  Color get _backgroundColor {
    if (_questCompleted) return const Color(0xFFCCFFAA);
    if (_showTimeWarning) return const Color(0xFFFF8F26);
    return const Color(0xFF91BBF9);
  }

  Color get _timerColor {
    if (_questCompleted) return const Color(0xFF3BB64B);
    if (_showTimeWarning) return const Color(0xFFFF8F26);
    return const Color(0xFF4542EB);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                const SizedBox(height: 54),
                
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 75),
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF011F54),
                      fontSize: 32,
                      fontFamily: 'Work Sans',
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                
                const SizedBox(height: 23),
                
                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _questCompleted 
                        ? 'Take a deep breath - you did great.\nI\'ll be here when you\'re ready for the next one.'
                        : _showTypingAnimation 
                            ? _typedText
                            : widget.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF011F54),
                      fontSize: 18,
                      fontFamily: 'Work Sans',
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Avatar with progress ring
                _buildAvatarWithProgress(size),
                
                const Spacer(),
                
                // Quest completed text
                if (_questCompleted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Text(
                      'QUEST\nCOMPLETED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF3BB64B),
                        fontSize: 52,
                        fontFamily: 'Wosker',
                        fontWeight: FontWeight.w400,
                        height: 0.8,
                      ),
                    ),
                  ),
                
                // Timer and controls
                if (!_questCompleted) ...[
                  _buildTimer(),
                  const SizedBox(height: 20),
                  _buildControls(),
                ],
                
                const SizedBox(height: 40),
              ],
            ),
            
            // Time warning popup
            if (_showTimeWarning && !_questCompleted)
              _buildTimeWarningPopup(),
            
            // Mute warning
            if (_showMuteWarning)
              _buildMuteWarning(),
            
            // Network error
            if (_showNetworkError)
              _buildNetworkError(),
            
            // Wrap up dialog
            if (_showWrapUpDialog)
              _buildWrapUpDialog(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWithProgress(Size size) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse circles
            if (!_questCompleted) ...[
              Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.98,
                    colors: [
                      _timerColor.withOpacity(0),
                      _timerColor.withOpacity(0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ],
            
            // Progress ring
            SizedBox(
              width: size.width * 0.65,
              height: size.width * 0.65,
              child: CircularProgressIndicator(
                value: _progressController.value,
                strokeWidth: 16,
                backgroundColor: _timerColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(_timerColor),
              ),
            ),
            
            // Inner gradient circle
            Container(
              width: size.width * 0.48,
              height: size.width * 0.48,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.73,
                  colors: _questCompleted
                      ? [const Color(0xFF3BB64B), const Color(0xFF3BB64B)]
                      : [const Color(0xFF7270F3), const Color(0xFF3F3CD6)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _timerColor.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 11,
                  ),
                ],
              ),
            ),
            
            // Avatar
            Container(
              width: size.width * 0.35,
              height: size.width * 0.35,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage("https://placehold.co/131x129"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pause/Play button
          Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              color: const Color(0xFFC3DBFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: IconButton(
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                size: 20,
                color: const Color(0xFF4542EB),
              ),
              onPressed: _togglePause,
              padding: EdgeInsets.zero,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Timer display
          Row(
            children: [
              Text(
                _formatDuration(Duration(seconds: _totalDuration.inSeconds - _remainingTime.inSeconds)),
                style: TextStyle(
                  color: _timerColor,
                  fontSize: 52,
                  fontFamily: 'Wosker',
                  fontWeight: FontWeight.w400,
                  height: 0.8,
                ),
              ),
              Text(
                ' / ',
                style: TextStyle(
                  color: _timerColor.withOpacity(0.5),
                  fontSize: 52,
                  fontFamily: 'Wosker',
                  fontWeight: FontWeight.w400,
                  height: 0.8,
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: TextStyle(
                  color: _timerColor.withOpacity(0.5),
                  fontSize: 52,
                  fontFamily: 'Wosker',
                  fontWeight: FontWeight.w400,
                  height: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Mute button
              _buildControlButton(
                icon: _isMuted ? Icons.mic_off : Icons.mic,
                onTap: _toggleMute,
              ),
              const SizedBox(width: 8),
              // Volume button
              _buildControlButton(
                icon: Icons.volume_up,
                onTap: () {},
              ),
            ],
          ),
          
          // Mark as done
          Column(
            children: [
              _buildControlButton(
                icon: Icons.check,
                onTap: _markAsDone,
              ),
              const SizedBox(height: 12),
              Text(
                'Mark as done',
                style: TextStyle(
                  color: const Color(0xFF011F54),
                  fontSize: 12,
                  fontFamily: 'Work Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 64,
      height: 64,
      decoration: ShapeDecoration(
        color: const Color(0xFFC3DBFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 24, color: const Color(0xFF4542EB)),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildTimeWarningPopup() {
    return Positioned(
      top: 54,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: ShapeDecoration(
          color: const Color(0xFFFFFCF1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: [
            BoxShadow(
              color: Color(0x070A0C12),
              blurRadius: 6,
              offset: Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Call ending soon!',
              style: TextStyle(
                color: const Color(0xFF011F54),
                fontSize: 20,
                fontFamily: 'Work Sans',
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can add 10 more minutes to your call!',
              style: TextStyle(
                color: const Color(0xFF595754),
                fontSize: 14,
                fontFamily: 'Work Sans',
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addTenMinutes,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8F26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: const Color(0xFF011F54)),
                  const SizedBox(width: 8),
                  Text(
                    'Add 10 minutes',
                    style: TextStyle(
                      color: const Color(0xFF011F54),
                      fontSize: 18,
                      fontFamily: 'Work Sans',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuteWarning() {
    return Positioned(
      top: 54,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: const Color(0xFFFFFCF1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.mic_off, color: const Color(0xFF011F54)),
            const SizedBox(width: 12),
            Text(
              'You\'re muted',
              style: TextStyle(
                color: const Color(0xFF011F54),
                fontSize: 18,
                fontFamily: 'Work Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkError() {
    return Positioned(
      top: 54,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: const Color(0xFFFFE5E5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: const Color(0xFFFF0000)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network error',
                    style: TextStyle(
                      color: const Color(0xFF011F54),
                      fontSize: 18,
                      fontFamily: 'Work Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Please check your internet connection!',
                    style: TextStyle(
                      color: const Color(0xFF011F54),
                      fontSize: 14,
                      fontFamily: 'Work Sans',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrapUpDialog() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 50, color: const Color(0xFF4542EB)),
                const SizedBox(height: 16),
                Text(
                  'Wrap up already?',
                  style: TextStyle(
                    color: const Color(0xFF011F54),
                    fontSize: 24,
                    fontFamily: 'Work Sans',
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No rush — but if you\'re done, let\'s mark this quest complete.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF595754),
                    fontSize: 16,
                    fontFamily: 'Work Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _onWrapUpContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: const Color(0xFF4542EB), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: Text(
                    'Continue a bit longer',
                    style: TextStyle(
                      color: const Color(0xFF4542EB),
                      fontSize: 18,
                      fontFamily: 'Work Sans',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _onWrapUpYes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4542EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: Text(
                    'Yes, I\'m done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Work Sans',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
