import 'test_type.dart';

/// One completed test session.
class TestResult {
  const TestResult({
    this.id,
    required this.type,
    required this.timestamp,
    required this.durationMs,
    this.reactionMs,
    this.variabilityMs,
    this.tapIntervalMs,
    this.errors = 0,
    this.attempts = 0,
    this.mathAnswer,
    this.correctAnswer,
  });

  /// Latency treated as "instant" / "too slow" when scoring speed.
  static const fastMs = 200.0;
  static const slowMs = 1200.0;

  final int? id;
  final TestType type;
  final DateTime timestamp;

  /// Total time from start to submission (the math-solving time in dual tasks).
  final int durationMs;

  /// Mean stimulus-to-response latency; null when no stimulus was answered.
  final double? reactionMs;

  /// Standard deviation of response latencies or tap intervals.
  final double? variabilityMs;

  /// Mean interval between taps (tapping test only).
  final double? tapIntervalMs;

  /// Wrong responses, misses, false starts or tap-count mismatch.
  final int errors;

  /// Stimuli presented, trials run or taps required.
  final int attempts;

  final int? mathAnswer;
  final int? correctAnswer;

  bool get hasMath => correctAnswer != null;

  bool get isMathCorrect => hasMath && mathAnswer == correctAnswer;

  /// Share of correct responses (including the math answer), 0–1.
  double get accuracy {
    final total = attempts + (hasMath ? 1 : 0);
    if (total == 0) return 1;
    final mistakes = errors.clamp(0, attempts) + (hasMath && !isMathCorrect ? 1 : 0);
    return (total - mistakes) / total;
  }

  /// Composite 0–100 score: 60% speed, 40% accuracy.
  int get score {
    final latency = reactionMs ?? tapIntervalMs;
    final speed = latency == null ? accuracy : (1 - (latency - fastMs) / (slowMs - fastMs)).clamp(0.0, 1.0);
    return ((speed * 0.6 + accuracy * 0.4) * 100).round();
  }

  Duration get duration => Duration(milliseconds: durationMs);

  TestResult copyWith({int? id}) {
    return TestResult(
      id: id ?? this.id,
      type: type,
      timestamp: timestamp,
      durationMs: durationMs,
      reactionMs: reactionMs,
      variabilityMs: variabilityMs,
      tapIntervalMs: tapIntervalMs,
      errors: errors,
      attempts: attempts,
      mathAnswer: mathAnswer,
      correctAnswer: correctAnswer,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'test_type': type.key,
      'timestamp': timestamp.toIso8601String(),
      'duration_ms': durationMs,
      'reaction_ms': reactionMs,
      'variability_ms': variabilityMs,
      'tap_interval_ms': tapIntervalMs,
      'errors': errors,
      'attempts': attempts,
      'math_answer': mathAnswer,
      'correct_answer': correctAnswer,
    };
  }

  factory TestResult.fromMap(Map<String, Object?> map) {
    return TestResult(
      id: map['id'] as int?,
      type: TestType.fromKey(map['test_type'] as String),
      timestamp: DateTime.parse(map['timestamp'] as String),
      durationMs: (map['duration_ms'] as num?)?.toInt() ?? 0,
      reactionMs: (map['reaction_ms'] as num?)?.toDouble(),
      variabilityMs: (map['variability_ms'] as num?)?.toDouble(),
      tapIntervalMs: (map['tap_interval_ms'] as num?)?.toDouble(),
      errors: (map['errors'] as num?)?.toInt() ?? 0,
      attempts: (map['attempts'] as num?)?.toInt() ?? 0,
      mathAnswer: (map['math_answer'] as num?)?.toInt(),
      correctAnswer: (map['correct_answer'] as num?)?.toInt(),
    );
  }
}
