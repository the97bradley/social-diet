import 'package:flutter_test/flutter_test.dart';
import 'package:social_diet/models.dart';
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

  test('period phrase and remaining copy', () {
    expect(periodPhrase('day'), 'today');
    expect(periodPhrase('week'), 'this week');
    expect(periodPhrase('month'), 'this month');
    expect(formatGoalValue(3), '3');
    expect(formatGoalValue(3.5), '3.5');
    expect(remainingToward(logged: 1, target: 4), 3);
    expect(remainingToward(logged: 8, target: 4), 0);
    expect(
      goalHeadline(
        goal: const TrackerGoal(
          id: 'g',
          trackerId: 't',
          title: 'Work out 3 times',
          category: 'fitness',
          kind: 'count',
          targetValue: 3,
          targetUnit: 'sessions',
          period: 'week',
          sortOrder: 0,
        ),
        logged: 1,
      ),
      '2 sessions left this week',
    );
  });

  test('loggedToward sums this period and latestEntry is newest', () {
    final now = DateTime.utc(2026, 10, 14);
    final entries = [
      TrackerEntry(
        id: 'old',
        goalId: 'g',
        userId: 'me',
        loggedOn: DateTime.utc(2026, 10, 6),
        value: 9,
        createdAt: DateTime.utc(2026, 10, 6),
      ),
      TrackerEntry(
        id: 'a',
        goalId: 'g',
        userId: 'me',
        loggedOn: DateTime.utc(2026, 10, 13),
        value: 1,
        createdAt: DateTime.utc(2026, 10, 13, 8),
      ),
      TrackerEntry(
        id: 'b',
        goalId: 'g',
        userId: 'me',
        loggedOn: DateTime.utc(2026, 10, 14),
        value: 2,
        createdAt: DateTime.utc(2026, 10, 14, 9),
      ),
      TrackerEntry(
        id: 'friend',
        goalId: 'g',
        userId: 'them',
        loggedOn: DateTime.utc(2026, 10, 14),
        value: 4,
        createdAt: DateTime.utc(2026, 10, 14, 10),
      ),
    ];
    expect(
      loggedToward(entries, goalId: 'g', userId: 'me', period: 'week', now: now),
      3,
    );
    expect(latestEntry(entries, goalId: 'g', userId: 'me')?.id, 'b');
    expect(suggestedAmounts(120), [10, 25, 50, 120]);
  });
}
