enum ReportPeriod {
  daily(label: 'Daily', noun: 'day', days: 1),
  weekly(label: 'Weekly', noun: 'week', days: 7),
  monthly(label: 'Monthly', noun: 'month', days: 30);

  const ReportPeriod({required this.label, required this.noun, required this.days});

  final String label;
  final String noun;
  final int days;
}
