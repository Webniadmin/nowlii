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
  
  // Profile endpoints
  static const String createProfile = '$profilePrefix/';
  static const String getProfile = '$profilePrefix/';
  static const String updateProfile = '$profilePrefix/';
  
  // Insights endpoints
  static const String getInsights = '$insightsPrefix/insights/';
  
  // Quests endpoints
  static const String getStreak = '$questsPrefix/streak/';

  // Support endpoints
  static const String supportMessages = '/api/support/messages/';
  
  // AI Call endpoints (use aiBaseUrl)
  static const String createSession = '$aiCallPrefix/session/new';
  static const String chatStream = '$aiCallPrefix/chat-stream';
  
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
