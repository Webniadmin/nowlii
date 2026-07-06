import 'package:flutter/material.dart';

class SuccessFeedbackModal extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<FeedbackItem> feedbackItems;
  final String nextStepText;
  final VoidCallback onSaveReflection;
  final VoidCallback onDismiss;

  const SuccessFeedbackModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.feedbackItems,
    required this.nextStepText,
    required this.onSaveReflection,
    required this.onDismiss,
  });

  @override
  State<SuccessFeedbackModal> createState() => _SuccessFeedbackModalState();
}

class _SuccessFeedbackModalState extends State<SuccessFeedbackModal> {
  String personalNote = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.grey),
                onPressed: widget.onDismiss,
              ),
            ),
            SizedBox(height: 10),

            // Logo/Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFF4C3FFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                'assets/images/mascot.png', // Apnar mascot image
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 20),

            // Title
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A4F),
              ),
            ),
            SizedBox(height: 8),

            // Subtitle
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 30),

            // Feedback items
            ...widget.feedbackItems.map(
              (item) => FeedbackItemWidget(item: item),
            ),

            SizedBox(height: 20),

            // Next step
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.rocket_launch, color: Color(0xFF4C3FFF)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next step',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A4F),
                          ),
                        ),
                        Text(
                          widget.nextStepText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Personal note section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add personal note',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A4F),
                ),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write about how you felt...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                personalNote = value;
              },
            ),
            SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onDismiss,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Color(0xFF4C3FFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Dismiss',
                      style: TextStyle(
                        color: Color(0xFF4C3FFF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onSaveReflection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4C3FFF),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save reflection',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
}

class FeedbackItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String emoji;

  FeedbackItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.emoji,
  });
}

class FeedbackItemWidget extends StatelessWidget {
  final FeedbackItem item;

  const FeedbackItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: item.iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A4F),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(item.emoji, style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}

// Usage example
void showSuccessFeedback(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SuccessFeedbackModal(
      title: 'GREAT JOB!',
      subtitle:
          'You nailed it! Puzzle and Fuzzy loved what you did during that...',
      feedbackItems: [
        FeedbackItem(
          icon: Icons.favorite,
          iconColor: Colors.red,
          title: 'Mood detection',
          description: 'You sounded calm and optimistic.',
          emoji: '😊',
        ),
        FeedbackItem(
          icon: Icons.chat_bubble,
          iconColor: Colors.purple,
          title: 'Focus topic',
          description: 'You talked about staying consistent.',
          emoji: '🎯',
        ),
        FeedbackItem(
          icon: Icons.edit,
          iconColor: Colors.blue,
          title: 'Reflection',
          description: 'You started lined but ended excited.',
          emoji: '🤔',
        ),
      ],
      nextStepText: 'Start your next quest!',
      onSaveReflection: () {
        // Save logic here
        Navigator.pop(context);
      },
      onDismiss: () {
        Navigator.pop(context);
      },
    ),
  );
}
