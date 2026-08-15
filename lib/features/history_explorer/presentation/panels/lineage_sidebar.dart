import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/pwf_card.dart';
import '../../application/state/history_explorer_state.dart';
import '../../domain/enums/history_explorer_mode.dart';
import '../../domain/models/history_lineage_node.dart';
import '../../domain/models/history_modern_context.dart';
import '../../domain/models/history_overlay_feature.dart';
import '../../domain/models/history_waqf_asset_link.dart';
import '../widgets/waqf_reference_preview_card.dart';

class LineageSidebar extends StatelessWidget {
  const LineageSidebar({super.key, required this.state});

  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    final selectedFeature = state.selectedFeature;
    final selectedModern = state.selectedModernContext;
    final selectedWaqf = state.selectedWaqfAsset;
    final resolved = state.resolvedContext;
    final hasContext = selectedFeature != null ||
        selectedModern != null ||
        selectedWaqf != null ||
        resolved.lineageNodes.isNotEmpty ||
        resolved.modernContexts.isNotEmpty ||
        resolved.waqfAssets.isNotEmpty;

    final children = <Widget>[
      _Block(
        title: 'ملخص الفترة',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.periodMeta?.titleAr ?? state.selectedPeriod?.titleAr ?? '—',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            if (state.periodMeta?.rangeLabelAr?.trim().isNotEmpty == true ||
                state.selectedPeriod?.rangeLabelAr?.trim().isNotEmpty ==
                    true) ...[
              const SizedBox(height: 6),
              Text(
                state.periodMeta?.rangeLabelAr ??
                    state.selectedPeriod?.rangeLabelAr ??
                    '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PwfColors.onSurface.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              state.periodMeta?.summaryAr?.trim().isNotEmpty == true
                  ? state.periodMeta!.summaryAr!
                  : 'تعرض هذه اللوحة الآن مسار الاستكشاف الحالي: كيان تاريخي أو مرجع حديث أو أصل وقفي، مع محاولة ربطه بالسلسلة المقابلة.',
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                    label: 'النوع: ${state.selectedPeriodKind.labelAr}',
                    color: PwfColors.primaryBlue),
                _StatusChip(
                    label: 'السلسلة: ${state.periodMeta?.chainLabelAr ?? '—'}',
                    color: PwfColors.success),
                _StatusChip(
                    label: 'النمط: ${_modeLabel(state.mode)}',
                    color: PwfColors.warning),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _Block(title: 'مسار الاستكشاف الحالي', child: _PathPreview(state: state)),
      const SizedBox(height: 12),
      const _ReadingGuideBlock(),
      const SizedBox(height: 12),
    ];

    if (!hasContext || !state.showLineage) {
      children.add(_EmptyLineage(state: state));
    } else {
      if (selectedFeature != null) {
        children
            .add(_SelectedEntityCard(selected: selectedFeature, state: state));
      } else if (selectedModern != null) {
        children.add(_SelectedModernContextCard(selected: selectedModern));
      } else if (selectedWaqf != null) {
        children.add(_SelectedWaqfAssetCard(selected: selectedWaqf));
        children.add(const SizedBox(height: 12));
        children.add(WaqfReferencePreviewCard(
            asset: selectedWaqf, title: 'المرجع الوقفي التفصيلي'));
      }
      children.add(const SizedBox(height: 12));
      if (state.isResolvingContext) {
        children.add(const _Block(
          title: 'جاري التحليل',
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2)),
                SizedBox(width: 12),
                Expanded(
                    child: Text(
                        'يتم الآن تحليل المسار وربطه بالسجل التاريخي والمرجع الحديث والأصول الوقفية.')),
              ],
            ),
          ),
        ));
      } else {
        if (state.contextErrorMessage?.trim().isNotEmpty == true) {
          children.add(_Block(
            title: 'تنبيه',
            child: Text(
              state.contextErrorMessage!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: PwfColors.royalRed, height: 1.7),
            ),
          ));
          children.add(const SizedBox(height: 12));
        }
        children.add(_Block(
          title: 'منهج الحل الحالي',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(
                    label: resolved.isSovereign ? 'RPC سيادي' : 'Fallback مرن',
                    color: resolved.isSovereign
                        ? PwfColors.success
                        : PwfColors.warning,
                  ),
                  _StatusChip(
                      label: 'المنهج: ${resolved.resolutionMethod}',
                      color: PwfColors.primaryBlue),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                resolved.isSovereign
                    ? 'تم حل المسار الحالي عبر استجابة RPC موحّدة إن كانت متوفرة في قاعدة البيانات، وهذا هو المسار السيادي الأفضل.'
                    : 'المسار الحالي حُلّ عبر مطابقة مرنة بين السجلات التاريخية والمرجع الحديث/الوقفـي. يعمل عمليًا لكنه ليس البديل السيادي النهائي.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.7),
              ),
            ],
          ),
        ));
        children.add(const SizedBox(height: 12));
        if (resolved.note?.trim().isNotEmpty == true) {
          children.add(_Block(
            title: 'ملاحظة الربط',
            child: Text(
              resolved.note!,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
            ),
          ));
          children.add(const SizedBox(height: 12));
        }
        children.add(_LineageNodesBlock(
          nodes: resolved.lineageNodes,
          fallbackNode:
              _fallbackNode(selectedFeature, selectedModern, selectedWaqf),
        ));
        children.add(const SizedBox(height: 12));
        children.add(_ModernContextsBlock(
          contexts: resolved.modernContexts,
          enabled: state.showModernContext,
          selectedCommunityCode: state.selectedModernContextCode,
        ));
        children.add(const SizedBox(height: 12));
        children.add(_WaqfAssetsBlock(
          items: resolved.waqfAssets,
          enabled: state.showWaqfAssets,
          selectedAssetId: state.selectedWaqfAssetId,
        ));
      }
      if (selectedFeature != null) {
        children.add(const SizedBox(height: 12));
        children.add(_Block(
          title: 'خصائص خام مختصرة',
          child: SelectableText(
            const JsonEncoder.withIndent('  ')
                .convert(_summaryJson(selectedFeature.attributes)),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontFamily: 'monospace', height: 1.6),
          ),
        ));
      }
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: children,
    );
  }

  HistoryLineageNode? _fallbackNode(
    HistoryOverlayFeature? selectedFeature,
    HistoryModernContext? selectedModern,
    HistoryWaqfAssetLink? selectedWaqf,
  ) {
    if (selectedFeature != null) {
      return HistoryLineageNode(
        id: selectedFeature.sourceId,
        label: selectedFeature.displayLabel,
        periodId: selectedFeature.periodNo,
        periodLabel: selectedFeature.periodLabelAr,
        relationLabel: selectedFeature.levelKey,
        isPrimary: true,
      );
    }
    if (selectedModern != null) {
      return HistoryLineageNode(
        id: selectedModern.communityCode,
        label: selectedModern.communityLabel,
        periodLabel: 'مرجع حديث',
        relationLabel: 'community origin',
        originCommunityCode: selectedModern.communityCode,
        isPrimary: true,
      );
    }
    if (selectedWaqf != null) {
      return HistoryLineageNode(
        id: selectedWaqf.id,
        label: selectedWaqf.name ?? selectedWaqf.pwfKey,
        periodLabel: 'أصل وقفي حديث',
        relationLabel: 'waqf asset',
        isPrimary: true,
      );
    }
    return null;
  }

  Map<String, dynamic> _summaryJson(Map<String, dynamic> raw) {
    final keys = [
      'period_no',
      'period_label_ar',
      'level_key',
      'source_table',
      'source_id',
      'parent_source_id',
      'entity_code',
      'label_ar',
      'label_en',
    ];
    final result = <String, dynamic>{};
    for (final key in keys) {
      if (raw.containsKey(key) && raw[key] != null) {
        result[key] = raw[key];
      }
    }
    return result.isEmpty ? raw : result;
  }

  String _modeLabel(HistoryExplorerMode mode) {
    switch (mode) {
      case HistoryExplorerMode.historical:
        return 'من التاريخ';
      case HistoryExplorerMode.modern:
        return 'من الحديث';
      case HistoryExplorerMode.waqf:
        return 'من الوقف';
    }
  }
}

