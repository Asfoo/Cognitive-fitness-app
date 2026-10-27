import 'package:cognitive_fitness_app/models/test_result.dart';
import 'package:cognitive_fitness_app/models/test_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime(2026, 10, 27, 9, 30);

  test('map round trip preserves every field', () {
    final original = TestResult(
      id: 7,
      type: TestType.auditory,
      timestamp: at,
      durationMs: 12345,
      reactionMs: 412.5,
      variabilityMs: 40.2,
      errors: 1,
      attempts: 5,
      mathAnswer: 21,
      correctAnswer: 21,
    );
    final restored = TestResult.fromMap(original.toMap());

    expect(restored.id, 7);
    expect(restored.type, TestType.auditory);
    expect(restored.timestamp, at);
    expect(restored.durationMs, 12345);
    expect(restored.reactionMs, 412.5);
    expect(restored.variabilityMs, 40.2);
    expect(restored.errors, 1);
    expect(restored.attempts, 5);
    expect(restored.isMathCorrect, isTrue);
  });

  test('accuracy counts errors and a wrong math answer', () {
    final result = TestResult(
      type: TestType.dual,
      timestamp: at,
      durationMs: 0,
      errors: 1,
      attempts: 3,
      mathAnswer: 10,
      correctAnswer: 12,
    );
    expect(result.accuracy, 0.5); // 2 of 4 correct
  });

  test('score rewards fast, accurate sessions', () {
    TestResult withReaction(double ms) =>
        TestResult(type: TestType.single, timestamp: at, durationMs: 0, reactionMs: ms, attempts: 3);

    expect(withReaction(TestResult.fastMs).score, 100);
    expect(withReaction(TestResult.slowMs).score, 40);
    expect(withReaction(250).score, greaterThan(withReaction(600).score));
  });

  test('unknown test keys fall back to single', () {
    expect(TestType.fromKey('Legacy'), TestType.single);
    expect(TestType.fromKey('VisualBio'), TestType.visual);
  });
}
