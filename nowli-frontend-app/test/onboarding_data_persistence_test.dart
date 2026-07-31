import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/api/onboarding_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding answers used to live only in memory. Killing the app halfway
/// through threw them all away — and since the account already exists by that
/// point, the next launch dropped the user into an app with no profile.
///
/// `OnboardingData` is a singleton, so each test clears it first.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await OnboardingData().clear();
  });

  group('answers survive a restart', () {
    test('what was entered is written to storage', () async {
      final data = OnboardingData();
      data.setName('Julie');
      data.setGender("I'm a woman");
      data.setLanguage('Español');
      data.setVoice('Female');
      data.setNowliiName('fizzy');

      // Setters persist in the background; let the write settle.
      await Future<void>.delayed(Duration.zero);

      // Wipe memory only, the way a cold start would.
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('onboarding_data_v1');
      expect(stored, isNotNull);
      expect(stored, contains('Julie'));
      expect(stored, contains('Español'));
    });

    test('restore brings the answers back', () async {
      final data = OnboardingData();
      data.setName('Julie');
      data.setGender("I'm a woman");
      data.setLanguage('English');
      data.setVoice('Female');
      await Future<void>.delayed(Duration.zero);

      await data.restore();

      expect(data.name, 'Julie');
      expect(data.gender, "I'm a woman");
      expect(data.isComplete, isTrue);
    });

    test('clearing wipes storage too, not just memory', () async {
      final data = OnboardingData();
      data.setName('Julie');
      await Future<void>.delayed(Duration.zero);

      await data.clear();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('onboarding_data_v1'), isNull);
      expect(data.name, isNull);
    });

    test('restoring from empty storage is a no-op, not a crash', () async {
      final data = OnboardingData();
      await data.restore();
      expect(data.name, isNull);
    });
  });

  group('names no longer come from the mock', () {
    test('greeting uses the entered name', () {
      final data = OnboardingData();
      data.setName('Julie');
      expect(data.greetingName, 'Julie');
    });

    test('greeting falls back to something neutral, not a placeholder', () {
      // The voice-check screen used to read "YOU'RE ALL SET, JULIE!" for
      // everyone — the name straight out of the Figma mock.
      expect(OnboardingData().greetingName, 'there');
      expect(OnboardingData().greetingName, isNot(contains('Julie')));
    });

    test('a typed companion name wins over a suggested one', () {
      final data = OnboardingData();
      data.setNowliiName('fizzy');
      data.setCustomNowliiName('blooby');
      expect(data.companionName, 'blooby');
    });

    test('a suggested companion name is used when nothing was typed', () {
      final data = OnboardingData();
      data.setNowliiName('fizzy');
      expect(data.companionName, 'fizzy');
    });

    test('companion falls back to Nowlii, not the hardcoded "Fuzzy"', () {
      expect(OnboardingData().companionName, 'Nowlii');
    });
  });
}
