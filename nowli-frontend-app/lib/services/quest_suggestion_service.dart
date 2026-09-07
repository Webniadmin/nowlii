import 'dart:convert';
import 'package:nowlii/api/session.dart';
import 'package:http/http.dart' as http;
import 'package:nowlii/models/quest_suggestion_model.dart';
import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/services/subscription_service.dart';

class QuestSuggestionService {
  // Helper to print long strings in chunks
  void _printLongString(String text) {
    final pattern = RegExp('.{1,800}'); // 800 chars per line
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  // Get quest suggestions from API.
  //
  // They come from the Insights endpoint: the AI writes the week's reflections and its
  // quest suggestions in the same pass and caches them together, so there is no separate
  // suggestions route to call. This asked `/api/v1/quests/suggestions`, which has never
  // existed on the Django side, and sent no token either -- so every response was a 404
  // (or a 401 if the path had been right), the screen caught the null and drew its empty
  // state, and the AI suggestions simply looked like they did not work.
  Future<QuestSuggestionResponse?> getQuestSuggestions() async {
    try {
      final token = await Session.accessToken();
      if (token == null) {
        print('No auth token found - cannot load quest suggestions');
        return null;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getInsights}');
      
      print('\n========== QUEST SUGGESTIONS API ==========');
      print('🌐 URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body:');
      _printLongString(response.body);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final parsed = QuestSuggestionResponse.fromJson(jsonData);
        print('✅ Quest suggestions received: ${parsed.weekly.questSuggestions.length} suggestions');
        print('==========================================\n');
        return parsed;
      } else {
        if (response.statusCode == 401) await Session.reportUnauthorized();
        // 402 = free trial over / not subscribed. Same endpoint as Insights, so the same
        // rule: flip the cached entitlement and let the next navigation hit the paywall.
        if (response.statusCode == 402) {
          await SubscriptionService.markAccessRevoked();
        }
        print('❌ Failed to fetch quest suggestions: ${response.statusCode}');
        print('==========================================\n');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching quest suggestions: $e');
      print('==========================================\n');
      return null;
    }
  }
}
