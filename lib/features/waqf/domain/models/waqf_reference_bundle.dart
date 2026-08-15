
import 'endower_reference.dart';
import 'endowment_reference.dart';

class WaqfReferenceBundle {
  final EndowmentReference? endowment;
  final EndowerReference? endower;
  final bool isFallback;
  final String sourceLabel;
  final String? note;

  const WaqfReferenceBundle({
    required this.endowment,
    required this.endower,
    required this.isFallback,
    required this.sourceLabel,
    this.note,
  });

  bool get hasData => endowment != null || endower != null;
}
