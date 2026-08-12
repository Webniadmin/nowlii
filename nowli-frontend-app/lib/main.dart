import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/api/onboarding_data.dart';
import 'package:nowlii/api/session.dart';
import 'package:nowlii/api/storage.dart';
import 'package:nowlii/core/app_routes/app_pages.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/responsive/responsive_text.dart';
import 'package:nowlii/services/call_reminder_service.dart';

void main() async {
  // Enable debug prints
  debugPrint('🚀 App starting...');

  // Ensure all prints are visible
  if (kDebugMode) {
    debugPrint('✅ Debug mode enabled');
  }

  WidgetsFlutterBinding.ensureInitialized();

  // Tapping a call reminder opens the call screen. Wired here, once, so the reminder
  // service never has to know about routing. `AppPages.router` is a static GoRouter, so
  // no navigator key is needed.
  final reminders = CallReminderService.instance;
  reminders.onReminderTapped = (scheduledCallId, questTitle) {
    AppPages.router.push(
      AppRoutespath.aiVoice,
      extra: {'questTitle': questTitle, 'scheduledCallId': scheduledCallId},
    );
  };
  await reminders.init();

  // Bring back any half-finished onboarding. Without this, killing the app
  // mid-flow lost every answer, and since the account already exists by then the
  // user could end up in the app with no profile and no way to make one.
  await OnboardingData().restore();

  // Hydrate the chosen companion before the first frame, so screens that draw it do not
  // flash the default character first. Reading the cached profile is enough — the getter
  // itself feeds CompanionAvatar.
  await SecureStorage.getProfileData();

  // When the refresh token is finally spent, the session is genuinely over — take the user
  // to sign-in instead of leaving them on a screen where everything quietly fails. Wired
  // here so lib/api/session.dart stays unaware of routing.
  Session.onSignedOut = () {
    reminders.cancelAll(); // reminders for an account we can no longer act as
    AppPages.router.go(AppRoutespath.signInScreen);
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      minTextAdapt: true,
      splitScreenMode: true,
      designSize: const Size(375, 812),
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          // Text scaling for narrow phones and the OS font-size slider. This has
          // to hang off MaterialApp's own builder, not ScreenUtilInit's — the
          // app inserts a fresh MediaQuery from the view, so an override placed
          // above it would just be discarded.
          builder: (context, child) => ResponsiveText(child: child!),
          routerConfig: AppPages.router,
        );
      },
    );
  }
}
