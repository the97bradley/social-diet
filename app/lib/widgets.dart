import 'package:flutter/material.dart';

import 'theme.dart';

class PulseCard extends StatelessWidget {
  const PulseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: PulseTheme.moss,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PulseTheme.leaf),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: PulseTheme.mist,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class AvatarMark extends StatelessWidget {
  const AvatarMark({super.key, required this.initials, this.size = 40});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PulseTheme.leaf,
        shape: BoxShape.circle,
        border: Border.all(color: PulseTheme.lime.withValues(alpha: 0.4)),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: PulseTheme.lime,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(text, style: const TextStyle(color: PulseTheme.mist)),
    );
  }
}

String errorMessage(Object error) {
  final raw = error.toString();
  final text = raw.toLowerCase();
  if (text.contains('email rate limit') ||
      text.contains('over_email_send_rate_limit')) {
    return 'Too many confirmation emails just now. Wait a few minutes and try again, or sign in if the account already exists.';
  }
  if (text.contains('already registered') ||
      text.contains('user_already_exists') ||
      text.contains('email_exists')) {
    return 'That email already has an account. Sign in instead.';
  }
  return raw;
}

Future<void> showError(BuildContext context, Object error) {
  return ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(errorMessage(error))))
      .closed;
}

class GoalChip extends StatelessWidget {
  const GoalChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: PulseTheme.lime,
      labelStyle: TextStyle(
        color: selected ? PulseTheme.ink : PulseTheme.cream,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
