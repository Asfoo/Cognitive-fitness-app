import 'package:flutter/foundation.dart';

import '../models/summaries.dart';
import '../models/test_type.dart';
import '../services/analytics_service.dart';
import 'results_controller.dart';
import 'settings_controller.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(
    this._results,
    this._settings, {
    AnalyticsService analytics = const AnalyticsService(),
    DateTime Function() clock = DateTime.now,
  })  : _analytics = analytics,
        _clock = clock {
    _results.addListener(_recompute);
    _settings.addListener(_recompute);
    _recompute();
  }

  final ResultsController _results;
  final SettingsController _settings;
  final AnalyticsService _analytics;
  final DateTime Function() _clock;

  late DashboardSummary _summary;
  late TestType _suggestedTest;

  DashboardSummary get summary => _summary;

  /// The test to launch from the quick-start button.
  TestType get suggestedTest => _suggestedTest;

  DateTime get today => _clock();

  String get greeting {
    if (_summary.testsToday == 0) return "Let's start\nstrong!";
    if (_summary.goalProgress < 1) return 'Keep the\nmomentum!';
    return 'Goal smashed\ntoday!';
  }

  void _recompute() {
    final now = _clock();
    _summary = _analytics.dashboard(_results.results, _settings.settings, now);
    _suggestedTest = _analytics.leastPracticed(_results.results, now);
    notifyListeners();
  }

  @override
  void dispose() {
    _results.removeListener(_recompute);
    _settings.removeListener(_recompute);
    super.dispose();
  }
}
