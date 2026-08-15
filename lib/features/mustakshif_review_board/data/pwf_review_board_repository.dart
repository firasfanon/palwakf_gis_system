import 'package:flutter/services.dart' show rootBundle;

import '../domain/pwf_review_enums.dart';
import '../domain/pwf_review_record.dart';
import '../domain/pwf_source_locator.dart';

abstract interface class PwfReviewBoardRepository {
  Future<List<PwfReviewRecord>> fetchQueue({String? queueCode});
}

class PwfCsvSeedReviewBoardRepository implements PwfReviewBoardRepository {
  const PwfCsvSeedReviewBoardRepository({
    this.assetPath = 'assets/data/mustakshif_review_seed_v0_49.csv',
    this.fallbackRepository = const PwfSeedReviewBoardRepository(),
  });

  final String assetPath;
  final PwfReviewBoardRepository fallbackRepository;

  @override
  Future<List<PwfReviewRecord>> fetchQueue({String? queueCode}) async {
    try {
      final content = await rootBundle.loadString(assetPath);
      final records = _recordsFromCsv(content);
      final normalizedQueue = queueCode?.trim();
      if (normalizedQueue == null || normalizedQueue.isEmpty || normalizedQueue == 'all') {
        return records;
      }
      return records.where((record) => record.queueCode == normalizedQueue).toList();
    } catch (_) {
      return fallbackRepository.fetchQueue(queueCode: queueCode);
    }
  }

  List<PwfReviewRecord> _recordsFromCsv(String content) {
    final rows = _parseCsv(content);
    if (rows.isEmpty) return const [];

    final headers = rows.first
        .map((value) => value.replaceFirst('\uFEFF', '').trim())
        .toList(growable: false);

    return rows.skip(1).map((row) {
      final map = <String, String>{};
      for (var i = 0; i < headers.length; i++) {
        map[headers[i]] = i < row.length ? row[i].trim() : '';
      }
      return _mapCsvRow(map);
    }).where((record) => record.id.trim().isNotEmpty).toList(growable: false);
  }

  PwfReviewRecord _mapCsvRow(Map<String, String> row) {
    final distanceText = row['distance_meters'] ?? '';
    final confidenceText = row['confidence_score'] ?? '0';
    final locator = _buildLocator(row);
    final locatorStatus = PwfLocatorStatus.fromCode(
      row['source_locator_status']?.isNotEmpty == true
          ? row['source_locator_status']!
          : locator == null
              ? PwfLocatorStatus.missing.code
              : PwfLocatorStatus.submitted.code,
    );

    return PwfReviewRecord(
      id: row['record_id'] ?? '',
      placeNameAr: row['place_name_ar'] ?? '',
      currentCandidateAr: row['current_candidate_ar'] ?? '',
      queue: PwfReviewQueue.fromCode(row['queue_code'] ?? 'F4'),
      reviewStatus: row['review_status'] ?? 'review_only_not_final',
      distanceMeters: double.tryParse(distanceText),
      locatorStatus: locatorStatus,
      periodLabelAr: row['period_label_ar'] ?? '',
      adminDivisionAr: row['admin_division_ar'] ?? '',
      candidateType: row['candidate_type'] ?? '',
      confidenceScore: int.tryParse(confidenceText) ?? 0,
      geometryStatus: row['geometry_status'] ?? '',
      warningLabel: row['warning_label'] ?? 'review_only_not_final',
      sourceLocator: locator,
      reviewerOneDecision: PwfReviewDecision.fromCode(row['reviewer_one_decision']),
      reviewerOneNote: row['reviewer_one_note'] ?? '',
      reviewerTwoDecision: PwfReviewDecision.fromCode(row['reviewer_two_decision']),
      reviewerTwoNote: row['reviewer_two_note'] ?? '',
      historicalLat: _parseNullableDouble(row['historical_lat']),
      historicalLon: _parseNullableDouble(row['historical_lon']),
      candidateLat: _parseNullableDouble(row['candidate_lat']),
      candidateLon: _parseNullableDouble(row['candidate_lon']),
      bboxSouth: _parseNullableDouble(row['bbox_south']),
      bboxWest: _parseNullableDouble(row['bbox_west']),
      bboxNorth: _parseNullableDouble(row['bbox_north']),
      bboxEast: _parseNullableDouble(row['bbox_east']),
      mapAdapterStatus: row['map_adapter_status']?.isNotEmpty == true
          ? row['map_adapter_status']!
          : 'seed_or_placeholder',
    );
  }

