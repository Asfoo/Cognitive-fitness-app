import 'dart:async';

import '../../core/utils/stats.dart';
import '../../models/math_problem.dart';
import '../../models/test_result.dart';
import '../../models/test_type.dart';
import 'test_session_controller.dart';

enum ReactionPhase { ready, waiting, signal, answering, done }

/// Single-task (reaction only) and dual-task (reaction + mental math) tests.
class ReactionTestController extends TestSessionController {
  ReactionTestController(super.results, {required this.type, super.random, this.trials = 3})
      : assert(type == TestType.single || type == TestType.dual);

  final TestType type;
  final int trials;

  final _signalClock = Stopwatch();
  final List<int> _reactionTimes = [];
  Timer? _signalTimer;
  ReactionPhase _phase = ReactionPhase.ready;
  MathProblem? _problem;
  int _falseStarts = 0;
  String? _feedback;

  ReactionPhase get phase => _phase;
  MathProblem? get problem => _problem;
  int get completedTrials => _reactionTimes.length;
  int get falseStarts => _falseStarts;
  bool get withMath => type == TestType.dual;

  /// Short message about the last tap ("312 ms", "Too early!").
  String? get feedback => _feedback;

  void start() {
    if (_phase != ReactionPhase.ready) return;
    if (withMath) _problem = MathProblem.random(random);
    sessionClock.start();
    _armSignal();
  }

  void tap() {
    switch (_phase) {
      case ReactionPhase.waiting:
        _falseStarts++;
        _feedback = 'Too early! Wait for the signal.';
        _signalTimer?.cancel();
        _armSignal();
      case ReactionPhase.signal:
        _signalClock.stop();
        _reactionTimes.add(_signalClock.elapsedMilliseconds);
        _feedback = '${_signalClock.elapsedMilliseconds} ms';
        if (completedTrials < trials) {
          _armSignal();
        } else if (withMath) {
          _phase = ReactionPhase.answering;
          notify();
        } else {
          _finish(null);
        }
      case ReactionPhase.ready || ReactionPhase.answering || ReactionPhase.done:
        break;
    }
  }

  void submitAnswer(String raw) {
    if (_phase != ReactionPhase.answering) return;
    _finish(int.tryParse(raw.trim()));
  }

  void _armSignal() {
    _phase = ReactionPhase.waiting;
    notify();
    _signalTimer = Timer(Duration(milliseconds: 1500 + random.nextInt(2500)), () {
      _phase = ReactionPhase.signal;
      _signalClock
        ..reset()
        ..start();
      notify();
    });
  }

  void _finish(int? answer) {
    _phase = ReactionPhase.done;
    notify();
    complete(TestResult(
      type: type,
      timestamp: DateTime.now(),
      durationMs: sessionClock.elapsedMilliseconds,
      reactionMs: mean(_reactionTimes),
      variabilityMs: standardDeviation(_reactionTimes),
      errors: _falseStarts,
      attempts: trials,
      mathAnswer: answer,
      correctAnswer: _problem?.answer,
    ));
  }

  @override
  void cancelTimers() => _signalTimer?.cancel();
}
