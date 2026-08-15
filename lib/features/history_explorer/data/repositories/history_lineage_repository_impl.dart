import 'dart:convert';

import '../../domain/models/history_lineage_node.dart';
import '../../domain/models/history_modern_context.dart';
import '../../domain/models/history_overlay_feature.dart';
import '../../domain/models/history_resolved_context.dart';
import '../../domain/models/history_waqf_asset_link.dart';
import '../../domain/repositories/history_lineage_repository.dart';
import '../datasources/history_explorer_remote_datasource.dart';

class HistoryLineageRepositoryImpl implements HistoryLineageRepository {
  HistoryLineageRepositoryImpl(this._remote);

  final HistoryExplorerRemoteDataSource _remote;

  @override
  Future<HistoryResolvedContext> resolveContext({
    required int periodNo,
    required HistoryOverlayFeature feature,
  }) async {
    final rpcResolved = await _remote.tryResolveHistoricalContextRpc(
      periodNo: periodNo,
      sourceId: feature.sourceId,
      entityCode: feature.entityCode,
      labelAr: feature.labelAr,
      labelEn: feature.labelEn,
      levelKey: feature.levelKey,
    );
    final parsedRpc = _parseResolvedContextFromRpc(rpcResolved);
    if (parsedRpc != null && parsedRpc.hasAnyData) {
      return parsedRpc;
    }

    final candidates = <String>{
      if ((feature.entityCode ?? '').trim().isNotEmpty) feature.entityCode!.trim(),
      feature.sourceId.trim(),
      feature.displayLabel.trim(),
      feature.labelAr.trim(),
      feature.labelEn.trim(),
    }..removeWhere((e) => e.isEmpty);

    final matchedRows = await _remote.fetchHistoricalUnitsByCodes(
      periodNo: periodNo,
      codes: candidates.toList(growable: false),
    );

    if (matchedRows.isEmpty) {
      return HistoryResolvedContext(
        lineageNodes: [
          HistoryLineageNode(
            id: feature.sourceId,
            label: feature.displayLabel,
            periodId: periodNo,
            periodLabel: feature.periodLabelAr,
            relationLabel: feature.levelKey,
            isPrimary: true,
          ),
        ],
        note: 'تعذر العثور على مطابقة مباشرة داخل public.historical_admin_units لهذه الفترة.',
      );
    }

    final matched = _pickBestMatch(matchedRows, feature);
    final context = await _buildResolvedContextFromUnits(
      matchedRows: matchedRows,
      primaryRow: matched,
      fallbackLabel: feature.displayLabel,
      fallbackPeriodLabel: feature.periodLabelAr,
      fallbackRelationLabel: feature.levelKey,
    );
    return _enrichResolvedContextSpatially(context, historicalFeature: feature);
  }

