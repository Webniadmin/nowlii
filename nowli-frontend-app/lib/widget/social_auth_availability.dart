import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Which social sign-in each platform offers.
///
/// Every auth screen used to draw **both** buttons on every platform. Two
/// stacked 74-high pills plus a fixed gap is more vertical room than a 320dp
/// phone has to spare, which is what pushed "Don't have an account? Sign up"
/// off the bottom of the sign-in screen — the button a new user needs most.
/// And offering "Continue with Apple" on an Android phone was never useful:
/// it leaves the app for a browser round-trip that Android users have no
/// reason to take.
///
/// One per platform: Google on Android, Apple on iOS.
///
/// ⚠️ **On iOS this leaves Apple as the only social sign-in, and Apple sign-in
/// currently answers 503** — the backend is built but disabled until
/// `APPLE_CLIENT_IDS` and the `.p8` key are filled in (see `docs/apple-login.md`,
/// and the P3 item in `future-checklist.md`). Email and password still work, so
/// iOS is not locked out, but this must be configured before an iOS release.
///
/// Web keeps Google: the Apple web flow still points at a temporary tunnel URL.
bool get offersGoogleSignIn => kIsWeb || !Platform.isIOS;

bool get offersAppleSignIn => !kIsWeb && Platform.isIOS;
