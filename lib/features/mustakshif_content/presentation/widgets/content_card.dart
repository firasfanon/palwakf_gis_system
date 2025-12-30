import 'package:flutter/material.dart';

import '../../domain/enums/mustakshif_content_type.dart';
import '../../domain/models/mustakshif_content_item.dart';

class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.item,
    this.onTap,
    this.showTypeBadge = true,
  });

  final MustakshifContentItem item;
  final VoidCallback? onTap;
  final bool showTypeBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAnnouncement = item.type == MustakshifContentType.announcements;
    final isPinned = isAnnouncement && (item.isPinned ?? false);

    final excerpt = _safeExcerpt(item);

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: [
                  if (showTypeBadge) _TypeBadge(type: item.type),
                  if (isPinned) const _PinnedBadge(),
                  if (item.publishDate != null)
                    _MetaChip(
                      icon: Icons.calendar_month_outlined,
                      label: _formatDate(item.publishDate!),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                textDirection: TextDirection.rtl,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              if (excerpt.isNotEmpty)
                Text(
                  excerpt,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (isAnnouncement && (item.priority ?? 0) > 0)
                    _PriorityBadge(priority: item.priority ?? 0),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.read_more_outlined),
                    label: const Text('اقرأ المزيد', textDirection: TextDirection.rtl),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _safeExcerpt(MustakshifContentItem item) {
    final ex = (item.excerpt ?? '').trim();
    if (ex.isNotEmpty) return ex;

    final c = item.content.trim();
    if (c.isEmpty) return '';

    // Keep it dependency-free.
    final normalized = c.replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 220) return normalized;
    return '${normalized.substring(0, 220)}...';
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final MustakshifContentType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNews = type == MustakshifContentType.news;

    final bg = (isNews ? theme.colorScheme.secondary : theme.colorScheme.tertiary).withValues(alpha: 0.16);
    final fg = isNews ? theme.colorScheme.secondary : theme.colorScheme.tertiary;
    final label = isNews ? 'خبر' : 'إعلان';

    return _Pill(
      background: bg,
      foreground: fg,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isNews ? Icons.article_outlined : Icons.campaign_outlined, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label, textDirection: TextDirection.rtl),
        ],
      ),
    );
  }
}

class _PinnedBadge extends StatelessWidget {
  const _PinnedBadge();

  static const Color _pinnedColor = Color(0xFFB22222);

  @override
  Widget build(BuildContext context) {
    return _Pill(
      background: _pinnedColor.withValues(alpha: 0.12),
      foreground: _pinnedColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.push_pin_outlined, size: 16, color: _pinnedColor),
          SizedBox(width: 6),
          Text('مثبّت', textDirection: TextDirection.rtl),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final int priority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.colorScheme.primary;
    final bg = fg.withValues(alpha: 0.10);
    return _Pill(
      background: bg,
      foreground: fg,
      child: Text('أولوية: $priority', textDirection: TextDirection.rtl),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSurface.withValues(alpha: 0.72);
    final bg = theme.colorScheme.onSurface.withValues(alpha: 0.06);
    return _Pill(
      background: bg,
      foreground: fg,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label, textDirection: TextDirection.rtl),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.background,
    required this.foreground,
    required this.child,
  });

  final Color background;
  final Color foreground;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: DefaultTextStyle(
          style: theme.textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ) ??
              TextStyle(color: foreground, fontWeight: FontWeight.w700),
          child: child,
        ),
      ),
    );
  }
}