  double? _parseNullableDouble(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  PwfSourceLocator? _buildLocator(Map<String, String> row) {
    final locator = PwfSourceLocator(
      sourceTitle: row['source_title'] ?? '',
      sourceType: row['source_type'] ?? '',
      locatorText: row['locator_text'] ?? '',
      evidenceNote: row['evidence_note'] ?? '',
      page: row['page'],
      tableName: row['table_name'],
      rowReference: row['row_reference'],
    );
    return locator.isComplete ? locator : null;
  }

  List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    final row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      final next = i + 1 < input.length ? input[i + 1] : '';

      if (char == '"') {
        if (inQuotes && next == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        row.add(field.toString());
        field.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && next == '\n') i++;
        row.add(field.toString());
        field.clear();
        if (row.any((value) => value.trim().isNotEmpty)) {
          rows.add(List<String>.from(row));
        }
        row.clear();
      } else {
        field.write(char);
      }
    }

    if (field.length > 0 || row.isNotEmpty) {
      row.add(field.toString());
      if (row.any((value) => value.trim().isNotEmpty)) {
        rows.add(List<String>.from(row));
      }
    }
    return rows;
  }
}

class PwfSeedReviewBoardRepository implements PwfReviewBoardRepository {
  const PwfSeedReviewBoardRepository();

  @override
  Future<List<PwfReviewRecord>> fetchQueue({String? queueCode}) async {
    final rows = _seedRows;
    if (queueCode == null || queueCode == 'all') return rows;
    return rows.where((record) => record.queueCode == queueCode).toList();
  }

