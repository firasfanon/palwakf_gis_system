// ============================================
// 13. MAP REPOSITORY
// ============================================

// lib/features/map/data/repositories/waqf_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/waqf_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/constants/enums.dart';

final waqfRepositoryProvider = Provider<WaqfRepository>((ref) {
  return WaqfRepository(ref.watch(supabaseClientProvider));
});

class WaqfRepository {
  final SupabaseClient _client;

  WaqfRepository(this._client);

  static const List<String> _tablesByPriority = [
    // Newer naming (confirmed in your DB hint)
    'waqf_lands',
    // Legacy naming (older prototypes)
    'waqf_assets',
  ];

  bool _looksLikeMissingTable(String msg) {
    final m = msg.toLowerCase();
    return m.contains('could not find the table') ||
        m.contains('does not exist') ||
        m.contains('42p01') ||
        m.contains('pgrst205');
  }

  Future<List<WaqfModel>> searchWaqf({
    String? query,
    String? pwfKey,
    String? governorate,
    String? municipality,
    String? community,
    String? basin,
    String? parcel,
    WaqfType? type,
    WaqfStatus? status,
    double? minArea,
    double? maxArea,
  }) async {
    Object? lastErr;
    for (final table in _tablesByPriority) {
      try {
        var builder = _client.from(table).select();

        if (pwfKey != null && pwfKey.isNotEmpty) {
          builder = builder.ilike('pwf_key', '%$pwfKey%');
        }
        if (governorate != null) {
          builder = builder.eq('governorate', governorate);
        }
        if (municipality != null) {
          builder = builder.eq('municipality', municipality);
        }
        if (community != null) {
          builder = builder.eq('community', community);
        }
        if (basin != null && basin.isNotEmpty) {
          builder = builder.eq('basin', basin);
        }
        if (parcel != null && parcel.isNotEmpty) {
          builder = builder.eq('parcel', parcel);
        }
        if (type != null) {
          builder = builder.eq('type', type.name);
        }
        if (status != null) {
          builder = builder.eq('status', status.name);
        }
        if (minArea != null) {
          builder = builder.gte('area', minArea);
        }
        if (maxArea != null) {
          builder = builder.lte('area', maxArea);
        }

        final response = await builder.limit(100);
        return (response as List)
            .map((e) => WaqfModel.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      } catch (e) {
        lastErr = e;
        final msg = e.toString();
        if (_looksLikeMissingTable(msg)) {
          // try next table
          continue;
        }
        rethrow;
      }
    }
    throw lastErr ??
        Exception('لا توجد جداول بحث متاحة للأراضي/الأصول الوقفية.');
  }

  Future<WaqfModel?> getWaqfById(String id) async {
    Object? lastErr;
    for (final table in _tablesByPriority) {
      try {
        final response =
            await _client.from(table).select().eq('id', id).single();
        return WaqfModel.fromJson((response as Map).cast<String, dynamic>());
      } catch (e) {
        lastErr = e;
        final msg = e.toString();
        if (_looksLikeMissingTable(msg)) continue;
        rethrow;
      }
    }
    throw lastErr ?? Exception('تعذر العثور على السجل.');
  }
}
