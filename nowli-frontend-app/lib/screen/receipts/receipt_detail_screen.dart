import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/models/call_summary_history.dart';
import 'package:nowlii/services/receipt_format.dart';
import 'package:nowlii/services/receipt_pdf.dart';
import 'package:nowlii/services/voice_call_service.dart';
import 'package:nowlii/widget/nowlii_avatar.dart';

/// One receipt, opened from the library.
///
/// Shows only what the user said and what came out of it — their repeated words, the next
/// step they named, and one small question. The mood/focus/energy sentences stay on the
/// post-call screen; a receipt is meant to be short enough to read at a glance.
class ReceiptDetailScreen extends StatefulWidget {
  final CallSummaryHistoryItem receipt;

  /// Serial number, worked out by the list from the receipt's position.
  final int number;

  const ReceiptDetailScreen({
    super.key,
    required this.receipt,
    required this.number,
  });

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  static const Color _bg = Color(0xFFDFEFFF);
  static const Color _card = Color(0xFFFFFEF8);
  static const Color _ink = Color(0xFF011F54);
  static const Color _muted = Color(0xFF4C586E);
  static const Color _accent = Color(0xFF4542EB);

  final VoiceCallService _service = VoiceCallService();

  late CallSummaryHistoryItem _receipt = widget.receipt;
  bool _savingNote = false;
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final when = _receipt.startedAt ?? _receipt.createdAt;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'NOWLII RECEIPT',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Wosker',
                            color: _ink,
                            fontSize: 52,
                            fontWeight: FontWeight.w400,
                            height: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${receiptDateLabel(when)} · call length '
                      '${callLengthLabel(_receipt.durationSeconds)}',
                      style: GoogleFonts.martianMono(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(children: _buildCards()),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterLine(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFC3DBFF),
                shape: BoxShape.circle,
              ),
              child: Assets.svgIcons.receiptClose.svg(width: 15, height: 15),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: ShapeDecoration(
              color: const Color(0xFFFAE3CE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Text(
              'RECEIPT NO. ${receiptNumberLabel(widget.number)}',
              style: GoogleFonts.martianMono(
                color: _ink,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          // Balances the close button so the badge stays centred.
          const SizedBox(width: 32, height: 32),
        ],
      ),
    );
  }

