// Session Model
class AiSession {
  final String sessionId;
  final String userName;
  final String systemName;
  final String language;
  final String languageName;
  final double createdAt;

  AiSession({
    required this.sessionId,
    required this.userName,
    required this.systemName,
    required this.language,
    required this.languageName,
    required this.createdAt,
  });

  factory AiSession.fromJson(Map<String, dynamic> json) {
    return AiSession(
      sessionId: json['session_id'] ?? '',
      userName: json['user_name'] ?? '',
      systemName: json['system_name'] ?? '',
      language: json['language'] ?? '',
      languageName: json['language_name'] ?? '',
      createdAt: (json['created_at'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'user_name': userName,
      'system_name': systemName,
      'language': language,
      'language_name': languageName,
      'created_at': createdAt,
    };
  }
}

// Emotion Model
class EmotionData {
  final String name;
  final String emotionKey;
  final double score;
  final String source;
  final List<EmotionScore> allScores;
  final int turn;
  final String userName;
  final String systemName;
  final String language;
  final String languageName;

  EmotionData({
    required this.name,
    required this.emotionKey,
    required this.score,
    required this.source,
    required this.allScores,
    required this.turn,
    required this.userName,
    required this.systemName,
    required this.language,
    required this.languageName,
  });

  factory EmotionData.fromJson(Map<String, dynamic> json) {
    return EmotionData(
      name: json['name'] ?? '',
      emotionKey: json['emotion_key'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
      source: json['source'] ?? '',
      allScores: (json['all_scores'] as List?)
              ?.map((e) => EmotionScore.fromJson(e))
              .toList() ??
          [],
      turn: json['turn'] ?? 0,
      userName: json['user_name'] ?? '',
      systemName: json['system_name'] ?? '',
      language: json['language'] ?? '',
      languageName: json['language_name'] ?? '',
    );
  }
}

class EmotionScore {
  final String name;
  final double score;

  EmotionScore({
    required this.name,
    required this.score,
  });

  factory EmotionScore.fromJson(Map<String, dynamic> json) {
    return EmotionScore(
      name: json['name'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
    );
  }
}

// Stream Event Types
enum StreamEventType {
  emotion,
  word,
  done,
}

class StreamEvent {
  final StreamEventType type;
  final dynamic data;

  StreamEvent({
    required this.type,
    required this.data,
  });
}

// Done Event Data
class DoneEventData {
  final int turn;
  final int words;
  final String language;
  final String emotionKey;

  DoneEventData({
    required this.turn,
    required this.words,
    required this.language,
    required this.emotionKey,
  });

  factory DoneEventData.fromJson(Map<String, dynamic> json) {
    return DoneEventData(
      turn: json['turn'] ?? 0,
      words: json['words'] ?? 0,
      language: json['language'] ?? '',
      emotionKey: json['emotion_key'] ?? '',
    );
  }
}
