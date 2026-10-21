import 'package:flutter/material.dart';

import '../models.dart';
import '../progress.dart';
import '../session.dart';
import '../theme.dart';
import '../widgets.dart';

class TrackerDetailScreen extends StatefulWidget {
  const TrackerDetailScreen({super.key, required this.tracker});

  final Tracker tracker;

  @override
  State<TrackerDetailScreen> createState() => _TrackerDetailScreenState();
}

class _TrackerDetailScreenState extends State<TrackerDetailScreen> {
  late Tracker _tracker;
  List<TrackerEntry> _entries = [];
  Map<String, Profile> _people = {};
  List<Friendship> _friends = [];
  final _busyGoals = <String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tracker = widget.tracker;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load({bool silent = false}) async {
    final repo = SessionScope.of(context).repo;
    final me = SessionScope.of(context).user!.id;
    if (!silent || _entries.isEmpty) setState(() => _loading = true);
    try {
      final trackers = await repo.myTrackers();
      _tracker = trackers.firstWhere(
        (item) => item.id == _tracker.id,
        orElse: () => _tracker,
      );
      _entries = await repo.entriesForGoals(_tracker.goals.map((goal) => goal.id).toList());
      _friends = (await repo.friendships()).where((item) => item.status == 'accepted').toList();
      _people = await repo.profilesByIds({
        ..._tracker.members.map((member) => member.userId),
        ..._friends.map((item) => item.otherId(me)),
      });
    } catch (error) {
      if (mounted) await showError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _logged(TrackerGoal goal, String userId) {
    return loggedToward(
      _entries,
      goalId: goal.id,
      userId: userId,
      period: goal.period,
    );
  }

  Profile _person(String userId, String me) {
    return _people[userId] ??
        Profile(
          id: userId,
          username: 'member',
          displayName: userId == me ? 'You' : 'Friend',
          bio: '',
          dailyCalorieGoal: 2000,
        );
  }

  Future<void> _log(TrackerGoal goal, {double? amount}) async {
    final repo = SessionScope.of(context).repo;
    final me = SessionScope.of(context).user!.id;
    final logged = _logged(goal, me);
    if (goal.kind == 'boolean' && logged >= 1) {
      await _undo(goal);
      return;
    }

    var value = amount;
    if (value == null) {
      if (goal.kind == 'numeric') {
        value = await _askAmount(goal);
        if (value == null) return;
      } else {
        value = 1;
      }
    }

    final optimistic = TrackerEntry(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      goalId: goal.id,
      userId: me,
      loggedOn: DateTime.now().toUtc(),
      value: value,
      createdAt: DateTime.now().toUtc(),
    );
    setState(() {
      _entries = [..._entries, optimistic];
      _busyGoals.add(goal.id);
    });
    try {
      final saved = await repo.logGoal(goalId: goal.id, value: value);
      if (!mounted) return;
      setState(() {
        _entries = [
          for (final entry in _entries)
            if (entry.id == optimistic.id) saved else entry,
        ];
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _entries = [
          for (final entry in _entries)
            if (entry.id != optimistic.id) entry,
        ];
      });
      await showError(context, error);
    } finally {
      if (mounted) setState(() => _busyGoals.remove(goal.id));
    }
  }

  Future<void> _undo(TrackerGoal goal) async {
    final repo = SessionScope.of(context).repo;
    final me = SessionScope.of(context).user!.id;
    final last = latestEntry(_entries, goalId: goal.id, userId: me);
    if (last == null || last.id.startsWith('local-')) return;
    setState(() {
      _entries = [
        for (final entry in _entries)
          if (entry.id != last.id) entry,
      ];
      _busyGoals.add(goal.id);
    });
    try {
      await repo.deleteEntry(last.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _entries = [..._entries, last]);
      await showError(context, error);
    } finally {
      if (mounted) setState(() => _busyGoals.remove(goal.id));
    }
  }

  Future<double?> _askAmount(TrackerGoal goal) async {
    final controller = TextEditingController();
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Log ${goal.title}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'How many ${goal.targetUnit}?',
                style: const TextStyle(color: PulseTheme.mist),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: goal.targetUnit),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in suggestedAmounts(goal.targetValue))
                    ActionChip(
                      label: Text(formatGoalValue(option)),
                      onPressed: () => Navigator.pop(context, option),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final parsed = double.tryParse(controller.text.trim());
                  if (parsed == null || parsed <= 0) return;
                  Navigator.pop(context, parsed);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    return amount;
  }

  Future<void> _share() async {
    final repo = SessionScope.of(context).repo;
    final me = SessionScope.of(context).user!.id;
    final memberIds = _tracker.members.map((member) => member.userId).toSet();
    final candidates = _friends
        .map((item) => _people[item.otherId(me)])
        .whereType<Profile>()
        .where((profile) => !memberIds.contains(profile.id))
        .toList();
    if (candidates.isEmpty) {
      await showError(context, 'Add a friend first, then share this tracker.');
      return;
    }
    final chosen = await showModalBottomSheet<Profile>(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Share with a friend', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final person in candidates)
            ListTile(
              leading: AvatarMark(initials: person.initials),
              title: Text(person.displayName),
              subtitle: Text('@${person.username}'),
              onTap: () => Navigator.pop(context, person),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    try {
      await repo.shareTracker(_tracker.id, chosen.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shared with ${chosen.displayName}')),
      );
      await _load(silent: true);
    } catch (error) {
      if (mounted) await showError(context, error);
    }
  }

  Future<void> _leave() async {
    final ok = await _confirm('Leave this tracker?', 'You will stop seeing it.');
    if (!ok || !mounted) return;
    try {
      await SessionScope.of(context).repo.leaveTracker(_tracker.id);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) await showError(context, error);
    }
  }

  Future<void> _delete() async {
    final ok = await _confirm('Delete this tracker?', 'Goals and logs go with it.');
    if (!ok || !mounted) return;
    try {
      await SessionScope.of(context).repo.deleteTracker(_tracker.id);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) await showError(context, error);
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Do it')),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final me = SessionScope.of(context).user!.id;
    final owner = _tracker.ownerId == me;
    return Scaffold(
      appBar: AppBar(
        title: Text(_tracker.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _share();
                case 'leave':
                  _leave();
                case 'delete':
                  _delete();
              }
            },
            itemBuilder: (context) => [
              if (owner) const PopupMenuItem(value: 'share', child: Text('Share')),
              if (owner) const PopupMenuItem(value: 'delete', child: Text('Delete tracker')),
              if (!owner) const PopupMenuItem(value: 'leave', child: Text('Leave tracker')),
            ],
          ),
        ],
      ),
      body: _loading && _entries.isEmpty && _people.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                if (_tracker.description.isNotEmpty) ...[
                  Text(_tracker.description, style: const TextStyle(color: PulseTheme.mist, height: 1.4)),
                  const SizedBox(height: 8),
                ],
                if (owner)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: const Text('Invite a friend'),
                    ),
                  ),
                const SectionLabel('This period'),
                if (_tracker.goals.isEmpty) const EmptyHint('This tracker has no goals yet.'),
                for (final goal in _tracker.goals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GoalCard(
                      goal: goal,
                      logged: _logged(goal, me),
                      busy: _busyGoals.contains(goal.id),
                      members: [
                        for (final member in _tracker.members)
                          (
                            person: _person(member.userId, me),
                            logged: _logged(goal, member.userId),
                            isMe: member.userId == me,
                          ),
                      ],
                      onPlus: () => _log(goal),
                      onMinus: () => _undo(goal),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.logged,
    required this.busy,
    required this.members,
    required this.onPlus,
    required this.onMinus,
  });

  final TrackerGoal goal;
  final double logged;
  final bool busy;
  final List<({Profile person, double logged, bool isMe})> members;
  final VoidCallback onPlus;
  final VoidCallback onMinus;

  @override
  Widget build(BuildContext context) {
    final left = remainingToward(logged: logged, target: goal.targetValue);
    final done = left <= 0;
    final ranked = [...members]..sort((a, b) => b.logged.compareTo(a.logged));
    return PulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(goal.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            goalHeadline(goal: goal, logged: logged),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatGoalValue(logged)} / ${formatGoalValue(goal.targetValue)} ${goal.targetUnit} · ${periodPhrase(goal.period)}',
            style: const TextStyle(color: PulseTheme.mist),
          ),
          const SizedBox(height: 12),
          PulseBar(
            value: goalProgress(logged: logged, target: goal.targetValue),
            color: done ? PulseTheme.clay : PulseTheme.lime,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (goal.kind != 'boolean') ...[
                _StepButton(
                  icon: Icons.remove,
                  onPressed: busy || logged <= 0 ? null : onMinus,
                  label: 'Undo last log',
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onPlus,
                  child: Text(
                    goal.kind == 'boolean'
                        ? (done ? 'Undo' : 'Mark done')
                        : goal.kind == 'numeric'
                            ? 'Log amount'
                            : 'Log +1',
                  ),
                ),
              ),
            ],
          ),
          if (ranked.length > 1) ...[
            const SizedBox(height: 16),
            const Text(
              'Everyone',
              style: TextStyle(color: PulseTheme.mist, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final row in ranked)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    AvatarMark(initials: row.person.initials, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        row.isMe ? 'You' : row.person.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      goal.kind == 'boolean'
                          ? (row.logged >= 1 ? 'Done' : '—')
                          : '${formatGoalValue(row.logged)} / ${formatGoalValue(goal.targetValue)}',
                      style: TextStyle(
                        color: row.isMe ? PulseTheme.lime : PulseTheme.cream,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed, required this.label});

  final IconData icon;
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon),
    );
  }
}
