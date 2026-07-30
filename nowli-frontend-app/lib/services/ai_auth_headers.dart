import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/api/storage.dart';

/// Headers for every call to the nowli-ai service (`aiBaseUrl`, :8001).
///
/// That service mints OpenAI Realtime keys and runs paid model calls, so as of
/// 2026-07-30 it rejects unauthenticated `/api/v1/` requests with 401. It verifies the
/// same Django access token the app already stores — no second credential.
///
/// The token is attached best-effort: if none is stored yet the header is simply
/// omitted, so the request fails with a clean 401 rather than a crash.
Future<Map<String, String>> aiAuthHeaders({bool json = true}) async {
  final headers = <String, String>{
    if (json) 'Content-Type': ApiConstants.contentType,
    'Accept': ApiConstants.accept,
    'ngrok-skip-browser-warning': 'true',
  };

  final token = await SecureStorage.getAccessToken();
  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }

  return headers;
}
