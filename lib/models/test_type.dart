enum TestType {
  single(
    key: 'Single',
    title: 'Reaction Test',
    shortTitle: 'Reaction',
    description: 'Tap the moment the signal lights up.',
    estimatedSeconds: 20,
  ),
  dual(
    key: 'Dual',
    title: 'Dual-Task Test',
    shortTitle: 'Dual',
    description: 'Solve a sum while reacting to signals.',
    estimatedSeconds: 40,
  ),
  auditory(
    key: 'AuditoryBio',
    title: 'Auditory Biofeedback',
    shortTitle: 'Auditory',
    description: 'Match high and low beeps while doing math.',
    estimatedSeconds: 45,
  ),
  visual(
    key: 'VisualBio',
    title: 'Visual Biofeedback',
    shortTitle: 'Visual',
    description: 'Tap on green, hold back on red.',
    estimatedSeconds: 45,
  ),
  tapping(
    key: 'TappingBio',
    title: 'Tapping Pattern',
    shortTitle: 'Tapping',
    description: 'Hit the moving target an exact number of times.',
    estimatedSeconds: 30,
  );

  const TestType({
    required this.key,
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.estimatedSeconds,
  });

  /// Value persisted in the database; kept compatible with v1 data.
  final String key;
  final String title;
  final String shortTitle;
  final String description;
  final int estimatedSeconds;

  bool get isBiofeedback => this == auditory || this == visual || this == tapping;

  bool get hasMath => this != single;

  static TestType fromKey(String key) => values.firstWhere((t) => t.key == key, orElse: () => single);
}
