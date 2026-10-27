import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../models/test_result.dart';
import '../results_controller.dart';

/// Shared lifecycle for a single test run: timing, persistence and safe disposal.
abstract class TestSessionController extends ChangeNotifier {
  TestSessionController(this._results, {Random? random}) : random = random ?? Random();

  final ResultsController _results;
  final Random random;

  /// Runs from start until the session is submitted.
  final Stopwatch sessionClock = Stopwatch();

  TestResult? _result;
  bool _disposed = false;

  /// Set once the session has been saved; views navigate to the result on it.
  TestResult? get result => _result;

  @protected
  Future<void> complete(TestResult result) async {
    cancelTimers();
    sessionClock.stop();
    final saved = await _results.save(result);
    if (_disposed) return;
    _result = saved;
    notifyListeners();
  }

  /// notifyListeners that is safe to call from timers after disposal.
  @protected
  void notify() {
    if (!_disposed) notifyListeners();
  }

  @protected
  void cancelTimers();

  @override
  void dispose() {
    _disposed = true;
    cancelTimers();
    super.dispose();
  }
}
