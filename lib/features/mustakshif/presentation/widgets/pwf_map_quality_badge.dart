import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../domain/enums/mustakshif_map_layer_semantics.dart';

class PwfMapQualityBadge extends StatelessWidget {
  const PwfMapQualityBadge({
    super.key,
    required this.label,
    this.warning = false,
    this.compact = false,
  });

  final String label;
  final bool warning;
  final bool compact;

  factory PwfMapQualityBadge.legalWeight(MustakshifLayerLegalWeight weight, {bool compact = false}) {
    return PwfMapQualityBadge(
      label: weight.labelAr,
      warning: weight.requiresReview,
      compact: compact,
    );
  }

  factory PwfMapQualityBadge.accuracy(MustakshifLayerAccuracyLevel accuracy, {bool compact = false}) {
    return PwfMapQualityBadge(
      label: 'الدقة: ${accuracy.labelAr}',
      warning: accuracy == MustakshifLayerAccuracyLevel.low || accuracy == MustakshifLayerAccuracyLevel.unknown,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = warning ? PwfColors.royalRed : PwfColors.primaryBlue;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
