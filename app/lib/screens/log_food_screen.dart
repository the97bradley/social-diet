import 'package:flutter/material.dart';

import '../session.dart';
import '../widgets.dart';

class LogFoodScreen extends StatefulWidget {
  const LogFoodScreen({super.key});

  @override
  State<LogFoodScreen> createState() => _LogFoodScreenState();
}

class _LogFoodScreenState extends State<LogFoodScreen> {
  final _name = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController(text: '0');
  final _carbs = TextEditingController(text: '0');
  final _fat = TextEditingController(text: '0');
  String _meal = 'lunch';
  bool _share = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = SessionScope.of(context);
    setState(() => _busy = true);
    try {
      await session.repo.addFood(
        name: _name.text.trim(),
        calories: int.parse(_calories.text.trim()),
        proteinG: double.parse(_protein.text.trim()),
        carbsG: double.parse(_carbs.text.trim()),
        fatG: double.parse(_fat.text.trim()),
        mealType: _meal,
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
      appBar: AppBar(title: const Text('Log food')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'What did you eat?'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _calories,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Calories'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _protein,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Protein g'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _carbs,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Carbs g'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fat,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Fat g'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final meal in ['breakfast', 'lunch', 'dinner', 'snack'])
                GoalChip(
                  label: meal,
                  selected: _meal == meal,
                  onTap: () => setState(() => _meal = meal),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Share to feed'),
            value: _share,
            onChanged: (value) => setState(() => _share = value),
          ),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Saving…' : 'Save meal'),
          ),
        ],
      ),
    );
  }
}
