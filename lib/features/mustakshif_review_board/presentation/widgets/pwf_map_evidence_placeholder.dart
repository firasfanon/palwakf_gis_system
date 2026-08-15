import 'package:flutter/material.dart';

import '../../domain/pwf_review_record.dart';
import 'pwf_status_chip.dart';

class PwfMapEvidencePlaceholder extends StatelessWidget {
  const PwfMapEvidencePlaceholder({super.key, required this.record});

  final PwfReviewRecord record;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final riskColor = _riskColor(record.distanceRiskCode, colorScheme);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'مؤشر الخريطة / الدليل المكاني v0.48',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              PwfStatusChip(label: record.mapAdapterStatus, compact: true),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: CustomPaint(
              painter: _PwfMapPlaceholderPainter(
                colorScheme: colorScheme,
                riskCode: record.distanceRiskCode,
                hashSeed: record.id.hashCode,
                hasCoordinateEvidence: record.hasMapEvidence,
              ),
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: riskColor.withValues(alpha: 0.75), width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(record.placeNameAr, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text('المرشح الحالي: ${record.currentCandidateAr}'),
                        Text('المسافة: ${record.distanceLabel} — ${record.distanceRiskLabelAr}'),
                        Text('حالة الهندسة: ${record.geometryStatus}'),
                        Text('النقطة التاريخية: ${record.historicalPointLabel}'),
                        Text('centroid المرشح: ${record.candidatePointLabel}'),
                        Text('جاهزية الخريطة: ${record.coordinateEvidenceStatusAr}'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PwfStatusChip(label: record.distanceRiskLabelAr, compact: true),
              PwfStatusChip(label: record.mapEvidenceSummary, compact: true),
              PwfStatusChip(label: record.operationalGateStatus, compact: true),
              PwfStatusChip(label: record.coordinateEvidenceStatusAr, compact: true),
            ],
          ),
          const SizedBox(height: 12),
          _MapChecklist(record: record),
          const SizedBox(height: 10),
          const Text(
            'هذه مساحة تمهيدية للخريطة فقط. لا يتم تحميل طبقات GIS ولا ترسم حدودًا رسمية. v0.48 يجهز عقد Map Adapter فقط. اختيار السجل navigation/evidence focus ولا يشغّل/يوقف أي طبقة.',
          ),
        ],
      ),
    );
  }

  static Color _riskColor(String riskCode, ColorScheme scheme) {
    return switch (riskCode) {
      'critical_distance' => const Color(0xFFB22222),
      'high_distance' => Colors.deepOrange,
      'medium_distance' => Colors.amber.shade800,
      'geometry_missing' => Colors.purple,
      'unknown_distance' => scheme.outline,
      _ => scheme.primary,
    };
  }
}

class _MapChecklist extends StatelessWidget {
  const _MapChecklist({required this.record});

  final PwfReviewRecord record;

