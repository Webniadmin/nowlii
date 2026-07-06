import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/services/support_service.dart';
import 'package:nowlii/themes/text_styles.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final SupportService _service = SupportService();

  List<SupportMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await _service.getMessages();
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load messages. Pull to refresh or try again later.';
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final msg = await _service.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
        _messageController.clear();
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    return sameDay
        ? DateFormat('HH:mm').format(dt)
        : DateFormat('MMM d, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5B4FFF),
      body: Column(
        children: [
          const SizedBox(height: 50),
          _buildHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Expanded(child: _buildBody()),
                  _buildMessageInput(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error ??
                "No messages yet.\nSend us a message and we'll reply right here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.workSans(
              color: const Color(0xFF4C586E),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final showSenderName = index == 0 ||
              _messages[index - 1].isFromUser != message.isFromUser;
          return _buildMessageBubble(message, showSenderName);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const SizedBox(width: 12),
          Text('SUPPORT CHAT', style: AppsTextStyles.kSettingsTitleStyle),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(SupportMessage message, bool showSenderName) {
    return Column(
      crossAxisAlignment: message.isFromUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (showSenderName)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4, right: 4),
            child: Text(
              message.isFromUser ? 'You' : 'NOWLII Support',
              style: GoogleFonts.workSans(
                color: const Color(0xFF4C586E),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.40,
                letterSpacing: -0.50,
              ),
            ),
          )
        else
          const SizedBox(height: 8),
        Row(
          mainAxisAlignment: message.isFromUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: message.isFromUser
                      ? const Color(0xFFB8D4FF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.body,
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
          child: Text(
            _formatTime(message.createdAt),
            style: GoogleFonts.workSans(fontSize: 11, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 43.74,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1.88, color: const Color(0xFFC3DBFF)),
                  borderRadius: BorderRadius.circular(20971500),
                ),
              ),
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: GoogleFonts.workSans(
                    color: const Color(0xFFADB2BC),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    letterSpacing: -0.5,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: GoogleFonts.workSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sending ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              child: _sending
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Image.asset(
                      Assets.svgIcons.chatbot.path,
                      width: 40,
                      height: 40,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
