import 'package:flutter/material.dart';

import '../session.dart';
import '../theme.dart';
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
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _bio = TextEditingController();
    _calories = TextEditingController(text: '2000');
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
    super.dispose();
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
          OutlinedButton(
            onPressed: session.signOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
