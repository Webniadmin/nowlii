import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:nowlii/models/call_summary_history.dart';
import 'package:nowlii/services/receipt_format.dart';

/// "Keep this receipt" — renders one receipt as a PDF and hands it to the system share
/// sheet, which is also where "save to Files" lives on both platforms.
///
/// Sharing rather than writing into Downloads is deliberate: it needs no storage
/// permission, and Android's storage rules differ enough between OS versions that the
/// permission path fails silently on some devices.
///
/// The PDF is built from the same values the screen shows, so what gets kept is what was
/// on screen — no second source of truth to drift.
class ReceiptPdf {
  /// The receipt's own dark navy / cream palette.
  static const PdfColor _ink = PdfColor.fromInt(0xFF011F54);
  static const PdfColor _muted = PdfColor.fromInt(0xFF4C586E);
  static const PdfColor _accent = PdfColor.fromInt(0xFF4542EB);
  static const PdfColor _paper = PdfColor.fromInt(0xFFFFFEF8);

  /// Build and share. Returns false if the user dismissed the share sheet.
  static Future<bool> share({
    required CallSummaryHistoryItem receipt,
    required int number,
  }) async {
    final bytes = await build(receipt: receipt, number: number);
    return Printing.sharePdf(
      bytes: bytes,
      filename: 'nowlii-receipt-${receiptNumberLabel(number)}.pdf',
    );
  }

  static Future<Uint8List> build({
    required CallSummaryHistoryItem receipt,
    required int number,
  }) async {
    // The app's display faces are not bundled as PDF fonts, so the document uses the
    // built-in ones. Getting the layout and the words right matters more here than
    // matching the on-screen typeface.
    final doc = pw.Document();
    final when = receipt.startedAt ?? receipt.createdAt;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Container(
          color: _paper,
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RECEIPT NO. ${receiptNumberLabel(number)}',
                style: pw.TextStyle(
                  color: _muted,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Text(
                'NOWLII RECEIPT',
                style: pw.TextStyle(
                  color: _ink,
                  fontSize: 34,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                '${receiptDateLabel(when)} · call length '
                '${callLengthLabel(receipt.durationSeconds)}',
                style: pw.TextStyle(color: _muted, fontSize: 11, letterSpacing: 1),
              ),
              pw.SizedBox(height: 24),

              if (receipt.wordsCircled.isNotEmpty)
                _section(
                  'WORDS YOU CIRCLED AROUND',
                  pw.Text(
                    receiptWordLines(receipt.wordsCircled).join(' '),
                    style: pw.TextStyle(
                      color: _ink,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

              if (receipt.nextStep.trim().isNotEmpty)
                _section(
                  'NEXT STEP MENTIONED',
                  pw.Text(
                    '“${receipt.nextStep.trim()}”',
                    style: pw.TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

              if (receipt.tinyQuestion.trim().isNotEmpty)
                _section(
                  'TINY QUESTION',
                  pw.Text(
                    receipt.tinyQuestion.trim(),
                    style: pw.TextStyle(
                      color: _accent,
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

              if (receipt.hasNote)
                _section(
                  'YOUR NOTE',
                  pw.Text(
                    receipt.note.trim(),
                    style: const pw.TextStyle(color: _ink, fontSize: 13),
                  ),
                ),

              pw.Spacer(),
              pw.Text(
                'Not a diagnosis. Just a mirror.',
                style: const pw.TextStyle(color: _muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _section(String label, pw.Widget body) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 18),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                color: _muted,
                fontSize: 9,
                letterSpacing: 1.2,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            body,
          ],
        ),
      );
}
