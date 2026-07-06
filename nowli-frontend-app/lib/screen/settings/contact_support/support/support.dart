import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/services/support_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String? selectedCategory;
  final TextEditingController _messageController = TextEditingController();
  bool _messageSent = false; // Success message show korar jonno
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4D4DFF),
      body: Column(
        children: [
          // Header
          _buildHeader(),
          // const SizedBox(height: 20),
          // Main Content Card
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_messageSent) ...[
                      _buildTitle(),
                      const SizedBox(height: 20),
                      _buildCategoryButtons(),
                      const SizedBox(height: 28),
                      _buildMessageSection(),
                      const SizedBox(height: 24),
                      _buildSendButton(),
                    ] else ...[
                      _buildSuccessMessage(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Image.asset(
              Assets.svgIcons.settingsBackIcon.path,
              width: 32,
              height: 32,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Text(
            'SUPPORT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFFFFDF7) /* Text-text-light */,
              fontSize: 32,
              fontFamily: 'Wosker',
              fontWeight: FontWeight.w400,
              height: 0.80,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              // Navigate to the SupportChatScreen when the icon is tapped
              context.push("/supportChatScreen");
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                Assets.svgIcons.messages.path,
                width: 60,
                height: 60,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'WHAT DO YOU NEED \nHELP WITH?',
      style: GoogleFonts.workSans(
        color: const Color(0xFF354152),
        fontSize: 24,
        fontWeight: FontWeight.w900,
        height: 0.9,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildCategoryButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildCategoryChip('App issue'),
        _buildCategoryChip('Billing & Subscription'),
        _buildCategoryChip('Question about features'),
        _buildCategoryChip('Feedback or suggestion'),
      ],
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = isSelected ? null : label;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: isSelected
              ? const Color(0xFF4D4DFF).withValues(alpha: 0.1)
              : const Color(0xFFFFFDF7),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 2,
              color: isSelected
                  ? const Color(0xFF4D4DFF)
                  : const Color(0xFFC3DBFF),
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.workSans(
            color: const Color(0xFF011F54),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
            letterSpacing: -0.9,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us what\'s going on…',
          style: GoogleFonts.workSans(
            color: const Color(0xFF354152),
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.20,
            letterSpacing: -0.50,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1.88, color: const Color(0xFFC3DBFF)),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: TextField(
            controller: _messageController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText:
                  'Describe your issue or question here — the more details, the better.',
              hintStyle: GoogleFonts.workSans(
                color: const Color(0xFF4C586E),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.60,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: GoogleFonts.workSans(
              color: const Color(0xFF011F54),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.60,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We usually reply within 24 hours. You\'ll get a response directly in the app or by email.',
          style: GoogleFonts.workSans(
            color: const Color(0xFF595754),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.40,
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: _sending
            ? null
            : () async {
                if (selectedCategory == null ||
                    _messageController.text.trim().isEmpty) {
                  return;
                }
                setState(() => _sending = true);
                try {
                  await SupportService().sendMessage(
                    _messageController.text.trim(),
                    category: selectedCategory,
                  );
                  if (!mounted) return;
                  setState(() {
                    _messageSent = true;
                    _sending = false;
                  });
                } catch (e) {
                  if (!mounted) return;
                  setState(() => _sending = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not send your message. Please try again.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4D4DFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: _sending
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Send Message',
                textAlign: TextAlign.center,
                style: GoogleFonts.workSans(
                  color: const Color(0xFFFFFDF7), // Text-text-light
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 0.8,
                ),
              ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: ShapeDecoration(
        color: const Color(0xFFCFFFC9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: [
          BoxShadow(
            color: Color(0x070A0C12),
            blurRadius: 6,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Color(0x140A0C12),
            blurRadius: 16,
            offset: Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: ShapeDecoration(
                  color: const Color(0xFFA0E871),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(500),
                  ),
                ),
                child: Icon(Icons.check_circle, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message Sent!',
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF011F54),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.20,
                        letterSpacing: -0.50,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thanks for reaching out - our team will get back to you soon. You can check your messages anytime in the Support tab.',
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF595754),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA0E871),
                foregroundColor: const Color(0xFF011F54),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: Text(
                'Back to settings',
                textAlign: TextAlign.center,
                style: GoogleFonts.workSans(
                  color: const Color(0xFF011F54),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
