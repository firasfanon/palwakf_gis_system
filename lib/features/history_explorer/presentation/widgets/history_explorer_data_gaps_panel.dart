import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../map/data/repositories/map_feedback_repository.dart';
import '../../../../core/constants/colors.dart';
import '../../application/state/history_explorer_state.dart';
import '../../domain/enums/history_explorer_mode.dart';
import '../../domain/enums/history_period_kind.dart';
import '../../domain/models/history_modern_context.dart';
import '../../domain/models/history_overlay_feature.dart';
import '../../domain/models/history_waqf_asset_link.dart';

class HistoryExplorerDataGapsPanel extends StatelessWidget {
  const HistoryExplorerDataGapsPanel({super.key, required this.state});

  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    final gaps = _buildGaps(state);
    final high = gaps.where((item) => item.severity == _GapSeverity.high).length;
    final medium = gaps.where((item) => item.severity == _GapSeverity.medium).length;
    final low = gaps.where((item) => item.severity == _GapSeverity.low).length;
    final visibleTotal = state.filteredFeatures.length + state.modernSearchResults.length + state.waqfSearchResults.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PwfColors.warning.withValues(alpha: 0.16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PwfColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.fact_check_outlined, color: PwfColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تقرير فجوات مستكشف التاريخ والوقف',
                      style: TextStyle(color: PwfColors.primaryBlue, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    Text(
                      'تحليل مباشر للعناصر الظاهرة في أوضاع التاريخ، الحديث، والوقف دون تحميل طبقات إضافية.',
                      style: TextStyle(
                        color: PwfColors.onSurface.withValues(alpha: 0.70),
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              _GapPill(label: 'المجموع', value: '${gaps.length}', color: PwfColors.primaryBlue),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _GapPill(label: 'عالية', value: '$high', color: PwfColors.royalRed),
              _GapPill(label: 'متوسطة', value: '$medium', color: PwfColors.warning),
              _GapPill(label: 'منخفضة', value: '$low', color: PwfColors.success),
              _GapPill(label: 'عناصر ظاهرة', value: '$visibleTotal', color: PwfColors.primaryBlue),
              _GapPill(label: 'الوضع', value: _modeLabel(state.mode), color: _modeColor(state.mode)),
            ],
          ),
          const SizedBox(height: 12),
          if (gaps.isEmpty)
            _EmptyGapsNotice(state: state)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 880;
                final sections = _groupByDomain(gaps).entries.map((entry) {
                  return _GapDomainSection(
                    title: entry.key,
                    items: entry.value,
                    state: state,
                  );
                }).toList(growable: false);

                if (compact) {
                  return Column(
                    children: sections.map((section) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: section,
                    )).toList(growable: false),
                  );
                }

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: sections.map((section) => SizedBox(width: 420, child: section)).toList(growable: false),
                );
              },
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _copySummary(context, gaps),
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('نسخ ملخص التدقيق'),
              ),
              OutlinedButton.icon(
                onPressed: () => _copyCsv(context, gaps),
                icon: const Icon(Icons.table_view_outlined),
                label: const Text('نسخ CSV'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static List<_ExplorerGapItem> _buildGaps(HistoryExplorerState state) {
    final gaps = <_ExplorerGapItem>[];

    _addHistoricalGaps(state, gaps);
    _addModernGaps(state, gaps);
    _addWaqfGaps(state, gaps);
    _addLineageGaps(state, gaps);

    gaps.sort((a, b) {
      final bySeverity = b.severity.weight.compareTo(a.severity.weight);
      if (bySeverity != 0) return bySeverity;
      final byDomain = a.domain.compareTo(b.domain);
      if (byDomain != 0) return byDomain;
      return a.title.compareTo(b.title);
    });
    return gaps;
  }

  static void _addHistoricalGaps(HistoryExplorerState state, List<_ExplorerGapItem> gaps) {
    final selectedPeriod = state.selectedPeriod;
    if (selectedPeriod != null && state.selectedPeriodKind != HistoryPeriodKind.drawable) {
      gaps.add(_ExplorerGapItem(
        domain: 'التاريخ',
        severity: _GapSeverity.low,
        title: 'الفترة المختارة ليست طبقة GIS تشغيلية',
        detail: 'الفترة ${selectedPeriod.titleAr} مرجعية/وصفية ولا يتوقع أن تعرض هندسة كاملة الآن.',
        action: 'أبقها كسياق وصفي، ولا تعاملها كفشل تحميل.',
      ));
    }

    if (state.selectedPeriodKind == HistoryPeriodKind.drawable && state.overlayFeatures.isEmpty) {
      gaps.add(const _ExplorerGapItem(
        domain: 'التاريخ',
        severity: _GapSeverity.high,
        title: 'فترة قابلة للرسم بلا عناصر ظاهرة',
        detail: 'الفترة الحالية قابلة للرسم، لكن overlayFeatures فارغة.',
        action: 'تحقق من RPC التاريخي ومستوى الطبقة selectedLevelKey.',
      ));
    }

    final missingGeometry = state.overlayFeatures.where((item) => item.geomJson == null && item.centroidJson == null).length;
    if (missingGeometry > 0) {
      gaps.add(_ExplorerGapItem(
        domain: 'التاريخ',
        severity: _GapSeverity.high,
        title: 'عناصر تاريخية بلا هندسة أو مركز',
        detail: '$missingGeometry من ${state.overlayFeatures.length} عنصر تاريخي لا يملك geom/centroid.',
        action: 'لا تُسقطها من البحث، لكن أدرجها في مسار تدقيق هندسي.',
        sample: _sampleHistorical(state.overlayFeatures.where((item) => item.geomJson == null && item.centroidJson == null)),
      ));
    }

    final missingChain = state.overlayFeatures.where((item) => (item.chainKey ?? '').trim().isEmpty).length;
    if (missingChain > 0) {
      gaps.add(_ExplorerGapItem(
        domain: 'التاريخ',
        severity: _GapSeverity.medium,
        title: 'عناصر تاريخية بلا مفتاح سلالة',
        detail: '$missingChain عنصر لا يملك chainKey، وهذا يضعف الربط مع المراحل اللاحقة.',
        action: 'راجع مفاتيح السلالة التاريخية قبل بناء الربط الآلي.',
        sample: _sampleHistorical(state.overlayFeatures.where((item) => (item.chainKey ?? '').trim().isEmpty)),
      ));
    }

    final missingLabel = state.overlayFeatures.where((item) => item.displayLabel.trim().isEmpty).length;
    if (missingLabel > 0) {
      gaps.add(_ExplorerGapItem(
        domain: 'التاريخ',
        severity: _GapSeverity.low,
        title: 'عناصر تاريخية بلا تسمية واضحة',
        detail: '$missingLabel عنصر يحتاج label_ar أو label_en أو entity_code.',
        action: 'أكمل حقول العرض حتى لا تظهر بطاقات/تسميات مبهمة.',
      ));
    }
  }

  static void _addModernGaps(HistoryExplorerState state, List<_ExplorerGapItem> gaps) {
    final items = state.modernSearchResults;
    if (state.mode == HistoryExplorerMode.modern && items.isEmpty && state.searchQuery.trim().isNotEmpty && !state.isLoading) {
      gaps.add(_ExplorerGapItem(
        domain: 'الحديث',
        severity: _GapSeverity.medium,
        title: 'بحث حديث بلا نتائج',
        detail: 'لم يرجع البحث الحديث نتائج لعبارة: ${state.searchQuery.trim()}.',
        action: 'تحقق من أسماء التجمعات/الهيئات والحقول المستخدمة في البحث.',
      ));
    }

    final missingSpatial = items.where((item) => !item.hasGeometry && !item.hasCentroidGeometry && !item.hasCenter).length;
    if (missingSpatial > 0) {
      gaps.add(_ExplorerGapItem(
        domain: 'الحديث',
        severity: _GapSeverity.high,
        title: 'مراجع حديثة بلا تمثيل مكاني',
        detail: '$missingSpatial من ${items.length} مرجع حديث بلا geom/centroid/center.',
        action: 'اربطها بحدود LGU/Community أو وفّر centroid آمن للعرض.',
        sample: _sampleModern(items.where((item) => !item.hasGeometry && !item.hasCentroidGeometry && !item.hasCenter)),
      ));
    }

    final missingLgu = items.where((item) => (item.lguCode ?? '').trim().isEmpty && (item.lguLabel ?? '').trim().isEmpty).length;
    if (missingLgu > 0) {
      gaps.add(_ExplorerGapItem(
        domain: 'الحديث',
        severity: _GapSeverity.medium,
        title: 'مراجع حديثة بلا هيئة محلية',
        detail: '$missingLgu مرجع حديث لا يملك lguCode/lguLabel.',
        action: 'ثبت الربط بالهيئة المحلية لأن المستكشف الحديث يعتمد LGU لا التجمع فقط.',
        sample: _sampleModern(items.where((item) => (item.lguCode ?? '').trim().isEmpty && (item.lguLabel ?? '').trim().isEmpty)),
      ));
    }

    final missingGov = items.where((item) => (item.governorateCode ?? '').trim().isEmpty && (item.governorateLabel ?? '').trim().isEmpty).length;
    if (missingGov > 0) {
      gaps.add(_ExplorerGapItem(
        domain: 'الحديث',
        severity: _GapSeverity.low,
        title: 'مراجع حديثة بلا محافظة',
        detail: '$missingGov مرجع حديث لا يملك محافظة صريحة.',
        action: 'استخرج المحافظة من حدود LGU أو جدول core المعتمد.',
        sample: _sampleModern(items.where((item) => (item.governorateCode ?? '').trim().isEmpty && (item.governorateLabel ?? '').trim().isEmpty)),
      ));
    }
  }

  static void _addWaqfGaps(HistoryExplorerState state, List<_ExplorerGapItem> gaps) {
    final items = state.waqfSearchResults;
    if (state.mode == HistoryExplorerMode.waqf && items.isEmpty && state.searchQuery.trim().isNotEmpty && !state.isLoading) {
      gaps.add(_ExplorerGapItem(
        domain: 'الوقف',
        severity: _GapSeverity.medium,
        title: 'بحث وقف بلا نتائج',
        detail: 'لم يرجع بحث الأوقاف نتائج لعبارة: ${state.searchQuery.trim()}.',
        action: 'تحقق من الاسم أو الرقم الوطني أو فلتر الوقف المرجعي.',
      ));
    }

    final missingSpatial = items.where((item) => !item.hasGeometry && !item.hasCentroidGeometry && !item.hasCenter).length;
    if (missingSpatial > 0) {
      gaps.add(_ExplorerGapItem(
        domain: 'الوقف',
        severity: _GapSeverity.high,
        title: 'أصول وقفية بلا هندسة أو مركز',
        detail: '$missingSpatial من ${items.length} أصل وقفي بلا geom/centroid/center.',
        action: 'أبقها في البحث والبطاقات، وارسلها لمسار تدقيق هندسي/ربط قطعة.',
        sample: _sampleWaqf(items.where((item) => !item.hasGeometry && !item.hasCentroidGeometry && !item.hasCenter)),
      ));
    }

    final missingCode = items.where((item) => item.pwfKey.trim().isEmpty && item.id.trim().isEmpty).length;
    if (missingCode > 0) {
      gaps.add(_ExplorerGapItem(
        domain: 'الوقف',
        severity: _GapSeverity.high,
        title: 'أصول وقفية بلا مفتاح سيادي',
        detail: '$missingCode أصل لا يملك id أو national_asset_code/pwfKey.',
        action: 'لا تعتمد الربط المكاني قبل تثبيت مفتاح الأصل الوقفي السيادي.',
      ));
    }

    final missingAdmin = items.where((item) {
      return (item.governorate ?? '').trim().isEmpty &&
          (item.municipality ?? '').trim().isEmpty &&
          (item.community ?? '').trim().isEmpty;
    }).length;
    if (missingAdmin > 0) {
      gaps.add(_ExplorerGapItem(
        domain: 'الوقف',
        severity: _GapSeverity.medium,
        title: 'أصول وقفية بلا سياق إداري',
        detail: '$missingAdmin أصل لا يملك محافظة/هيئة/تجمع ظاهر.',
        action: 'استكمل الحقول المرجعية من awqaf_system/core ولا تولّدها داخل Mustakshif.',
        sample: _sampleWaqf(items.where((item) => (item.governorate ?? '').trim().isEmpty && (item.municipality ?? '').trim().isEmpty && (item.community ?? '').trim().isEmpty)),
      ));
    }

    final selectedAsset = state.selectedWaqfAsset ??
        (state.selectedWaqfAssetRecord != null
            ? HistoryWaqfAssetLink(
                id: state.selectedWaqfAssetRecord!.waqfAssetId,
                pwfKey: state.selectedWaqfAssetRecord!.nationalAssetCode,
                name: state.selectedWaqfAssetRecord!.nameAr,
              )
            : null);
    if (selectedAsset != null && state.linkedParcels.isEmpty) {
      gaps.add(_ExplorerGapItem(
        domain: 'الوقف',
        severity: _GapSeverity.medium,
        title: 'الأصل المحدد بلا قطع مرتبطة ظاهرة',
        detail: 'الأصل ${selectedAsset.displayLabel} لا يملك linkedParcels محمّلة في الحالة الحالية.',
        action: 'تحقق من جدول الربط أو RPC القطع المرتبطة بعد اعتماد طبقة التسوية.',
      ));
    }

    final nonSpatialParcels = state.linkedParcels.where((row) => !_parcelHasSpatial(row)).length;
    if (nonSpatialParcels > 0) {
      gaps.add(_ExplorerGapItem(
        domain: 'الوقف',
        severity: _GapSeverity.medium,
        title: 'قطع مرتبطة بلا هندسة',
        detail: '$nonSpatialParcels من ${state.linkedParcels.length} قطعة مرتبطة لا تملك تمثيلًا مكانيًا ظاهرًا.',
        action: 'لا تعرضها كطبقة، واعرضها في جدول تدقيق حتى تكتمل هندستها.',
      ));
    }
  }

  static void _addLineageGaps(HistoryExplorerState state, List<_ExplorerGapItem> gaps) {
    final hasSelection = state.selectedFeatureId != null ||
        state.selectedModernContextCode != null ||
        state.selectedWaqfAssetId != null ||
        state.selectedWaqfAssetRecord != null;

    if (hasSelection && !state.resolvedContext.hasAnyData && !state.isResolvingContext) {
      gaps.add(const _ExplorerGapItem(
        domain: 'السلالة',
        severity: _GapSeverity.high,
        title: 'عنصر محدد بلا سياق ربط',
        detail: 'يوجد عنصر محدد لكن resolvedContext فارغ.',
        action: 'راجع RPC/Repository الربط بين التاريخ والحديث والوقف.',
      ));
    }

    if (state.resolvedContext.hasAnyData && state.resolvedContext.lineageNodes.isEmpty) {
      gaps.add(_ExplorerGapItem(
        domain: 'السلالة',
        severity: _GapSeverity.high,
        title: 'سياق موجود بلا سلالة تاريخية',
        detail: 'يوجد سياق حديث/وقفي لكن lineageNodes فارغة. طريقة الحل: ${state.resolvedContext.resolutionMethod}.',
        action: 'ثبت ربط الأصل/التجمع بجذر تاريخي أو ضع سبب فجوة واضح.',
      ));
    }

    if (state.resolvedContext.hasAnyData && !state.resolvedContext.isSovereign) {
      gaps.add(_ExplorerGapItem(
        domain: 'السلالة',
        severity: _GapSeverity.medium,
        title: 'الربط الحالي غير سيادي بالكامل',
        detail: 'طريقة الربط الحالية: ${state.resolvedContext.resolutionMethod}.',
        action: 'استخدمه كاقتراح/مؤشر، ولا تعتمده كحقيقة نهائية قبل المراجعة.',
      ));
    }

    if (state.contextErrorMessage != null && state.contextErrorMessage!.trim().isNotEmpty) {
      gaps.add(_ExplorerGapItem(
        domain: 'السلالة',
        severity: _GapSeverity.high,
        title: 'خطأ في تحليل السلالة',
        detail: state.contextErrorMessage!,
        action: 'عالج الخطأ من مصدر الربط فقط دون إعادة هندسة المستكشف.',
      ));
    }
  }

  static Map<String, List<_ExplorerGapItem>> _groupByDomain(List<_ExplorerGapItem> gaps) {
    final map = <String, List<_ExplorerGapItem>>{};
    for (final gap in gaps) {
      map.putIfAbsent(gap.domain, () => <_ExplorerGapItem>[]).add(gap);
    }
    return map;
  }

  static List<String> _sampleHistorical(Iterable<HistoryOverlayFeature> items) {
    return items.take(4).map((item) => item.displayLabel).where((text) => text.trim().isNotEmpty).toList(growable: false);
  }

  static List<String> _sampleModern(Iterable<HistoryModernContext> items) {
    return items.take(4).map((item) => item.communityLabel.trim().isNotEmpty ? item.communityLabel : item.communityCode).where((text) => text.trim().isNotEmpty).toList(growable: false);
  }

  static List<String> _sampleWaqf(Iterable<HistoryWaqfAssetLink> items) {
    return items.take(4).map((item) => item.displayLabel).where((text) => text.trim().isNotEmpty).toList(growable: false);
  }

  static bool _parcelHasSpatial(Map<String, dynamic> row) {
    for (final key in const [
      'geom',
      'geom_json',
      'geometry',
      'geometry_json',
      'centroid',
      'centroid_json',
      'center',
      'lat',
      'latitude',
      'center_lat',
    ]) {
      if (row[key] != null) return true;
    }
    return false;
  }

  static String _modeLabel(HistoryExplorerMode mode) {
    switch (mode) {
      case HistoryExplorerMode.historical:
        return 'التاريخ';
      case HistoryExplorerMode.modern:
        return 'الحديث';
      case HistoryExplorerMode.waqf:
        return 'الوقف';
    }
  }

  static Color _modeColor(HistoryExplorerMode mode) {
    switch (mode) {
      case HistoryExplorerMode.historical:
        return PwfColors.primaryBlue;
      case HistoryExplorerMode.modern:
        return PwfColors.warning;
      case HistoryExplorerMode.waqf:
        return PwfColors.royalRed;
    }
  }

  void _copySummary(BuildContext context, List<_ExplorerGapItem> gaps) {
    final lines = <String>[
      'PalWakf Explorer Data Gaps Report',
      'mode=${state.mode.name}',
      'period=${state.selectedPeriodNo ?? '-'}',
      'level=${state.selectedLevelKey ?? '-'}',
      'query=${state.searchQuery.trim().isEmpty ? '-' : state.searchQuery.trim()}',
      'historical_visible=${state.filteredFeatures.length}',
      'modern_results=${state.modernSearchResults.length}',
      'waqf_results=${state.waqfSearchResults.length}',
      'linked_parcels=${state.linkedParcels.length}',
      'gaps_total=${gaps.length}',
      '',
      ...gaps.map((gap) => '[${gap.severity.label}] ${gap.domain} - ${gap.title}: ${gap.detail} | action=${gap.action}'),
    ];
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ ملخص فجوات المستكشف.')),
    );
  }

  void _copyCsv(BuildContext context, List<_ExplorerGapItem> gaps) {
    final rows = <List<String>>[
      const ['domain', 'severity', 'title', 'detail', 'action', 'sample'],
      ...gaps.map((gap) => [
            gap.domain,
            gap.severity.name,
            gap.title,
            gap.detail,
            gap.action,
            gap.sample.join(' | '),
          ]),
    ];
    final csv = rows.map((row) => row.map(_csvEscape).join(',')).join('\n');
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ CSV فجوات المستكشف.')),
    );
  }

  static String _csvEscape(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') || escaped.contains('\n') || escaped.contains('"')) {
      return '"$escaped"';
    }
    return escaped;
  }


  static Future<void> _showCreateGapAuditDialog(
    BuildContext context,
    HistoryExplorerState state,
    _ExplorerGapItem gap,
  ) async {
    final noteController = TextEditingController();
    final priority = _priorityForGap(gap.severity);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('تحويل الفجوة إلى طلب تدقيق'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gap.title,
                  style: const TextStyle(
                    color: PwfColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  gap.detail,
                  style: TextStyle(
                    color: PwfColors.onSurface.withValues(alpha: 0.76),
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  minLines: 2,
                  maxLines: 4,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة إضافية اختيارية',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'الأولوية المقترحة: ${_priorityLabel(priority)}',
                  style: const TextStyle(
                    color: PwfColors.primaryBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.assignment_turned_in_outlined),
              label: const Text('إنشاء طلب تدقيق'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = MapFeedbackRepository(Supabase.instance.client);
      final request = await repo.createExplorerGapAuditRequest(
        ExplorerGapAuditSubmission(
          domain: gap.domain,
          severity: gap.severity.name,
          title: gap.title,
          detail: gap.detail,
          recommendedAction: gap.action,
          sample: gap.sample,
          explorerMode: state.mode.name,
          priority: priority,
          reporterNote: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
          context: _gapContext(state),
        ),
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text('تم إنشاء طلب تدقيق للفجوة: ${request.displayStatus}'),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('تعذر إنشاء طلب التدقيق: $error')),
      );
    } finally {
      noteController.dispose();
    }
  }

  static Map<String, dynamic> _gapContext(HistoryExplorerState state) {
    return {
      'source': 'history_explorer_data_gaps_panel',
      'mode': state.mode.name,
      'period_no': state.selectedPeriodNo,
      'period_title': state.selectedPeriod?.titleAr,
      'period_kind': state.selectedPeriodKind.name,
      'level_key': state.selectedLevelKey,
      'level_label': state.selectedLevelLabel,
      'query': state.searchQuery.trim(),
      'selected_feature_id': state.selectedFeatureId,
      'selected_modern_context_code': state.selectedModernContextCode,
      'selected_waqf_asset_id': state.selectedWaqfAssetId,
      'selected_national_asset_code': state.selectedNationalAssetCode,
      'historical_visible_count': state.filteredFeatures.length,
      'historical_overlay_count': state.overlayFeatures.length,
      'modern_results_count': state.modernSearchResults.length,
      'waqf_results_count': state.waqfSearchResults.length,
      'linked_parcels_count': state.linkedParcels.length,
      'lineage_nodes_count': state.resolvedContext.lineageNodes.length,
      'resolution_method': state.resolvedContext.resolutionMethod,
      'is_sovereign_context': state.resolvedContext.isSovereign,
      'runtime_request_token': state.runtimeRequestToken,
    };
  }

  static String _priorityForGap(_GapSeverity severity) {
    switch (severity) {
      case _GapSeverity.high:
        return 'high';
      case _GapSeverity.medium:
        return 'normal';
      case _GapSeverity.low:
        return 'low';
    }
  }

  static String _priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'مرتفعة';
      case 'low':
        return 'منخفضة';
      case 'urgent':
        return 'عاجلة';
      default:
        return 'عادية';
    }
  }
}
class _GapDomainSection extends StatelessWidget {
  const _GapDomainSection({
    required this.title,
    required this.items,
    required this.state,
  });

