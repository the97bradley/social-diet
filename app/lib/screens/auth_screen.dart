import 'package:flutter/material.dart';

import '../session.dart';
import '../theme.dart';
import '../widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _username.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final session = SessionScope.of(context);
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      if (_signUp) {
        final username = _username.text.trim().toLowerCase();
        if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(username)) {
          throw Exception('Username must be 3-24 letters, numbers, or underscores.');
        }
        final result = await session.signUp(
          email: _email.text.trim(),
          password: _password.text,
          username: username,
          displayName: _displayName.text.trim().isEmpty
              ? username
              : _displayName.text.trim(),
        );
        if (result.session == null) {
          setState(() {
            _notice = 'Check your email to confirm the account, then sign in.';
            _signUp = false;
          });
        }
      } else {
        await session.signIn(_email.text.trim(), _password.text);
      }
    } catch (error) {
      if (mounted) await showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              children: [
                Text(
                  'Social Diet',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track meals, workouts, and the habits you invent. Share a tracker with friends and keep each other honest.',
                  style: TextStyle(color: PulseTheme.mist, height: 1.4),
                ),
                const SizedBox(height: 32),
                if (_notice != null) ...[
                  PulseCard(child: Text(_notice!)),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                if (_signUp) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _username,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _displayName,
                    decoration: const InputDecoration(labelText: 'Display name'),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy
                      ? 'Working…'
                      : _signUp
                          ? 'Create account'
                          : 'Sign in'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _signUp = !_signUp),
                  child: Text(
                    _signUp
                        ? 'Already have an account? Sign in'
                        : 'New here? Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
