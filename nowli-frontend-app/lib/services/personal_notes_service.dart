import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A single user-authored note shown on the Insights screen.
class PersonalNote {
  final String id;
  final String text;

  const PersonalNote({required this.id, required this.text});

  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  factory PersonalNote.fromJson(Map<String, dynamic> json) => PersonalNote(
        id: json['id']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
      );
}

/// Per-user, locally-persisted personal notes (SharedPreferences — the app's existing
/// local storage layer). Notes are scoped by the stored `user_id`, so different accounts
/// on the same device keep separate notes.
class PersonalNotesService {
  static const String _userIdKey = 'user_id';

  Future<String> _keyForUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);
    return 'personal_notes_${userId ?? 'guest'}';
  }

  Future<List<PersonalNote>> getNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(await _keyForUser());
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => PersonalNote.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getNotes error: $e');
      return [];
    }
  }

  Future<List<PersonalNote>> _save(List<PersonalNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      await _keyForUser(),
      jsonEncode(notes.map((n) => n.toJson()).toList()),
    );
    return notes;
  }

  /// Add a note (no-op on empty text). Returns the updated list.
  Future<List<PersonalNote>> addNote(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return getNotes();
    final notes = await getNotes();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    notes.add(PersonalNote(id: id, text: trimmed));
    return _save(notes);
  }

  /// Delete a note by id. Returns the updated list.
  Future<List<PersonalNote>> deleteNote(String id) async {
    final notes = await getNotes();
    notes.removeWhere((n) => n.id == id);
    return _save(notes);
  }
}
