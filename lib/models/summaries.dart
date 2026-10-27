import 'report_period.dart';
import 'test_result.dart';
import 'test_type.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.testsToday,
    required this.dailyGoal,
    required this.streakDays,
    required this.trainingToday,
    required this.recent,
    this.avgReactionMs,
    this.accuracy,
    this.readiness,
  });

  final int testsToday;
  final int dailyGoal;
  final int streakDays;
  final Duration trainingToday;
  final List<TestResult> recent;
  final double? avgReactionMs;
  final double? accuracy;

  /// Average score of the latest sessions in the last 48 hours.
  final int? readiness;

  double get goalProgress => (testsToday / dailyGoal).clamp(0.0, 1.0);
}

class TrendPoint {
  const TrendPoint({required this.label, required this.start, required this.count, this.avgReactionMs, this.avgScore});

  final String label;
  final DateTime start;
  final int count;
  final double? avgReactionMs;
  final double? avgScore;
}

class TypeBreakdown {
  const TypeBreakdown({required this.type, required this.count, this.avgScore});

  final TestType type;
  final int count;
  final double? avgScore;
}

enum InsightTone { positive, neutral, warning }

class Insight {
  const Insight(this.message, {this.tone = InsightTone.neutral});

  final String message;
  final InsightTone tone;
}

class ReportSummary {
  const ReportSummary({
    required this.period,
    required this.results,
    required this.trend,
    required this.breakdown,
    required this.accuracy,
    required this.goalTests,
    required this.trainingTime,
    required this.insight,
    this.avgReactionMs,
    this.bestReactionMs,
    this.consistencyMs,
    this.avgScore,
    this.reactionChange,
  });

  final ReportPeriod period;

  /// Sessions inside the period, newest first.
  final List<TestResult> results;
  final List<TrendPoint> trend;
  final List<TypeBreakdown> breakdown;
  final double accuracy;
  final int goalTests;
  final Duration trainingTime;
  final Insight insight;
  final double? avgReactionMs;
  final double? bestReactionMs;
  final double? consistencyMs;
  final double? avgScore;

  /// Relative change of mean reaction time vs the previous period (negative = faster).
  final double? reactionChange;

  int get totalTests => results.length;

  int get totalErrors => results.fold(0, (sum, r) => sum + r.errors);

  bool get isEmpty => results.isEmpty;

  double get goalProgress => goalTests == 0 ? 0 : (totalTests / goalTests).clamp(0.0, 1.0);
}

class ResultComparison {
  const ResultComparison({required this.previousSessions, this.avgScore, this.avgReactionMs});

  final int previousSessions;
  final double? avgScore;
  final double? avgReactionMs;
}
