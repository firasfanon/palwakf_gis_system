import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums/mustakshif_content_type.dart';
import '../../domain/models/mustakshif_content_item.dart';
import 'content_list_providers.dart';

class ContentDetailsArgs {
  const ContentDetailsArgs({
    required this.type,
    required this.id,
  });

  final MustakshifContentType type;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is ContentDetailsArgs && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}

final mustakshifContentByIdProvider = FutureProvider.family<MustakshifContentItem?, ContentDetailsArgs>(
  (ref, args) async {
    final repo = ref.watch(mustakshifContentRepositoryProvider);
    return repo.fetchById(type: args.type, id: args.id);
  },
);