  @override
  Widget build(BuildContext context) {
    final checks = [
      _CheckItem('Source locator', record.hasLocator, record.hasLocator ? 'مدخل' : 'مطلوب'),
      _CheckItem('Reviewer 1', record.reviewerOneDecision.code != 'none', record.reviewerOneDecision.labelAr),
      _CheckItem('Reviewer 2', record.reviewerTwoDecision.code != 'none', record.reviewerTwoDecision.labelAr),
      _CheckItem('Decision alignment', record.isDecisionAligned, record.isDecisionAligned ? 'متطابق' : 'غير مكتمل/متعارض'),
      _CheckItem('Geometry repair', !record.requiresGeometryRepair, record.requiresGeometryRepair ? 'مطلوب' : 'غير مطلوب'),
      _CheckItem('Spatial exception', !record.requiresSpatialReview, record.requiresSpatialReview ? 'مراجعة مكانية' : 'مستقر مبدئيًا'),
      _CheckItem('Map evidence', record.hasMapEvidence, record.coordinateEvidenceStatusAr),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: checks.map((check) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                check.ok ? Icons.check_circle_outline : Icons.pending_actions_outlined,
                size: 16,
                color: check.ok ? Theme.of(context).colorScheme.primary : const Color(0xFFB22222),
              ),
              const SizedBox(width: 6),
              Text('${check.label}: ${check.value}', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CheckItem {
  const _CheckItem(this.label, this.ok, this.value);

  final String label;
  final bool ok;
  final String value;
}

class _PwfMapPlaceholderPainter extends CustomPainter {
  const _PwfMapPlaceholderPainter({
    required this.colorScheme,
    required this.riskCode,
    required this.hashSeed,
    required this.hasCoordinateEvidence,
  });

  final ColorScheme colorScheme;
  final String riskCode;
  final int hashSeed;
  final bool hasCoordinateEvidence;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    final boundaryPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final candidatePaint = Paint()
      ..color = const Color(0xFFB22222).withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final pointPaint = Paint()
      ..color = const Color(0xFFB22222)
      ..style = PaintingStyle.fill;
    final centerPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = _lineColor().withValues(alpha: 0.9)
      ..strokeWidth = riskCode == 'critical_distance' ? 3 : 2
      ..style = PaintingStyle.stroke;

    const step = 28.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final boundary = Path()
      ..moveTo(size.width * .16, size.height * .30)
      ..quadraticBezierTo(size.width * .35, size.height * .10, size.width * .55, size.height * .22)
      ..quadraticBezierTo(size.width * .84, size.height * .30, size.width * .77, size.height * .62)
      ..quadraticBezierTo(size.width * .60, size.height * .88, size.width * .30, size.height * .75)
      ..quadraticBezierTo(size.width * .08, size.height * .62, size.width * .16, size.height * .30)
      ..close();
    canvas.drawPath(boundary, boundaryPaint);

    final candidate = Path()
      ..moveTo(size.width * .30, size.height * .38)
      ..quadraticBezierTo(size.width * .45, size.height * .25, size.width * .63, size.height * .36)
      ..quadraticBezierTo(size.width * .71, size.height * .52, size.width * .57, size.height * .68)
      ..quadraticBezierTo(size.width * .40, size.height * .72, size.width * .30, size.height * .58)
      ..quadraticBezierTo(size.width * .24, size.height * .49, size.width * .30, size.height * .38)
      ..close();
    canvas.drawPath(candidate, candidatePaint);

    final offsetFactor = _riskOffsetFactor();
    final seedJitter = ((hashSeed.abs() % 11) - 5) / 100.0;
    final candidateCenter = Offset(size.width * (.58 + seedJitter), size.height * .47);
    final historicalPoint = Offset(
      size.width * (.47 - offsetFactor + seedJitter),
      size.height * (.50 + offsetFactor / 2),
    );

    canvas.drawLine(historicalPoint, candidateCenter, linePaint);
    canvas.drawCircle(candidateCenter, 5, centerPaint);
    canvas.drawCircle(historicalPoint, 6.5, pointPaint);

    if (!hasCoordinateEvidence) {
      final warningPaint = Paint()
        ..color = const Color(0xFFB22222).withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * .10, size.height * .12, size.width * .80, size.height * .76),
          const Radius.circular(18),
        ),
        warningPaint,
      );
    }

    if (riskCode == 'geometry_missing' || riskCode == 'unknown_distance') {
      final hatchPaint = Paint()
        ..color = Colors.purple.withValues(alpha: 0.24)
        ..strokeWidth = 2;
      for (double x = -size.height; x < size.width; x += 18) {
        canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), hatchPaint);
      }
    }
  }

  Color _lineColor() {
    return switch (riskCode) {
      'critical_distance' => const Color(0xFFB22222),
      'high_distance' => Colors.deepOrange,
      'medium_distance' => Colors.amber.shade800,
      'geometry_missing' => Colors.purple,
      _ => colorScheme.primary,
    };
  }

  double _riskOffsetFactor() {
    return switch (riskCode) {
      'critical_distance' => .25,
      'high_distance' => .18,
      'medium_distance' => .11,
      'geometry_missing' => .20,
      'unknown_distance' => .16,
      _ => .05,
    };
  }

  @override
  bool shouldRepaint(covariant _PwfMapPlaceholderPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme ||
        oldDelegate.riskCode != riskCode ||
        oldDelegate.hashSeed != hashSeed ||
        oldDelegate.hasCoordinateEvidence != hasCoordinateEvidence;
  }
}
