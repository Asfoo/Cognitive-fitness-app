import '../../core/utils/stats.dart';
import '../../models/math_problem.dart';
import '../../models/test_result.dart';
import '../../models/test_type.dart';
import 'test_session_controller.dart';

enum TappingPhase { ready, running, done }

/// Hit a target that jumps after every tap, exactly [requiredTaps] times, while solving a sum.
class TappingTestController extends TestSessionController {
  TappingTestController(super.results, {super.random});

  final List<int> _tapTimes = [];
  TappingPhase _phase = TappingPhase.ready;
  MathProblem? _problem;
  int _requiredTaps = 0;
  double _targetX = 0;
  double _targetY = 0;

  TappingPhase get phase => _phase;
  MathProblem? get problem => _problem;
  int get requiredTaps => _requiredTaps;
  int get taps => _tapTimes.length;

  /// Target position in alignment units (-1…1 on both axes).
  double get targetX => _targetX;
  double get targetY => _targetY;

  void start() {
    if (_phase != TappingPhase.ready) return;
    _problem = MathProblem.random(random, maxA: 50);
    _requiredTaps = 3 + random.nextInt(4);
    _phase = TappingPhase.running;
    sessionClock.start();
    _moveTarget();
    notify();
  }

  void tapTarget() {
    if (_phase != TappingPhase.running) return;
    _tapTimes.add(sessionClock.elapsedMilliseconds);
    _moveTarget();
    notify();
  }

  void submit(String raw) {
    if (_phase != TappingPhase.running) return;
    _phase = TappingPhase.done;
    notify();
    final intervals = [for (var i = 1; i < _tapTimes.length; i++) _tapTimes[i] - _tapTimes[i - 1]];
    complete(TestResult(
      type: TestType.tapping,
      timestamp: DateTime.now(),
      durationMs: sessionClock.elapsedMilliseconds,
      tapIntervalMs: mean(intervals),
      variabilityMs: standardDeviation(intervals),
      errors: (taps - _requiredTaps).abs(),
      attempts: _requiredTaps,
      mathAnswer: int.tryParse(raw.trim()),
      correctAnswer: _problem!.answer,
    ));
  }

  void _moveTarget() {
    _targetX = random.nextDouble() * 1.6 - 0.8;
    _targetY = random.nextDouble() * 1.6 - 0.8;
  }

  @override
  void cancelTimers() {}
}
