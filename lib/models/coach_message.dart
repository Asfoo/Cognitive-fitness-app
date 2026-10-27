import 'test_type.dart';

enum CoachTopic {
  yesterday('How did I do yesterday?'),
  weekly('How is my week going?'),
  bestTest('Which test am I best at?'),
  streak("What's my streak?"),
  nextStep('What should I train next?');

  const CoachTopic(this.question);

  final String question;
}

class CoachStat {
  const CoachStat({required this.label, required this.value, this.progress});

  final String label;
  final String value;

  /// Optional 0–1 value rendered as a ring.
  final double? progress;
}

class CoachMessage {
  const CoachMessage.user(this.text)
      : fromUser = true,
        stats = const [],
        suggestedTest = null;

  const CoachMessage.coach(this.text, {this.stats = const [], this.suggestedTest}) : fromUser = false;

  final bool fromUser;
  final String text;
  final List<CoachStat> stats;
  final TestType? suggestedTest;
}
