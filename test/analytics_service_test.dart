import 'package:cognitive_fitness_app/models/app_settings.dart';
import 'package:cognitive_fitness_app/models/report_period.dart';
import 'package:cognitive_fitness_app/models/summaries.dart';
import 'package:cognitive_fitness_app/models/test_result.dart';
import 'package:cognitive_fitness_app/models/test_type.dart';
import 'package:cognitive_fitness_app/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const analytics = AnalyticsService();
  const settings = AppSettings(dailyGoal: 4, reactionTargetMs: 400);
  final now = DateTime(2026, 10, 27, 15);

  TestResult result(DateTime at, {double? reactionMs, TestType type = TestType.single, int errors = 0}) {
    return TestResult(
      type: type,
      timestamp: at,
      durationMs: 10000,
      reactionMs: reactionMs,
      errors: errors,
      attempts: 3,
    );
  }

  group('dashboard', () {
    test('counts only today towards the goal', () {
      final summary = analytics.dashboard([
        result(now.subtract(const Duration(hours: 1)), reactionMs: 300),
        result(now.subtract(const Duration(hours: 2)), reactionMs: 500),
        result(now.subtract(const Duration(days: 1)), reactionMs: 900),
      ], settings, now);

      expect(summary.testsToday, 2);
      expect(summary.goalProgress, 0.5);
      expect(summary.avgReactionMs, 400);
      expect(summary.trainingToday, const Duration(seconds: 20));
    });

    test('goal progress is capped at 100%', () {
      final summary = analytics.dashboard(
        List.generate(6, (i) => result(now.subtract(Duration(minutes: i)), reactionMs: 300)),
        settings,
        now,
      );
      expect(summary.goalProgress, 1);
    });
  });

  group('streakDays', () {
    test('counts consecutive days ending today', () {
      final results = [for (var d = 0; d < 3; d++) result(now.subtract(Duration(days: d)))];
      expect(analytics.streakDays(results, now), 3);
    });

    test('a streak ending yesterday is still alive', () {
      final results = [result(now.subtract(const Duration(days: 1))), result(now.subtract(const Duration(days: 2)))];
      expect(analytics.streakDays(results, now), 2);
    });

    test('a gap breaks the streak', () {
      expect(analytics.streakDays([result(now.subtract(const Duration(days: 3)))], now), 0);
    });
  });

  group('report', () {
    test('weekly report has seven buckets and filters to the period', () {
      final report = analytics.report([
        result(now, reactionMs: 300),
        result(now.subtract(const Duration(days: 6)), reactionMs: 500),
        result(now.subtract(const Duration(days: 8)), reactionMs: 700),
      ], ReportPeriod.weekly, settings, now);

      expect(report.trend, hasLength(7));
      expect(report.totalTests, 2);
      expect(report.goalTests, 28);
      expect(report.avgReactionMs, 400);
      expect(report.bestReactionMs, 300);
      expect(report.trend.last.count, 1);
    });

    test('daily report uses 3-hour buckets', () {
      final report = analytics.report([result(now, reactionMs: 300)], ReportPeriod.daily, settings, now);
      expect(report.trend, hasLength(8));
      expect(report.trend[5].count, 1); // 15:00 falls in the 15–18 bucket
    });

    test('reaction change compares with the previous period', () {
      final report = analytics.report([
        result(now, reactionMs: 360),
        result(now.subtract(const Duration(days: 9)), reactionMs: 400),
      ], ReportPeriod.weekly, settings, now);

      expect(report.reactionChange, closeTo(-0.1, 1e-9));
      expect(report.insight.tone, InsightTone.positive);
    });

    test('an empty period yields a neutral insight', () {
      final report = analytics.report(const [], ReportPeriod.monthly, settings, now);
      expect(report.isEmpty, isTrue);
      expect(report.trend, hasLength(30));
      expect(report.insight.tone, InsightTone.neutral);
    });
  });

  test('leastPracticed picks a test with no recent sessions', () {
    final results = [
      for (final type in TestType.values.where((t) => t != TestType.visual)) result(now, type: type),
    ];
    expect(analytics.leastPracticed(results, now), TestType.visual);
  });

  test('compare excludes the result itself', () {
    final current = result(now, reactionMs: 300).copyWith(id: 2);
    final earlier = result(now.subtract(const Duration(days: 1)), reactionMs: 500).copyWith(id: 1);
    final comparison = analytics.compare(current, [current, earlier]);
    expect(comparison.previousSessions, 1);
    expect(comparison.avgReactionMs, 500);
  });
}
