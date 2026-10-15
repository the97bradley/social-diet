import 'package:flutter/material.dart';

import '../models.dart';
import '../progress.dart';
import '../session.dart';
import '../theme.dart';
import '../trello.dart';
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
  bool _loading = true;
  bool _trelloBusy = false;

  @override
  void initState() {
    super.initState();
    _tracker = widget.tracker;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final repo = SessionScope.of(context).repo;
    final me = SessionScope.of(context).user!.id;
    setState(() => _loading = true);
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
    final now = DateTime.now().toUtc();
    final period = parseGoalPeriod(goal.period);
    return _entries
        .where((entry) =>
            entry.goalId == goal.id &&
            entry.userId == userId &&
            isInPeriod(entry.loggedOn, now, period))
        .fold<double>(0, (sum, entry) => sum + entry.value);
  }

  Future<void> _log(TrackerGoal goal) async {
    final repo = SessionScope.of(context).repo;
    try {
      await repo.logGoal(goalId: goal.id, value: goal.kind == 'boolean' ? 1 : 1);
      await _load();
    } catch (error) {
      if (mounted) await showError(context, error);
    }
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
      await _load();
    } catch (error) {
      if (mounted) await showError(context, error);
    }
  }

  Future<void> _sendToTrello() async {
    setState(() => _trelloBusy = true);
    TrelloClient? trello;
    try {
      final connection = await SessionScope.of(context).repo.trelloConnection();
      if (connection == null || !connection.isReady) {
        throw 'Connect Trello in your profile first.';
      }
      trello = TrelloClient(apiKey: connection.apiKey, token: connection.token);
      final count = await trello.pushTracker(_tracker, boardId: connection.boardId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sent $count goals to ${connection.boardName.isEmpty ? 'Trello' : connection.boardName}',
          ),
        ),
      );
    } catch (error) {
      if (mounted) await showError(context, error);
    } finally {
      trello?.close();
      if (mounted) setState(() => _trelloBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = SessionScope.of(context).user!.id;
    return Scaffold(
      appBar: AppBar(
        title: Text(_tracker.title),
        actions: [
          if (_tracker.ownerId == me)
            IconButton(onPressed: _share, icon: const Icon(Icons.ios_share)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_tracker.description.isNotEmpty)
                  Text(_tracker.description, style: const TextStyle(color: PulseTheme.mist)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _trelloBusy ? null : _sendToTrello,
                  child: Text(_trelloBusy ? 'Sending to Trello…' : 'Send to Trello'),
                ),
                const SectionLabel('This period'),
                for (final goal in _tracker.goals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PulseCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(goal.title, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            '${_logged(goal, me).toStringAsFixed(0)} / ${goal.targetValue.toStringAsFixed(0)} ${goal.targetUnit} · ${goal.period}',
                            style: const TextStyle(color: PulseTheme.mist),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: goalProgress(
                              logged: _logged(goal, me),
                              target: goal.targetValue,
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _log(goal),
                              child: const Text('Log +1'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SectionLabel('People on this tracker'),
                for (final member in _tracker.members)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: AvatarMark(initials: (_people[member.userId] ?? Profile(
                      id: member.userId,
                      username: 'member',
                      displayName: member.userId == me ? 'You' : 'Friend',
                      bio: '',
                      dailyCalorieGoal: 2000,
                    )).initials),
                    title: Text(_people[member.userId]?.displayName ?? (member.userId == me ? 'You' : 'Friend')),
                    subtitle: Text(member.role),
                  ),
              ],
            ),
    );
  }
}