class _EmptyLineage extends StatelessWidget {
  const _EmptyLineage({required this.state});

  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    String message;
    switch (state.mode) {
      case HistoryExplorerMode.historical:
        message = state.showLineage
            ? 'اختر عنصرًا من القائمة أو من الخريطة لعرض السجل التاريخي الموافق له، ثم المرجع الحديث واقتراحات الأصول الوقفية.'
            : 'لوحة السلالة معطلة حاليًا من الفلاتر العلوية.';
        break;
      case HistoryExplorerMode.modern:
        message = state.showLineage
            ? 'اختر وحدة حديثة من قائمة اليمين ليبدأ تتبع الجذر التاريخي والأصول الوقفية المرتبطة بها.'
            : 'لوحة السلالة معطلة حاليًا من الفلاتر العلوية.';
        break;
      case HistoryExplorerMode.waqf:
        message = state.showLineage
            ? 'اختر أصلًا وقفيًا حديثًا من قائمة اليمين ليتم تحليل مرجعه الحديث ثم جذره التاريخي.'
            : 'لوحة السلالة معطلة حاليًا من الفلاتر العلوية.';
        break;
    }
    return _Block(
      title: 'تفاصيل المسار المحدد',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.7)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _StatusChip(label: 'تاريخي أصلي', color: PwfColors.primaryBlue),
              _StatusChip(label: 'مرجع حديث', color: PwfColors.warning),
              _StatusChip(label: 'أصل وقفي نهائي', color: PwfColors.royalRed),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedEntityCard extends StatelessWidget {
  const _SelectedEntityCard({required this.selected, required this.state});

  final HistoryOverlayFeature selected;
  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    return _Block(
      title: 'العنصر التاريخي المحدد',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(selected.displayLabel,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                  label: selected.levelKey ?? '—',
                  color: PwfColors.primaryBlue),
              _StatusChip(
                  label: selected.sourceTable ?? 'overlay',
                  color: PwfColors.success),
              if ((selected.chainKey ?? '').trim().isNotEmpty)
                _StatusChip(
                    label: selected.chainKey!, color: PwfColors.warning),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'source_id', value: selected.sourceId),
          _InfoRow(label: 'entity_code', value: selected.entityCode ?? '—'),
          _InfoRow(
              label: 'parent_source_id', value: selected.parentSourceId ?? '—'),
          if (state.resolvedContext.matchedUnitCode?.trim().isNotEmpty ==
              true) ...[
            const SizedBox(height: 8),
            _InfoRow(
                label: 'matched_unit_code',
                value: state.resolvedContext.matchedUnitCode!),
          ],
        ],
      ),
    );
  }
}

