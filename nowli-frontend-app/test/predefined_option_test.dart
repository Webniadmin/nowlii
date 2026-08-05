import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/api/onboarding_data.dart';
import 'package:nowlii/api/profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `predefined_option` is the only field that sets the companion. The backend derives
/// `avatar_logo` from it and treats both `avatar_logo` and `nowlii_name` as read-only —
/// send those instead and the request returns 200 with the choice silently discarded.
///
/// That is exactly what happened: onboarding held the option id and stored only the URL,
/// and `createProfile` had no parameter for the id at all, so **every new account got the
/// default companion** — and with it the wrong AI voice, since `Profile.save()` adopts the
/// companion's voice. The same defect sat in the profile picker.
///
/// These tests follow the id down the whole path it has to survive: the onboarding store,
/// a cold start, and both request bodies.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await OnboardingData().clear();
  });

  group('the signup request', () {
    CreateProfileRequest request({int? option}) => CreateProfileRequest(
          name: 'Miki',
          gender: "I'm a man",
          language: 'English',
          voice: 'Female',
          predefinedOption: option,
        );

    test('carries the chosen companion', () {
      expect(request(option: 3).toJson()['predefined_option'], 3);
    });

    test('omits the field rather than sending null', () {
      // A null would be a value the serializer has to reject; absent means "unchanged".
      expect(request().toJson().containsKey('predefined_option'), isFalse);
    });

    test('still carries it when the user renamed the companion', () {
      // The rename goes in custom_nowlii_name, which must not displace the id — the
      // picture and the voice both hang off the id, not the name.
      final json = CreateProfileRequest(
        name: 'Miki',
        gender: "I'm a man",
        language: 'English',
        voice: 'Female',
        customNowliiName: 'Blooby',
        predefinedOption: 5,
      ).toJson();

      expect(json['predefined_option'], 5);
      expect(json['custom_nowlii_name'], 'Blooby');
    });

    test('carries it alongside an avatar URL, which the server ignores', () {
      final json = CreateProfileRequest(
        name: 'Miki',
        gender: "I'm a man",
        language: 'English',
        voice: 'Female',
        avatarLogo: 'https://example.com/knotty.png',
        predefinedOption: 4,
      ).toJson();

      expect(json['predefined_option'], 4);
    });
  });

  group('the profile update request', () {
    test('changing the companion sends the id', () {
      // The picker used to send avatar_logo + nowlii_name, both read-only, and then
      // announce "Avatar updated successfully!" over a server that had changed nothing.
      final json = UpdateProfileRequest(predefinedOption: 3).toJson();
      expect(json['predefined_option'], 3);
    });

    test('an update that is not about the companion leaves it alone', () {
      final json = UpdateProfileRequest(name: 'Miki').toJson();
      expect(json.containsKey('predefined_option'), isFalse);
    });
  });

  group('the id survives onboarding', () {
    test('the store keeps it, not just the picture', () async {
      final data = OnboardingData();
      data.setAvatarLogo('https://example.com/knotty.png');
      data.setPredefinedOption(3);
      await Future<void>.delayed(Duration.zero);

      expect(data.predefinedOption, 3);
    });

    test('it comes back after a cold start', () async {
      // Answers are persisted because the app can be killed mid-flow; if the id were
      // dropped there, the account would be created with the default companion.
      final data = OnboardingData();
      data.setName('Miki');
      data.setPredefinedOption(6);
      await Future<void>.delayed(Duration.zero);

      await data.restore();

      expect(data.predefinedOption, 6);
    });

    test('what onboarding holds is what signup sends', () async {
      final data = OnboardingData();
      data.setName('Miki');
      data.setGender("I'm a man");
      data.setLanguage('English');
      data.setVoice('Female');
      data.setPredefinedOption(2);
      await Future<void>.delayed(Duration.zero);

      final json = CreateProfileRequest(
        name: data.name!,
        gender: data.gender!,
        language: data.language!,
        voice: data.voice!,
        avatarLogo: data.avatarLogo,
        predefinedOption: data.predefinedOption,
      ).toJson();

      expect(json['predefined_option'], 2);
    });
  });
}
