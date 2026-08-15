/// Map layer recommendations generated from Smart Explorer scope.
///
/// Recommendations are local guidance for what the reviewer should activate or
/// inspect. They do not enable layers automatically and do not change layer
/// settings.
class SmartExplorerLayerRecommendationSet {
  const SmartExplorerLayerRecommendationSet({
    required this.recommendations,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerLayerRecommendation> recommendations;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => recommendations.isEmpty;
  int get totalRecommendations => recommendations.length;
  int get requiredCount => recommendations.where((item) => item.isRequired).length;

  List<SmartExplorerLayerRecommendation> get topRecommendations {
    final out = List<SmartExplorerLayerRecommendation>.from(recommendations)
      ..sort((a, b) => b.weight.compareTo(a.weight));
    return out.take(14).toList(growable: false);
  }

  String get summaryAr {
    if (recommendations.isEmpty) return 'لا توجد طبقات مقترحة ضمن النطاق الحالي.';
    return 'طبقات مقترحة: $totalRecommendations، منها $requiredCount أساسية للاختبار.';
  }
}

class SmartExplorerLayerRecommendation {
  const SmartExplorerLayerRecommendation({
    required this.layerKey,
    required this.titleAr,
    required this.reasonAr,
    required this.whenToUseAr,
    required this.weight,
    this.isRequired = false,
    this.guardrailAr = 'تفعيل/فحص يدوي فقط دون تعديل إعدادات الطبقة.',
  });

  final String layerKey;
  final String titleAr;
  final String reasonAr;
  final String whenToUseAr;
  final int weight;
  final bool isRequired;
  final String guardrailAr;

  String get priorityLabelAr {
    if (weight >= 85) return 'أساسية';
    if (weight >= 65) return 'مهمة';
    if (weight >= 40) return 'مساعدة';
    return 'اختيارية';
  }
}
