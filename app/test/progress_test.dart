import 'package:flutter_test/flutter_test.dart';
import 'package:social_diet/progress.dart';

void main() {
  test('week starts on Monday', () {
    final thursday = DateTime.utc(2026, 10, 15);
    expect(startOfPeriod(thursday, GoalPeriod.week), DateTime.utc(2026, 10, 12));
    expect(endOfPeriod(thursday, GoalPeriod.week), DateTime.utc(2026, 10, 19));
  });

  test('goal progress clamps between 0 and 1', () {
    expect(goalProgress(logged: 3, target: 4), 0.75);
    expect(goalProgress(logged: 8, target: 4), 1);
    expect(goalProgress(logged: -1, target: 4), 0);
    expect(goalProgress(logged: 1, target: 0), 0);
  });

  test('remaining calories adds back burned', () {
    expect(remainingCalories(eaten: 1800, burned: 300, goal: 2000), 500);
  });

  test('period membership uses inclusive start', () {
    final now = DateTime.utc(2026, 10, 14);
    expect(isInPeriod(DateTime.utc(2026, 10, 14), now, GoalPeriod.day), isTrue);
    expect(isInPeriod(DateTime.utc(2026, 10, 13), now, GoalPeriod.day), isFalse);
    expect(isInPeriod(DateTime.utc(2026, 10, 12), now, GoalPeriod.week), isTrue);
  });
}
