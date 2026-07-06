import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../api/api_constant.dart';

class Subtask {
  final int id;
  final String title;
  final bool taskDone;

  Subtask({
    required this.id,
    required this.title,
    required this.taskDone,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'],
      title: json['title'],
      taskDone: json['task_done'],
    );
  }
}

class Quest {
  final int id;
  final List<Subtask> subtasks;
  final String task;
  final String zone;
  final String selectADate;
  final String? selectATime; // Add time field
  final bool enableCall;
  final bool repeatQuest;
  final bool setAlarm;
  bool taskDone;

  Quest({
    required this.id,
    required this.subtasks,
    required this.task,
    required this.zone,
    required this.selectADate,
    this.selectATime, // Add time parameter
    required this.enableCall,
    required this.repeatQuest,
    required this.setAlarm,
    required this.taskDone,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      subtasks: (json['subtasks'] as List)
          .map((subtask) => Subtask.fromJson(subtask))
          .toList(),
      task: json['task'],
      zone: json['zone'],
      selectADate: json['select_a_date'],
      selectATime: json['select_a_time'], // Parse time from JSON
      enableCall: json['enable_call'],
      repeatQuest: json['repeat_quest'],
      setAlarm: json['set_alarm'],
      taskDone: json['task_done'],
    );
  }
}

class QuestService {
  static String get baseUrl => '${ApiConstants.baseUrl}/api';

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  Future<List<Quest>> fetchQuestsByDate(DateTime date) async {
    try {
      final token = await _getToken();
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final url = '$baseUrl/quests/?due_date=$formattedDate';

      print('\n========== FETCH QUESTS BY DATE ==========');
      print('🌐 URL: $url');
      print('📅 Date: $formattedDate');
      print('🔑 Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      print('==========================================\n');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Parsed ${data.length} quests');
        return data.map((quest) => Quest.fromJson(quest)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching quests: $e');
      return [];
    }
  }

  Future<List<Quest>> fetchTodayQuests() async {
    return fetchQuestsByDate(DateTime.now());
  }

  Future<List<Quest>> fetchAllQuests() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/quests/'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((quest) => Quest.fromJson(quest)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching all quests: $e');
      return [];
    }
  }

  Future<bool> updateQuestStatus(int questId, bool taskDone) async {
    try {
      final token = await _getToken();

      final response = await http.patch(
        Uri.parse('$baseUrl/quests/$questId/'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode({'task_done': taskDone}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating quest status: $e');
      return false;
    }
  }

  Future<bool> deleteQuest(int questId) async {
    try {
      final token = await _getToken();

      final response = await http.delete(
        Uri.parse('$baseUrl/quests/$questId/'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Error deleting quest: $e');
      return false;
    }
  }

  Future<bool> updateQuestDate(int questId, String newDate) async {
    try {
      final token = await _getToken();

      final response = await http.patch(
        Uri.parse('$baseUrl/quests/$questId/'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode({'select_a_date': newDate}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating quest date: $e');
      return false;
    }
  }

  Future<Quest?> createQuest({
    required String task,
    required String zone,
    required String selectADate,
    String? selectATime, // Add time parameter
    required bool enableCall,
    required bool repeatQuest,
    required bool setAlarm,
    List<Map<String, dynamic>>? subtasks,
  }) async {
    try {
      final token = await _getToken();

      final body = {
        'task': task,
        'zone': zone,
        'select_a_date': selectADate,
        if (selectATime != null) 'select_a_time': selectATime, // Add time to body
        'enable_call': enableCall,
        'repeat_quest': repeatQuest,
        'set_alarm': setAlarm,
        'task_done': false,
        if (subtasks != null && subtasks.isNotEmpty) 'subtasks': subtasks,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/quests/'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Quest.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error creating quest: $e');
      return null;
    }
  }

  Future<Quest?> updateQuest({
    required int questId,
    String? task,
    String? zone,
    String? selectADate,
    String? selectATime, // Add time parameter
    bool? enableCall,
    bool? repeatQuest,
    bool? setAlarm,
    bool? taskDone,
    List<Map<String, dynamic>>? subtasks,
  }) async {
    try {
      final token = await _getToken();

      final body = <String, dynamic>{};
      if (task != null) body['task'] = task;
      if (zone != null) body['zone'] = zone;
      if (selectADate != null) body['select_a_date'] = selectADate;
      if (selectATime != null) body['select_a_time'] = selectATime; // Add time to body
      if (enableCall != null) body['enable_call'] = enableCall;
      if (repeatQuest != null) body['repeat_quest'] = repeatQuest;
      if (setAlarm != null) body['set_alarm'] = setAlarm;
      if (taskDone != null) body['task_done'] = taskDone;
      if (subtasks != null) body['subtasks'] = subtasks;

      final response = await http.patch(
        Uri.parse('$baseUrl/quests/$questId/'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Quest.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error updating quest: $e');
      return null;
    }
  }
}
