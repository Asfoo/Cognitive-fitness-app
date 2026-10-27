import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/utils/stats.dart';
import '../../models/math_problem.dart';
import '../../models/stimulus.dart';
import '../../models/test_result.dart';
import '../../models/test_type.dart';
import '../../services/beep_player.dart';
import 'test_session_controller.dart';

enum BiofeedbackPhase { ready, running, answering, done }

/// Math task with periodic cues that must be answered (or withheld) in a time window.
abstract class BiofeedbackTestController extends TestSessionController {
  BiofeedbackTestController(
    super.results, {
    super.random,
    this.stimulusCount = 5,
    this.responseWindow = const Duration(milliseconds: 1800),
  });

  final int stimulusCount;
  final Duration responseWindow;

  final _stimulusClock = Stopwatch();
  final List<int> _responseTimes = [];
  Timer? _gapTimer;
  Timer? _windowTimer;
  BiofeedbackPhase _phase = BiofeedbackPhase.ready;
  MathProblem? _problem;
  StimulusKind? _active;
  int _presented = 0;
  int _errors = 0;
  bool? _lastCorrect;
  int _responseCount = 0;

  TestType get type;

  @protected
  StimulusKind nextStimulus();

  @protected
  void onStimulusShown(StimulusKind stimulus) {}

  BiofeedbackPhase get phase => _phase;
  MathProblem? get problem => _problem;
  StimulusKind? get activeStimulus => _active;
  int get presented => _presented;
  int get errors => _errors;

  /// Outcome of the most recent cue; [responseCount] changes with each one.
  bool? get lastCorrect => _lastCorrect;
  int get responseCount => _responseCount;

  bool get canSubmit => _phase == BiofeedbackPhase.running || _phase == BiofeedbackPhase.answering;

  void start() {
    if (_phase != BiofeedbackPhase.ready) return;
    _problem = MathProblem.random(random, maxA: 30);
    _phase = BiofeedbackPhase.running;
    sessionClock.start();
    _scheduleNext();
    notify();
  }

  void respond(ResponseKind response) {
    if (_phase != BiofeedbackPhase.running) return;
    final stimulus = _active;
    if (stimulus == null) {
      _record(correct: false);
      notify();
      return;
    }
    final correct = stimulus.expected == response;
    if (correct) _responseTimes.add(_stimulusClock.elapsedMilliseconds);
    _resolve(correct: correct);
  }

  void submit(String raw) {
    if (!canSubmit) return;
    _phase = BiofeedbackPhase.done;
    _active = null;
    notify();
    complete(TestResult(
      type: type,
      timestamp: DateTime.now(),
      durationMs: sessionClock.elapsedMilliseconds,
      reactionMs: mean(_responseTimes),
      variabilityMs: standardDeviation(_responseTimes),
      errors: _errors,
      attempts: _presented,
      mathAnswer: int.tryParse(raw.trim()),
      correctAnswer: _problem!.answer,
    ));
  }

  void _scheduleNext() {
    if (_presented >= stimulusCount) {
      _phase = BiofeedbackPhase.answering;
      return;
    }
    _gapTimer = Timer(Duration(milliseconds: 1200 + random.nextInt(1800)), _present);
  }

  void _present() {
    final stimulus = nextStimulus();
    _active = stimulus;
    _presented++;
    _stimulusClock
      ..reset()
      ..start();
    onStimulusShown(stimulus);
    _windowTimer = Timer(responseWindow, () => _resolve(correct: stimulus.expected == null));
    notify();
  }

  void _resolve({required bool correct}) {
    _windowTimer?.cancel();
    _stimulusClock.stop();
    _active = null;
    _record(correct: correct);
    _scheduleNext();
    notify();
  }

  void _record({required bool correct}) {
    if (!correct) _errors++;
    _lastCorrect = correct;
    _responseCount++;
  }

  @override
  void cancelTimers() {
    _gapTimer?.cancel();
    _windowTimer?.cancel();
  }
}

/// High beep → left, low beep → right.
class AuditoryTestController extends BiofeedbackTestController {
  AuditoryTestController(super.results, this._player, {super.random});

  final BeepPlayer _player;

  @override
  TestType get type => TestType.auditory;

  @override
  StimulusKind nextStimulus() => random.nextBool() ? StimulusKind.highPitch : StimulusKind.lowPitch;

  @override
  void onStimulusShown(StimulusKind stimulus) => _player.play(high: stimulus == StimulusKind.highPitch);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

/// Green → tap, red → withhold.
class VisualTestController extends BiofeedbackTestController {
  VisualTestController(super.results, {super.random});

  static const goProbability = 0.6;

  @override
  TestType get type => TestType.visual;

  @override
  StimulusKind nextStimulus() => random.nextDouble() < goProbability ? StimulusKind.go : StimulusKind.noGo;
}