class _SelectedModernContextCard extends StatelessWidget {
  const _SelectedModernContextCard({required this.selected});

  final HistoryModernContext selected;

  @override
  Widget build(BuildContext context) {
    return _Block(
      title: 'المرجع الحديث المحدد',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(selected.communityLabel,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const _StatusChip(label: 'community', color: PwfColors.warning),
              if ((selected.lguLabel ?? '').trim().isNotEmpty)
                _StatusChip(
                    label: selected.lguLabel!, color: PwfColors.success),
              if ((selected.governorateLabel ?? '').trim().isNotEmpty)
                _StatusChip(
                    label: selected.governorateLabel!,
                    color: PwfColors.primaryBlue),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'community_code', value: selected.communityCode),
          _InfoRow(label: 'الهيئة المحلية', value: selected.lguLabel ?? '—'),
          _InfoRow(label: 'المحافظة', value: selected.governorateLabel ?? '—'),
        ],
      ),
    );
  }
}

class _SelectedWaqfAssetCard extends StatelessWidget {
  const _SelectedWaqfAssetCard({required this.selected});

  final HistoryWaqfAssetLink selected;

  @override
  Widget build(BuildContext context) {
    return _Block(
      title: 'الأصل الوقفي المحدد',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(selected.name ?? selected.pwfKey,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(label: selected.pwfKey, color: PwfColors.royalRed),
              if ((selected.community ?? '').trim().isNotEmpty)
                _StatusChip(
                    label: selected.community!, color: PwfColors.warning),
              if ((selected.governorate ?? '').trim().isNotEmpty)
                _StatusChip(
                    label: selected.governorate!, color: PwfColors.primaryBlue),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'المجتمع', value: selected.community ?? '—'),
          _InfoRow(
              label: 'الهيئة المحلية', value: selected.municipality ?? '—'),
          _InfoRow(label: 'المحافظة', value: selected.governorate ?? '—'),
          _InfoRow(label: 'النوع', value: selected.typeLabel ?? '—'),
          _InfoRow(label: 'الفئة', value: selected.categoryLabel ?? '—'),
          _InfoRow(label: 'الواقف', value: selected.endowerName ?? '—'),
          _InfoRow(label: 'الحالة', value: selected.statusLabel ?? '—'),
          if ((selected.purpose ?? '').trim().isNotEmpty)
            _InfoRow(label: 'الغرض', value: selected.purpose!),
          if (selected.area != null)
            _InfoRow(
                label: 'المساحة', value: selected.area!.toStringAsFixed(2)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => context.go(
                  '/waqf/${selected.pwfKey.isNotEmpty ? selected.pwfKey : selected.id}'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('فتح مرجع الوقف'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineageNodesBlock extends StatelessWidget {
  const _LineageNodesBlock({required this.nodes, required this.fallbackNode});

  final List<HistoryLineageNode> nodes;
  final HistoryLineageNode? fallbackNode;

  @override
  Widget build(BuildContext context) {
    final effectiveNodes = nodes.isNotEmpty
        ? nodes
        : (fallbackNode == null
            ? const <HistoryLineageNode>[]
            : [fallbackNode!]);

    return _Block(
      title: 'السجل التاريخي والسلالة',
      child: effectiveNodes.isEmpty
          ? const Text('لم تُولد عقد سلالة بعد لهذا الاختيار.')
          : Column(
              children: effectiveNodes
                  .map(
                    (node) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: node.isPrimary
                            ? PwfColors.primaryBlue.withValues(alpha: 0.07)
                            : PwfColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: node.isPrimary
                              ? PwfColors.primaryBlue.withValues(alpha: 0.24)
                              : PwfColors.outline,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: node.isPrimary
                                  ? PwfColors.primaryBlue
                                  : PwfColors.success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(node.label,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    if (node.relationLabel?.trim().isNotEmpty ==
                                        true)
                                      node.relationLabel,
                                    if (node.periodLabel?.trim().isNotEmpty ==
                                        true)
                                      node.periodLabel,
                                    if (node.periodId != null)
                                      'period=${node.periodId}',
                                  ].whereType<String>().join(' • '),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: PwfColors.onSurface
                                              .withValues(alpha: 0.66)),
                                ),
                                if (node.originCommunityCode
                                        ?.trim()
                                        .isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'origin_community_code: ${node.originCommunityCode}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: PwfColors.warning,
                                            fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _ModernContextsBlock extends StatelessWidget {
  const _ModernContextsBlock({
    required this.contexts,
    required this.enabled,
    required this.selectedCommunityCode,
  });

  final List<HistoryModernContext> contexts;
  final bool enabled;
  final String? selectedCommunityCode;

  @override
  Widget build(BuildContext context) {
    return _Block(
      title: 'المرجع الإداري الحديث',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusChip(
            label: enabled
                ? 'المرجع الحديث مفعّل بصريًا'
                : 'المرجع الحديث غير مفعّل بصريًا',
            color: enabled ? PwfColors.success : PwfColors.warning,
          ),
          const SizedBox(height: 10),
          if (contexts.isEmpty)
            Text(
              'لم يتم العثور بعد على community origin مرتبطة بهذا المسار، أو أن lookup الحديث غير متاح في هذه القاعدة.',
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
            )
          else
            Column(
              children: contexts.map(
                (item) {
                  final isSelected =
                      selectedCommunityCode == item.communityCode;
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? PwfColors.primaryBlue.withValues(alpha: 0.08)
                          : PwfColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isSelected
                              ? PwfColors.primaryBlue.withValues(alpha: 0.45)
                              : PwfColors.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(item.communityLabel,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800))),
                            if (isSelected)
                              const _StatusChip(
                                  label: 'محدد على الخريطة',
                                  color: PwfColors.primaryBlue),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if ((item.lguLabel ?? '').trim().isNotEmpty)
                          _InfoRow(
                              label: 'الهيئة المحلية', value: item.lguLabel!),
                        if ((item.governorateLabel ?? '').trim().isNotEmpty)
                          _InfoRow(
                              label: 'المحافظة', value: item.governorateLabel!),
                        _InfoRow(
                            label: 'community_code', value: item.communityCode),
                      ],
                    ),
                  );
                },
              ).toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _WaqfAssetsBlock extends StatelessWidget {
  const _WaqfAssetsBlock({
    required this.items,
    required this.enabled,
    required this.selectedAssetId,
  });

  final List<HistoryWaqfAssetLink> items;
  final bool enabled;
  final String? selectedAssetId;

  @override
  Widget build(BuildContext context) {
    return _Block(
      title: 'الأصول الوقفية المقترحة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusChip(
            label: enabled
                ? 'إظهار الأصول الوقفية مفعّل'
                : 'إظهار الأصول الوقفية غير مفعّل بصريًا',
            color: enabled ? PwfColors.royalRed : PwfColors.warning,
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              'لم تُسترجع أصول وقفية مرتبطة بهذا المسار حتى الآن.',
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
            )
          else
            Column(
              children: items.map(
                (item) {
                  final isSelected = selectedAssetId == item.id;
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? PwfColors.royalRed.withValues(alpha: 0.07)
                          : PwfColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isSelected
                              ? PwfColors.royalRed.withValues(alpha: 0.42)
                              : PwfColors.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(item.name ?? item.pwfKey,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800))),
                            if (isSelected)
                              const _StatusChip(
                                  label: 'محدد على الخريطة',
                                  color: PwfColors.royalRed),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _InfoRow(label: 'PWF', value: item.pwfKey),
                        if ((item.community ?? '').trim().isNotEmpty)
                          _InfoRow(label: 'المجتمع', value: item.community!),
                        if ((item.municipality ?? '').trim().isNotEmpty)
                          _InfoRow(
                              label: 'الهيئة المحلية',
                              value: item.municipality!),
                        if ((item.governorate ?? '').trim().isNotEmpty)
                          _InfoRow(label: 'المحافظة', value: item.governorate!),
                        if ((item.endowerName ?? '').trim().isNotEmpty)
                          _InfoRow(label: 'الواقف', value: item.endowerName!),
                        if ((item.statusLabel ?? '').trim().isNotEmpty)
                          _InfoRow(label: 'الحالة', value: item.statusLabel!),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => context.go(
                                '/waqf/${item.pwfKey.isNotEmpty ? item.pwfKey : item.id}'),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('فتح صفحة الوقف'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _PathPreview extends StatelessWidget {
  const _PathPreview({required this.state});

  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    final historical = state.selectedFeature?.displayLabel;
    final modern = state.selectedModernContext?.communityLabel ??
        state.resolvedContext.modernContexts.firstOrNull?.communityLabel;
    final waqf = state.selectedWaqfAsset?.name ??
        state.selectedWaqfAsset?.pwfKey ??
        state.resolvedContext.waqfAssets.firstOrNull?.name ??
        state.resolvedContext.waqfAssets.firstOrNull?.pwfKey;
    final parts = <String>[
      if (state.selectedPeriod?.titleAr.trim().isNotEmpty == true)
        state.selectedPeriod!.titleAr,
      if (historical?.trim().isNotEmpty == true) historical!,
      if (modern?.trim().isNotEmpty == true) modern!,
      if (waqf?.trim().isNotEmpty == true) waqf!,
    ];

    if (parts.isEmpty) {
      return const Text('لا يوجد مسار نشط بعد.');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: parts
          .map((part) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: PwfColors.background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: PwfColors.outline),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    part,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: PwfColors.onSurface),
                  ),
                ),
              ))
          .toList(growable: false),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PwfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PwfColors.onSurface.withValues(alpha: 0.64),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              flex: 3,
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

extension _FirstOrNullExt<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _ReadingGuideBlock extends StatelessWidget {
  const _ReadingGuideBlock();

  @override
  Widget build(BuildContext context) {
    return const _Block(
      title: 'كيف تقرأ النتيجة؟',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuideLine('ابدأ من نوع العنصر المحدد: تاريخي أو حديث أو وقفي.'),
          SizedBox(height: 8),
          _GuideLine(
              'انتبه إلى شارة RPC سيادي أو Fallback مرن لفهم درجة ثبات الربط الحالي.'),
          SizedBox(height: 8),
          _GuideLine(
              'اقرأ الامتدادات الحديثة بوصفها مرجعًا تفسيريا، لا ككيانات أصيلة للفترة التاريخية نفسها.'),
        ],
      ),
    );
  }
}

class _GuideLine extends StatelessWidget {
  const _GuideLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.subdirectory_arrow_left,
              size: 18, color: PwfColors.primaryBlue),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.7),
          ),
        ),
      ],
    );
  }
}
