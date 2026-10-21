import 'models.dart';

enum GoalPeriod { day, week, month }

GoalPeriod parseGoalPeriod(String raw) {
  return GoalPeriod.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => GoalPeriod.week,
  );
}

DateTime startOfPeriod(DateTime day, GoalPeriod period) {
  final date = DateTime.utc(day.year, day.month, day.day);
  switch (period) {
    case GoalPeriod.day:
      return date;
    case GoalPeriod.week:
      return date.subtract(Duration(days: date.weekday - DateTime.monday));
    case GoalPeriod.month:
      return DateTime.utc(date.year, date.month, 1);
  }
}

DateTime endOfPeriod(DateTime day, GoalPeriod period) {
  final start = startOfPeriod(day, period);
  switch (period) {
    case GoalPeriod.day:
      return start.add(const Duration(days: 1));
    case GoalPeriod.week:
      return start.add(const Duration(days: 7));
    case GoalPeriod.month:
      return DateTime.utc(start.year, start.month + 1, 1);
  }
}

bool isInPeriod(DateTime loggedOn, DateTime now, GoalPeriod period) {
  final start = startOfPeriod(now, period);
  final end = endOfPeriod(now, period);
  final day = DateTime.utc(loggedOn.year, loggedOn.month, loggedOn.day);
  return !day.isBefore(start) && day.isBefore(end);
}

double goalProgress({
  required double logged,
  required double target,
}) {
  if (target <= 0) return 0;
  final ratio = logged / target;
  if (ratio.isNaN || ratio.isInfinite) return 0;
  if (ratio < 0) return 0;
  if (ratio > 1) return 1;
  return ratio;
}

int remainingCalories({
  required int eaten,
  required int burned,
  required int goal,
}) {
  return goal - eaten + burned;
}

String periodPhrase(String period) {
  switch (parseGoalPeriod(period)) {
    case GoalPeriod.day:
      return 'today';
    case GoalPeriod.week:
      return 'this week';
    case GoalPeriod.month:
      return 'this month';
  }
}

String formatGoalValue(double value) {
  if ((value - value.roundToDouble()).abs() < 0.05) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}

double remainingToward({required double logged, required double target}) {
  final left = target - logged;
  return left < 0 ? 0 : left;
}

double loggedToward(
  Iterable<TrackerEntry> entries, {
  required String goalId,
  required String userId,
  required String period,
  DateTime? now,
}) {
  final when = now ?? DateTime.now().toUtc();
  final parsed = parseGoalPeriod(period);
  var total = 0.0;
  for (final entry in entries) {
    if (entry.goalId != goalId || entry.userId != userId) continue;
    if (isInPeriod(entry.loggedOn, when, parsed)) total += entry.value;
  }
  return total;
}

TrackerEntry? latestEntry(
  Iterable<TrackerEntry> entries, {
  required String goalId,
  required String userId,
}) {
  TrackerEntry? latest;
  for (final entry in entries) {
    if (entry.goalId != goalId || entry.userId != userId) continue;
    if (latest == null || entry.createdAt.isAfter(latest.createdAt)) {
      latest = entry;
    }
  }
  return latest;
}

List<double> suggestedAmounts(double target) {
  if (target >= 100) return [10, 25, 50, target];
  if (target >= 10) return [1, 2, 5, target];
  return [1, if (target != 1) target];
}

String goalHeadline({
  required TrackerGoal goal,
  required double logged,
}) {
  final left = remainingToward(logged: logged, target: goal.targetValue);
  final when = periodPhrase(goal.period);
  if (goal.kind == 'boolean') {
    return left <= 0 ? 'Done $when' : 'Not yet $when';
  }
  if (left <= 0) {
    return '${goal.title} is done $when';
  }
  return '${formatGoalValue(left)} ${goal.targetUnit} left $when';
}
