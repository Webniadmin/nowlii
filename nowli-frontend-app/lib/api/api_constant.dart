class ApiConstants {
  // Main Backend API URL.
  // Provided at build/run time via --dart-define (or --dart-define-from-file).
  // Defaults to localhost for local development.
  //   flutter run --dart-define-from-file=dart_defines.json
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  // AI Backend API URL (separate server).
  static const String aiBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'http://localhost:8001',
  );
  
  static const String apiPrefix = '/api/auth';
  static const String profilePrefix = '/api/profiles';
  static const String insightsPrefix = '/api';
  static const String aiCallPrefix = '/api/v1';
  static const String questsPrefix = '/api/quests';
  
  // Auth endpoints
  static const String register = '$apiPrefix/register/';
  static const String verifyOtp = '$apiPrefix/verify-otp/';
  static const String login = '$apiPrefix/login/';
  static const String googleLogin = '$apiPrefix/google/';
  static const String appleLogin = '$apiPrefix/apple/';
  static const String forgotPassword = '$apiPrefix/forgot-password/';
  static const String verifyForgotPasswordOtp = '$apiPrefix/verify-forgot-password-otp/';
  static const String setNewPassword = '$apiPrefix/set-new-password/';
  // Exchange a refresh token for a fresh access token (and, because rotation is on, a fresh
  // refresh token). See lib/api/session.dart.
  static const String tokenRefresh = '$apiPrefix/token/refresh/';
  // Permanent account deletion. Required by Google Play's data-deletion policy and Apple
  // guideline 5.1.1(v) for any app that lets users create an account.
  static const String deleteAccount = '$apiPrefix/delete-account/';

  // ── Legal ──────────────────────────────────────────────────────────────────
  // Play requires a reachable privacy policy URL for the listing AND in-app.
  static const String privacyPolicyUrl = 'https://www.nowlii.com/privacy-policy';
  // TODO(legal): Terms of Service does not exist yet. Publish it at
  // https://www.nowlii.com/terms (or wherever), set it here, and re-enable the link on the
  // sign-up screen — search for TODO(legal) in lib/screen/auth/sign_up.dart.
  // Must be done before the store listing goes live.
  static const String termsOfServiceUrl = '';
  
  // Profile endpoints
  static const String createProfile = '$profilePrefix/';
  static const String getProfile = '$profilePrefix/';
  static const String updateProfile = '$profilePrefix/';
  
  // Insights endpoints
  static const String getInsights = '$insightsPrefix/insights/';
  static const String insightsRestDays = '$insightsPrefix/insights/rest-days/';
  
  // Quests endpoints
  static const String getStreak = '$questsPrefix/streak/';

  // Support endpoints
  static const String supportMessages = '/api/support/messages/';

  // Subscription endpoints (baseUrl / Django). Backend is the source of truth for the
  // decreasing-price-then-free lifecycle. See Apps.subscriptions.
  static const String subscriptionPlan = '/api/subscriptions/plan/';
  static const String subscriptionMe = '/api/subscriptions/me/';
  static const String subscriptionStartTrial = '/api/subscriptions/start-trial/';
  static const String subscriptionActivate = '/api/subscriptions/activate/';
  static const String subscriptionCancel = '/api/subscriptions/cancel/';

  // AI voice-call limit endpoints (use baseUrl / Django — the authority for the
  // per-user daily limit). See Apps.voice_calls on the backend.
  static const String voiceCallQuota = '/api/voice-calls/quota/';
  static const String voiceCallStart = '/api/voice-calls/start/';
  static String voiceCallEnd(int id) => '/api/voice-calls/$id/end/';
  // Persist a finished call's conversational summary (per user) + list saved summaries.
  static String voiceCallSummary(int id) => '/api/voice-calls/$id/summary/';
  static const String voiceCallSummaries = '/api/voice-calls/summaries/';
  // Calls the user planned via a quest's "Enable call" toggle. These are plans, not
  // bookings — they never reserve one of the two daily calls.
  static const String scheduledCalls = '/api/voice-calls/scheduled/';
  static String scheduledCall(int id) => '/api/voice-calls/scheduled/$id/';
  
  // AI Call endpoints (use aiBaseUrl)
  static const String createSession = '$aiCallPrefix/session/new';
  static const String chatStream = '$aiCallPrefix/chat-stream';
  // 5-category Top-Emotion breakdown for a finished session (used by Insights).
  static String aiEmotionBreakdown(String sessionId) =>
      '$aiCallPrefix/conversation/emotion-breakdown/$sessionId';
  // One GPT-free call at call end: both the emotion breakdown AND the low-mood phrases.
  static String aiCallInsights(String sessionId) =>
      '$aiCallPrefix/conversation/call-insights/$sessionId';
  
  // Google Sign-In server/web client id — becomes the `id_token` audience the backend
  // verifies. Pass at build/run time (same as the base URLs):
  //   --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  // Sign in with Apple — only needed for the WEB / ANDROID web-redirect flow (iOS native
  // needs neither). Leave empty until Apple is configured.
  //   APPLE_SERVICE_ID   = the Apple "Services ID" (also add it to APPLE_CLIENT_IDS on the backend)
  //   APPLE_REDIRECT_URI = the https return URL registered with that Services ID
  static const String appleServiceId = String.fromEnvironment(
    'APPLE_SERVICE_ID',
    defaultValue: '',
  );
  static const String appleRedirectUri = String.fromEnvironment(
    'APPLE_REDIRECT_URI',
    defaultValue: '',
  );

  // Headers
  static const String contentType = 'application/json';
  static const String accept = 'application/json';
}
