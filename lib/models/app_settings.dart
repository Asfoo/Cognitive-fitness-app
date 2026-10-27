class AppSettings {
  const AppSettings({this.dailyGoal = 5, this.reactionTargetMs = 400});

  static const minGoal = 1;
  static const maxGoal = 20;
  static const minTargetMs = 200;
  static const maxTargetMs = 800;

  /// Number of tests to complete per day.
  final int dailyGoal;

  /// Personal reaction-time target in milliseconds.
  final int reactionTargetMs;

  AppSettings copyWith({int? dailyGoal, int? reactionTargetMs}) {
    return AppSettings(
      dailyGoal: (dailyGoal ?? this.dailyGoal).clamp(minGoal, maxGoal),
      reactionTargetMs: (reactionTargetMs ?? this.reactionTargetMs).clamp(minTargetMs, maxTargetMs),
    );
  }
}
