import 'package:flutter/material.dart';

import '../models.dart';
import '../progress.dart';
import '../session.dart';
import '../theme.dart';
import '../widgets.dart';
import 'log_food_screen.dart';
import 'log_workout_screen.dart';
import 'tracker_detail_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  List<FoodLog> _foods = [];
  List<Workout> _workouts = [];
  List<Tracker> _trackers = [];
  List<TrackerEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final session = SessionScope.of(context);
    final now = DateTime.now();
    setState(() => _loading = true);
    try {
      _foods = await session.repo.foodForDay(now);
      _workouts = await session.repo.workoutsForDay(now);
      _trackers = await session.repo.myTrackers();
      _entries = await session.repo.entriesForGoals([
        for (final tracker in _trackers)
          for (final goal in tracker.goals) goal.id,
      ]);
    } catch (error) {
      if (mounted) await showError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Widget screen) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (changed == true || changed == null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final profile = SessionScope.of(context).profile;
    final eaten = _foods.fold<int>(0, (sum, item) => sum + item.calories);
    final burned = _workouts.fold<int>(0, (sum, item) => sum + item.caloriesBurned);
    final goal = profile?.dailyCalorieGoal ?? 2000;
    final left = remainingCalories(eaten: eaten, burned: burned, goal: goal);
    final me = SessionScope.of(context).user!.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Hello ${profile?.displayName ?? ''}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  PulseCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Calories remaining'),
                        Text(
                          '$left',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$eaten eaten · $burned burned · $goal goal',
                          style: const TextStyle(color: PulseTheme.mist),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: goalProgress(logged: eaten.toDouble(), target: goal.toDouble()),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _open(const LogFoodScreen()),
                          child: const Text('Log food'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _open(const LogWorkoutScreen()),
                          child: const Text('Log workout'),
                        ),
                      ),
                    ],
                  ),
                  const SectionLabel('Meals'),
                  if (_foods.isEmpty) const EmptyHint('Nothing logged yet.'),
                  for (final food in _foods)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(food.name),
                      subtitle: Text('${food.mealType} · ${food.calories} kcal'),
                    ),
                  const SectionLabel('Workouts'),
                  if (_workouts.isEmpty) const EmptyHint('No session yet today.'),
                  for (final workout in _workouts)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(workout.title),
                      subtitle: Text(
                        '${workout.category} · ${workout.durationMinutes}m · ${workout.caloriesBurned} kcal',
                      ),
                    ),
                  const SectionLabel('Active trackers'),
                  if (_trackers.isEmpty) const EmptyHint('Create a tracker to count anything you want.'),
                  for (final tracker in _trackers.take(4))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PulseCard(
                        onTap: () => _open(TrackerDetailScreen(tracker: tracker)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tracker.title, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            for (final goal in tracker.goals.take(2))
                              Text(
                                goalHeadline(
                                  goal: goal,
                                  logged: loggedToward(
                                    _entries,
                                    goalId: goal.id,
                                    userId: me,
                                    period: goal.period,
                                  ),
                                ),
                                style: const TextStyle(color: PulseTheme.mist),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

}
