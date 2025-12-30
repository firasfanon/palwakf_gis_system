import 'package:flutter/material.dart';

class ContentLoadingState extends StatelessWidget {
  const ContentLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    // Simple skeleton-like placeholders (no extra deps).
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                _Line(widthFactor: .7),
                SizedBox(height: 10),
                _Line(widthFactor: 1),
                SizedBox(height: 6),
                _Line(widthFactor: .85),
                SizedBox(height: 10),
                _Line(widthFactor: .4),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Align(
      alignment: Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 12,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class ContentEmptyState extends StatelessWidget {
  const ContentEmptyState({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 52, color: theme.colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              message,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class ContentErrorState extends StatelessWidget {
  const ContentErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 44, color: theme.colorScheme.error),
                const SizedBox(height: 10),
                Text(
                  'حدث خطأ أثناء تحميل المحتوى',
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة', textDirection: TextDirection.rtl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
