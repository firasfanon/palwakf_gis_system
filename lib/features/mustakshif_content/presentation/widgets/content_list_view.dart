import 'package:flutter/material.dart';

import '../../domain/models/mustakshif_content_item.dart';
import 'content_card.dart';

class ContentListView extends StatelessWidget {
  const ContentListView({
    super.key,
    required this.items,
    this.onTapItem,
    this.showTypeBadge = false,
  });

  final List<MustakshifContentItem> items;
  final void Function(MustakshifContentItem item)? onTapItem;
  final bool showTypeBadge;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('لا يوجد محتوى للعرض'));
    }

    return ListView.separated(
      itemCount: items.length,
      padding: const EdgeInsets.all(12),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return ContentCard(
          item: item,
          showTypeBadge: showTypeBadge,
          onTap: onTapItem == null ? null : () => onTapItem!(item),
        );
      },
    );
  }
}
