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
