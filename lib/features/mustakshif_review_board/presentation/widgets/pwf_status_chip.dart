import 'package:flutter/material.dart';

enum PwfStatusTone {
  neutral,
  success,
  warning,
  danger,
}

class PwfStatusChip extends StatelessWidget {
  const PwfStatusChip({
    super.key,
    required this.label,
    this.compact = false,
    this.tone = PwfStatusTone.neutral,
  });

  final String label;
  final bool compact;
  final PwfStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color foreground = switch (tone) {
      PwfStatusTone.success => colorScheme.primary,
      PwfStatusTone.warning => colorScheme.tertiary,
      PwfStatusTone.danger => const Color(0xFFB22222),
      PwfStatusTone.neutral => colorScheme.onSurfaceVariant,
    };
    final Color background = switch (tone) {
      PwfStatusTone.neutral => colorScheme.surfaceContainerHighest,
      _ => foreground.withValues(alpha: 0.10),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
}
