import 'package:flutter/material.dart';

import '../models.dart';
import '../session.dart';
import '../theme.dart';
import '../widgets.dart';
import 'chat_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _search = TextEditingController();
  List<Friendship> _friendships = [];
  Map<String, Profile> _people = {};
  List<Profile> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = SessionScope.of(context).repo;
    final me = SessionScope.of(context).user!.id;
    setState(() => _loading = true);
    try {
      _friendships = await repo.friendships();
      _people = await repo.profilesByIds([
        for (final item in _friendships) item.otherId(me),
      ]);
    } catch (error) {
      if (mounted) await showError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runSearch() async {
    try {
      _results = await SessionScope.of(context).repo.searchPeople(_search.text);
      setState(() {});
    } catch (error) {
      if (mounted) await showError(context, error);
    }
  }

  Future<void> _add(Profile person) async {
    try {
      await SessionScope.of(context).repo.sendFriendRequest(person.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to ${person.displayName}')),
        );
      }
      await _load();
    } catch (error) {
      if (mounted) await showError(context, error);
    }
  }

  Future<void> _respond(Friendship item, String status) async {
    try {
      await SessionScope.of(context).repo.respondToFriend(item.id, status);
      await _load();
    } catch (error) {
      if (mounted) await showError(context, error);
    }
  }

  Future<void> _message(Profile other) async {
    try {
      final id = await SessionScope.of(context).repo.openConversation(other.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversationId: id, other: other),
        ),
      );
    } catch (error) {
      if (mounted) await showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = SessionScope.of(context).user!.id;
    final incoming = _friendships.where((item) => item.status == 'pending' && item.addresseeId == me);
    final friends = _friendships.where((item) => item.status == 'accepted');

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      labelText: 'Find people',
                      suffixIcon: IconButton(
                        onPressed: _runSearch,
                        icon: const Icon(Icons.search),
                      ),
                    ),
                    onSubmitted: (_) => _runSearch(),
                  ),
                  if (_results.isNotEmpty) ...[
                    const SectionLabel('Search'),
                    for (final person in _results)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: AvatarMark(initials: person.initials),
                        title: Text(person.displayName),
                        subtitle: Text('@${person.username}'),
                        trailing: TextButton(
                          onPressed: () => _add(person),
                          child: const Text('Add'),
                        ),
                      ),
                  ],
                  const SectionLabel('Requests'),
                  if (incoming.isEmpty) const EmptyHint('No pending requests.'),
                  for (final item in incoming)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: AvatarMark(initials: _people[item.requesterId]?.initials ?? 'SD'),
                      title: Text(_people[item.requesterId]?.displayName ?? 'Someone'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(onPressed: () => _respond(item, 'accepted'), child: const Text('Accept')),
                          TextButton(onPressed: () => _respond(item, 'declined'), child: const Text('Decline')),
                        ],
                      ),
                    ),
                  const SectionLabel('Friends'),
                  if (friends.isEmpty)
                    const EmptyHint('Search a username and send a request.'),
                  for (final item in friends)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: AvatarMark(initials: _people[item.otherId(me)]?.initials ?? 'SD'),
                      title: Text(_people[item.otherId(me)]?.displayName ?? 'Friend'),
                      subtitle: Text('@${_people[item.otherId(me)]?.username ?? ''}'),
                      trailing: IconButton(
                        onPressed: _people[item.otherId(me)] == null
                            ? null
                            : () => _message(_people[item.otherId(me)]!),
                        icon: const Icon(Icons.chat_bubble_outline),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Messaging is friends-only. Share a tracker from the tracker screen.',
                    style: TextStyle(color: PulseTheme.mist),
                  ),
                ],
              ),
            ),
    );
  }
}
