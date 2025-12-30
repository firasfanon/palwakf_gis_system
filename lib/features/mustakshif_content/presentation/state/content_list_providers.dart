import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_client_provider.dart';
import '../../data/mustakshif_content_repository.dart';
import '../../domain/enums/mustakshif_content_type.dart';
import '../../domain/models/mustakshif_content_item.dart';

final mustakshifContentRepositoryProvider = Provider<MustakshifContentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MustakshifContentRepository(client);
});

class ContentListArgs {
  const ContentListArgs({
    required this.type,
    required this.adminMode,
    this.historicalPeriodId,
  });

  final MustakshifContentType type;
  final bool adminMode;
  final int? historicalPeriodId;

  @override
  bool operator ==(Object other) =>
      other is ContentListArgs &&
      other.type == type &&
      other.adminMode == adminMode &&
      other.historicalPeriodId == historicalPeriodId;

  @override
  int get hashCode => Object.hash(type, adminMode, historicalPeriodId);
}

final mustakshifContentListProvider = FutureProvider.family<List<MustakshifContentItem>, ContentListArgs>(
  (ref, args) async {
    final repo = ref.watch(mustakshifContentRepositoryProvider);
    return repo.fetchList(
      type: args.type,
      adminMode: args.adminMode,
      historicalPeriodId: args.historicalPeriodId,
    );
  },
);
