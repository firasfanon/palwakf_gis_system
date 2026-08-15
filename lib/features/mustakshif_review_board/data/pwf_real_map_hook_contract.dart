import '../domain/pwf_review_record.dart';

/// عقد تحضيري لـ v0.49 يصف أوامر الخريطة التي سيستهلكها لاحقًا
/// flutter_map/PostGIS adapter داخل PalWakf. هذا العقد لا يرسم طبقات،
/// لا يغيّر activeLayers، ولا يعتمد أي حدود سيادية.
abstract interface class PwfRealMapHookAdapter {
  PwfMapHookEnvelope buildEnvelope(PwfReviewRecord record);
}

class PwfMapHookEnvelope {
  const PwfMapHookEnvelope({
    required this.recordId,
    required this.cameraCommand,
    required this.layerPolicy,
    required this.rpcPolicy,
    required this.validationCode,
    required this.validationLabelAr,
    required this.commands,
    required this.warnings,
  });

  final String recordId;
  final String cameraCommand;
  final String layerPolicy;
  final String rpcPolicy;
  final String validationCode;
  final String validationLabelAr;
  final List<PwfMapHookCommand> commands;
  final List<String> warnings;

  bool get isReadyForRealMapHook => validationCode.startsWith('ready_') || validationCode == 'partial_map_hook_ready';

  String get compactPayload {
    final commandCodes = commands.map((command) => command.commandCode).join('|');
    return '{'
        '"record_id":"$recordId",'
        '"camera_command":"$cameraCommand",'
        '"layer_policy":"$layerPolicy",'
        '"rpc_policy":"$rpcPolicy",'
        '"validation_code":"$validationCode",'
        '"commands":"$commandCodes",'
        '"governance":"review_only_not_final"'
        '}';
  }
}

class PwfMapHookCommand {
  const PwfMapHookCommand({
    required this.commandCode,
    required this.labelAr,
    required this.enabled,
    required this.reasonAr,
    this.lat,
    this.lon,
    this.south,
    this.west,
    this.north,
    this.east,
  });

  final String commandCode;
  final String labelAr;
  final bool enabled;
  final String reasonAr;
  final double? lat;
  final double? lon;
  final double? south;
  final double? west;
  final double? north;
  final double? east;

  String get debugLine {
    if (commandCode == 'fit_bbox') {
      return '$commandCode enabled=$enabled bbox=[$south,$west,$north,$east] reason=$reasonAr';
    }
    return '$commandCode enabled=$enabled point=[$lat,$lon] reason=$reasonAr';
  }
}

class PwfStandaloneRealMapHookAdapter implements PwfRealMapHookAdapter {
  const PwfStandaloneRealMapHookAdapter();

  @override
  PwfMapHookEnvelope buildEnvelope(PwfReviewRecord record) {
    final commands = <PwfMapHookCommand>[
      PwfMapHookCommand(
        commandCode: 'focus_historical_point',
        labelAr: 'تركيز على النقطة التاريخية',
        enabled: record.hasHistoricalPoint,
        reasonAr: record.hasHistoricalPoint ? 'نقطة تاريخية متوفرة' : 'لا توجد نقطة تاريخية',
        lat: record.historicalLat,
        lon: record.historicalLon,
      ),
      PwfMapHookCommand(
        commandCode: 'focus_candidate_centroid',
        labelAr: 'تركيز على المرشح الحالي',
        enabled: record.hasCandidateCentroid,
        reasonAr: record.hasCandidateCentroid ? 'centroid مرشح متوفر' : 'لا يوجد centroid مرشح',
        lat: record.candidateLat,
        lon: record.candidateLon,
      ),
      PwfMapHookCommand(
        commandCode: 'fit_bbox',
        labelAr: 'ملاءمة الخريطة على bbox',
        enabled: record.hasMapBbox,
        reasonAr: record.hasMapBbox ? 'bbox متوفر للمراجعة' : 'bbox غير متوفر',
        south: record.bboxSouth,
        west: record.bboxWest,
        north: record.bboxNorth,
        east: record.bboxEast,
      ),
    ];

    final validationCode = _validationCodeFor(record);
    return PwfMapHookEnvelope(
      recordId: record.id,
      cameraCommand: record.mapCameraIntentCode,
      layerPolicy: 'navigation_only_no_layer_mutation',
      rpcPolicy: 'log_only_no_gis_write',
      validationCode: validationCode,
      validationLabelAr: _validationLabelFor(validationCode),
      commands: commands,
      warnings: _warningsFor(record),
    );
  }

  static String _validationCodeFor(PwfReviewRecord record) {
    if (record.hasHistoricalPoint && record.hasCandidateCentroid && record.hasMapBbox) {
      return 'ready_full_map_hook';
    }
    if (record.hasHistoricalPoint && record.hasCandidateCentroid) {
      return 'ready_points_map_hook';
    }
    if (record.hasHistoricalPoint || record.hasCandidateCentroid) {
      return 'partial_map_hook_ready';
    }
    if (record.requiresGeometryRepair) return 'blocked_geometry_repair';
    if (record.requiresManualResearch) return 'blocked_manual_research';
    return 'blocked_missing_coordinates';
  }

  static String _validationLabelFor(String code) {
    return switch (code) {
      'ready_full_map_hook' => 'جاهز لربط خريطة كامل',
      'ready_points_map_hook' => 'جاهز لربط خريطة بالنقاط فقط',
      'partial_map_hook_ready' => 'جاهزية جزئية لربط الخريطة',
      'blocked_geometry_repair' => 'محجوب بسبب إصلاح هندسي',
      'blocked_manual_research' => 'محجوب بسبب بحث يدوي',
      _ => 'محجوب بسبب نقص الإحداثيات',
    };
  }

  static List<String> _warningsFor(PwfReviewRecord record) {
    return [
      'لا اعتماد نهائي من محول الخريطة.',
      'لا تعديل على core أو waqf.',
      'لا تشغيل أو إيقاف طبقات من الأوامر التحضيرية.',
      if (!record.hasLocator) 'source locator غير مغلق.',
      if (!record.hasDualDecision) 'توقيع المراجعين غير مكتمل.',
      if (record.requiresSpatialReview) 'السجل يحتاج مراجعة مكانية قبل أي استعمال تحليلي متقدم.',
    ];
  }
}
