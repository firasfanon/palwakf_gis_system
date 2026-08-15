import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/pwf_review_enums.dart';
import '../domain/pwf_review_record.dart';
import '../domain/pwf_source_locator.dart';

class PwfLocalDraftSaveResult {
  const PwfLocalDraftSaveResult({
    required this.recordId,
    required this.draftCount,
    required this.bytesLength,
    required this.checksum,
    required this.savedAt,
    required this.verified,
  });

  final String recordId;
  final int draftCount;
  final int bytesLength;
  final String checksum;
  final DateTime savedAt;
  final bool verified;

  String get messageAr {
    final status = verified ? 'تم التحقق' : 'لم يكتمل التحقق';
    return '$status من حفظ المسودة محليًا — drafts=$draftCount; bytes=$bytesLength; checksum=$checksum';
  }
}

class PwfLocalDraftHealthReport {
  const PwfLocalDraftHealthReport({
    required this.exists,
    required this.draftCount,
    required this.bytesLength,
    required this.checksum,
    required this.schemaVersion,
    this.errorMessage,
  });

  final bool exists;
  final int draftCount;
  final int bytesLength;
  final String checksum;
  final String schemaVersion;
  final String? errorMessage;

  bool get isHealthy => errorMessage == null;

  String get labelAr {
    if (!exists) return 'لا توجد مسودات محلية';
    if (!isHealthy) return 'توجد مشكلة في قراءة المسودات المحلية';
    return 'المسودات المحلية سليمة — drafts=$draftCount; bytes=$bytesLength; checksum=$checksum';
  }
}

class PwfLocalReviewDraftStore {
  const PwfLocalReviewDraftStore({
    this.storageKey = 'pwf_mustakshif_review_board_local_drafts_v0_48',
    this.corruptBackupKey = 'pwf_mustakshif_review_board_local_drafts_corrupt_backup_v0_50',
  });

  static const String schemaVersion = 'local_drafts_v0_50';

  final String storageKey;
  final String corruptBackupKey;

  Future<List<PwfReviewRecord>> mergeDrafts(
    List<PwfReviewRecord> baseRecords,
  ) async {
    final drafts = await _readDraftMap();
    return baseRecords.map((record) {
      final draft = drafts[record.id];
      if (draft == null) return record;
      return _applyDraft(record, draft);
    }).toList(growable: false);
  }

  Future<Set<String>> loadDraftRecordIds() async {
    final drafts = await _readDraftMap();
    return drafts.keys.toSet();
  }

  Future<PwfLocalDraftHealthReport> inspectHealth() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const PwfLocalDraftHealthReport(
        exists: false,
        draftCount: 0,
        bytesLength: 0,
        checksum: '00000000',
        schemaVersion: schemaVersion,
      );
    }

    try {
      final decoded = jsonDecode(raw);
      final draftCount = decoded is Map ? decoded.length : 0;
      return PwfLocalDraftHealthReport(
        exists: true,
        draftCount: draftCount,
        bytesLength: utf8.encode(raw).length,
        checksum: _fnv1a32(utf8.encode(raw)),
        schemaVersion: schemaVersion,
      );
    } catch (error) {
      return PwfLocalDraftHealthReport(
        exists: true,
        draftCount: 0,
        bytesLength: utf8.encode(raw).length,
        checksum: _fnv1a32(utf8.encode(raw)),
        schemaVersion: schemaVersion,
        errorMessage: error.toString(),
      );
    }
  }

  Future<PwfLocalDraftSaveResult> saveRecord(PwfReviewRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await _readDraftMap();
    drafts[record.id] = _recordToDraft(record);

    final payload = jsonEncode(drafts);
    final bytes = utf8.encode(payload);
    final checksum = _fnv1a32(bytes);
    final savedAt = DateTime.now();

    await prefs.setString(storageKey, payload);

    final verifyRaw = prefs.getString(storageKey) ?? '';
    final verified = _verifyStoredRecord(
      verifyRaw: verifyRaw,
      recordId: record.id,
      expectedChecksum: checksum,
    );

    return PwfLocalDraftSaveResult(
      recordId: record.id,
      draftCount: drafts.length,
      bytesLength: bytes.length,
      checksum: checksum,
      savedAt: savedAt,
      verified: verified,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  Future<Map<String, Map<String, dynamic>>> _readDraftMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, Map<String, dynamic>>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, Map<String, dynamic>>{};

      final result = <String, Map<String, dynamic>>{};
      for (final entry in decoded.entries) {
        final key = '${entry.key}';
        final value = entry.value;
        if (key.trim().isEmpty || value is! Map) continue;
        result[key] = Map<String, dynamic>.from(value);
      }
      return result;
    } catch (_) {
      await prefs.setString(corruptBackupKey, raw);
      return <String, Map<String, dynamic>>{};
    }
  }

  bool _verifyStoredRecord({
    required String verifyRaw,
    required String recordId,
    required String expectedChecksum,
  }) {
    if (verifyRaw.trim().isEmpty) return false;
    final actualChecksum = _fnv1a32(utf8.encode(verifyRaw));
    if (actualChecksum != expectedChecksum) return false;

    try {
      final decoded = jsonDecode(verifyRaw);
      return decoded is Map && decoded.containsKey(recordId);
    } catch (_) {
      return false;
    }
  }

  PwfReviewRecord _applyDraft(
    PwfReviewRecord base,
    Map<String, dynamic> draft,
  ) {
    final locatorMap = draft['source_locator'];
    final locator = locatorMap is Map
        ? PwfSourceLocator.fromJson(Map<String, dynamic>.from(locatorMap))
        : null;
    final updatedAtText = '${draft['updated_at'] ?? ''}'.trim();

    return base.copyWith(
      sourceLocator: locator,
      locatorStatus: PwfLocatorStatus.fromCode(
        '${draft['locator_status'] ?? base.locatorStatus.code}',
      ),
      reviewerOneDecision: PwfReviewDecision.fromCode(
        '${draft['reviewer_one_decision'] ?? base.reviewerOneDecision.code}',
      ),
      reviewerOneNote: '${draft['reviewer_one_note'] ?? base.reviewerOneNote}',
      reviewerTwoDecision: PwfReviewDecision.fromCode(
        '${draft['reviewer_two_decision'] ?? base.reviewerTwoDecision.code}',
      ),
      reviewerTwoNote: '${draft['reviewer_two_note'] ?? base.reviewerTwoNote}',
      updatedAt: updatedAtText.isEmpty
          ? base.updatedAt
          : DateTime.tryParse(updatedAtText),
    );
  }

  Map<String, dynamic> _recordToDraft(PwfReviewRecord record) {
    final savedAt = DateTime.now().toIso8601String();
    return {
      'record_id': record.id,
      'source_locator': record.sourceLocator?.toJson(),
      'locator_status': record.locatorStatus.code,
      'reviewer_one_decision': record.reviewerOneDecision.code,
      'reviewer_one_note': record.reviewerOneNote,
      'reviewer_two_decision': record.reviewerTwoDecision.code,
      'reviewer_two_note': record.reviewerTwoNote,
      'updated_at': record.updatedAt?.toIso8601String() ?? savedAt,
      'saved_at': savedAt,
      'schema_version': schemaVersion,
      'storage_scope': 'local_browser_only_not_supabase',
      'governance_status': 'draft_only_not_final',
      'verification_policy': 'write_then_read_checksum_verify',
    };
  }

  static String _fnv1a32(List<int> bytes) {
    var hash = 0x811c9dc5;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
