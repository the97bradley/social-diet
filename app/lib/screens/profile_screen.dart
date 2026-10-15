import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../session.dart';
import '../theme.dart';
import '../trello.dart';
import '../widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late final TextEditingController _calories;
  late final TextEditingController _trelloKey;
  late final TextEditingController _trelloToken;
  bool _busy = false;
  bool _trelloBusy = false;
  String _boardId = '';
  String _boardName = '';
  List<TrelloBoard> _boards = [];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _bio = TextEditingController();
    _calories = TextEditingController(text: '2000');
    _trelloKey = TextEditingController();
    _trelloToken = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadTrello();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = SessionScope.of(context).profile;
    if (profile == null) return;
    if (_name.text.isEmpty) _name.text = profile.displayName;
    if (_bio.text.isEmpty) _bio.text = profile.bio;
    if (_calories.text == '2000') {
      _calories.text = '${profile.dailyCalorieGoal}';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _calories.dispose();
    _trelloKey.dispose();
    _trelloToken.dispose();
    super.dispose();
  }

  Future<void> _loadTrello() async {
    try {
      final connection = await SessionScope.of(context).repo.trelloConnection();
      if (!mounted || connection == null) return;
      setState(() {
        _trelloKey.text = connection.apiKey;
        _trelloToken.text = connection.token;
        _boardId = connection.boardId;
        _boardName = connection.boardName;
      });
    } catch (error) {
      if (mounted) await showError(context, error);
    }
  }

  Future<void> _copyAuthorizeUrl() async {
    final key = _trelloKey.text.trim();
    if (key.isEmpty) {
      await showError(context, 'Paste your Trello API key first.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: trelloAuthorizeUrl(key).toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Authorize link copied. Paste the token Trello shows you.')),
    );
  }

  TrelloClient _client() {
    return TrelloClient(
      apiKey: _trelloKey.text.trim(),
      token: _trelloToken.text.trim(),
    );
  }

  Future<void> _loadBoards() async {
    setState(() => _trelloBusy = true);
    final client = _client();
    try {
      final boards = await client.boards();
      if (!mounted) return;
      setState(() {
        _boards = boards;
        if (_boardId.isNotEmpty) {
          final match = boards.where((board) => board.id == _boardId);
          if (match.isNotEmpty) _boardName = match.first.name;
        }
      });
    } catch (error) {
      if (mounted) await showError(context, error);
    } finally {
      client.close();
      if (mounted) setState(() => _trelloBusy = false);
    }
  }

  Future<void> _saveTrello() async {
    final key = _trelloKey.text.trim();
    final token = _trelloToken.text.trim();
    if (key.length < 16 || token.length < 16) {
      await showError(context, 'Trello API key and token are both required.');
      return;
    }
    setState(() => _trelloBusy = true);
    try {
      await SessionScope.of(context).repo.saveTrelloConnection(
        apiKey: key,
        token: token,
        boardId: _boardId,
        boardName: _boardName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _boardName.isEmpty
                ? 'Trello saved. Load boards and pick one.'
                : 'Trello saved. Trackers go to $_boardName.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) await showError(context, error);
    } finally {
      if (mounted) setState(() => _trelloBusy = false);
    }
  }

  Future<void> _disconnectTrello() async {
    setState(() => _trelloBusy = true);
    try {
      await SessionScope.of(context).repo.clearTrelloConnection();
      if (!mounted) return;
      setState(() {
        _trelloKey.clear();
        _trelloToken.clear();
        _boardId = '';
        _boardName = '';
        _boards = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trello disconnected')),
      );
    } catch (error) {
      if (mounted) await showError(context, error);
    } finally {
      if (mounted) setState(() => _trelloBusy = false);
    }
  }

  Future<void> _save() async {
    final session = SessionScope.of(context);
    setState(() => _busy = true);
    try {
      await session.repo.updateProfile(
        displayName: _name.text.trim(),
        bio: _bio.text.trim(),
        dailyCalorieGoal: int.parse(_calories.text.trim()),
      );
      await session.refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
      }
    } catch (error) {
      if (mounted) await showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final profile = session.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              AvatarMark(initials: profile?.initials ?? 'SD', size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile?.displayName ?? '', style: Theme.of(context).textTheme.headlineSmall),
                    Text('@${profile?.username ?? ''}', style: const TextStyle(color: PulseTheme.mist)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bio,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Bio'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _calories,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Daily calorie goal'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Saving…' : 'Save profile'),
          ),
          const SizedBox(height: 12),
          const SectionLabel('Trello'),
          const Text(
            'Get an API key at trello.com/power-ups/admin, authorize a token, then pick the board that should receive tracker goals.',
            style: TextStyle(color: PulseTheme.mist),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _trelloKey,
            decoration: const InputDecoration(labelText: 'Trello API key'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _trelloToken,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Trello token'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _trelloBusy ? null : _copyAuthorizeUrl,
            child: const Text('Copy authorize link'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _trelloBusy ? null : _loadBoards,
            child: Text(_trelloBusy ? 'Talking to Trello…' : 'Load boards'),
          ),
          if (_boardName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Sending trackers to $_boardName',
              style: const TextStyle(color: PulseTheme.mist),
            ),
          ],
          for (final board in _boards)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(board.name),
              trailing: _boardId == board.id ? const Icon(Icons.check) : null,
              onTap: () => setState(() {
                _boardId = board.id;
                _boardName = board.name;
              }),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _trelloBusy ? null : _saveTrello,
            child: const Text('Save Trello'),
          ),
          if (_trelloKey.text.isNotEmpty || _boardId.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _trelloBusy ? null : _disconnectTrello,
              child: const Text('Disconnect Trello'),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: session.signOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
