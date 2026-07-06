import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/screen/onboarding/energy_check_in_screen.dart';
import 'package:nowlii/screen/onboarding/pop_speaking_loading.dart';
import 'package:nowlii/screen/home/swipe_to_talk/swipe_to_talk_loading.dart';
import 'package:nowlii/screen/home/swipe_to_talk/popup_share_how_you_feel.dart';
import 'package:nowlii/screen/home/swipe_to_talk/popup_speaking.dart';
import 'package:nowlii/screen/home/swipe_to_talk/popup_processing.dart';
import 'package:nowlii/screen/home/swipe_to_talk/voice_check/popup_your_share_you.dart';
import 'package:nowlii/screen/home/swipe_to_talk/voice_check/popup_speaking.dart';
import 'package:nowlii/screen/home/swipe_to_talk/voice_check/popup_processing.dart';
import 'package:nowlii/screen/home/swipe_to_talk/voice_check/popup_error.dart';
import 'package:nowlii/screen/onboarding/loading_onboarding_nowli.dart';
import 'package:nowlii/screen/onboarding/nowli_how_to_use.dart';
import 'package:nowlii/screen/onboarding/onboarding_features/onboarding_features.dart';
import 'package:nowlii/screen/onboarding/onboarding_flow_file/onboarding_flow.dart';
import 'package:nowlii/screen/ai_call/ai_voice.dart';
import 'package:nowlii/screen/ai_call/call_summary_screen.dart';
import 'package:nowlii/screen/ai_call/pop_po_sahre.dart';
import 'package:nowlii/screen/auth/enter_new_password.dart';
import 'package:nowlii/screen/auth/password_updated_popup_screen.dart';
import 'package:nowlii/screen/auth/resent_password_page.dart';
import 'package:nowlii/screen/auth/reset_password_otp_screen.dart';
import 'package:nowlii/screen/auth/sign_in_screen.dart';
import 'package:nowlii/screen/auth/sign_up.dart';
import 'package:nowlii/screen/auth/otp_verification_screen.dart';
import 'package:nowlii/screen/entry_screen_p2.dart';
import 'package:nowlii/screen/home/home_screen.dart';
import 'package:nowlii/screen/profile/edit_profile/edit_from.dart';
import 'package:nowlii/screen/profile/edit_profile/edit_profile.dart';
import 'package:nowlii/screen/profile/edit_profile/edit_name.dart';
import 'package:nowlii/screen/profile/profile_menu_with_notification/profile_menu_with_notification.dart';
import 'package:nowlii/screen/progress/progress.dart';
import 'package:nowlii/screen/quests/create_quests/create_quests_default.dart';
import 'package:nowlii/screen/quests/create_quests/edit_quest_page.dart';
import 'package:nowlii/screen/quests/suggested/suggested_task_overview.dart';
import 'package:nowlii/screen/quests/suggested/quest_suggestions_list.dart';
import 'package:nowlii/models/quest_suggestion_model.dart';
import 'package:nowlii/screen/quests/quests_my_quests_today_empty_state.dart';
import 'package:nowlii/screen/ready_to_start_screen_p4.dart';
import 'package:nowlii/screen/settings/contact_support/chat_boot/support_chat_screen.dart';
import 'package:nowlii/screen/settings/contact_support/support/support.dart';
import 'package:nowlii/screen/settings/setting.dart';
import 'package:nowlii/screen/splash.dart';
import 'package:nowlii/screen/welcome_activation_flow/notice_loader_screen.dart';
import 'package:nowlii/screen/welcome_activation_flow/popup_speaking.dart';
import 'package:nowlii/screen/welcome_activation_flow/procrastination_screen.dart';
import 'package:nowlii/screen/settings/subscription/subscription_popup.dart';
import 'package:nowlii/screen/settings/subscription/nowli_pro_subscription.dart';
import 'package:nowlii/screen/welcome_come_screen_p3.dart';

import 'package:nowlii/screen/onboarding/popup_choose_mood_updates.dart';

import '../../screen/onboarding/onboarding_features/avatar_logo_name_selection.dart';
import '../../screen/onboarding/onboarding_features/avatar_logo_selection.dart';

class AppPages {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      // Skip redirect for splash screen
      if (state.matchedLocation == AppRoutespath.splash) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final isFirstTime = prefs.getBool('isFirstTime') ?? true;

