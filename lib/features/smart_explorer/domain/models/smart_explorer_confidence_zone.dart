/// Textual confidence zones for candidate spatial investigation.
/// The current batch does not create geometry. It prepares review zones and the
/// layers/evidence needed to draw or confirm them later through approved GIS paths.
class SmartExplorerConfidenceZoneSet {
  const SmartExplorerConfidenceZoneSet({
    required this.zones,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerConfidenceZone> zones;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => zones.isEmpty;
  int get totalZones => zones.length;

  String get summaryAr {
    if (zones.isEmpty) return 'لا توجد مناطق ثقة مقترحة للنطاق الحالي.';
    return 'تم تحضير $totalZones منطقة ثقة وصفية لاختبارها على الخريطة.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('مناطق الثقة المكانية المقترحة')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('تنبيه: هذه مناطق وصفية/احتمالية وليست هندسة معتمدة.')
      ..writeln('---');
    for (final zone in zones) {
      buffer
        ..writeln('- ${zone.labelAr}')
        ..writeln('  النوع: ${zone.zoneTypeLabelAr}')
        ..writeln('  الثقة: ${zone.confidencePercent}%')
        ..writeln('  الأساس: ${zone.basisAr}')
        ..writeln('  الطبقات المطلوبة: ${zone.requiredLayersAr.join('، ')}')
        ..writeln('  الاختبار التالي: ${zone.nextTestAr}');
    }
    return buffer.toString();
  }
}

class SmartExplorerConfidenceZone {
  const SmartExplorerConfidenceZone({
    required this.labelAr,
    required this.zoneTypeLabelAr,
    required this.confidencePercent,
    required this.basisAr,
    required this.requiredLayersAr,
    required this.nextTestAr,
  });

  final String labelAr;
  final String zoneTypeLabelAr;
  final int confidencePercent;
  final String basisAr;
  final List<String> requiredLayersAr;
  final String nextTestAr;
}
