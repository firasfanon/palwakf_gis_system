import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/endower_reference.dart';
import '../../domain/models/endowment_reference.dart';
import '../../domain/models/waqf_reference_bundle.dart';
import '../../domain/repositories/waqf_reference_repository.dart';

class WaqfReferenceRepositoryImpl implements WaqfReferenceRepository {
  WaqfReferenceRepositoryImpl({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _endowmentTables = ['waqf_lands', 'waqf_assets', 'endowments', 'waqf_endowments'];
  static const _endowerTables = ['waqf_endowers', 'endowers'];
  static const _gisWaqfLayerKeys = ['waqf_lands', 'waqf_assets'];
  static const _coreLguSchema = 'core';
  static const _coreLguTable = 'core_lgus';
  static const _coreLguSearchRpc = 'rpc_waqf_lgu_search_v1';

  // Approximate Palestine-wide bounds in EPSG:4326.
  static const double _west = 34.15;
  static const double _south = 29.30;
  static const double _east = 35.95;
  static const double _north = 33.45;

  @override
  Future<WaqfReferenceBundle?> getReferenceBundle(String idOrPwf) async {
    final endowment = await getEndowmentByIdOrKey(idOrPwf);
    if (endowment == null) return null;

    EndowerReference? endower;
    final endowerId = (endowment.endowerId ?? '').trim();
    if (endowerId.isNotEmpty) {
      endower = await getEndowerById(endowerId);
    }
    if (endower == null && (endowment.endowerName ?? '').trim().isNotEmpty) {
      endower = EndowerReference(
        id: endowerId.isNotEmpty ? endowerId : 'derived:${endowment.nationalId}',
        nationalId: '',
        nameAr: endowment.endowerName!.trim(),
        governorate: endowment.governorateName,
        city: endowment.cityName,
      );
    }

    return WaqfReferenceBundle(
      endowment: endowment,
      endower: endower,
      isFallback: true,
      sourceLabel: 'waqf reference lookup',
      note: endower == null ? 'لم يُعثر على سجل واقف مستقل؛ تم الاكتفاء ببيانات الوقف المتاحة.' : null,
    );
  }

  @override
  Future<EndowmentReference?> getEndowmentByIdOrKey(String idOrPwf) async {
    final key = idOrPwf.trim();
    if (key.isEmpty) return null;

    final coreExact = await _tryFetchCoreLguExact(key);
    if (coreExact != null) return _mapEndowmentFromCoreLgu(coreExact);

    for (final table in _endowmentTables) {
      final exact = await _tryFetchExact(table, key);
      if (exact != null) return _mapEndowment(exact);
    }

    final gisMatches = await _searchGisWaqfAssets(query: key, limit: 20, exactPreferred: true);
    if (gisMatches.isNotEmpty) {
      return _mapEndowmentFromGis(gisMatches.first);
    }
    return null;
  }

  @override
  Future<EndowerReference?> getEndowerById(String id) async {
    final key = id.trim();
    if (key.isEmpty) return null;
    for (final table in _endowerTables) {
      try {
        final raw = await _client.from(table).select().or('id.eq.${_escape(key)},national_id.eq.${_escape(key)},id_number.eq.${_escape(key)}').limit(1);
        final rows = _asRows(raw);
        if (rows.isNotEmpty) return _mapEndower(rows.first);
      } catch (_) {
        try {
          final raw = await _client.from(table).select().limit(150);
          final rows = _asRows(raw);
          for (final row in rows) {
            if (_matchesAny(row, key, const ['id', 'national_id', 'id_number'])) {
              return _mapEndower(row);
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  @override
  Future<List<EndowmentReference>> searchEndowments({String? query, int limit = 40}) async {
    final normalized = (query ?? '').trim().toLowerCase();
    final out = <EndowmentReference>[];
    final seen = <String>{};

    final coreRows = await _searchCoreLguRows(query: query, limit: normalized.isEmpty ? limit * 3 : limit * 8);
    for (final row in coreRows) {
      final mapped = _mapEndowmentFromCoreLgu(row);
      final id = mapped.id.trim().isNotEmpty ? mapped.id.trim() : mapped.nationalId.trim();
      if (id.isEmpty || !seen.add(id)) continue;
      out.add(mapped);
      if (out.length >= limit) return out;
    }

    for (final table in _endowmentTables) {
      try {
        final raw = await _client.from(table).select().limit(normalized.isEmpty ? limit * 2 : limit * 6);
        for (final row in _asRows(raw)) {
          if (!_rowMatchesQuery(row, normalized)) continue;
          final mapped = _mapEndowment(row);
          final id = mapped.id.trim().isNotEmpty ? mapped.id.trim() : mapped.nationalId.trim();
          if (id.isEmpty || !seen.add(id)) continue;
          out.add(mapped);
          if (out.length >= limit) return out;
        }
      } catch (_) {}
    }

    final gisRows = await _searchGisWaqfAssets(query: query, limit: limit * 3);
    for (final row in gisRows) {
      final mapped = _mapEndowmentFromGis(row);
      final id = mapped.id.trim().isNotEmpty ? mapped.id.trim() : mapped.nationalId.trim();
      if (id.isEmpty || !seen.add(id)) continue;
      out.add(mapped);
      if (out.length >= limit) break;
    }
    return out;
  }



  Future<Map<String, dynamic>?> _tryFetchCoreLguExact(String key) async {
    final normalized = key.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final rpcRows = await _searchCoreLguRows(query: key, limit: 80);
    for (final row in rpcRows) {
      final values = [
        row['id'],
        row['source_id'],
        row['code'],
        row['source_code'],
        row['community_code'],
        row['wakf_name'],
        row['name_ar'],
      ]
          .where((e) => e != null)
          .map((e) => e.toString().trim().toLowerCase());
      if (values.any((value) => value == normalized)) return row;
    }

    if (_looksLikeUuid(normalized)) {
      final wideRows = await _searchCoreLguRows(query: null, limit: 2000);
      for (final row in wideRows) {
        final values = [
          row['id'],
          row['source_id'],
          row['code'],
          row['source_code'],
        ]
            .where((e) => e != null)
            .map((e) => e.toString().trim().toLowerCase());
        if (values.any((value) => value == normalized)) return row;
      }
    }

    try {
      final raw = await _client
          .schema(_coreLguSchema)
          .from(_coreLguTable)
          .select('id, code, community_code, name_ar, name_en, wakf_name, wakf_type, wakf_status, city_status, lgus_no, community_no, sort_order, is_active')
          .limit(2000);
      final rows = _asRows(raw);
      for (final row in rows) {
        if (!_rowHasWaqfData(row)) continue;
        final values = [row['id'], row['code'], row['community_code'], row['wakf_name'], row['name_ar']]
            .where((e) => e != null)
            .map((e) => e.toString().trim().toLowerCase());
        if (values.any((value) => value == normalized)) return row;
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> _searchCoreLguRows({String? query, int limit = 80}) async {
    final normalized = (query ?? '').trim();

    try {
      final raw = await _client.rpc(_coreLguSearchRpc, params: {
        'p_query': normalized.isEmpty ? null : normalized,
        'p_limit': limit,
      });
      final rows = _asRows(raw);
      if (rows.isNotEmpty) return rows;
    } catch (e, st) {
      debugPrint('$_coreLguSearchRpc failed in WaqfReferenceRepositoryImpl: $e');
      debugPrintStack(stackTrace: st);
    }

    try {
      final raw = await _client
          .schema(_coreLguSchema)
          .from(_coreLguTable)
          .select('id, code, community_code, name_ar, name_en, wakf_name, wakf_type, wakf_status, city_status, lgus_no, community_no, sort_order, is_active')
          .limit(2000);
      final out = <Map<String, dynamic>>[];
      for (final row in _asRows(raw)) {
        if (!_rowHasWaqfData(row)) continue;
        if (!_matchesCoreLguQuery(row, normalized.toLowerCase())) continue;
        out.add(row);
        if (out.length >= limit) break;
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  bool _rowHasWaqfData(Map<String, dynamic> row) {
    bool has(String key) => (row[key] ?? '').toString().trim().isNotEmpty;
    return has('wakf_name') || has('wakf_type') || has('wakf_status');
  }

  bool _looksLikeUuid(String value) {
    final v = value.trim();
    return RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(v);
  }

  bool _matchesCoreLguQuery(Map<String, dynamic> row, String query) {
    if (query.isEmpty) return true;
    final values = [
      row['id'],
      row['code'],
      row['community_code'],
      row['name_ar'],
      row['name_en'],
      row['wakf_name'],
      row['wakf_type'],
      row['wakf_status'],
      row['city_status'],
      row['lgus_no'],
      row['community_no'],
    ].where((e) => e != null).map((e) => e.toString().trim().toLowerCase()).where((e) => e.isNotEmpty);
    return values.any((value) => value.contains(query));
  }

  bool _rowMatchesQuery(Map<String, dynamic> row, String query) {
    if (query.isEmpty) return true;
    final values = [
      row['id'],
      row['pwf_key'],
      row['pwf'],
      row['national_id'],
      row['code'],
      row['name'],
      row['name_ar'],
      row['name_en'],
      row['title'],
      row['title_ar'],
      row['title_en'],
      row['deed_number'],
      row['full_address'],
      row['address'],
      row['governorate'],
      row['governorate_name'],
      row['gov_name'],
      row['gov_ar'],
      row['city'],
      row['city_name'],
      row['community'],
      row['community_name'],
      row['community_ar'],
      row['municipality'],
      row['municipality_name'],
      row['lgu'],
      row['lgu_name'],
      row['basin'],
      row['basin_no'],
      row['basin_number'],
      row['parcel'],
      row['parcel_no'],
      row['parcel_number'],
      row['endower_name'],
      row['founder_name'],
      row['waqif_name'],
      row['type'],
      row['category'],
      row['sub_type'],
      row['status'],
      row['purpose'],
    ]
        .where((e) => e != null)
        .map((e) => e.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty);
    return values.any((value) => value.contains(query));
  }

  Future<Map<String, dynamic>?> _tryFetchExact(String table, String key) async {
    try {
      final raw = await _client.from(table).select().or('id.eq.${_escape(key)},pwf_key.eq.${_escape(key)},pwf.eq.${_escape(key)},national_id.eq.${_escape(key)},code.eq.${_escape(key)}').limit(1);
      final rows = _asRows(raw);
      if (rows.isNotEmpty) return rows.first;
    } catch (_) {
      try {
        final raw = await _client.from(table).select().limit(250);
        final rows = _asRows(raw);
        for (final row in rows) {
          if (_matchesAny(row, key, const ['id', 'pwf_key', 'pwf', 'national_id', 'code'])) {
            return row;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _searchGisWaqfAssets({
    String? query,
    int limit = 60,
    bool exactPreferred = false,
  }) async {
    final q = (query ?? '').trim().toLowerCase();
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final layerKey in _gisWaqfLayerKeys) {
      try {
        final raw = await _client.schema('gis').rpc(
          'rpc_layer_features_in_bounds',
          params: {
            'p_layer_key': layerKey,
            'p_minx': _west,
            'p_miny': _south,
            'p_maxx': _east,
            'p_maxy': _north,
            'p_limit': exactPreferred ? 600 : 900,
            'p_unit_id': '00000000-0000-0000-0000-000000000000',
          },
        );

        final rows = _asRows(raw);
        final filtered = rows.where((row) => _gisRowMatches(row, q, exactPreferred: exactPreferred)).toList(growable: false);
        for (final row in filtered) {
          final mapped = _mapEndowmentFromGis(row);
          if (!seen.add(mapped.id)) continue;
          out.add(row);
          if (out.length >= limit) return out;
        }
      } catch (_) {}
    }

    return out;
  }

  bool _gisRowMatches(Map<String, dynamic> row, String query, {bool exactPreferred = false}) {
    if (query.isEmpty) return true;
    final props = (row['props'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final values = <String>[
      row['id']?.toString() ?? '',
      row['title_ar']?.toString() ?? '',
      row['title_en']?.toString() ?? '',
      props['pwf_key']?.toString() ?? '',
      props['pwf']?.toString() ?? '',
      props['pwfKey']?.toString() ?? '',
      props['code']?.toString() ?? '',
      props['name']?.toString() ?? '',
      props['name_ar']?.toString() ?? '',
      props['title_ar']?.toString() ?? '',
      props['community']?.toString() ?? '',
      props['community_name']?.toString() ?? '',
      props['community_ar']?.toString() ?? '',
      props['municipality']?.toString() ?? '',
      props['lgu']?.toString() ?? '',
      props['lgu_name']?.toString() ?? '',
      props['governorate']?.toString() ?? '',
      props['gov_name']?.toString() ?? '',
      props['gov_ar']?.toString() ?? '',
      props['endower_name']?.toString() ?? '',
      props['founder_name']?.toString() ?? '',
      props['waqif_name']?.toString() ?? '',
      props['deed_number']?.toString() ?? '',
      props['type']?.toString() ?? '',
      props['status']?.toString() ?? '',
    ].map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList(growable: false);

    if (exactPreferred) {
      if (values.any((value) => value == query)) return true;
      final pwfCandidates = ['pwf_key', 'pwf', 'pwfKey', 'code'];
      for (final key in pwfCandidates) {
        final v = props[key]?.toString().trim().toLowerCase();
        if (v == query) return true;
      }
    }

    return values.any((value) => value.contains(query));
  }

  EndowmentReference _mapEndowmentFromCoreLgu(Map<String, dynamic> row) {
    final lguName = (row['name_ar'] ?? '').toString().trim();
    final wakfName = (row['wakf_name'] ?? '').toString().trim();
    final wakfType = (row['wakf_type'] ?? '').toString().trim();
    final wakfStatus = (row['wakf_status'] ?? '').toString().trim();
    final cityStatus = (row['city_status'] ?? '').toString().trim();

    final code = (row['code'] ?? row['source_code'] ?? '').toString().trim();
    final sourceId = (row['source_id'] ?? row['id'] ?? '').toString().trim();
    final id = code.isNotEmpty ? code : sourceId;
    final location = lguName.isNotEmpty ? lguName : code;
    final nameEn = (row['name_en'] ?? '').toString().trim();

    return EndowmentReference(
      id: id.isNotEmpty ? id : code,
      nationalId: code,
      nameAr: wakfName.isNotEmpty ? wakfName : location,
      nameEn: nameEn.isEmpty ? null : nameEn,
      type: wakfType.isEmpty ? null : wakfType,
      subType: null,
      category: cityStatus.isEmpty ? null : cityStatus,
      endowerId: null,
      endowerName: null,
      governorateName: null,
      cityName: location,
      fullAddress: code.isEmpty ? null : code,
      totalArea: null,
      status: wakfStatus.isNotEmpty ? wakfStatus : (cityStatus.isEmpty ? null : cityStatus),
      purpose: lguName.isEmpty ? null : 'الهيئة المحلية: $lguName',
      conditions: null,
      historicalNotes: 'مرجع وقفي مشتق من core.core_lgus ومُثْرى من gis.lgus_boundary.',
      legalNotes: null,
      latitude: null,
      longitude: null,
    );
  }

  EndowmentReference _mapEndowment(Map<String, dynamic> row) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = row[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    double? pickDouble(List<String> keys) {
      for (final key in keys) {
        final value = row[key];
        if (value == null) continue;
        if (value is num) return value.toDouble();
        final parsed = double.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
      return null;
    }

    final nameEn = pick(['name_en', 'title_en']);
    final type = pick(['type', 'type_ar', 'asset_type']);
    final subType = pick(['sub_type', 'subtype', 'asset_sub_type']);
    final category = pick(['category']);
    final endowerId = pick(['endower_id']);
    final endowerName = pick(['endower_name', 'founder_name', 'waqif_name']);
    final governorateName = pick(['governorate_name', 'governorate', 'gov_name', 'gov_ar']);
    final cityName = pick(['city_name', 'city', 'community', 'community_name', 'community_ar']);
    final fullAddress = pick(['full_address', 'address']);
    final status = pick(['status']);
    final purpose = pick(['purpose']);
    final conditions = pick(['conditions']);
    final historicalNotes = pick(['historical_notes', 'general_notes']);
    final legalNotes = pick(['legal_notes']);

    return EndowmentReference(
      id: pick(['id', 'uuid', 'land_id', 'gid']).isEmpty ? pick(['national_id', 'pwf_key', 'pwf', 'code']) : pick(['id', 'uuid', 'land_id', 'gid']),
      nationalId: pick(['national_id', 'pwf_key', 'pwf', 'code']),
      nameAr: pick(['name_ar', 'title_ar', 'name', 'title']),
      nameEn: nameEn.isEmpty ? null : nameEn,
      type: type.isEmpty ? null : type,
      subType: subType.isEmpty ? null : subType,
      category: category.isEmpty ? null : category,
      endowerId: endowerId.isEmpty ? null : endowerId,
      endowerName: endowerName.isEmpty ? null : endowerName,
      governorateName: governorateName.isEmpty ? null : governorateName,
      cityName: cityName.isEmpty ? null : cityName,
      fullAddress: fullAddress.isEmpty ? null : fullAddress,
      totalArea: pickDouble(['total_area', 'area']),
      status: status.isEmpty ? null : status,
      purpose: purpose.isEmpty ? null : purpose,
      conditions: conditions.isEmpty ? null : conditions,
      historicalNotes: historicalNotes.isEmpty ? null : historicalNotes,
      legalNotes: legalNotes.isEmpty ? null : legalNotes,
      latitude: pickDouble(['latitude', 'lat']),
      longitude: pickDouble(['longitude', 'lng', 'lon']),
    );
  }

  EndowmentReference _mapEndowmentFromGis(Map<String, dynamic> row) {
    final props = (row['props'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    String pick(List<String> keys) {
      for (final key in keys) {
        final direct = row[key];
        if (direct != null) {
          final text = direct.toString().trim();
          if (text.isNotEmpty) return text;
        }
        final value = props[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    double? pickDouble(List<String> keys) {
      for (final key in keys) {
        final direct = row[key] ?? props[key];
        if (direct == null) continue;
        if (direct is num) return direct.toDouble();
        final parsed = double.tryParse(direct.toString());
        if (parsed != null) return parsed;
      }
      return null;
    }

    double? centroidCoord(int index) {
      final centroid = row['centroid'];
      if (centroid is Map) {
        final coords = centroid['coordinates'];
        if (coords is List && coords.length > index) {
          final value = coords[index];
          if (value is num) return value.toDouble();
          return double.tryParse(value.toString());
        }
      }
      return null;
    }

    final nameAr = pick(['name_ar', 'title_ar', 'label_ar', 'name', 'title']);
    final nameEn = pick(['name_en', 'title_en', 'label_en']);
    final pwf = pick(['pwf_key', 'pwf', 'pwfKey', 'code']);
    final governorate = pick(['governorate', 'governorate_name', 'gov_name', 'gov_ar']);
    final city = pick(['community', 'community_name', 'community_ar', 'city', 'city_name']);
    final municipality = pick(['municipality', 'lgu', 'lgu_name', 'municipality_name']);
    final status = pick(['status']);
    final purpose = pick(['purpose']);
    final type = pick(['type', 'type_ar', 'asset_type']);
    final category = pick(['category']);
    final endowerName = pick(['endower_name', 'founder_name', 'waqif_name']);

    return EndowmentReference(
      id: pick(['id']).isEmpty ? (pwf.isNotEmpty ? pwf : nameAr.isNotEmpty ? nameAr : row['id']?.toString() ?? 'gis-waqf') : pick(['id']),
      nationalId: pwf,
      nameAr: nameAr,
      nameEn: nameEn.isEmpty ? null : nameEn,
      type: type.isEmpty ? null : type,
      category: category.isEmpty ? null : category,
      endowerName: endowerName.isEmpty ? null : endowerName,
      governorateName: governorate.isEmpty ? null : governorate,
      cityName: city.isEmpty ? (municipality.isEmpty ? null : municipality) : city,
      fullAddress: municipality.isEmpty ? null : municipality,
      totalArea: pickDouble(['area', 'total_area']),
      status: status.isEmpty ? null : status,
      purpose: purpose.isEmpty ? null : purpose,
      historicalNotes: 'تم توليد هذا المرجع من طبقة GIS الوقفية لغايات الاستكشاف والربط.',
      latitude: centroidCoord(1) ?? pickDouble(['latitude', 'lat']),
      longitude: centroidCoord(0) ?? pickDouble(['longitude', 'lng', 'lon']),
    );
  }

  EndowerReference _mapEndower(Map<String, dynamic> row) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = row[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    int? pickInt(List<String> keys) {
      for (final key in keys) {
        final value = row[key];
        if (value == null) continue;
        if (value is num) return value.toInt();
        final parsed = int.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
      return null;
    }

    final nameEn = pick(['name_en']);
    final gender = pick(['gender']);
    final status = pick(['status']);
    final nationality = pick(['nationality']);
    final city = pick(['city']);
    final governorate = pick(['governorate']);
    final familyHistory = pick(['family_history']);

    return EndowerReference(
      id: pick(['id']),
      nationalId: pick(['national_id', 'id_number']),
      nameAr: pick(['name_ar', 'name']),
      nameEn: nameEn.isEmpty ? null : nameEn,
      gender: gender.isEmpty ? null : gender,
      status: status.isEmpty ? null : status,
      nationality: nationality.isEmpty ? null : nationality,
      city: city.isEmpty ? null : city,
      governorate: governorate.isEmpty ? null : governorate,
      endowmentCount: pickInt(['endowment_count']),
      familyHistory: familyHistory.isEmpty ? null : familyHistory,
    );
  }

  List<Map<String, dynamic>> _asRows(dynamic raw) {
    if (raw is List) return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(growable: false);
    if (raw is Map<String, dynamic>) return [raw];
    return const [];
  }

  bool _matchesAny(Map<String, dynamic> row, String key, List<String> columns) {
    final lowered = key.trim().toLowerCase();
    for (final column in columns) {
      final value = row[column];
      if (value == null) continue;
      if (value.toString().trim().toLowerCase() == lowered) return true;
    }
    return false;
  }

  String _escape(String value) => value.replaceAll(',', r'\,').replaceAll('(', '').replaceAll(')', '');
}