  /// Each card hides when it has nothing to say, rather than printing an empty frame or
  /// inventing filler. A short call legitimately produces very little.
  List<Widget> _buildCards() {
    final cards = <Widget>[];

    if (_receipt.wordsCircled.isNotEmpty) {
      cards.add(_ReceiptCard(
        dotColour: const Color(0xFFFF8F26),
        label: 'Words you circled around',
        child: Text(
          receiptWordLines(_receipt.wordsCircled).join('\n'),
          style: GoogleFonts.workSans(
            color: _ink,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -1,
          ),
        ),
      ));
    }

    if (_receipt.nextStep.trim().isNotEmpty) {
      cards.add(_ReceiptCard(
        dotColour: _accent,
        label: 'Next step mentioned',
        child: Text(
          '“${_receipt.nextStep.trim()}”',
          style: GoogleFonts.workSans(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.4,
            letterSpacing: -0.5,
          ),
        ),
      ));
    }

    if (_receipt.tinyQuestion.trim().isNotEmpty) {
      cards.add(_ReceiptCard(
        dotColour: const Color(0xFF3BB64B),
        label: 'Tiny question',
        child: Text(
          _receipt.tinyQuestion.trim(),
          style: GoogleFonts.workSans(
            color: _accent,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.3,
            letterSpacing: -0.5,
          ),
        ),
      ));
    }

    // The user's own words get their own card once written, so they can see what they
    // kept rather than having to open the editor to find out.
    if (_receipt.hasNote) {
      cards.add(_ReceiptCard(
        dotColour: const Color(0xFF8C4F15),
        label: 'Your note',
        child: Text(
          _receipt.note.trim(),
          style: GoogleFonts.workSans(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ));
    }

    if (cards.isEmpty) {
      cards.add(_ReceiptCard(
        dotColour: _muted,
        label: 'This one was short',
        child: Text(
          'Not every call leaves a pattern behind.',
          style: GoogleFonts.workSans(
            color: _muted,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ));
    }

    return [
      for (int i = 0; i < cards.length; i++) ...[
        if (i > 0) const SizedBox(height: 8),
        cards[i],
      ],
    ];
  }

  Widget _buildFooterLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // The user's companion, not fizzy. `receipt_fizzy.png` is byte-for-byte the
          // fizzy character standing neutral, so every receipt showed the same orange
          // character whoever the reader had picked. Neutral pose = the profile's own
          // picture, which is that same standing shot for each companion. Footprint
          // unchanged at 32 × 48.
          const NowliiAvatar(size: 32, height: 48),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Not a diagnosis. Just a mirror.',
              style: GoogleFonts.workSans(
                color: _muted,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          SizedBox(
            width: 131,
            child: _PillButton(
              label: _receipt.hasNote ? 'Edit note' : 'Add a note',
              background: _card,
              borderColour: const Color(0xFFC3DBFF),
              onTap: _savingNote ? null : _editNote,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PillButton(
              label: _sharing ? 'Preparing…' : 'Keep this receipt',
              background: const Color(0xFFFF8F26),
              onTap: _sharing ? null : _keepReceipt,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editNote() async {
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteSheet(initial: _receipt.note),
    );
    if (text == null || !mounted) return; // dismissed without saving

    setState(() => _savingNote = true);
    final saved = await _service.saveReceiptNote(
      callId: _receipt.callId,
      note: text,
    );
    if (!mounted) return;

    setState(() {
      _savingNote = false;
      // Only reflect what the server actually stored. Showing the typed text after a
      // failed save would be a note that exists on screen and nowhere else.
      if (saved != null) {
        _receipt = _receipt.withNote(
          saved,
          saved.isEmpty ? null : DateTime.now(),
        );
      }
    });

    if (saved == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't save your note. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _keepReceipt() async {
    setState(() => _sharing = true);
    try {
      await ReceiptPdf.share(receipt: _receipt, number: widget.number);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't create the PDF. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

/// One labelled card: a coloured dot, a small mono label, and the content.
class _ReceiptCard extends StatelessWidget {
  final Color dotColour;
  final String label;
  final Widget child;

  const _ReceiptCard({
    required this.dotColour,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: _ReceiptDetailScreenState._card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFC8CBD2)),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x140A0D12),
            blurRadius: 16,
            offset: Offset(0, 12),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Color(0x080A0D12),
            blurRadius: 6,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dotColour, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.martianMono(
                    color: _ReceiptDetailScreenState._muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color? borderColour;
  final VoidCallback? onTap;

  const _PillButton({
    required this.label,
    required this.background,
    required this.onTap,
    this.borderColour,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: borderColour == null
                  ? BorderSide.none
                  : BorderSide(color: borderColour!, width: 2),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.workSans(
              color: const Color(0xFF011F54),
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

/// The note editor. Returns the new text, or null if dismissed without saving.
///
/// Clearing the field and saving is how a note is deleted — the backend treats an empty
/// string as a delete, so that path needs no separate button.
class _NoteSheet extends StatefulWidget {
  final String initial;

  const _NoteSheet({required this.initial});

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  /// Matches the backend's cap, so an over-long note is prevented rather than rejected.
  static const int _maxLength = 2000;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFEF8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your note',
              style: GoogleFonts.workSans(
                color: const Color(0xFF011F54),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 5,
              maxLength: _maxLength,
              style: GoogleFonts.workSans(
                color: const Color(0xFF011F54),
                fontSize: 16,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Anything you want to keep with this one.',
                hintStyle: GoogleFonts.workSans(color: const Color(0xFF8A93A3)),
                filled: true,
                fillColor: const Color(0xFFFFFCF1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFC3DBFF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFC3DBFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF4542EB), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PillButton(
                    label: 'Cancel',
                    background: const Color(0xFFFFFEF8),
                    borderColour: const Color(0xFFC3DBFF),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PillButton(
                    label: 'Save',
                    background: const Color(0xFFFF8F26),
                    onTap: () => Navigator.of(context).pop(_controller.text),
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