  @override
  Future<List<HistoryModernContext>> searchModernContexts({String? query}) async {
    final contexts = await _loadAllModernContexts();
    final normalized = query?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) {
      return contexts.take(120).toList(growable: false);
    }
    final filtered = contexts.where((item) {
      return item.communityLabel.toLowerCase().contains(normalized) ||
          item.communityCode.toLowerCase().contains(normalized) ||
          (item.lguLabel ?? '').toLowerCase().contains(normalized) ||
          (item.governorateLabel ?? '').toLowerCase().contains(normalized);
    }).take(120).toList(growable: false);
    return _enrichModernContextsWithCenters(filtered.take(24).toList(growable: false));
  }

  @override
  Future<HistoryResolvedContext> resolveContextFromModern({required HistoryModernContext context}) async {
    final enrichedContext = await _enrichModernContextCenter(context);
    final rpcResolved = await _remote.tryResolveModernContextRpc(
      communityCode: enrichedContext.communityCode,
      communityLabel: enrichedContext.communityLabel,
    );
    final parsedRpc = _parseResolvedContextFromRpc(rpcResolved);
    if (parsedRpc != null && parsedRpc.hasAnyData) {
      return parsedRpc;
    }

    final matchedRows = await _remote.fetchHistoricalUnitsByOriginCommunityCodes([enrichedContext.communityCode]);
    if (matchedRows.isEmpty) {
      return HistoryResolvedContext(
        modernContexts: [enrichedContext],
        note: 'لم يتم العثور على وحدات تاريخية مرتبطة بـ origin_community_code = ${enrichedContext.communityCode}.',
      );
    }
    final sorted = [...matchedRows]..sort((a, b) => (_asInt(a['period_id']) ?? 9999).compareTo(_asInt(b['period_id']) ?? 9999));
    final result = await _buildResolvedContextFromUnits(
      matchedRows: sorted,
      primaryRow: sorted.first,
      fallbackLabel: enrichedContext.communityLabel,
      fallbackPeriodLabel: 'مرجع حديث',
      fallbackRelationLabel: 'community origin',
      forcedModernContexts: [enrichedContext],
    );
    return _enrichResolvedContextSpatially(result, modernSelection: enrichedContext);
  }

  @override
  Future<List<HistoryWaqfAssetLink>> searchWaqfAssets({String? query}) async {
    final rows = await _remote.fetchWaqfAssets(query: query, limit: (query?.trim().isEmpty ?? true) ? 60 : 120);
    final items = <HistoryWaqfAssetLink>[];
    final seen = <String>{};
    for (final row in rows) {
      final mapped = _mapWaqfAsset(row);
      if (!seen.add(mapped.id)) continue;
      items.add(mapped);
    }
    items.sort((a, b) => (a.name ?? a.pwfKey).compareTo(b.name ?? b.pwfKey));
    return items;
  }

  @override
  Future<HistoryResolvedContext> resolveContextFromWaqf({required HistoryWaqfAssetLink asset}) async {
    final rpcResolved = await _remote.tryResolveWaqfContextRpc(
      assetId: asset.id,
      pwfKey: asset.pwfKey,
      assetName: asset.name,
    );
    final parsedRpc = _parseResolvedContextFromRpc(rpcResolved);
    if (parsedRpc != null && parsedRpc.hasAnyData) {
      return parsedRpc;
    }

    final supplementalRows = await _remote.fetchWaqfAssets(
      query: asset.pwfKey.trim().isNotEmpty && asset.pwfKey != '—'
          ? asset.pwfKey
          : ((asset.name ?? '').trim().isNotEmpty ? asset.name : asset.id),
      limit: 24,
    );
    final enrichedAsset = _mergeAssetWithRows(asset, supplementalRows);

    var matchedContexts = await _resolveModernContextsFromWaqfRows(supplementalRows);
    if (matchedContexts.isEmpty) {
      final candidates = await searchModernContexts(
        query: enrichedAsset.community ?? enrichedAsset.municipality ?? enrichedAsset.governorate ?? enrichedAsset.name ?? enrichedAsset.pwfKey,
      );
      matchedContexts = await _enrichModernContextsWithCenters(_matchAssetToContexts(enrichedAsset, candidates));
    }

    if (matchedContexts.isEmpty) {
      return HistoryResolvedContext(
        waqfAssets: [enrichedAsset],
        note: 'تم العثور على الأصل الوقفي، لكن لم تُحسم بعد مطابقة المجتمع/الهيئة المحلية الحديثة له بشكل آلي.',
      );
    }

    final historicalRows = await _remote.fetchHistoricalUnitsByOriginCommunityCodes(
      matchedContexts.map((e) => e.communityCode).toList(growable: false),
    );
    if (historicalRows.isEmpty) {
      return HistoryResolvedContext(
        modernContexts: matchedContexts,
        waqfAssets: [enrichedAsset],
        note: 'تم العثور على مرجع حديث محتمل للأصل الوقفي، لكن لم تُعثر وحدات تاريخية مرتبطة به داخل historical_admin_units.',
      );
    }

    final sorted = [...historicalRows]..sort((a, b) => (_asInt(a['period_id']) ?? 9999).compareTo(_asInt(b['period_id']) ?? 9999));
    final result = await _buildResolvedContextFromUnits(
      matchedRows: sorted,
      primaryRow: sorted.first,
      fallbackLabel: enrichedAsset.name ?? enrichedAsset.pwfKey,
      fallbackPeriodLabel: 'أصل وقفي حديث',
      fallbackRelationLabel: 'waqf asset',
      forcedModernContexts: matchedContexts,
      forcedWaqfAssets: [enrichedAsset],
    );
    return _enrichResolvedContextSpatially(result, waqfSelection: enrichedAsset);
  }


  Future<List<HistoryModernContext>> _resolveModernContextsFromWaqfRows(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return const [];
    final directCodes = <String>{};
    for (final row in rows) {
      for (final key in const ['community_code', 'origin_community_code', 'code']) {
        final value = _readString(row[key]);
        if (value != null && value.trim().isNotEmpty) {
          directCodes.add(value.trim());
        }
      }
      final props = _readMap(row['props']);
      for (final key in const ['community_code', 'origin_community_code', 'code']) {
        final value = _readString(props[key]);
        if (value != null && value.trim().isNotEmpty) {
          directCodes.add(value.trim());
        }
      }
    }
    if (directCodes.isNotEmpty) {
      final exact = await _resolveModernContexts(directCodes.toList(growable: false));
      final enriched = await _enrichModernContextsWithCenters(exact);
      if (enriched.isNotEmpty) return enriched;
    }

    final textCandidates = <String>{};
    for (final row in rows) {
      for (final key in const ['community', 'community_name', 'community_ar', 'municipality', 'lgu_name', 'name_ar', 'title_ar']) {
        final value = _readString(row[key]);
        if (value != null && value.trim().isNotEmpty) {
          textCandidates.add(value.trim());
        }
      }
      final props = _readMap(row['props']);
      for (final key in const ['community', 'community_name', 'community_ar', 'municipality', 'lgu_name', 'name_ar', 'title_ar']) {
        final value = _readString(props[key]);
        if (value != null && value.trim().isNotEmpty) {
          textCandidates.add(value.trim());
        }
      }
    }

    final merged = <HistoryModernContext>[];
    final seen = <String>{};
    for (final candidate in textCandidates) {
      final found = await searchModernContexts(query: candidate);
      for (final item in found) {
        if (!seen.add(item.communityCode)) continue;
        merged.add(item);
        if (merged.length >= 6) break;
      }
      if (merged.length >= 6) break;
    }
    return _enrichModernContextsWithCenters(merged);
  }

  HistoryWaqfAssetLink _mergeAssetWithRows(
    HistoryWaqfAssetLink base,
    List<Map<String, dynamic>> rows,
  ) {
    if (rows.isEmpty) return base;
    Map<String, dynamic>? best;
    final targetPwf = base.pwfKey.trim().toLowerCase();
    final targetName = (base.name ?? '').trim().toLowerCase();
    for (final row in rows) {
      final mapped = _mapWaqfAsset(row);
      final candidatePwf = mapped.pwfKey.trim().toLowerCase();
      final candidateName = (mapped.name ?? '').trim().toLowerCase();
      final pwfExact = targetPwf.isNotEmpty && candidatePwf == targetPwf;
      final nameExact = targetName.isNotEmpty && candidateName == targetName;
      if (pwfExact || nameExact) {
        best = row;
        break;
      }
      best ??= row;
    }
    if (best == null) return base;
    final mapped = _mapWaqfAsset(best);
    return HistoryWaqfAssetLink(
      id: base.id.trim().isNotEmpty && base.id != 'unknown' ? base.id : mapped.id,
      pwfKey: base.pwfKey.trim().isNotEmpty && base.pwfKey != '—' ? base.pwfKey : mapped.pwfKey,
      name: (base.name ?? '').trim().isNotEmpty ? base.name : mapped.name,
      governorate: (base.governorate ?? '').trim().isNotEmpty ? base.governorate : mapped.governorate,
      community: (base.community ?? '').trim().isNotEmpty ? base.community : mapped.community,
      municipality: (base.municipality ?? '').trim().isNotEmpty ? base.municipality : mapped.municipality,
      area: base.area ?? mapped.area,
      typeLabel: (base.typeLabel ?? '').trim().isNotEmpty ? base.typeLabel : mapped.typeLabel,
      categoryLabel: (base.categoryLabel ?? '').trim().isNotEmpty ? base.categoryLabel : mapped.categoryLabel,
      endowerName: (base.endowerName ?? '').trim().isNotEmpty ? base.endowerName : mapped.endowerName,
      statusLabel: (base.statusLabel ?? '').trim().isNotEmpty ? base.statusLabel : mapped.statusLabel,
      purpose: (base.purpose ?? '').trim().isNotEmpty ? base.purpose : mapped.purpose,
      centerLat: base.centerLat ?? mapped.centerLat,
      centerLng: base.centerLng ?? mapped.centerLng,
      geomJson: base.geomJson ?? mapped.geomJson,
      centroidJson: base.centroidJson ?? mapped.centroidJson,
    );
  }

  Future<HistoryResolvedContext> _buildResolvedContextFromUnits({
    required List<Map<String, dynamic>> matchedRows,
    required Map<String, dynamic> primaryRow,
    required String fallbackLabel,
    required String? fallbackPeriodLabel,
    required String? fallbackRelationLabel,
    List<HistoryModernContext>? forcedModernContexts,
    List<HistoryWaqfAssetLink>? forcedWaqfAssets,
  }) async {
    final primaryId = _asInt(primaryRow['id']);
    final primaryCode = _readString(primaryRow['code']);

    final relationRows = primaryId == null
        ? const <Map<String, dynamic>>[]
        : await _remote.fetchHistoricalRelationsByUnitIds(matchedRows.map((row) => _asInt(row['id'])).whereType<int>().toList(growable: false));

    final relatedIds = <int>{
      ...matchedRows.map((row) => _asInt(row['id'])).whereType<int>(),
      ...relationRows.map((row) => _asInt(row['source_historical_admin_unit_id'])).whereType<int>(),
      ...relationRows.map((row) => _asInt(row['target_historical_admin_unit_id'])).whereType<int>(),
      ...matchedRows.map((row) => _asInt(row['parent_id'])).whereType<int>(),
    };

    final relatedUnits = relatedIds.isEmpty
        ? matchedRows
        : await _remote.fetchHistoricalUnitsByIds(relatedIds.toList(growable: false));
    final unitsById = <int, Map<String, dynamic>>{};
    for (final row in relatedUnits) {
      final id = _asInt(row['id']);
      if (id != null) unitsById[id] = row;
    }

    final lineageNodes = <HistoryLineageNode>[];
    final sortedMatches = [...matchedRows]..sort((a, b) => (_asInt(a['period_id']) ?? 9999).compareTo(_asInt(b['period_id']) ?? 9999));
    for (final row in sortedMatches) {
      final id = _asInt(row['id']);
      lineageNodes.add(
        HistoryLineageNode(
          id: '${id ?? primaryCode ?? fallbackLabel}',
          label: _readString(row['code']) ?? fallbackLabel,
          periodId: _asInt(row['period_id']),
          periodLabel: _periodLabel(row),
          relationLabel: id == primaryId ? (fallbackRelationLabel ?? 'match') : 'origin',
          originCommunityCode: _readString(row['origin_community_code']),
          isPrimary: id == primaryId,
        ),
      );
    }

    for (final row in relationRows) {
      final sourceId = _asInt(row['source_historical_admin_unit_id']);
      final targetId = _asInt(row['target_historical_admin_unit_id']);
      final relationType = _readString(row['relation_type']);
      final confidence = _asDouble(row['confidence']);

      int? otherId;
      String direction = relationType ?? 'relation';
      if (primaryId != null && sourceId == primaryId && targetId != null) {
        otherId = targetId;
        direction = '← ${relationType ?? 'relation'}';
      } else if (primaryId != null && targetId == primaryId && sourceId != null) {
        otherId = sourceId;
        direction = '→ ${relationType ?? 'relation'}';
      } else if (sourceId != null && targetId != null) {
        otherId = targetId;
      }
      if (otherId == null) continue;
      final other = unitsById[otherId];
      if (other == null) continue;
      lineageNodes.add(
        HistoryLineageNode(
          id: '$otherId',
          label: _readString(other['code']) ?? '$otherId',
          periodId: _asInt(other['period_id']),
          periodLabel: _periodLabel(other),
          relationLabel: direction,
          originCommunityCode: _readString(other['origin_community_code']),
          confidence: confidence,
        ),
      );
    }

    final originCodes = <String>{
      ...matchedRows.map((row) => _readString(row['origin_community_code'])).whereType<String>(),
      ...relatedUnits.map((row) => _readString(row['origin_community_code'])).whereType<String>(),
    };

    final modernContexts = await _enrichModernContextsWithCenters(
      forcedModernContexts ?? await _resolveModernContexts(originCodes.toList(growable: false)),
    );
    final waqfAssets = <HistoryWaqfAssetLink>[
      ..._attachFallbackCentersToAssets(forcedWaqfAssets ?? const [], modernContexts),
      ...await _resolveWaqfAssets(modernContexts),
    ];

    final uniqueAssets = <HistoryWaqfAssetLink>[];
    final seenAssetIds = <String>{};
    for (final asset in waqfAssets) {
      if (!seenAssetIds.add(asset.id)) continue;
      uniqueAssets.add(asset);
    }

    return HistoryResolvedContext(
      matchedUnitCode: primaryCode,
      matchedUnitPeriodId: _asInt(primaryRow['period_id']),
      lineageNodes: _dedupeLineage(lineageNodes),
      modernContexts: modernContexts,
      waqfAssets: uniqueAssets,
      note: modernContexts.isEmpty ? 'لم يتم العثور على origin_community_code صالح لهذا المسار حتى الآن.' : null,
      resolutionMethod: 'fallback_matching',
      isSovereign: false,
    );
  }

  HistoryResolvedContext? _parseResolvedContextFromRpc(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return null;
    final lineage = _parseLineageNodes(raw['lineage_nodes']);
    final modern = _parseModernContexts(raw['modern_contexts']);
    final waqf = _parseWaqfAssets(raw['waqf_assets']);
    return HistoryResolvedContext(
      matchedUnitCode: _readString(raw['matched_unit_code']),
      matchedUnitPeriodId: _asInt(raw['matched_unit_period_id']),
      lineageNodes: lineage,
      modernContexts: modern,
      waqfAssets: waqf,
      note: _readString(raw['note']),
      resolutionMethod: _readString(raw['resolution_method']) ?? _readString(raw['_rpc_name']) ?? 'rpc',
      isSovereign: true,
    );
  }

  List<HistoryLineageNode> _parseLineageNodes(dynamic raw) {
    final rows = _normalizeJsonList(raw);
    return rows.map((row) {
      return HistoryLineageNode(
        id: _readString(row['id']) ?? _readString(row['code']) ?? 'node',
        label: _readString(row['label']) ?? _readString(row['code']) ?? '—',
        periodId: _asInt(row['period_id']),
        periodLabel: _readString(row['period_label']),
        relationLabel: _readString(row['relation_label']),
        originCommunityCode: _readString(row['origin_community_code']),
        confidence: _asDouble(row['confidence']),
        isPrimary: row['is_primary'] == true,
      );
    }).toList(growable: false);
  }

  List<HistoryModernContext> _parseModernContexts(dynamic raw) {
    final rows = _normalizeJsonList(raw);
    return rows.map((row) {
      return HistoryModernContext(
        communityCode: _readString(row['community_code']) ?? _readString(row['code']) ?? '—',
        communityLabel: _readString(row['community_label']) ?? _readString(row['label']) ?? '—',
        lguCode: _readString(row['lgu_code']),
        lguLabel: _readString(row['lgu_label']),
        governorateCode: _readString(row['governorate_code']),
        governorateLabel: _readString(row['governorate_label']),
        centerLat: _readLat(row),
        centerLng: _readLng(row),
        geomJson: _readGeoMap(row['geom_json']) ?? _readGeoMap(row['geom']) ?? _readGeoMap(row['geometry']),
        centroidJson: _readGeoMap(row['centroid_json']) ?? _readGeoMap(row['centroid']),
      );
    }).toList(growable: false);
  }

  List<HistoryWaqfAssetLink> _parseWaqfAssets(dynamic raw) {
    final rows = _normalizeJsonList(raw);
    return rows.map((row) => _mapWaqfAsset(row)).toList(growable: false);
  }

  List<Map<String, dynamic>> _normalizeJsonList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(growable: false);
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        return _normalizeJsonList(decoded);
      } catch (_) {
        return const [];
      }
    }
    return const [];
  }

  Map<String, dynamic> _pickBestMatch(List<Map<String, dynamic>> rows, HistoryOverlayFeature feature) {
    String? exactCode = feature.entityCode?.trim();
    if (exactCode != null && exactCode.isNotEmpty) {
      for (final row in rows) {
        if ((row['code'] ?? '').toString().trim() == exactCode) return row;
      }
    }
    final sourceId = feature.sourceId.trim();
    for (final row in rows) {
      if ((row['code'] ?? '').toString().trim() == sourceId) return row;
    }
    return rows.first;
  }

  Future<List<HistoryModernContext>> _loadAllModernContexts() async {
    final communities = await _remote.fetchLookupRows(
      rpcName: 'rpc_gis_lookup_communities',
      schema: 'gis',
      preferred: 'v_communities_core',
      fallback: 'communities_boundary',
    );
    final lgus = await _remote.fetchLookupRows(
      rpcName: 'rpc_gis_lookup_lgus',
      schema: 'gis',
      preferred: 'v_lgus_core',
      fallback: 'lgus_boundary',
    );
    final governorates = await _remote.fetchLookupRows(
      rpcName: 'rpc_gis_lookup_governorates',
      schema: 'gis',
      preferred: 'v_governorates_core',
      fallback: 'governorates_boundary',
    );

    final lguByCode = <String, Map<String, dynamic>>{};
    for (final row in lgus) {
      final code = _lookupCode(row);
      if (code.isNotEmpty) lguByCode[code] = row;
    }
    final govByCode = <String, Map<String, dynamic>>{};
    for (final row in governorates) {
      final code = _lookupCode(row);
      if (code.isNotEmpty) govByCode[code] = row;
    }

    final contexts = <HistoryModernContext>[];
    final seen = <String>{};
    for (final community in communities) {
      final code = _lookupCode(community);
      if (code.isEmpty || !seen.add(code)) continue;
      final lguCode = _lookupParentCode(community);
      final lgu = lguCode == null ? null : lguByCode[lguCode];
      final govCode = lgu == null ? null : _lookupParentCode(lgu);
      final gov = govCode == null ? null : govByCode[govCode];
      contexts.add(
        HistoryModernContext(
          communityCode: code,
          communityLabel: _lookupLabel(community),
          lguCode: lguCode,
          lguLabel: lgu == null ? null : _lookupLabel(lgu),
          governorateCode: govCode,
          governorateLabel: gov == null ? null : _lookupLabel(gov),
          centerLat: _readLat(community),
          centerLng: _readLng(community),
          geomJson: _readGeoMap(community['geom_json']) ?? _readGeoMap(community['geom']) ?? _readGeoMap(community['geometry']),
          centroidJson: _readGeoMap(community['centroid_json']) ?? _readGeoMap(community['centroid']),
        ),
      );
    }
    contexts.sort((a, b) => a.communityLabel.compareTo(b.communityLabel));
    return contexts;
  }

  Future<List<HistoryModernContext>> _resolveModernContexts(List<String> originCodes) async {
    if (originCodes.isEmpty) return const [];
    final all = await _loadAllModernContexts();
    final wanted = originCodes.toSet();
    return all.where((item) => wanted.contains(item.communityCode)).toList(growable: false);
  }

  Future<List<HistoryWaqfAssetLink>> _resolveWaqfAssets(List<HistoryModernContext> contexts) async {
    if (contexts.isEmpty) return const [];
    final seen = <String>{};
    final items = <HistoryWaqfAssetLink>[];
    for (final context in contexts.take(3)) {
      final rows = await _remote.fetchWaqfAssetsByContext(
        community: context.communityLabel,
        municipality: context.lguLabel,
        governorate: context.governorateLabel,
      );
      for (final row in rows) {
        var mapped = _mapWaqfAsset(row);
        if (!mapped.hasCenter && context.hasCenter) {
          mapped = mapped.copyWith(centerLat: context.centerLat, centerLng: context.centerLng);
        }
        if (!seen.add(mapped.id)) continue;
        items.add(mapped);
        if (items.length >= 12) return items;
      }
    }
    return items;
  }

  List<HistoryModernContext> _matchAssetToContexts(
    HistoryWaqfAssetLink asset,
    List<HistoryModernContext> candidates,
  ) {
    final community = (asset.community ?? '').trim().toLowerCase();
    final municipality = (asset.municipality ?? '').trim().toLowerCase();
    final governorate = (asset.governorate ?? '').trim().toLowerCase();

    final scored = <MapEntry<HistoryModernContext, int>>[];
    for (final item in candidates) {
      var score = 0;
      final communityLabel = item.communityLabel.toLowerCase();
      final lguLabel = (item.lguLabel ?? '').toLowerCase();
      final govLabel = (item.governorateLabel ?? '').toLowerCase();
      if (community.isNotEmpty && (communityLabel.contains(community) || community.contains(communityLabel))) score += 5;
      if (municipality.isNotEmpty && (lguLabel.contains(municipality) || municipality.contains(lguLabel))) score += 3;
      if (governorate.isNotEmpty && (govLabel.contains(governorate) || governorate.contains(govLabel))) score += 2;
      if (score > 0) scored.add(MapEntry(item, score));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    final out = <HistoryModernContext>[];
    final seen = <String>{};
    for (final entry in scored) {
      if (!seen.add(entry.key.communityCode)) continue;
      out.add(entry.key);
      if (out.length >= 5) break;
    }
    return out;
  }

  HistoryWaqfAssetLink _mapWaqfAsset(Map<String, dynamic> row) {
    return HistoryWaqfAssetLink(
      id: _readString(row['id']) ?? _readString(row['uuid']) ?? _readString(row['land_id']) ?? 'unknown',
      pwfKey: _readString(row['pwf_key']) ?? _readString(row['pwf']) ?? _readString(row['code']) ?? '—',
      name: _readString(row['name']) ?? _readString(row['name_ar']) ?? _readString(row['title']) ?? _readString(row['title_ar']),
      governorate: _readString(row['governorate']) ?? _readString(row['gov_name']) ?? _readString(row['gov_ar']),
      community: _readString(row['community']) ?? _readString(row['community_name']) ?? _readString(row['community_ar']),
      municipality: _readString(row['municipality']) ?? _readString(row['lgu']) ?? _readString(row['lgu_name']),
      area: _asDouble(row['area']) ?? _asDouble(row['total_area']),
      typeLabel: _readString(row['type']) ?? _readString(row['asset_type']) ?? _readString(row['type_ar']),
      categoryLabel: _readString(row['category']),
      endowerName: _readString(row['endower_name']) ?? _readString(row['founder_name']) ?? _readString(row['waqif_name']),
      statusLabel: _readString(row['status']),
      purpose: _readString(row['purpose']),
      centerLat: _readLat(row),
      centerLng: _readLng(row),
      geomJson: _readGeoMap(row['geom_json']) ?? _readGeoMap(row['geom']) ?? _readGeoMap(row['geometry']),
      centroidJson: _readGeoMap(row['centroid_json']) ?? _readGeoMap(row['centroid']),
    );
  }


  Future<List<HistoryModernContext>> _enrichModernContextsWithCenters(List<HistoryModernContext> items) async {
    if (items.isEmpty) return const [];
    final enriched = <HistoryModernContext>[];
    for (final item in items) {
      enriched.add(await _enrichModernContextCenter(item));
    }
    return enriched;
  }

  Future<HistoryModernContext> _enrichModernContextCenter(HistoryModernContext context) async {
    if (context.hasCenter) return context;
    final candidates = [
      context.communityLabel,
      context.communityCode,
      if ((context.lguLabel ?? '').trim().isNotEmpty) context.lguLabel!,
      if ((context.governorateLabel ?? '').trim().isNotEmpty) context.governorateLabel!,
    ];
    for (final candidate in candidates) {
      final places = await _remote.searchPlaces(query: candidate, limit: 8);
      final matched = _pickBestPlaceRow(places, context);
      if (matched == null) continue;
      final lat = _readLat(matched);
      final lng = _readLng(matched);
      if (lat != null && lng != null) {
        return context.copyWith(centerLat: lat, centerLng: lng);
      }
    }
    return context;
  }

  Map<String, dynamic>? _pickBestPlaceRow(List<Map<String, dynamic>> rows, HistoryModernContext context) {
    if (rows.isEmpty) return null;
    final exact = context.communityLabel.trim().toLowerCase();
    for (final row in rows) {
      final nameAr = (_readString(row['name_ar']) ?? _readString(row['label_ar']) ?? '').trim().toLowerCase();
      final nameEn = (_readString(row['name_en']) ?? _readString(row['label_en']) ?? '').trim().toLowerCase();
      if (nameAr == exact || nameEn == exact) return row;
    }
    return rows.first;
  }

  List<HistoryWaqfAssetLink> _attachFallbackCentersToAssets(
    List<HistoryWaqfAssetLink> assets,
    List<HistoryModernContext> contexts,
  ) {
    if (assets.isEmpty) return const [];
    HistoryModernContext? anchor;
    for (final item in contexts) {
      if (item.hasCenter) {
        anchor = item;
        break;
      }
    }
    if (anchor == null) return assets;
    final anchorLat = anchor.centerLat;
    final anchorLng = anchor.centerLng;
    return assets.map((asset) {
      if (asset.hasCenter) return asset;
      return asset.copyWith(centerLat: anchorLat, centerLng: anchorLng);
    }).toList(growable: false);
  }

  Future<HistoryResolvedContext> _enrichResolvedContextSpatially(
    HistoryResolvedContext context, {
    HistoryOverlayFeature? historicalFeature,
    HistoryModernContext? modernSelection,
    HistoryWaqfAssetLink? waqfSelection,
  }) async {
    if (!context.hasAnyData) return context;

    final bounds = _deriveBounds(
      historicalFeature: historicalFeature,
      modernSelection: modernSelection,
      waqfSelection: waqfSelection,
      context: context,
    );
    if (bounds == null) return context;

    final enrichedModern = await _enrichModernContextsWithSpatialGeometries(context.modernContexts, bounds);
    final enrichedWaqf = await _enrichWaqfAssetsWithSpatialGeometries(context.waqfAssets, bounds);

    return context.copyWith(
      modernContexts: enrichedModern,
      waqfAssets: enrichedWaqf,
    );
  }

  List<double>? _deriveBounds({
    HistoryOverlayFeature? historicalFeature,
    HistoryModernContext? modernSelection,
    HistoryWaqfAssetLink? waqfSelection,
    required HistoryResolvedContext context,
  }) {
    final fromHistorical = _boundsFromGeo(historicalFeature?.geomJson);
    if (fromHistorical != null) return _expandBounds(fromHistorical, 0.02);

    final fromModern = _boundsFromGeo(modernSelection?.geomJson) ?? _pointBounds(
      modernSelection?.centerLat,
      modernSelection?.centerLng,
      delta: 0.06,
    );
    if (fromModern != null) return fromModern;

    final fromWaqf = _boundsFromGeo(waqfSelection?.geomJson) ?? _pointBounds(
      waqfSelection?.centerLat,
      waqfSelection?.centerLng,
      delta: 0.03,
    );
    if (fromWaqf != null) return fromWaqf;

    for (final item in context.modernContexts) {
      final bounds = _boundsFromGeo(item.geomJson) ?? _pointBounds(item.centerLat, item.centerLng, delta: 0.06);
      if (bounds != null) return bounds;
    }
    for (final item in context.waqfAssets) {
      final bounds = _boundsFromGeo(item.geomJson) ?? _pointBounds(item.centerLat, item.centerLng, delta: 0.03);
      if (bounds != null) return bounds;
    }
    return null;
  }

  Future<List<HistoryModernContext>> _enrichModernContextsWithSpatialGeometries(
    List<HistoryModernContext> items,
    List<double> bounds,
  ) async {
    if (items.isEmpty) return const [];
    final results = [...items];
    final layerRows = <Map<String, dynamic>>[];
    for (final layerKey in const ['communities', 'lgus', 'governorates']) {
      final rows = await _remote.fetchLayerFeaturesInBounds(
        layerKey: layerKey,
        west: bounds[0],
        south: bounds[1],
        east: bounds[2],
        north: bounds[3],
        limit: 600,
      );
      layerRows.addAll(rows);
    }
    if (layerRows.isEmpty) return results;

    for (var i = 0; i < results.length; i++) {
      final current = results[i];
      if (current.hasGeometry && current.hasCenter) continue;
      final row = _matchModernGeometryRow(layerRows, current);
      if (row == null) continue;
      results[i] = current.copyWith(
        geomJson: current.geomJson ?? _readGeoMap(row['geom']) ?? _readGeoMap(row['geometry']),
        centroidJson: current.centroidJson ?? _readGeoMap(row['centroid']),
        centerLat: current.centerLat ?? _readCentroidLat(row),
        centerLng: current.centerLng ?? _readCentroidLng(row),
      );
    }
    return results;
  }

  Future<List<HistoryWaqfAssetLink>> _enrichWaqfAssetsWithSpatialGeometries(
    List<HistoryWaqfAssetLink> items,
    List<double> bounds,
  ) async {
    if (items.isEmpty) return const [];
    final results = [...items];
    final layerRows = <Map<String, dynamic>>[];
    for (final layerKey in const ['waqf_lands', 'waqf_assets']) {
      final rows = await _remote.fetchLayerFeaturesInBounds(
        layerKey: layerKey,
        west: bounds[0],
        south: bounds[1],
        east: bounds[2],
        north: bounds[3],
        limit: 800,
      );
      layerRows.addAll(rows);
    }
    if (layerRows.isEmpty) return results;

    for (var i = 0; i < results.length; i++) {
      final current = results[i];
      if (current.hasGeometry && current.hasCenter) continue;
      final row = _matchWaqfGeometryRow(layerRows, current);
      if (row == null) continue;
      results[i] = current.copyWith(
        geomJson: current.geomJson ?? _readGeoMap(row['geom']) ?? _readGeoMap(row['geometry']),
        centroidJson: current.centroidJson ?? _readGeoMap(row['centroid']),
        centerLat: current.centerLat ?? _readCentroidLat(row),
        centerLng: current.centerLng ?? _readCentroidLng(row),
      );
    }
    return results;
  }

  Map<String, dynamic>? _matchModernGeometryRow(List<Map<String, dynamic>> rows, HistoryModernContext target) {
    final code = target.communityCode.trim().toLowerCase();
    final label = target.communityLabel.trim().toLowerCase();
    final lgu = (target.lguLabel ?? '').trim().toLowerCase();
    final gov = (target.governorateLabel ?? '').trim().toLowerCase();
    for (final row in rows) {
      final props = _readMap(row['props']);
      final values = [
        row['id'],
        row['title_ar'],
        row['title_en'],
        props['code'],
        props['community_code'],
        props['id'],
        props['name_ar'],
        props['name_en'],
        props['label_ar'],
        props['label_en'],
        props['municipality_name_ar'],
        props['gov_name_ar'],
      ].where((e) => e != null).map((e) => e.toString().trim().toLowerCase()).toList();
      if (values.contains(code) || values.contains(label)) return row;
      if (label.isNotEmpty && values.any((v) => v == label || v.contains(label) || label.contains(v))) return row;
      if (lgu.isNotEmpty && values.any((v) => v.contains(lgu) || lgu.contains(v))) return row;
      if (gov.isNotEmpty && values.any((v) => v.contains(gov) || gov.contains(v))) return row;
    }
    return null;
  }

  Map<String, dynamic>? _matchWaqfGeometryRow(List<Map<String, dynamic>> rows, HistoryWaqfAssetLink target) {
    final pwf = target.pwfKey.trim().toLowerCase();
    final name = (target.name ?? '').trim().toLowerCase();
    final community = (target.community ?? '').trim().toLowerCase();
    for (final row in rows) {
      final props = _readMap(row['props']);
      final values = [
        row['id'],
        row['title_ar'],
        row['title_en'],
        props['pwf_key'],
        props['pwf'],
        props['code'],
        props['name'],
        props['name_ar'],
        props['title'],
        props['title_ar'],
        props['community'],
        props['community_name'],
      ].where((e) => e != null).map((e) => e.toString().trim().toLowerCase()).toList();
      if (pwf.isNotEmpty && values.any((v) => v == pwf)) return row;
      if (name.isNotEmpty && values.any((v) => v == name || v.contains(name) || name.contains(v))) return row;
      if (community.isNotEmpty && values.any((v) => v.contains(community) || community.contains(v))) return row;
    }
    return null;
  }

  List<double>? _boundsFromGeo(Map<String, dynamic>? geom) {
    if (geom == null) return null;
    final points = <List<double>>[];
    void collect(dynamic coords) {
      if (coords is List && coords.isNotEmpty) {
        if (coords.length >= 2 && coords[0] is num && coords[1] is num) {
          points.add([(coords[0] as num).toDouble(), (coords[1] as num).toDouble()]);
        } else {
          for (final item in coords) {
            collect(item);
          }
        }
      }
    }
    collect(geom['coordinates']);
    if (points.isEmpty) return null;
    double minX = points.first[0], maxX = points.first[0], minY = points.first[1], maxY = points.first[1];
    for (final p in points.skip(1)) {
      if (p[0] < minX) minX = p[0];
      if (p[0] > maxX) maxX = p[0];
      if (p[1] < minY) minY = p[1];
      if (p[1] > maxY) maxY = p[1];
    }
    return [minX, minY, maxX, maxY];
  }

  List<double>? _pointBounds(double? lat, double? lng, {required double delta}) {
    if (lat == null || lng == null) return null;
    return [lng - delta, lat - delta, lng + delta, lat + delta];
  }

  List<double> _expandBounds(List<double> bounds, double delta) {
    return [bounds[0] - delta, bounds[1] - delta, bounds[2] + delta, bounds[3] + delta];
  }

  Map<String, dynamic>? _readGeoMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) return value.cast<String, dynamic>();
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty || !text.startsWith('{')) return null;
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    if (value is String && value.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {}
    }
    return const <String, dynamic>{};
  }

  double? _readCentroidLat(Map<String, dynamic> row) {
    final centroid = _readGeoMap(row['centroid']) ?? _readGeoMap(row['centroid_json']);
    final coords = centroid?['coordinates'];
    if (coords is List && coords.length >= 2 && coords[1] is num) {
      return (coords[1] as num).toDouble();
    }
    return _readLat(row);
  }

  double? _readCentroidLng(Map<String, dynamic> row) {
    final centroid = _readGeoMap(row['centroid']) ?? _readGeoMap(row['centroid_json']);
    final coords = centroid?['coordinates'];
    if (coords is List && coords.length >= 2 && coords[0] is num) {
      return (coords[0] as num).toDouble();
    }
    return _readLng(row);
  }

  List<HistoryLineageNode> _dedupeLineage(List<HistoryLineageNode> nodes) {
    final seen = <String>{};
    final out = <HistoryLineageNode>[];
    for (final node in nodes) {
      final key = '${node.id}|${node.relationLabel ?? ''}|${node.periodId ?? ''}';
      if (!seen.add(key)) continue;
      out.add(node);
    }
    return out;
  }

  String _lookupCode(Map<String, dynamic> row) {
    return _firstString(row, const ['code', 'id', 'gid', 'key', 'slug', 'name']) ?? '';
  }

  String _lookupLabel(Map<String, dynamic> row) {
    return _firstString(row, const ['name_ar', 'ar_name', 'label_ar', 'title_ar', 'name', 'name_en']) ?? '—';
  }

  String? _lookupParentCode(Map<String, dynamic> row) {
    return _firstString(row, const ['parent_code', 'governorate_code', 'gov_code', 'governorate', 'lgu_code', 'municipality_code', 'community_parent']);
  }

  String? _periodLabel(Map<String, dynamic> row) {
    final id = _asInt(row['period_id']);
    return id == null ? null : 'الفترة $id';
  }

  String? _firstString(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = _readString(row[key]);
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String? _readString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  double? _readLat(Map<String, dynamic> row) {
    final centroid = _readGeoMap(row['centroid']) ?? _readGeoMap(row['centroid_json']);
    final centroidCoords = centroid?['coordinates'];
    if (centroidCoords is List && centroidCoords.length >= 2 && centroidCoords[1] is num) {
      return (centroidCoords[1] as num).toDouble();
    }
    final geom = _readGeoMap(row['geom']) ?? _readGeoMap(row['geom_json']) ?? _readGeoMap(row['geometry']);
    final bounds = _boundsFromGeo(geom);
    if (bounds != null) return (bounds[1] + bounds[3]) / 2;
    return _firstDouble(row, const [
      'center_lat',
      'lat',
      'latitude',
      'y',
      'centroid_lat',
    ]);
  }

  double? _readLng(Map<String, dynamic> row) {
    final centroid = _readGeoMap(row['centroid']) ?? _readGeoMap(row['centroid_json']);
    final centroidCoords = centroid?['coordinates'];
    if (centroidCoords is List && centroidCoords.length >= 2 && centroidCoords[0] is num) {
      return (centroidCoords[0] as num).toDouble();
    }
    final geom = _readGeoMap(row['geom']) ?? _readGeoMap(row['geom_json']) ?? _readGeoMap(row['geometry']);
    final bounds = _boundsFromGeo(geom);
    if (bounds != null) return (bounds[0] + bounds[2]) / 2;
    return _firstDouble(row, const [
      'center_lng',
      'lng',
      'lon',
      'longitude',
      'x',
      'centroid_lng',
    ]);
  }

  double? _firstDouble(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = _asDouble(row[key]);
      if (value != null) return value;
    }
    return null;
  }
}
