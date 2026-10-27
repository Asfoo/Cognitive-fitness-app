import '../core/utils/formatters.dart';
import '../core/utils/stats.dart';
import '../models/app_settings.dart';
import '../models/report_period.dart';
import '../models/summaries.dart';
import '../models/test_result.dart';
import '../models/test_type.dart';

/// Pure aggregation of session history into dashboard and report figures.
class AnalyticsService {
  const AnalyticsService();

  static const _tips = [
    'Short daily sessions sharpen focus more than occasional long ones.',
    'Stretching after workouts improves sleep quality, and good sleep speeds up reactions.',
    'Dual-task training builds the split attention you rely on while driving.',
    'Hydration matters: even mild dehydration slows reaction time.',
  ];

  DashboardSummary dashboard(List<TestResult> results, AppSettings settings, DateTime now) {
    final today = results.where((r) => r.timestamp.isSameDay(now)).toList();
    final recentWindow = results.where((r) => now.difference(r.timestamp) < const Duration(hours: 48)).take(3);

    return DashboardSummary(
      testsToday: today.length,
      dailyGoal: settings.dailyGoal,
      streakDays: streakDays(results, now),
      trainingToday: _totalDuration(today),
      recent: results.take(5).toList(),
      avgReactionMs: meanOfPresent(today.map((r) => r.reactionMs)),
      accuracy: mean(today.map((r) => r.accuracy)),
      readiness: mean(recentWindow.map((r) => r.score))?.round(),
    );
  }

