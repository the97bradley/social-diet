import 'package:flutter/material.dart';

import '../session.dart';
import '../widgets.dart';

class LogWorkoutScreen extends StatefulWidget {
  const LogWorkoutScreen({super.key});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  final _title = TextEditingController();
  final _minutes = TextEditingController(text: '30');
  final _calories = TextEditingController(text: '200');
  final _notes = TextEditingController();
  String _category = 'strength';
  bool _share = true;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _minutes.dispose();
    _calories.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = SessionScope.of(context);
    setState(() => _busy = true);
    try {
      await session.repo.addWorkout(
        title: _title.text.trim(),
        category: _category,
        durationMinutes: int.parse(_minutes.text.trim()),
        caloriesBurned: int.parse(_calories.text.trim()),
        notes: _notes.text.trim(),
        shareToFeed: _share,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) await showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log workout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Workout name'),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final category in ['strength', 'cardio', 'flexibility', 'sports', 'other'])
                GoalChip(
                  label: category,
                  selected: _category == category,
                  onTap: () => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _minutes,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Minutes'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _calories,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Calories burned'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Share to feed'),
            value: _share,
            onChanged: (value) => setState(() => _share = value),
          ),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Saving…' : 'Save workout'),
          ),
        ],
      ),
    );
  }
}
