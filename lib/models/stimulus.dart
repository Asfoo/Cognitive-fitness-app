enum ResponseKind { left, right, tap }

/// A biofeedback cue and the response it expects (null = withhold).
enum StimulusKind {
  highPitch(ResponseKind.left),
  lowPitch(ResponseKind.right),
  go(ResponseKind.tap),
  noGo(null);

  const StimulusKind(this.expected);

  final ResponseKind? expected;
}
