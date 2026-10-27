import 'dart:math';

import 'package:cognitive_fitness_app/controllers/results_controller.dart';
import 'package:cognitive_fitness_app/controllers/tests/biofeedback_test_controller.dart';
import 'package:cognitive_fitness_app/controllers/tests/reaction_test_controller.dart';
import 'package:cognitive_fitness_app/controllers/tests/tapping_test_controller.dart';
import 'package:cognitive_fitness_app/models/stimulus.dart';
import 'package:cognitive_fitness_app/models/test_type.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late ResultsController results;

  setUp(() => results = ResultsController(InMemoryResultRepository()));

  group('ReactionTestController', () {
    test('tapping before the signal is a false start', () {
      fakeAsync((async) {
        final controller = ReactionTestController(results, type: TestType.single, random: Random(1))..start();
        expect(controller.phase, ReactionPhase.waiting);

        controller.tap();
        expect(controller.falseStarts, 1);
        expect(controller.phase, ReactionPhase.waiting);
        controller.dispose();
      });
    });

    test('single task saves a result after all trials', () {
      fakeAsync((async) {
        final controller = ReactionTestController(results, type: TestType.single, random: Random(1), trials: 2)
          ..start();
        for (var i = 0; i < 2; i++) {
          async.elapse(const Duration(seconds: 5));
          expect(controller.phase, ReactionPhase.signal);
          controller.tap();
        }
        async.flushMicrotasks();

        expect(controller.result, isNotNull);
        expect(controller.result!.attempts, 2);
        expect(results.results, hasLength(1));
        controller.dispose();
      });
    });

    test('dual task waits for the math answer', () {
      fakeAsync((async) {
        final controller = ReactionTestController(results, type: TestType.dual, random: Random(2), trials: 1)
          ..start();
        async.elapse(const Duration(seconds: 5));
        controller.tap();
        expect(controller.phase, ReactionPhase.answering);

        controller.submitAnswer('${controller.problem!.answer}');
        async.flushMicrotasks();
        expect(controller.result!.isMathCorrect, isTrue);
        controller.dispose();
      });
    });
  });

  group('VisualTestController', () {
    test('missed go cues and taps without a cue count as errors', () {
      fakeAsync((async) {
        final controller = VisualTestController(results, random: Random(3))..start();
        controller.respond(ResponseKind.tap); // nothing shown yet
        expect(controller.errors, 1);

        while (controller.phase == BiofeedbackPhase.running) {
          async.elapse(const Duration(milliseconds: 100));
        }
        expect(controller.presented, controller.stimulusCount);
        expect(controller.phase, BiofeedbackPhase.answering);

        controller.submit('0');
        async.flushMicrotasks();
        final result = controller.result!;
        expect(result.attempts, controller.stimulusCount);
        expect(result.reactionMs, isNull); // never responded
        controller.dispose();
      });
    });

    test('correct responses record reaction times', () {
      fakeAsync((async) {
        final controller = VisualTestController(results, random: Random(4))..start();
        while (controller.phase == BiofeedbackPhase.running) {
          async.elapse(const Duration(milliseconds: 50));
          if (controller.activeStimulus == StimulusKind.go) controller.respond(ResponseKind.tap);
        }
        controller.submit('');
        async.flushMicrotasks();
        expect(controller.errors, 0);
        expect(controller.result!.reactionMs, isNotNull);
        controller.dispose();
      });
    });
  });

  test('TappingTestController scores tap-count mismatch as errors', () {
    fakeAsync((async) {
      final controller = TappingTestController(results, random: Random(5))..start();
      final required = controller.requiredTaps;
      for (var i = 0; i < required + 1; i++) {
        async.elapse(const Duration(milliseconds: 300));
        controller.tapTarget();
      }
      controller.submit('${controller.problem!.answer}');
      async.flushMicrotasks();

      final result = controller.result!;
      expect(result.errors, 1);
      expect(result.attempts, required);
      expect(result.isMathCorrect, isTrue);
      controller.dispose();
    });
  });
}
