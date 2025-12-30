import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/enums/mustakshif_content_type.dart';
import '../state/content_list_providers.dart';
import '../widgets/content_list_view.dart';

class AdminMustakshifContentListScreen extends ConsumerWidget {
  const AdminMustakshifContentListScreen({
    super.key,
    required this.type,
  });

  final MustakshifContentType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(
      mustakshifContentListProvider(
        ContentListArgs(type: type, adminMode: true),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(type.labelAr),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () => ref.invalidate(
              mustakshifContentListProvider(ContentListArgs(type: type, adminMode: true)),
            ),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/mustakshif/${type.name}/new'),
        icon: const Icon(Icons.add),
        label: const Text('إضافة'),
      ),
      body: asyncItems.when(
        data: (items) => ContentListView(
          items: items,
          onTapItem: (item) => context.go('/admin/mustakshif/${type.name}/${item.id}/edit'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('حدث خطأ: $e')),
      ),
    );
  }
}
