import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';

/// Enum representing each screen in the flow
enum FlowScreen {
  swipeToTalkLoading,
  poupYourShareYou,
  poupSpking,
  poupProssing,
  aiVoice,
  poupError,
}

/// Configuration for the screen flow
class ScreenFlowConfig {
  /// Duration each screen stays visible before transitioning
  final Duration screenDuration;
  
  /// Whether to loop back to first screen after completing the flow
  final bool loopEnabled;
  
  /// Optional callback when flow completes
  final VoidCallback? onFlowComplete;

  const ScreenFlowConfig({
    this.screenDuration = const Duration(seconds: 3),
    this.loopEnabled = false,
    this.onFlowComplete,
  });
}

/// Controller for managing automatic screen flow navigation
/// 
/// Usage:
/// 1. Create an instance in your screen's initState
/// 2. Call startAutoNavigation() to begin the flow
/// 3. Call dispose() in your screen's dispose method
class ScreenFlowController {
  final BuildContext context;
  final FlowScreen currentScreen;
  final ScreenFlowConfig config;
  
  Timer? _navigationTimer;
  bool _isDisposed = false;

  ScreenFlowController({
    required this.context,
    required this.currentScreen,
    this.config = const ScreenFlowConfig(),
  });

  /// The ordered sequence of screens in the flow
  static const List<FlowScreen> _flowSequence = [
    FlowScreen.swipeToTalkLoading,
    FlowScreen.poupYourShareYou,
    FlowScreen.poupSpking,
    FlowScreen.poupProssing,
    FlowScreen.aiVoice,
    FlowScreen.poupError,
  ];

  /// Maps FlowScreen enum to route paths
  static String _getRoutePath(FlowScreen screen) {
    switch (screen) {
      case FlowScreen.swipeToTalkLoading:
        return AppRoutespath.swipeToTalkLoading;
      case FlowScreen.poupYourShareYou:
        return AppRoutespath.poupYourShareYou;
      case FlowScreen.poupSpking:
        return AppRoutespath.poupSpking;
      case FlowScreen.poupProssing:
        return AppRoutespath.poupProssing;
      case FlowScreen.aiVoice:
        return AppRoutespath.aiVoice;
      case FlowScreen.poupError:
        return AppRoutespath.poupError;
    }
  }

  /// Gets the next screen in the flow sequence
  FlowScreen? get nextScreen {
    final currentIndex = _flowSequence.indexOf(currentScreen);
    if (currentIndex == -1) return null;
    
    final nextIndex = currentIndex + 1;
    if (nextIndex >= _flowSequence.length) {
      return config.loopEnabled ? _flowSequence.first : null;
    }
    return _flowSequence[nextIndex];
  }

  /// Checks if this is the last screen in the flow
  bool get isLastScreen {
    return _flowSequence.indexOf(currentScreen) == _flowSequence.length - 1;
  }

  /// Starts the automatic navigation timer
  /// Navigates to the next screen after the configured duration
  void startAutoNavigation() {
    if (_isDisposed) return;
    
    _navigationTimer = Timer(config.screenDuration, () {
      if (_isDisposed) return;
      _navigateToNextScreen();
    });
  }

  /// Manually navigate to the next screen
  void navigateToNext() {
    if (_isDisposed) return;
    _cancelTimer();
    _navigateToNextScreen();
  }

  /// Skip to a specific screen in the flow
  void skipToScreen(FlowScreen screen) {
    if (_isDisposed) return;
    _cancelTimer();
    
    if (context.mounted) {
      context.go(_getRoutePath(screen));
    }
  }

  /// Cancel the current navigation timer
  void cancelNavigation() {
    _cancelTimer();
  }

  /// Restart the navigation timer
  void restartNavigation() {
    _cancelTimer();
    startAutoNavigation();
  }

  void _navigateToNextScreen() {
    if (!context.mounted || _isDisposed) return;
    
    final next = nextScreen;
    if (next != null) {
      context.go(_getRoutePath(next));
    } else {
      // Flow completed
      config.onFlowComplete?.call();
    }
  }

  void _cancelTimer() {
    _navigationTimer?.cancel();
    _navigationTimer = null;
  }

  /// Dispose the controller and cancel any pending timers
  void dispose() {
    _isDisposed = true;
    _cancelTimer();
  }
}

/// Mixin to easily add screen flow functionality to StatefulWidgets
/// 
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with ScreenFlowMixin {
///   @override
///   FlowScreen get flowScreen => FlowScreen.poupSpking;
///   
///   @override
///   void initState() {
///     super.initState();
///     initializeFlow(context); // Call after super.initState()
///   }
/// }
/// ```
mixin ScreenFlowMixin<T extends StatefulWidget> on State<T> {
  ScreenFlowController? _flowController;
  
  /// Override this to specify which screen this widget represents
  FlowScreen get flowScreen;
  
  /// Override to customize flow configuration
  ScreenFlowConfig get flowConfig => const ScreenFlowConfig();
  
  /// Called when the flow completes (on the last screen)
  void onFlowComplete() {}
  
  /// Initialize the flow controller and start auto navigation
  /// Call this in initState() after super.initState()
  void initializeFlow(BuildContext context) {
    // Use addPostFrameCallback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _flowController = ScreenFlowController(
          context: context,
          currentScreen: flowScreen,
          config: ScreenFlowConfig(
            screenDuration: flowConfig.screenDuration,
            loopEnabled: flowConfig.loopEnabled,
            onFlowComplete: onFlowComplete,
          ),
        );
        _flowController!.startAutoNavigation();
      }
    });
  }
  
  /// Get the flow controller for manual control
  ScreenFlowController? get flowController => _flowController;
  
  /// Skip to next screen manually
  void skipToNextScreen() {
    _flowController?.navigateToNext();
  }
  
  /// Cancel automatic navigation
  void cancelAutoNavigation() {
    _flowController?.cancelNavigation();
  }
  
  @override
  void dispose() {
    _flowController?.dispose();
    super.dispose();
  }
}