  static const List<PwfReviewRecord> _seedRows = [
    PwfReviewRecord(
      id: 'F1-001',
      placeNameAr: 'سجل قرية تاريخية تجريبي',
      currentCandidateAr: 'مرشح مجتمع حالي',
      queue: PwfReviewQueue.f1,
      reviewStatus: 'review_only_not_final',
      distanceMeters: 420,
      locatorStatus: PwfLocatorStatus.missing,
      periodLabelAr: 'انتداب 1945',
      adminDivisionAr: 'قضاء تاريخي',
      candidateType: 'core.community',
      confidenceScore: 86,
      geometryStatus: 'داخل حدود المرشح',
      warningLabel: 'لا اعتماد دون source locator وتوقيعين',
    ),
    PwfReviewRecord(
      id: 'F1-002',
      placeNameAr: 'سجل مواءمة اسمية قوية',
      currentCandidateAr: 'مرشح هيئة محلية',
      queue: PwfReviewQueue.f1,
      reviewStatus: 'locator_required',
      distanceMeters: 680,
      locatorStatus: PwfLocatorStatus.missing,
      periodLabelAr: 'عثماني متأخر',
      adminDivisionAr: 'ناحية/قضاء',
      candidateType: 'core.lgu',
      confidenceScore: 79,
      geometryStatus: 'قريب من centroid المرشح',
      warningLabel: 'يحتاج locator أصلي للصفحة/الجدول',
    ),
    PwfReviewRecord(
      id: 'F2-001',
      placeNameAr: 'سجل تعارض مكاني',
      currentCandidateAr: 'مرشح بحاجة فحص',
      queue: PwfReviewQueue.f2,
      reviewStatus: 'spatial_exception',
      distanceMeters: 12500,
      locatorStatus: PwfLocatorStatus.missing,
      periodLabelAr: 'ما بعد 1948',
      adminDivisionAr: 'حالة مكانية غير محسومة',
      candidateType: 'core.community',
      confidenceScore: 41,
      geometryStatus: 'خارج الحدود بمسافة عالية',
      warningLabel: 'لا قرار قبل فحص بديل مكاني',
    ),
    PwfReviewRecord(
      id: 'F2-002',
      placeNameAr: 'سجل قريب من حدود المرشح',
      currentCandidateAr: 'مرشح قريب من boundary',
      queue: PwfReviewQueue.f2,
      reviewStatus: 'near_boundary_review',
      distanceMeters: 3100,
      locatorStatus: PwfLocatorStatus.missing,
      periodLabelAr: 'انتداب/أردني',
      adminDivisionAr: 'قضاء/لواء',
      candidateType: 'core.lgu',
      confidenceScore: 62,
      geometryStatus: 'قريب لكن ليس داخل الحدود',
      warningLabel: 'يحتاج مراجعة GIS',
    ),
    PwfReviewRecord(
      id: 'F3-001',
      placeNameAr: 'سجل بلا هندسة core',
      currentCandidateAr: 'مرشح اسمي بلا geometry',
      queue: PwfReviewQueue.f3,
      reviewStatus: 'geometry_repair_required',
      distanceMeters: null,
      locatorStatus: PwfLocatorStatus.missing,
      periodLabelAr: 'حالي/مطابقة core',
      adminDivisionAr: 'مجتمع/هيئة محلية',
      candidateType: 'core.community',
      confidenceScore: 55,
      geometryStatus: 'geometry مفقودة أو غير قابلة للقراءة',
      warningLabel: 'يحتاج إعادة تصدير core boundary',
    ),
    PwfReviewRecord(
      id: 'F3-002',
      placeNameAr: 'سجل centroid proxy فقط',
      currentCandidateAr: 'مرشح proxy',
      queue: PwfReviewQueue.f3,
      reviewStatus: 'centroid_proxy_not_final',
      distanceMeters: null,
      locatorStatus: PwfLocatorStatus.missing,
      periodLabelAr: 'مراجعة هندسية',
      adminDivisionAr: 'core boundary',
      candidateType: 'core.lgu',
      confidenceScore: 50,
      geometryStatus: 'centroid proxy غير نهائي',
      warningLabel: 'proxy لا يعتمد نهائيًا',
    ),
    PwfReviewRecord(
      id: 'F4-001',
      placeNameAr: 'سجل غير مطابق يدويًا',
      currentCandidateAr: 'لا يوجد مرشح حالي',
      queue: PwfReviewQueue.f4,
      reviewStatus: 'manual_research',
      distanceMeters: null,
      locatorStatus: PwfLocatorStatus.missing,
      periodLabelAr: 'عثماني/انتداب',
      adminDivisionAr: 'غير محسوم',
      candidateType: 'none',
      confidenceScore: 18,
      geometryStatus: 'غير متوفر',
      warningLabel: 'يتطلب بحثًا تاريخيًا يدويًا',
    ),
    PwfReviewRecord(
      id: 'F4-002',
      placeNameAr: 'سجل اسم مكرر',
      currentCandidateAr: 'عدة احتمالات',
      queue: PwfReviewQueue.f4,
      reviewStatus: 'ambiguous_name',
      distanceMeters: null,
      locatorStatus: PwfLocatorStatus.missing,
      periodLabelAr: 'كل الفترات',
      adminDivisionAr: 'أسماء متداخلة',
      candidateType: 'multiple_candidates',
      confidenceScore: 22,
      geometryStatus: 'يتطلب تمييزًا سياقيًا',
      warningLabel: 'لا اختيار آلي عند تعدد المواقع',
    ),
  ];
}
