// import 'package:flutter/material.dart';

// class AIInsightsScreen extends StatelessWidget {
//   const AIInsightsScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5E6D3),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.blue,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Icon(
//                       Icons.auto_awesome,
//                       color: Colors.white,
//                       size: 24,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   const Text(
//                     'Your AI insights',
//                     style: TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1A1A3E),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),

//               // Most completed quests card
//               _buildCard(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Most completed quests',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF1A1A3E),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     const Text(
//                       'These are the quests you tend to finish the most:',
//                       style: TextStyle(fontSize: 14, color: Color(0xFF1A1A3E)),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildQuestItem('Clean house'),
//                     const SizedBox(height: 12),
//                     _buildQuestItem('Walk a dog'),
//                     const SizedBox(height: 12),
//                     _buildQuestItem('Sleep'),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Most productive days/hours card
//               _buildCard(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Most productive days / hours',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF1A1A3E),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Container(
//                             padding: const EdgeInsets.all(20),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF5B5FFF),
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: const [
//                                 Text(
//                                   'Day',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Colors.white70,
//                                   ),
//                                 ),
//                                 SizedBox(height: 4),
//                                 Text(
//                                   'Sunday',
//                                   style: TextStyle(
//                                     fontSize: 28,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Container(
//                             padding: const EdgeInsets.all(20),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFD4E7FF),
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: const [
//                                 Text(
//                                   'Hour',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Color(0xFF5B5FFF),
//                                   ),
//                                 ),
//                                 SizedBox(height: 4),
//                                 Text(
//                                   '10:00',
//                                   style: TextStyle(
//                                     fontSize: 28,
//                                     fontWeight: FontWeight.bold,
//                                     color: Color(0xFF5B5FFF),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Preferred quest types card
//               _buildCard(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Preferred quest types',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF1A1A3E),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     const Text(
//                       'You complete more Soft Moves than Power Moves (72% vs 28%).',
//                       style: TextStyle(fontSize: 14, color: Color(0xFF1A1A3E)),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           flex: 72,
//                           child: Container(
//                             padding: const EdgeInsets.all(20),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFFFD4B3),
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: const [
//                                 Text(
//                                   'Soft moves',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Color(0xFF1A1A3E),
//                                   ),
//                                 ),
//                                 SizedBox(height: 4),
//                                 Text(
//                                   '78%',
//                                   style: TextStyle(
//                                     fontSize: 32,
//                                     fontWeight: FontWeight.bold,
//                                     color: Color(0xFF1A1A3E),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           flex: 28,
//                           child: Container(
//                             padding: const EdgeInsets.all(20),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFFFAA66),
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: const [
//                                 Text(
//                                   'Power moves',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Color(0xFF1A1A3E),
//                                   ),
//                                 ),
//                                 SizedBox(height: 4),
//                                 Text(
//                                   '22%',
//                                   style: TextStyle(
//                                     fontSize: 32,
//                                     fontWeight: FontWeight.bold,
//                                     color: Color(0xFF1A1A3E),
//                                   ),
//                                 ),
//                               ],
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

//   Widget _buildCard({required Widget child}) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }

//   Widget _buildQuestItem(String title) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFE9D4),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 28,
//             height: 28,
//             decoration: BoxDecoration(
//               color: const Color(0xFF5B5FFF),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: const Icon(Icons.check, color: Colors.white, size: 18),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1A1A3E),
//               ),
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFFD4B3),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: const Icon(
//               Icons.refresh,
//               color: Color(0xFF1A1A3E),
//               size: 20,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ...existing code...
import 'package:flutter/material.dart';

class AIInsightsScreen extends StatelessWidget {
  const AIInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: const Text(
                      'Your AI insights',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A3E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Most completed quests card
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Most completed quests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A3E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These are the quests you tend to finish the most:',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1A1A3E)),
                    ),
                    const SizedBox(height: 16),
                    _buildQuestItem('Clean house'),
                    const SizedBox(height: 12),
                    _buildQuestItem('Walk a dog'),
                    const SizedBox(height: 12),
                    _buildQuestItem('Sleep'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Most productive days/hours card
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Most productive days / hours',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A3E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B5FFF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Day',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Sunday',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4E7FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Hour',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF5B5FFF),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '10:00',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5B5FFF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Preferred quest types card
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preferred quest types',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A3E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You complete more Soft Moves than Power Moves (72% vs 28%).',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1A1A3E)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Flexible(
                          flex: 72,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD4B3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Soft moves',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1A1A3E),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '78%',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A3E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          flex: 28,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFAA66),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Power moves',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1A1A3E),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '22%',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A3E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildQuestItem(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9D4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF5B5FFF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A3E),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD4B3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.refresh,
              color: Color(0xFF1A1A3E),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ...existing code...
