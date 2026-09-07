import 'package:nowlii/api/storage.dart';

/// The one place that turns stored profile/auth state into a name to show or speak.
///
/// Every screen that greets the user used to inline its own version of this, and the
/// fallback in the mock was the designer's name ("JULIE") — so a user whose profile had
/// not loaded yet was greeted as someone else. Keep new call/greeting UI pointed here
/// rather than reading the profile directly, so there is a single fallback to audit.
class DisplayName {
  const DisplayName._();

  /// The user's own name: profile name → auth username → a neutral word.
  ///
  /// The last fallback is deliberately 'there' (as in "hi there") and never a person's
  /// name: being greeted by the wrong name reads as a bug, being greeted generically
  /// does not.
  static Future<String> user() async {
    final storage = StorageService();
    final profile = await storage.getProfileData();
    final profileName = profile?.name.trim() ?? '';
    if (profileName.isNotEmpty) return profileName;
    final username = (await storage.getUsername())?.trim() ?? '';
    if (username.isNotEmpty) return username;
    return 'there';
  }

  /// The user's name for a shouted headline, e.g. `HI SARAH!` / `HI THERE!`.
  ///
  /// Returns the bare word, uppercased; callers own the surrounding copy. Always pair
  /// with `maxLines` + `TextOverflow.ellipsis` — the name is user-supplied and these
  /// headlines sit at 32sp in a `Row`.
  static Future<String> userUpper() async => (await user()).toUpperCase();

  /// The companion's name: the user's custom rename → the chosen preset → 'Fuzzy'.
  ///
  /// The user is invited to rename their companion, so this is the only correct source
  /// for it — never the predefined-option id, and never the bundled art's filename.
  static Future<String> companion() async {
    final storage = StorageService();
    final profile = await storage.getProfileData();
    final custom = profile?.customNowliiName?.trim() ?? '';
    if (custom.isNotEmpty) return custom;
    final predefined = profile?.nowliiName?.trim() ?? '';
    if (predefined.isNotEmpty) return predefined;
    return 'Fuzzy';
  }
}
