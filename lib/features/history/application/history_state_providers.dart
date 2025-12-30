// lib/features/history/application/history_state_providers.dart

import 'package:flutter_riverpod/legacy.dart';

/// الفترة التاريخية المختارة في الـ GIS / لوحة التاريخ
final selectedHistoricalPeriodIdProvider = StateProvider<int?>(
      (ref) => null,
);

/// طبقات الخرائط التاريخية الظاهرة حاليًا (حسب ID الطبقة)
final visibleHistoricalLayerIdsProvider = StateProvider<Set<int>>(
      (ref) => <int>{},
);
