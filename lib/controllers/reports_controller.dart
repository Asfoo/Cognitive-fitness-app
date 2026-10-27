import 'package:flutter/foundation.dart';

import '../models/report_period.dart';
import '../models/summaries.dart';
import '../models/test_type.dart';
import '../services/analytics_service.dart';
import 'results_controller.dart';
import 'settings_controller.dart';

class ReportsController extends ChangeNotifier {
  ReportsController(
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

  static const collapsedHistoryLength = 6;

  final ResultsController _results;
  final SettingsController _settings;
  final AnalyticsService _analytics;
  final DateTime Function() _clock;

  ReportPeriod _period = ReportPeriod.weekly;
  bool _insightDismissed = false;
  bool _historyExpanded = false;
  late ReportSummary _summary;

  ReportPeriod get period => _period;
  ReportSummary get summary => _summary;
  bool get showInsight => !_insightDismissed;
  bool get historyExpanded => _historyExpanded;
  int get reactionTargetMs => _settings.settings.reactionTargetMs;
  DateTime get now => _clock();

  TestType get suggestedTest => _analytics.leastPracticed(_results.results, _clock());

  void selectPeriod(ReportPeriod period) {
    if (period == _period) return;
    _period = period;
    _historyExpanded = false;
    _recompute();
  }

  void dismissInsight() {
    _insightDismissed = true;
    notifyListeners();
  }

  void toggleHistory() {
    _historyExpanded = !_historyExpanded;
    notifyListeners();
  }

  void _recompute() {
    _summary = _analytics.report(_results.results, _period, _settings.settings, _clock());
    notifyListeners();
  }

  @override
  void dispose() {
    _results.removeListener(_recompute);
    _settings.removeListener(_recompute);
    super.dispose();
  }
}