      // Public routes that don't need authentication
      final publicRoutes = [
        AppRoutespath.entryScreen,
        AppRoutespath.welcomeScreen,
        AppRoutespath.readyToStartScreen,
        AppRoutespath.signInScreen,
        AppRoutespath.signUpScreen,
        AppRoutespath.otpVerificationScreen,
        AppRoutespath.resentPasswordPage,
        '/resetPasswordOtpScreen',
        AppRoutespath.enterNewPassword,
        AppRoutespath.passwordUpdatedPopupScreen,
      ];

      final isPublicRoute = publicRoutes.contains(state.matchedLocation);

      // If user has valid token, allow access to protected routes
      if (accessToken != null && accessToken.isNotEmpty) {
        // If user is on public route but already authenticated, redirect to home
        if (isPublicRoute) {
          return AppRoutespath.homeScreen;
        }
        return null; // Allow access to requested route
      }

      // No token - user not authenticated
      if (!isPublicRoute) {
        // Redirect to appropriate screen based on first time status
        if (isFirstTime) {
          return AppRoutespath.entryScreen;
        } else {
          return AppRoutespath.signInScreen;
        }
      }

      return null; // Allow access to public routes
    },
    routes: [
      GoRoute(
        path: AppRoutespath.splash,
        builder: (context, state) => Splash(),
      ),
      GoRoute(
        path: AppRoutespath.entryScreen,
        builder: (context, state) => EntryScreen(),
      ),
      GoRoute(
        path: AppRoutespath.welcomeScreen,
        builder: (context, state) => WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutespath.readyToStartScreen,
        builder: (context, state) => ReadyToStartScreen(),
      ),
      GoRoute(
        path: AppRoutespath.signInScreen,
        builder: (context, state) =>
            const SignInScreen(), // Placeholder for SignInScreen
      ),
      GoRoute(
        path: AppRoutespath.popSpkingLoding,
        builder: (context, state) =>
            const PopSpkingLoding(), // Placeholder for SignInScreen
      ),
      GoRoute(
        path: AppRoutespath.energyCheckInScreen,
        builder: (context, state) =>
            const EnergyCheckInScreen(), // Placeholder for SignInScreen
      ),
      GoRoute(
        path: AppRoutespath.noticeLoaderScreen,
        builder: (context, state) =>
            const NoticeLoaderScreen(), // Placeholder for SignInScreen
      ),
      GoRoute(
        path: AppRoutespath.signUpScreen,
        builder: (context, state) =>
            const SignUpScreen(), // Placeholder for SignUpScreen
      ),
      GoRoute(
        path: AppRoutespath.otpVerificationScreen,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutespath.resentPasswordPage,
        builder: (context, state) => const ResentPasswordPage(),
      ),
      GoRoute(
        path: AppRoutespath.passwordUpdatedPopupScreen,
        builder: (context, state) => const PasswordUpdatedPopupScreen(),
      ),
      GoRoute(
        path: AppRoutespath.enterNewPassword,
        builder: (context, state) {
          final email = state.extra as String?;
          return EnterNewPassword(email: email);
        },
      ),
      GoRoute(
        path: '/resetPasswordOtpScreen',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ResetPasswordOtpScreen(email: email);
        },
      ),

      /* onboarding */
      GoRoute(
        path: AppRoutespath.onboardingFlow,
        builder: (context, state) {
          final page = state.uri.queryParameters['page'];
          final initialPage = page != null ? int.tryParse(page) ?? 0 : 0;
          return OnboardingFlow(initialPage: initialPage);
        },
      ),

      /*  create a quets start here  */
      GoRoute(
        path: AppRoutespath.questHomePage,
        builder: (context, state) => const QuestHomePage(),
      ),
      GoRoute(
        path: AppRoutespath.createQuestPage,
        builder: (context, state) => const CreateQuestPage(),
      ),
      GoRoute(
        path: AppRoutespath.editQuestPage,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EditQuestPage(
            taskId: extra?['taskId'],
            taskData: extra?['taskData'],
          );
        },
      ),
      GoRoute(
        path: AppRoutespath.suggestedTaskOverview,
        builder: (context, state) {
          final suggestion = state.extra as QuestSuggestion?;
          return SuggestedTaskOverview(suggestion: suggestion);
        },
      ),
      GoRoute(
        path: '/questSuggestionsList',
        builder: (context, state) => const QuestSuggestionsList(),
      ),

      /*  create a quets end here  */
      /*   on boarding */
      GoRoute(
        path: AppRoutespath.onboardingFlow,
        builder: (context, state) => const OnboardingFlow(),
      ),

      GoRoute(
        path: AppRoutespath.onbordingFetures,
        builder: (context, state) => OnboardingFeatures(),
      ),
      GoRoute(
        path: AppRoutespath.loadingOnboardingNowli,
        builder: (context, state) {
          final userData = state.extra as Map<String, dynamic>?;
          return LoadingOnboridngNowli(userData: userData);
        },
      ),
      GoRoute(
        path: AppRoutespath.nowliHowToUse,
        builder: (context, state) => NowliHowToUse(),
      ),
      GoRoute(
        path: AppRoutespath.avatarLogo,
        builder: (context, state) => const AvatarLogo(),
      ),
      GoRoute(
        path: AppRoutespath.avatarLogoAndName,
        builder: (context, state) => const AvatarLogoAndName(),
      ),
      GoRoute(
        path: AppRoutespath.popupSpeking,
        builder: (context, state) => const PopupSpeaking(),
      ),
      GoRoute(
        path: AppRoutespath.procrastinationScreen,
        builder: (context, state) {
          return ProcrastinationScreen();
        },
      ),
      // AI Voice Calling
      GoRoute(
        path: AppRoutespath.aiVoice,
        builder: (context, state) => const AiVoice(),
      ),
      GoRoute(
        path: AppRoutespath.callSummary,
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'];
          return CallSummaryScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: AppRoutespath.popPoSahre,
        builder: (context, state) => PopPoSahre(),
      ),
      GoRoute(
        path: AppRoutespath.popupChooseMoodUpdates,
        builder: (context, state) => const PopupChooseMoodUpdates(),
      ),

      /*   on boarding end  */
      GoRoute(
        path: AppRoutespath.swipeToTalkLoading,
        builder: (context, state) => const SwipeToTalkLoading(),
      ),
      // Emotion Detection Flow (Daily once)
      GoRoute(
        path: AppRoutespath.emotionShareScreen,
        builder: (context, state) => const EmotionShareScreen(),
      ),
      GoRoute(
        path: AppRoutespath.emotionSpeakingScreen,
        builder: (context, state) => const EmotionSpeakingScreen(),
      ),
      GoRoute(
        path: AppRoutespath.emotionProcessingScreen,
        builder: (context, state) => const EmotionProcessingScreen(),
      ),
      // Old voice check screens (for calling)
      GoRoute(
        path: AppRoutespath.poupYourShareYou,
        builder: (context, state) => const PoupYourShareYou(),
      ),
      GoRoute(
        path: AppRoutespath.poupSpking,
        builder: (context, state) => const PoupSpking(),
      ),
      GoRoute(
        path: AppRoutespath.poupError,
        builder: (context, state) => const PoupError(),
      ),
      GoRoute(
        path: AppRoutespath.poupProssing,
        builder: (context, state) => const PoupProssing(),
      ),

      /*  home page start  */
      GoRoute(
        path: AppRoutespath.homeScreen,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutespath.profileNotificationsScreen,
        builder: (context, state) {
          return const ProfileNotificationsScreen(); // Placeholder for ChatBoot screen
        },
      ),

      GoRoute(
        path: AppRoutespath.editProfileScreen,
        builder: (context, state) {
          return const EditProfileScreen(); // Placeholder for EditProfileScreen
        },
      ),

      GoRoute(
        path: AppRoutespath.editFrom,
        builder: (context, state) {
          return const EditFrom();
        },
      ),

      GoRoute(
        path: AppRoutespath.editNameScreen,
        builder: (context, state) {
          return const EditNameScreen(); // Edit name screen
        },
      ),

      /*  QuestHomePage page end  */
      GoRoute(
        path: AppRoutespath.questHomePage,
        builder: (context, state) => const QuestHomePage(),
      ),

      /* progress start end  */
      GoRoute(
        path: AppRoutespath.progress,
        builder: (context, state) => const Progress(),
      ),

      GoRoute(
        path: AppRoutespath.settingsScreen,
        builder: (context, state) {
          return const SettingsScreen(); // Placeholder for SettingsScreen
        },
      ),
      GoRoute(
        path: AppRoutespath.subscriptionPage,
        builder: (context, state) {
          return const SubscriptionPage(); // Placeholder for SubscriptionPage
        },
      ),
      GoRoute(
        path: AppRoutespath.nowliProSubscription,
        builder: (context, state) {
          return const NowliProSubscription();
        },
      ),
      GoRoute(
        path: AppRoutespath.supportScreen,
        builder: (context, state) {
          return const SupportScreen(); // Placeholder for SupportScreen
        },
      ),
      GoRoute(
        path: AppRoutespath.supportChatScreen,
        builder: (context, state) {
          return const SupportChatScreen(); // Placeholder for SupportChatScreen
        },
      ),
    ],
  );
}
