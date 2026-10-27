import 'dart:math' as math;

/// Arithmetic mean, or null when [values] is empty.
double? mean(Iterable<num> values) {
  if (values.isEmpty) return null;
  return values.fold<double>(0, (sum, v) => sum + v) / values.length;
}

/// Mean of the non-null entries, or null when there are none.
double? meanOfPresent(Iterable<num?> values) => mean(values.whereType<num>());

/// Population standard deviation, or null with fewer than two values.
double? standardDeviation(Iterable<num> values) {
  if (values.length < 2) return null;
  final avg = mean(values)!;
  final variance = values.fold<double>(0, (sum, v) => sum + (v - avg) * (v - avg)) / values.length;
  return math.sqrt(variance);
}
