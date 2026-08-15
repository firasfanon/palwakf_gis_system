import '../domain/pwf_review_record.dart';

/// عقد تحضيري فقط لـ v0.48. لا يرسم طبقات ولا يغيّر activeLayers.
/// عند الدمج الحقيقي سيستبدل هذا العقد بمحول flutter_map/PostGIS عبر public RPC wrappers.
abstract interface class PwfMapEvidenceAdapter {
  Future<PwfMapEvidencePayload> buildPayload(PwfReviewRecord record);
}

class PwfMapEvidencePayload {
  const PwfMapEvidencePayload({
    required this.recordId,
    required this.layerPolicy,
    required this.cameraPolicy,
    required this.hasHistoricalPoint,
    required this.hasCandidateCentroid,
    required this.hasBbox,
    required this.warning,
  });

  final String recordId;
  final String layerPolicy;
  final String cameraPolicy;
  final bool hasHistoricalPoint;
  final bool hasCandidateCentroid;
  final bool hasBbox;
  final String warning;

  bool get isReadyForFlutterMapAdapter => hasHistoricalPoint || hasCandidateCentroid || hasBbox;
}

class PwfStandaloneMapEvidenceAdapter implements PwfMapEvidenceAdapter {
  const PwfStandaloneMapEvidenceAdapter();

  @override
  Future<PwfMapEvidencePayload> buildPayload(PwfReviewRecord record) async {
    return PwfMapEvidencePayload(
      recordId: record.id,
      layerPolicy: 'do_not_toggle_layers_navigation_only',
      cameraPolicy: record.hasMapEvidence ? 'fit_record_evidence_when_map_is_available' : 'show_placeholder_only',
      hasHistoricalPoint: record.hasHistoricalPoint,
      hasCandidateCentroid: record.hasCandidateCentroid,
      hasBbox: record.hasMapBbox,
      warning: 'v0.50 explorer adapter preparation: لا يعتمد حدودًا، ولا يكتب إلى core/waqf، ولا يغيّر activeLayers.',
    );
  }
}
