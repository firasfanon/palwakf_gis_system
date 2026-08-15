import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/smart_explorer_controller.dart';
import '../state/smart_explorer_state.dart';

export 'smart_explorer_repository_provider.dart';

final smartExplorerControllerProvider =
    NotifierProvider<SmartExplorerController, SmartExplorerState>(
  SmartExplorerController.new,
);
