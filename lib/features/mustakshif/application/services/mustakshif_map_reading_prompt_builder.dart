import '../../domain/enums/mustakshif_map_layer_semantics.dart';
import '../../domain/models/mustakshif_layer_cartography.dart';

class MustakshifMapReadingPromptBuilder {
  const MustakshifMapReadingPromptBuilder();

  String buildLayerExplanationPrompt({
    required String userQuestion,
    required double currentZoom,
    required List<MustakshifLayerCartography> visibleLayers,
    String? selectedWaqfAssetId,
    String? selectedLayerKey,
  }) {
    final buffer = StringBuffer()
      ..writeln('أنت مساعد مستكشف الوقف داخل منصة PalWakf.')
      ..writeln('فسّر الخريطة بوصفها أداة تحليل وقراءة مكانية لا سندًا قانونيًا نهائيًا.')
      ..writeln('لا تعتبر Mustakshif مصدر Master Data.')
      ..writeln('لا تعتبر parcel بديلًا عن waqf_assets.')
      ..writeln('الربط التشغيلي المركزي يكون عبر waqf_asset_id.')
      ..writeln('مستوى الزوم الحالي: $currentZoom')
      ..writeln('سؤال المستخدم: $userQuestion');

    if (selectedWaqfAssetId != null && selectedWaqfAssetId.trim().isNotEmpty) {
      buffer.writeln('الأصل الوقفي المحدد: $selectedWaqfAssetId');
    }
    if (selectedLayerKey != null && selectedLayerKey.trim().isNotEmpty) {
      buffer.writeln('الطبقة المحددة: $selectedLayerKey');
    }

    buffer.writeln('الطبقات الظاهرة:');
    for (final layer in visibleLayers) {
      buffer.writeln('- ${layer.layerKey}: ${layer.layerNameAr} | الغرض: ${layer.purpose.labelAr} | المصدر: ${layer.readableSourceAr} | الدقة: ${layer.accuracyLevel.labelAr} | الوزن: ${layer.legalWeight.labelAr}');
      if (layer.warningAr != null && layer.warningAr!.trim().isNotEmpty) {
        buffer.writeln('  تحذير: ${layer.warningAr}');
      }
    }

    buffer
      ..writeln('قواعد الإجابة:')
      ..writeln('1. اربط الإجابة بالمصدر والدقة والوزن القانوني.')
      ..writeln('2. إذا كانت الطبقة تحليلية أو غير محققة، اذكر أنها للمراجعة.')
      ..writeln('3. إذا كان السؤال عن عدم ظهور التفاصيل، اشرح علاقة الزوم ومقياس الرسم والتعميم.')
      ..writeln('4. إذا كان السؤال عن صحة الحدود، اطلب مطابقة مع الوثائق أو مخطط التسوية أو المصدر الرسمي.')
      ..writeln('5. لا تصدر حكمًا قانونيًا نهائيًا من الخريطة وحدها.');

    return buffer.toString();
  }
}
