import 'package:flutter/material.dart';

import '../models.dart';
import '../progress.dart';
import '../session.dart';
import '../widgets.dart';

final _templates = <GoalDraft>[
  GoalDraft(title: 'Work out 3 times', category: 'fitness', targetValue: 3, targetUnit: 'sessions', period: 'week'),
  GoalDraft(title: 'Drink 8 glasses of water', category: 'lifestyle', targetValue: 8, targetUnit: 'glasses', period: 'day'),
  GoalDraft(title: 'Limit to 4 beers', category: 'lifestyle', targetValue: 4, targetUnit: 'beers', period: 'week'),
  GoalDraft(title: 'Hit protein target', category: 'food', kind: 'numeric', targetValue: 120, targetUnit: 'grams', period: 'day'),
  GoalDraft(title: 'Walk 10,000 steps', category: 'fitness', kind: 'numeric', targetValue: 10000, targetUnit: 'steps', period: 'day'),
];

class TrackerEditorScreen extends StatefulWidget {
  const TrackerEditorScreen({super.key});

  @override
  State<TrackerEditorScreen> createState() => _TrackerEditorScreenState();
}

class _TrackerEditorScreenState extends State<TrackerEditorScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _goals = <GoalDraft>[];
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  bool _hasTemplate(GoalDraft template) {
    return _goals.any((goal) =>
        goal.title == template.title &&
        goal.period == template.period &&
        goal.targetValue == template.targetValue);
  }

  void _toggleTemplate(GoalDraft template) {
    setState(() {
      final index = _goals.indexWhere((goal) =>
          goal.title == template.title &&
          goal.period == template.period &&
          goal.targetValue == template.targetValue);
      if (index >= 0) {
        _goals.removeAt(index);
      } else {
        _goals.add(GoalDraft(
          title: template.title,
          category: template.category,
          kind: template.kind,
          targetValue: template.targetValue,
          targetUnit: template.targetUnit,
          period: template.period,
        ));
      }
    });
  }

  Future<void> _addCustomGoal() async {
    final draft = GoalDraft(title: '');
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => GoalDraftSheet(draft: draft),
    );
    if (accepted == true && draft.title.trim().isNotEmpty) {
      setState(() => _goals.add(draft));
    }
  }

  Future<void> _editGoal(int index) async {
    final draft = _goals[index];
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => GoalDraftSheet(draft: draft, editing: true),
    );
    if (accepted == true && draft.title.trim().isNotEmpty) {
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _goals.isEmpty) {
      await showError(context, 'Add a title and at least one goal.');
      return;
    }
    final session = SessionScope.of(context);
    setState(() => _busy = true);
    try {
      await session.repo.createTracker(
        title: _title.text.trim(),
        description: _description.text.trim(),
        goals: [
          for (var i = 0; i < _goals.length; i++) _goals[i].toGoal(i),
        ],
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
      appBar: AppBar(title: const Text('New tracker')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Tracker name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'What is this for?'),
            maxLines: 2,
          ),
          const SectionLabel('Starter goals'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final template in _templates)
                GoalChip(
                  label: template.title,
                  selected: _hasTemplate(template),
                  onTap: () => _toggleTemplate(template),
                ),
            ],
          ),
          const SectionLabel('Goals in this tracker'),
          if (_goals.isEmpty) const EmptyHint('Tap a starter, or write your own.'),
          for (var i = 0; i < _goals.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PulseCard(
                onTap: () => _editGoal(i),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_goals[i].title} · ${formatGoalValue(_goals[i].targetValue)} ${_goals[i].targetUnit}/${_goals[i].period}',
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _goals.removeAt(i)),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _addCustomGoal,
            icon: const Icon(Icons.add),
            label: const Text('Custom goal'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Creating…' : 'Create tracker'),
          ),
        ],
      ),
    );
  }
}

class GoalDraftSheet extends StatefulWidget {
  const GoalDraftSheet({super.key, required this.draft, this.editing = false});

  final GoalDraft draft;
  final bool editing;

  @override
  State<GoalDraftSheet> createState() => _GoalDraftSheetState();
}

class _GoalDraftSheetState extends State<GoalDraftSheet> {
  late final TextEditingController _title;
  late final TextEditingController _target;
  late final TextEditingController _unit;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.draft.title);
    _target = TextEditingController(text: formatGoalValue(widget.draft.targetValue));
    _unit = TextEditingController(text: widget.draft.targetUnit);
  }

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final boolean = draft.kind == 'boolean';
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.editing ? 'Edit goal' : 'Custom goal', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Goal, like “4 beers a week”'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final kind in ['count', 'numeric', 'boolean'])
                GoalChip(
                  label: kind == 'boolean' ? 'yes / no' : kind,
                  selected: draft.kind == kind,
                  onTap: () => setState(() {
                    draft.kind = kind;
                    if (kind == 'boolean') {
                      draft.targetValue = 1;
                      draft.targetUnit = 'times';
                      _target.text = '1';
                      _unit.text = 'times';
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final category in ['fitness', 'food', 'lifestyle', 'custom'])
                GoalChip(
                  label: category,
                  selected: draft.category == category,
                  onTap: () => setState(() => draft.category = category),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final period in ['day', 'week', 'month'])
                GoalChip(
                  label: 'per $period',
                  selected: draft.period == period,
                  onTap: () => setState(() => draft.period = period),
                ),
            ],
          ),
          if (!boolean) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _target,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Target'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              draft.title = _title.text.trim();
              if (draft.title.isEmpty) return;
              draft.targetValue = boolean ? 1 : (double.tryParse(_target.text.trim()) ?? 1);
              if (draft.targetValue <= 0) draft.targetValue = 1;
              draft.targetUnit = boolean
                  ? 'times'
                  : (_unit.text.trim().isEmpty ? 'times' : _unit.text.trim());
              Navigator.of(context).pop(true);
            },
            child: Text(widget.editing ? 'Save goal' : 'Add goal'),
          ),
        ],
      ),
    );
  }
}
