import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/services/call_duration.dart';

/// Four screens quote a spark's length. They now read it from one constant, so this pins
/// the formatting that copy depends on.
void main() {
  test('renders whole minutes without a trailing decimal', () {
    // "5.0 min" would read like a measurement.
    expect(callMinutesLabel, '5');
  });

  test('renders the half-minute extension as a decimal', () {
    // Mid-sentence, "+2.5" reads better than "+2:30".
    expect(extensionMinutesLabel, '2.5');
  });

  test('builds the shared sentence', () {
    expect(callLengthCopy, '5 min · +2.5 if you need it');
  });

  test('the extension really is half a minute longer than two', () {
    expect(kCallExtensionDuration.inSeconds, 150);
    expect(kCallInitialDuration.inSeconds, 300);
  });
}
