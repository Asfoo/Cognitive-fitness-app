import '../core/utils/formatters.dart';
import '../core/utils/stats.dart';
import '../models/app_settings.dart';
import '../models/coach_message.dart';
import '../models/report_period.dart';
import '../models/test_result.dart';
import '../models/test_type.dart';
import 'analytics_service.dart';

/// Answers coach questions from local session history.
class CoachService {
  const CoachService({this.analytics = const AnalyticsService()});

  final AnalyticsService analytics;

  CoachMessage answer(CoachTopic topic, List<TestResult> results, AppSettings settings, DateTime now) {
    return switch (topic) {
      CoachTopic.yesterday => _yesterday(results, now),
      CoachTopic.weekly => _weekly(results, settings, now),
      CoachTopic.bestTest => _bestTest(results),
      CoachTopic.streak => _streak(results, now),
      CoachTopic.nextStep => _nextStep(results, now),
    };
  }

  CoachMessage _yesterday(List<TestResult> results, DateTime now) {
    final yesterday = now.addDays(-1);
    final sessions = results.where((r) => r.timestamp.isSameDay(yesterday)).toList();
    if (sessions.isEmpty) {
      return CoachMessage.coach(
        "You didn't train yesterday. A quick test today keeps your rhythm going.",
        suggestedTest: TestType.single,
      );
    }
    final reaction = meanOfPresent(sessions.map((r) => r.reactionMs));
    final types = sessions.map((r) => r.type).toSet();
    return CoachMessage.coach(
      'You completed ${_plural(sessions.length, 'test')} across ${_plural(types.length, 'activity', 'activities')}'
      '${reaction == null ? '' : ' with a ${reaction.round()} ms average reaction'}.',
      stats: types.map((type) {
        final avg = mean(sessions.where((r) => r.type == type).map((r) => r.score))!;
        return CoachStat(label: type.shortTitle, value: '${avg.round()} pts', progress: avg / 100);
      }).toList(),
    );
  }

  CoachMessage _weekly(List<TestResult> results, AppSettings settings, DateTime now) {
    final report = analytics.report(results, ReportPeriod.weekly, settings, now);
    if (report.isEmpty) {
      return const CoachMessage.coach('No sessions this week yet. Start with a reaction test.', suggestedTest: TestType.single);
    }
    return CoachMessage.coach(
      '${report.insight.message} You logged ${_plural(report.totalTests, 'session')} this week.',
      stats: [
        CoachStat(label: 'Sessions', value: '${report.totalTests}/${report.goalTests}', progress: report.goalProgress),
        CoachStat(label: 'Accuracy', value: '${Format.percent(report.accuracy)}%', progress: report.accuracy),
        if (report.avgScore != null)
          CoachStat(label: 'Avg score', value: '${report.avgScore!.round()}', progress: report.avgScore! / 100),
      ],
    );
  }

  CoachMessage _bestTest(List<TestResult> results) {
    final scored = [
      for (final type in TestType.values)
        if (results.any((r) => r.type == type))
          (type: type, score: mean(results.where((r) => r.type == type).map((r) => r.score))!),
    ]..sort((a, b) => b.score.compareTo(a.score));
    if (scored.isEmpty) {
      return const CoachMessage.coach('Complete a few tests and I can tell you where you shine.', suggestedTest: TestType.single);
    }
    final best = scored.first;
    return CoachMessage.coach(
      'Your strongest test is ${best.type.title} with an average score of ${best.score.round()}.',
      stats: [
        for (final entry in scored.take(4))
          CoachStat(label: entry.type.shortTitle, value: '${entry.score.round()} pts', progress: entry.score / 100),
      ],
    );
  }

  CoachMessage _streak(List<TestResult> results, DateTime now) {
    final streak = analytics.streakDays(results, now);
    final best = analytics.bestReaction(results);
    return CoachMessage.coach(
      streak == 0
          ? 'No active streak. One test today starts a new one!'
          : "You're on a ${_plural(streak, 'day')} streak. Don't break the chain!",
      stats: [
        CoachStat(label: 'Streak', value: _plural(streak, 'day'), progress: (streak / 7).clamp(0.0, 1.0)),
        CoachStat(label: 'All sessions', value: '${results.length}'),
        if (best != null) CoachStat(label: 'Best reaction', value: '${best.round()} ms'),
      ],
      suggestedTest: streak == 0 ? TestType.single : null,
    );
  }

  CoachMessage _nextStep(List<TestResult> results, DateTime now) {
    final type = analytics.leastPracticed(results, now);
    return CoachMessage.coach(
      'Try the ${type.title} next. You have practiced it the least over the last two weeks.',
      suggestedTest: type,
    );
  }

  static String _plural(int count, String singular, [String? plural]) {
    return '$count ${count == 1 ? singular : plural ?? '${singular}s'}';
  }
}