  /// Consecutive training days ending today (or yesterday, until today is over).
  int streakDays(List<TestResult> results, DateTime now) {
    final days = results.map((r) => r.timestamp.startOfDay).toSet();
    var day = now.startOfDay;
    if (!days.contains(day)) day = day.addDays(-1);
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = day.addDays(-1);
    }
    return streak;
  }

  ReportSummary report(List<TestResult> results, ReportPeriod period, AppSettings settings, DateTime now) {
    final buckets = _buckets(period, now);
    final start = buckets.first.start;
    final end = buckets.last.end;
    final current = _between(results, start, end);
    final previous = _between(results, start.addDays(-period.days), start);

    final avgReaction = meanOfPresent(current.map((r) => r.reactionMs));
    final previousReaction = meanOfPresent(previous.map((r) => r.reactionMs));
    final reactionChange =
        avgReaction != null && previousReaction != null ? (avgReaction - previousReaction) / previousReaction : null;
    final accuracy = mean(current.map((r) => r.accuracy)) ?? 0;

    return ReportSummary(
      period: period,
      results: current,
      trend: [
        for (final bucket in buckets) _trendPoint(bucket, _between(current, bucket.start, bucket.end)),
      ],
      breakdown: _breakdown(current),
      accuracy: accuracy,
      goalTests: settings.dailyGoal * period.days,
      trainingTime: _totalDuration(current),
      avgReactionMs: avgReaction,
      bestReactionMs: bestReaction(current),
      consistencyMs: meanOfPresent(current.map((r) => r.variabilityMs)),
      avgScore: mean(current.map((r) => r.score)),
      reactionChange: reactionChange,
      insight: _insight(
        period: period,
        settings: settings,
        now: now,
        isEmpty: current.isEmpty,
        accuracy: accuracy,
        avgReaction: avgReaction,
        reactionChange: reactionChange,
      ),
    );
  }

  /// Fastest mean reaction among [results], or null if none were timed.
  double? bestReaction(Iterable<TestResult> results) {
    final times = results.map((r) => r.reactionMs).whereType<double>();
    return times.isEmpty ? null : times.reduce((a, b) => a < b ? a : b);
  }

  /// How [result] compares with earlier sessions of the same test.
  ResultComparison compare(TestResult result, List<TestResult> history) {
    final previous = history.where((r) => r.type == result.type && r.id != result.id).toList();
    return ResultComparison(
      previousSessions: previous.length,
      avgScore: mean(previous.map((r) => r.score)),
      avgReactionMs: meanOfPresent(previous.map((r) => r.reactionMs)),
    );
  }

  /// The test practiced least over the past two weeks (ties go to the simpler test).
  TestType leastPracticed(List<TestResult> results, DateTime now) {
    final since = now.startOfDay.addDays(-13);
    final counts = {for (final type in TestType.values) type: 0};
    for (final r in results.where((r) => !r.timestamp.isBefore(since))) {
      counts[r.type] = counts[r.type]! + 1;
    }
    return TestType.values.reduce((a, b) => counts[b]! < counts[a]! ? b : a);
  }

  List<TestResult> _between(List<TestResult> results, DateTime start, DateTime end) {
    return results.where((r) => !r.timestamp.isBefore(start) && r.timestamp.isBefore(end)).toList();
  }

  Duration _totalDuration(Iterable<TestResult> results) {
    return Duration(milliseconds: results.fold(0, (sum, r) => sum + r.durationMs));
  }

  List<_Bucket> _buckets(ReportPeriod period, DateTime now) {
    final today = now.startOfDay;
    if (period == ReportPeriod.daily) {
      return [
        for (var hour = 0; hour < 24; hour += 3)
          _Bucket(
            DateTime(today.year, today.month, today.day, hour),
            DateTime(today.year, today.month, today.day, hour + 3),
            hour.toString().padLeft(2, '0'),
          ),
      ];
    }
    final first = today.addDays(1 - period.days);
    return [
      for (var i = 0; i < period.days; i++)
        _Bucket(
          first.addDays(i),
          first.addDays(i + 1),
          period == ReportPeriod.weekly ? first.addDays(i).weekdayShort : '${first.addDays(i).day}',
        ),
    ];
  }

  TrendPoint _trendPoint(_Bucket bucket, List<TestResult> results) {
    return TrendPoint(
      label: bucket.label,
      start: bucket.start,
      count: results.length,
      avgReactionMs: meanOfPresent(results.map((r) => r.reactionMs)),
      avgScore: mean(results.map((r) => r.score)),
    );
  }

  List<TypeBreakdown> _breakdown(List<TestResult> results) {
    return TestType.values.map((type) {
      final ofType = results.where((r) => r.type == type);
      return TypeBreakdown(type: type, count: ofType.length, avgScore: mean(ofType.map((r) => r.score)));
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  Insight _insight({
    required ReportPeriod period,
    required AppSettings settings,
    required DateTime now,
    required bool isEmpty,
    required double accuracy,
    required double? avgReaction,
    required double? reactionChange,
  }) {
    if (isEmpty) {
      return Insight('No sessions this ${period.noun} yet. A 20-second reaction test is a great warm-up.');
    }
    if (reactionChange != null && reactionChange <= -0.05) {
      return Insight(
        'Your reactions are ${(reactionChange.abs() * 100).round()}% faster than last ${period.noun}. Keep it up!',
        tone: InsightTone.positive,
      );
    }
    if (reactionChange != null && reactionChange >= 0.05) {
      return Insight(
        'Reactions are ${(reactionChange * 100).round()}% slower than last ${period.noun}. Rest and hydration help recovery.',
        tone: InsightTone.warning,
      );
    }
    if (accuracy < 0.7) {
      return Insight(
        'Accuracy is at ${(accuracy * 100).round()}%. Slow down slightly: precision builds speed.',
        tone: InsightTone.warning,
      );
    }
    if (avgReaction != null && avgReaction <= settings.reactionTargetMs) {
      return Insight(
        "You're beating your ${settings.reactionTargetMs} ms target. Try a dual-task test to raise the challenge.",
        tone: InsightTone.positive,
      );
    }
    return Insight(_tips[now.day % _tips.length]);
  }
}

class _Bucket {
  const _Bucket(this.start, this.end, this.label);

  final DateTime start;
  final DateTime end;
  final String label;
}
