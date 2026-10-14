import 'package:flutter/material.dart';

import '../models.dart';
import '../progress.dart';
import '../session.dart';
import '../theme.dart';
import '../widgets.dart';
import 'tracker_detail_screen.dart';
import 'tracker_editor_screen.dart';

class TrackersScreen extends StatefulWidget {
  const TrackersScreen({super.key});

  @override
  State<TrackersScreen> createState() => _TrackersScreenState();
}

class _TrackersScreenState extends State<TrackersScreen> {
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
    final repo = SessionScope.of(context).repo;
    setState(() => _loading = true);
    try {
      _trackers = await repo.myTrackers();
      _entries = await repo.entriesForGoals([
        for (final tracker in _trackers)
          for (final goal in tracker.goals) goal.id,
      ]);
    } catch (error) {
      if (mounted) await showError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _trackerProgress(Tracker tracker, String userId) {
    if (tracker.goals.isEmpty) return 0;
    final now = DateTime.now().toUtc();
    var total = 0.0;
    for (final goal in tracker.goals) {
      final logged = _entries
          .where((entry) =>
              entry.goalId == goal.id &&
              entry.userId == userId &&
              isInPeriod(entry.loggedOn, now, parseGoalPeriod(goal.period)))
          .fold<double>(0, (sum, entry) => sum + entry.value);
      total += goalProgress(logged: logged, target: goal.targetValue);
    }
    return total / tracker.goals.length;
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TrackerEditorScreen()),
    );
    if (created == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final me = SessionScope.of(context).user!.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trackers'),
        actions: [
          IconButton(onPressed: _create, icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'A tracker is a bundle of goals you invent: workouts, beers, water, anything you want to count with friends.',
                    style: TextStyle(color: PulseTheme.mist),
                  ),
                  const SizedBox(height: 16),
                  if (_trackers.isEmpty)
                    PulseCard(
                      onTap: _create,
                      child: const Text('Create your first tracker'),
                    ),
                  for (final tracker in _trackers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PulseCard(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TrackerDetailScreen(tracker: tracker),
                            ),
                          );
                          await _load();
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tracker.title, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Text(
                              '${tracker.goals.length} goals · ${tracker.members.length} people',
                              style: const TextStyle(color: PulseTheme.mist),
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: _trackerProgress(tracker, me),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(8),
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