  final String title;
  final List<_ExplorerGapItem> items;
  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PwfColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_folder_outlined, color: PwfColors.primaryBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: PwfColors.primaryBlue, fontWeight: FontWeight.w900),
                ),
              ),
              _GapPill(label: 'فجوات', value: '${items.length}', color: PwfColors.primaryBlue),
            ],
          ),
          const SizedBox(height: 10),
          ...items.take(5).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _GapItemTile(item: item, state: state),
              )),
          if (items.length > 5)
            Text(
              'و ${items.length - 5} فجوة أخرى ضمن نفس المجال.',
              style: TextStyle(color: PwfColors.onSurface.withValues(alpha: 0.64), fontWeight: FontWeight.w700, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _GapItemTile extends StatelessWidget {
  const _GapItemTile({required this.item, required this.state});

  final _ExplorerGapItem item;
  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    final color = item.severity.color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.severity.icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ),
              _GapPill(label: item.severity.label, value: '', color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.detail,
            style: TextStyle(color: PwfColors.onSurface.withValues(alpha: 0.78), fontWeight: FontWeight.w700, height: 1.45),
          ),
          const SizedBox(height: 4),
          Text(
            'الإجراء: ${item.action}',
            style: const TextStyle(color: PwfColors.primaryBlue, fontWeight: FontWeight.w800, height: 1.45),
          ),
          if (item.sample.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.sample.map((sample) => _SmallSampleChip(label: sample)).toList(growable: false),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: OutlinedButton.icon(
              onPressed: () => HistoryExplorerDataGapsPanel._showCreateGapAuditDialog(context, state, item),
              icon: const Icon(Icons.assignment_add, size: 18),
              label: const Text('تحويل لطلب تدقيق'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGapsNotice extends StatelessWidget {
  const _EmptyGapsNotice({required this.state});

  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    final hasData = state.filteredFeatures.isNotEmpty || state.modernSearchResults.isNotEmpty || state.waqfSearchResults.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PwfColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PwfColors.success.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: PwfColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasData
                  ? 'لا توجد فجوات ظاهرة ضمن البيانات المحمّلة حاليًا.'
                  : 'لا توجد بيانات ظاهرة لتحليل الفجوات. اختر وضعًا أو ابحث عن عنصر أولًا.',
              style: const TextStyle(color: PwfColors.success, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _GapPill extends StatelessWidget {
  const _GapPill({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = value.isEmpty ? label : '$label: $value';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11),
      ),
    );
  }
}

class _SmallSampleChip extends StatelessWidget {
  const _SmallSampleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: PwfColors.onSurface.withValues(alpha: 0.72), fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}

class _ExplorerGapItem {
  const _ExplorerGapItem({
    required this.domain,
    required this.severity,
    required this.title,
    required this.detail,
    required this.action,
    this.sample = const [],
  });

  final String domain;
  final _GapSeverity severity;
  final String title;
  final String detail;
  final String action;
  final List<String> sample;
}

enum _GapSeverity { high, medium, low }

extension _GapSeverityX on _GapSeverity {
  String get label {
    switch (this) {
      case _GapSeverity.high:
        return 'عالية';
      case _GapSeverity.medium:
        return 'متوسطة';
      case _GapSeverity.low:
        return 'منخفضة';
    }
  }

  String get name {
    switch (this) {
      case _GapSeverity.high:
        return 'high';
      case _GapSeverity.medium:
        return 'medium';
      case _GapSeverity.low:
        return 'low';
    }
  }

  int get weight {
    switch (this) {
      case _GapSeverity.high:
        return 3;
      case _GapSeverity.medium:
        return 2;
      case _GapSeverity.low:
        return 1;
    }
  }

  Color get color {
    switch (this) {
      case _GapSeverity.high:
        return PwfColors.royalRed;
      case _GapSeverity.medium:
        return PwfColors.warning;
      case _GapSeverity.low:
        return PwfColors.success;
    }
  }

  IconData get icon {
    switch (this) {
      case _GapSeverity.high:
        return Icons.error_outline;
      case _GapSeverity.medium:
        return Icons.warning_amber_outlined;
      case _GapSeverity.low:
        return Icons.info_outline;
    }
  }
}
