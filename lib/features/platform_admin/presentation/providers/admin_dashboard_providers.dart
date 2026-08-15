import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/admin_dashboard_repository.dart';

final adminDashboardCountsProvider =
    FutureProvider<AdminDashboardCounts>((ref) async {
  return ref.watch(adminDashboardRepositoryProvider).loadCounts();
});
