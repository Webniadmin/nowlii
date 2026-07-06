// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class CompletionDialog extends StatelessWidget {
//   const CompletionDialog({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Material(
//         color: Colors.transparent,
//         child: Container(
//           width: 335,
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//           decoration: ShapeDecoration(
//             color: const Color(0xFFCFFFC9),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             shadows: const [
//               BoxShadow(
//                 color: Color(0x070A0C12),
//                 blurRadius: 6,
//                 offset: Offset(0, 4),
//                 spreadRadius: -2,
//               ),
//               BoxShadow(
//                 color: Color(0x140A0C12),
//                 blurRadius: 16,
//                 offset: Offset(0, 12),
//                 spreadRadius: -4,
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             mainAxisAlignment: MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: ShapeDecoration(
//                   color: const Color(0xFFA0E871),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                 ),
//                 child: const Icon(
//                   Icons.check_circle,
//                   color: Color(0xFF011F54),
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Expanded(
//                           child: Text(
//                             'Boom, your first task completed!',
//                             style: TextStyle(
//                               color: Color(0xFF011F54),
//                               fontSize: 20,
//                               fontFamily: 'Work Sans',
//                               fontWeight: FontWeight.w800,
//                               height: 1.20,
//                               letterSpacing: -0.50,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: ShapeDecoration(
//                             color: const Color(0xFFFFFDF7),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(999),
//                             ),
//                           ),
//                           child: const Text(
//                             '+1 streak',
//                             style: TextStyle(
//                               color: Color(0xFF011F54),
//                               fontSize: 12,
//                               fontFamily: 'Work Sans',
//                               fontWeight: FontWeight.w600,
//                               height: 1,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// enum NotificationType { error, questSuggestion, defaultYellow, success }

// // ============================================
// // NOTIFICATION DATA MODEL
// // ============================================
// class NotificationData {
//   final NotificationType type;
//   final String title;
//   final String? subtitle;
//   final String? buttonText;
//   final VoidCallback? onButtonPressed;
//   final IconData? icon;
//   final Duration displayDuration;

//   NotificationData({
//     required this.type,
//     required this.title,
//     this.subtitle,
//     this.buttonText,
//     this.onButtonPressed,
//     this.icon,
//     this.displayDuration = const Duration(seconds: 5),
//   });
// }

// // ============================================
// // NOTIFICATION MANAGER (Singleton)
// // ============================================
// class NotificationManager {
//   static final NotificationManager _instance = NotificationManager._internal();
//   factory NotificationManager() => _instance;
//   NotificationManager._internal();

//   final List<NotificationData> _queue = [];
//   bool _isShowing = false;

//   void show(BuildContext context, NotificationData notification) {
//     _queue.add(notification);
//     if (!_isShowing) {
//       _showNext(context);
//     }
//   }

//   void _showNext(BuildContext context) {
//     if (_queue.isEmpty) {
//       _isShowing = false;
//       return;
//     }

//     _isShowing = true;
//     final notification = _queue.removeAt(0);

//     final overlay = Overlay.of(context);
//     late OverlayEntry overlayEntry;

//     overlayEntry = OverlayEntry(
//       builder: (context) => Positioned(
//         top: 15 + MediaQuery.of(context).padding.top,
//         left: 10,
//         right: 10,
//         child: Material(
//           color: Colors.transparent,
//           child: TweenAnimationBuilder<double>(
//             tween: Tween(begin: 0.0, end: 1.0),
//             duration: const Duration(milliseconds: 400),
//             curve: Curves.easeOutBack,
//             builder: (context, value, child) {
//               return Transform.translate(
//                 offset: Offset(0, -80 * (1 - value)),
//                 child: Opacity(opacity: value, child: child),
//               );
//             },
//             child: AICallNotification(notification: notification),
//           ),
//         ),
//       ),
//     );

//     overlay.insert(overlayEntry);

//     // Auto-dismiss and show next
//     Future.delayed(notification.displayDuration, () {
//       if (overlayEntry.mounted) {
//         overlayEntry.remove();
//       }
//       _showNext(context);
//     });
//   }

//   void clear() {
//     _queue.clear();
//     _isShowing = false;
//   }
// }

// // ============================================
// // AI CALL NOTIFICATION WIDGET
// // ============================================
// class AICallNotification extends StatelessWidget {
//   final NotificationData notification;

//   const AICallNotification({super.key, required this.notification});

//   @override
//   Widget build(BuildContext context) {
//     final config = _getNotificationConfig(notification.type);

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//       decoration: ShapeDecoration(
//         color: config.backgroundColor,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         shadows: const [
//           BoxShadow(
//             color: Color(0x070A0C12),
//             blurRadius: 6,
//             offset: Offset(0, 4),
//             spreadRadius: -2,
//           ),
//           BoxShadow(
//             color: Color(0x140A0C12),
//             blurRadius: 16,
//             offset: Offset(0, 12),
//             spreadRadius: -4,
//           ),
//         ],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Icon Container
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: ShapeDecoration(
//               color: config.iconBackgroundColor,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(6),
//               ),
//             ),
//             child: Icon(
//               notification.icon ?? config.defaultIcon,
//               color: config.iconColor,
//               size: 24,
//             ),
//           ),
//           const SizedBox(width: 10),

//           // Content
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Title
//                 Text(
//                   notification.title,
//                   style: GoogleFonts.workSans(
//                     color: const Color(0xFF011F54),
//                     fontSize: 20,
//                     fontWeight: FontWeight.w800,
//                     height: 1.20,
//                     letterSpacing: -0.50,
//                   ),
//                 ),

//                 // Subtitle
//                 if (notification.subtitle != null) ...[
//                   const SizedBox(height: 8),
//                   Text(
//                     notification.subtitle!,
//                     style: GoogleFonts.workSans(
//                       color: const Color(0xFF595754),
//                       fontSize: 14,
//                       fontWeight: FontWeight.w400,
//                       height: 1.60,
//                     ),
//                   ),
//                 ],

//                 // Button
//                 if (notification.buttonText != null) ...[
//                   const SizedBox(height: 16),
//                   GestureDetector(
//                     onTap: notification.onButtonPressed,
//                     child: Container(
//                       width: double.infinity,
//                       height: 44,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 40,
//                         vertical: 14,
//                       ),
//                       decoration: ShapeDecoration(
//                         color: config.buttonColor,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(999),
//                         ),
//                       ),
//                       child: Center(
//                         child: Text(
//                           notification.buttonText!,
//                           textAlign: TextAlign.center,
//                           style: GoogleFonts.workSans(
//                             color: config.buttonTextColor,
//                             fontSize: 18,
//                             fontWeight: FontWeight.w900,
//                             height: 0.80,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   _NotificationConfig _getNotificationConfig(NotificationType type) {
//     switch (type) {
//       case NotificationType.error:
//         return _NotificationConfig(
//           backgroundColor: const Color(0xFFFDDBDC),
//           iconBackgroundColor: const Color(0xFFD53D40),
//           iconColor: Colors.white,
//           buttonColor: const Color(0xFFD53D3F),
//           buttonTextColor: const Color(0xFFFFFDF7),
//           defaultIcon: Icons.error_outline,
//         );
//       case NotificationType.questSuggestion:
//         return _NotificationConfig(
//           backgroundColor: const Color(0xFF3D87F5),
//           iconBackgroundColor: const Color(0xFF3F3CD6),
//           iconColor: Colors.white,
//           buttonColor: const Color(0xFF4542EB),
//           buttonTextColor: const Color(0xFFFFFDF7),
//           defaultIcon: Icons.lightbulb_outline,
//         );
//       case NotificationType.defaultYellow:
//         return _NotificationConfig(
//           backgroundColor: const Color(0xFFFFCE73),
//           iconBackgroundColor: const Color(0xFFFF8F26),
//           iconColor: Colors.white,
//           buttonColor: const Color(0xFFFF8F26),
//           buttonTextColor: const Color(0xFF011F54),
//           defaultIcon: Icons.notifications_outlined,
//         );
//       case NotificationType.success:
//         return _NotificationConfig(
//           backgroundColor: const Color(0xFFCFFFC9),
//           iconBackgroundColor: const Color(0xFFA0E871),
//           iconColor: Colors.white,
//           buttonColor: const Color(0xFFA0E871),
//           buttonTextColor: const Color(0xFF011F54),
//           defaultIcon: Icons.check_circle_outline,
//         );
//     }
//   }
// }

// // ============================================
// // NOTIFICATION CONFIG
// // ============================================
// class _NotificationConfig {
//   final Color backgroundColor;
//   final Color iconBackgroundColor;
//   final Color iconColor;
//   final Color buttonColor;
//   final Color buttonTextColor;
//   final IconData defaultIcon;

//   _NotificationConfig({
//     required this.backgroundColor,
//     required this.iconBackgroundColor,
//     required this.iconColor,
//     required this.buttonColor,
//     required this.buttonTextColor,
//     required this.defaultIcon,
//   });
// }

// // ============================================
// // EXAMPLE USAGE IN HOME SCREEN
// // ============================================
// class NotificationExampleScreen extends StatelessWidget {
//   const NotificationExampleScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('AI Call Notifications')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Error Notification Example
//             ElevatedButton(
//               onPressed: () {
//                 NotificationManager().show(
//                   context,
//                   NotificationData(
//                     type: NotificationType.error,
//                     title: 'You missed our talk, that\'s okay',
//                     subtitle: 'I\'m here when you\'re ready',
//                     buttonText: 'Add another quest',
//                     onButtonPressed: () {
//                       debugPrint('Add another quest pressed');
//                     },
//                   ),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFFD53D40),
//               ),
//               child: const Text('Show Error Notification'),
//             ),
//             const SizedBox(height: 16),

//             // Quest Suggestion Notification Example
//             ElevatedButton(
//               onPressed: () {
//                 NotificationManager().show(
//                   context,
//                   NotificationData(
//                     type: NotificationType.questSuggestion,
//                     title: 'Wake up or wind down with Nowlli! 😴🌞',
//                     subtitle:
//                         'You can schedule Nowlli for wake-up or bedtime calls! Just create a task, turn on repeat, and Nowlli will call you 10 minutes before — to help you wake up or drift off peacefully. 💕',
//                     buttonText: 'Add quest',
//                     onButtonPressed: () {
//                       debugPrint('Add quest pressed');
//                     },
//                   ),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF3F3CD6),
//               ),
//               child: const Text('Show Quest Suggestion'),
//             ),
//             const SizedBox(height: 16),

//             // Default Yellow Notification Example
//             ElevatedButton(
//               onPressed: () {
//                 NotificationManager().show(
//                   context,
//                   NotificationData(
//                     type: NotificationType.defaultYellow,
//                     title:
//                         'Quest starts soon! Wanna share how u feel before we dive in?',
//                     subtitle:
//                         'Send a voice note to your bestie- me! Tell me what\'s on your mind, or how you\'re feeling before the session.',
//                     buttonText: 'Send a quick note',
//                     onButtonPressed: () {
//                       debugPrint('Send a quick note pressed');
//                     },
//                   ),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFFFF8F26),
//               ),
//               child: const Text('Show Default Notification'),
//             ),
//             const SizedBox(height: 16),

//             // Success Notification Example
//             ElevatedButton(
//               onPressed: () {
//                 NotificationManager().show(
//                   context,
//                   NotificationData(
//                     type: NotificationType.success,
//                     title: 'Fuzzy\'s proud of you',
//                     subtitle: 'One chat at a time, you\'re getting stronger',
//                     buttonText: 'See progress',
//                     onButtonPressed: () {
//                       debugPrint('See progress pressed');
//                     },
//                   ),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFFA0E871),
//               ),
//               child: const Text('Show Success Notification'),
//             ),
//             const SizedBox(height: 32),

//             // Show Multiple Notifications (Queue)
//             ElevatedButton(
//               onPressed: () {
//                 // Show multiple notifications in sequence
//                 NotificationManager().show(
//                   context,
//                   NotificationData(
//                     type: NotificationType.success,
//                     title: 'First notification',
//                     displayDuration: const Duration(seconds: 3),
//                   ),
//                 );
//                 NotificationManager().show(
//                   context,
//                   NotificationData(
//                     type: NotificationType.defaultYellow,
//                     title: 'Second notification',
//                     displayDuration: const Duration(seconds: 3),
//                   ),
//                 );
//                 NotificationManager().show(
//                   context,
//                   NotificationData(
//                     type: NotificationType.questSuggestion,
//                     title: 'Third notification',
//                     displayDuration: const Duration(seconds: 3),
//                   ),
//                 );
//               },
//               child: const Text('Show Multiple Notifications'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
