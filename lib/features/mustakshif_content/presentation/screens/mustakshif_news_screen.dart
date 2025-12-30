import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/content_list_providers.dart';
import '../../domain/enums/mustakshif_content_type.dart';
import '../widgets/content_list_view.dart';

class MustakshifNewsScreen extends ConsumerWidget {
  const MustakshifNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(
      mustakshifContentListProvider(
        const ContentListArgs(type: MustakshifContentType.news, adminMode: false),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('أخبار المستكشف')),
      body: asyncItems.when(
        data: (items) => ContentListView(items: items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('حدث خطأ: $e')),
      ),
    );
  }
}
