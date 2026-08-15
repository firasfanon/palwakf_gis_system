import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../history_explorer/application/providers/history_explorer_providers.dart';
import '../../../map/data/repositories/map_feedback_repository.dart';
import '../../data/repositories/smart_explorer_repository.dart';

final smartExplorerRepositoryProvider = Provider<SmartExplorerRepository>((ref) {
  return SmartExplorerRepository(
    waqfAssetRepository: ref.watch(waqfAssetRepositoryProvider),
    mapFeedbackRepository: ref.watch(mapFeedbackRepositoryProvider),
  );
});
