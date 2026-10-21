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
  Map<String, Profile> _people = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load({bool silent = false}) async {
    final repo = SessionScope.of(context).repo;
    if (!silent || _trackers.isEmpty) setState(() => _loading = true);
    try {
      _trackers = await repo.myTrackers();
      _entries = await repo.entriesForGoals([
        for (final tracker in _trackers)
          for (final goal in tracker.goals) goal.id,
      ]);
      _people = await repo.profilesByIds({
        for (final tracker in _trackers)
          for (final member in tracker.members) member.userId,
      });
    } catch (error) {
      if (mounted) await showError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  TrackerGoal? _focusGoal(Tracker tracker, String userId) {
    TrackerGoal? pick;
    var worst = 2.0;
    for (final goal in tracker.goals) {
      final logged = loggedToward(
        _entries,
        goalId: goal.id,
        userId: userId,
        period: goal.period,
      );
      final progress = goalProgress(logged: logged, target: goal.targetValue);
      if (progress < worst) {
        worst = progress;
        pick = goal;
      }
    }
    return pick;
  }

  double _trackerProgress(Tracker tracker, String userId) {
    if (tracker.goals.isEmpty) return 0;
    var total = 0.0;
    for (final goal in tracker.goals) {
      total += goalProgress(
        logged: loggedToward(
          _entries,
          goalId: goal.id,
          userId: userId,
          period: goal.period,
        ),
        target: goal.targetValue,
      );
    }
    return total / tracker.goals.length;
  }

  String _headline(Tracker tracker, String userId) {
    final goal = _focusGoal(tracker, userId);
    if (goal == null) return 'Add a goal to start';
    return goalHeadline(
      goal: goal,
      logged: loggedToward(
        _entries,
        goalId: goal.id,
        userId: userId,
        period: goal.period,
      ),
    );
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TrackerEditorScreen()),
    );
    if (created == true) await _load();
  }

  Future<void> _open(Tracker tracker) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrackerDetailScreen(tracker: tracker)),
    );
    await _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final me = SessionScope.of(context).user!.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Trackers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('New tracker'),
      ),
      body: _loading && _trackers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  if (_trackers.isEmpty)
                    PulseCard(
                      onTap: _create,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nothing to count yet',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Make a tracker, log against it, then share it with friends.',
                            style: TextStyle(color: PulseTheme.mist, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'New tracker',
                            style: TextStyle(
                              color: PulseTheme.lime,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final tracker in _trackers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TrackerSummaryCard(
                          title: tracker.title,
                          headline: _headline(tracker, me),
                          progress: _trackerProgress(tracker, me),
                          meta: tracker.goals.isEmpty
                              ? '${tracker.members.length} people'
                              : '${tracker.goals.length} goals · ${tracker.members.length} people',
                          memberInitials: [
                            for (final member in tracker.members)
                              (_people[member.userId] ??
                                      Profile(
                                        id: member.userId,
                                        username: '',
                                        displayName: member.userId == me ? 'You' : 'Friend',
                                        bio: '',
                                        dailyCalorieGoal: 2000,
                                      ))
                                  .initials,
                          ],
                          onTap: () => _open(tracker),
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}
