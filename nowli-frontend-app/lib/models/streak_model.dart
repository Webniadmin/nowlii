class StreakResponse {
  final int streak;

  StreakResponse({required this.streak});

  factory StreakResponse.fromJson(Map<String, dynamic> json) {
    return StreakResponse(
      streak: json['streak'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streak': streak,
    };
  }
}
