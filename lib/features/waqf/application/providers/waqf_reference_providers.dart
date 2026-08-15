import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/waqf_reference_repository_impl.dart';
import '../../domain/models/endowment_reference.dart';
import '../../domain/models/waqf_reference_bundle.dart';
import '../../domain/repositories/waqf_reference_repository.dart';

final waqfReferenceRepositoryProvider = Provider<WaqfReferenceRepository>((ref) {
  return WaqfReferenceRepositoryImpl();
});

final waqfReferenceBundleProvider = FutureProvider.family<WaqfReferenceBundle?, String>((ref, idOrPwf) {
  return ref.watch(waqfReferenceRepositoryProvider).getReferenceBundle(idOrPwf);
});

final waqfAdminSearchQueryProvider = StateProvider<String>((ref) => '');

final waqfAdminSearchResultsProvider = FutureProvider<List<EndowmentReference>>((ref) async {
  final query = ref.watch(waqfAdminSearchQueryProvider).trim();
  final client = Supabase.instance.client;

  try {
    final raw = await client.rpc(
      'rpc_waqf_lgu_search_v1',
      params: {
        'p_query': query.isEmpty ? null : query,
        'p_limit': 60,
      },
    );

    final rows = (raw as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);

    debugPrint('rpc_waqf_lgu_search_v1 rows = ${rows.length} for query="$query"');

    return rows.map((row) {
      final code = (row['source_code'] ?? row['code'] ?? '').toString().trim();
      final sourceId = (row['source_id'] ?? row['id'] ?? '').toString().trim();
      final id = code.isNotEmpty ? code : sourceId;
      final lguName = (row['name_ar'] ?? '').toString().trim();
      final wakfName = (row['wakf_name'] ?? '').toString().trim();
      final wakfType = (row['wakf_type'] ?? '').toString().trim();
      final wakfStatus = (row['wakf_status'] ?? '').toString().trim();
      final cityStatus = (row['city_status'] ?? '').toString().trim();
      final nameEn = (row['name_en'] ?? '').toString().trim();

      return EndowmentReference(
        id: id.isNotEmpty ? id : code,
        nationalId: code,
        nameAr: wakfName.isNotEmpty ? wakfName : lguName,
        nameEn: nameEn.isEmpty ? null : nameEn,
        type: wakfType.isEmpty ? null : wakfType,
        subType: null,
        category: cityStatus.isEmpty ? null : cityStatus,
        endowerId: null,
        endowerName: null,
        governorateName: null,
        cityName: lguName.isEmpty ? null : lguName,
        fullAddress: code.isEmpty ? null : code,
        totalArea: null,
        status: wakfStatus.isNotEmpty ? wakfStatus : (cityStatus.isEmpty ? null : cityStatus),
        purpose: lguName.isEmpty ? null : 'الهيئة المحلية: $lguName',
        conditions: null,
        historicalNotes: 'مرجع وقفي مشتق من core.core_lgus عبر rpc_waqf_lgu_search_v1.',
        legalNotes: null,
        latitude: null,
        longitude: null,
      );
    }).toList(growable: false);
  } catch (e, st) {
    debugPrint('waqfAdminSearchResultsProvider direct RPC failed: $e');
    debugPrintStack(stackTrace: st);
    return ref.watch(waqfReferenceRepositoryProvider).searchEndowments(query: query, limit: 60);
  }
});