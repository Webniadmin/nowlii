import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nowlii/models/quest_suggestion_model.dart';
import 'package:nowlii/api/api_constant.dart';

class QuestSuggestionService {
  // Helper to print long strings in chunks
  void _printLongString(String text) {
    final pattern = RegExp('.{1,800}'); // 800 chars per line
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  // Get quest suggestions from API
  Future<QuestSuggestionResponse?> getQuestSuggestions() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/v1/quests/suggestions');
      
      print('\n========== QUEST SUGGESTIONS API ==========');
      print('🌐 URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body:');
      _printLongString(response.body);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Quest suggestions received: ${jsonData['weekly']['quest_suggestions'].length} suggestions');
        print('==========================================\n');
        return QuestSuggestionResponse.fromJson(jsonData);
      } else {
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
