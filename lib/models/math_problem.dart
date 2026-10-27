import 'dart:math';

class MathProblem {
  const MathProblem(this.a, this.b);

  factory MathProblem.random(Random random, {int maxA = 20, int maxB = 20}) {
    return MathProblem(random.nextInt(maxA) + 1, random.nextInt(maxB) + 1);
  }

  final int a;
  final int b;

  int get answer => a + b;

  String get question => '$a + $b';

  bool check(int? value) => value == answer;
}
