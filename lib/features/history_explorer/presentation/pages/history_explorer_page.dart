import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../application/providers/history_explorer_providers.dart';
import '../../domain/enums/history_explorer_mode.dart';
import '../panels/explorer_sidebar.dart';
import '../panels/lineage_sidebar.dart';
import '../widgets/history_explorer_header.dart';
import '../widgets/history_explorer_overview_strip.dart';
import '../widgets/history_explorer_story_cards.dart';
import '../widgets/history_explorer_tool_sync_panel.dart';
import '../widgets/history_explorer_data_gaps_panel.dart';
import '../widgets/history_explorer_investigation_workbench.dart';
import '../widgets/explorer_suite_contract_panel.dart';
import '../widgets/history_explorer_quick_guide_sheet.dart';
import '../widgets/history_map_canvas.dart';
import '../widgets/history_timeline_strip.dart';

class HistoryExplorerPage extends ConsumerStatefulWidget {
  const HistoryExplorerPage({super.key});

  @override
  ConsumerState<HistoryExplorerPage> createState() => _HistoryExplorerPageState();
}

class _HistoryExplorerPageState extends ConsumerState<HistoryExplorerPage> {
  String? _lastBootstrapSignature;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleBootstrapFromRoute();
  }

  void _scheduleBootstrapFromRoute() {
    final goState = GoRouterState.of(context);
    final params = goState.uri.queryParameters;
    final signature = [
      params['mode'] ?? '',
      params['q'] ?? params['query'] ?? '',
      params['period'] ?? params['periodNo'] ?? '',
      params['level'] ?? params['levelKey'] ?? '',
      params['waqfId'] ?? params['assetId'] ?? params['id'] ?? '',
      params['waqfKey'] ?? params['code'] ?? params['pwf'] ?? '',
      params['communityCode'] ?? '',
    ].join('|');
    if (signature == _lastBootstrapSignature) return;
    _lastBootstrapSignature = signature;
    if (signature.replaceAll('|', '').trim().isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyBootstrap(params);
    });
  }

  Future<void> _applyBootstrap(Map<String, String> params) async {
    final controller = ref.read(historyExplorerControllerProvider.notifier);
    final mode = _parseMode(params['mode']);
    final query = (params['q'] ?? params['query'] ?? '').trim();
    final periodNo = int.tryParse((params['period'] ?? params['periodNo'] ?? '').trim());
    final levelKey = (params['level'] ?? params['levelKey'] ?? '').trim();
    final waqfId = (params['waqfId'] ?? params['assetId'] ?? params['id'] ?? '').trim();
    final waqfKey = (params['waqfKey'] ?? params['code'] ?? params['pwf'] ?? '').trim();
    final modernCode = (params['communityCode'] ?? '').trim();

    if (periodNo != null) {
      await controller.selectPeriod(periodNo);
    }
    if (levelKey.isNotEmpty) {
      await controller.selectLevel(levelKey);
    }
    if (mode != null) {
      await controller.selectMode(mode);
    }
    if (query.isNotEmpty) {
      await controller.setSearchQuery(query);
    }

    if (mode == HistoryExplorerMode.waqf) {
      final state = ref.read(historyExplorerControllerProvider);
      final target = _matchWaqfTarget(state, waqfId: waqfId, waqfKey: waqfKey, query: query);
      if (target != null) {
        await controller.selectWaqfAsset(target);
      }
      return;
    }

    if (mode == HistoryExplorerMode.modern && modernCode.isNotEmpty) {
      await controller.selectModernContext(modernCode);
    }
  }

  HistoryExplorerMode? _parseMode(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'waqf':
        return HistoryExplorerMode.waqf;
      case 'modern':
        return HistoryExplorerMode.modern;
      case 'historical':
        return HistoryExplorerMode.historical;
      default:
        return null;
    }
  }

  String? _matchWaqfTarget(dynamic state, {required String waqfId, required String waqfKey, required String query}) {
    final candidates = <String>{
      waqfId.trim(),
      waqfKey.trim(),
      query.trim(),
    }..removeWhere((e) => e.isEmpty);
    if (candidates.isEmpty) return null;
    final lowered = candidates.map((e) => e.toLowerCase()).toSet();
    for (final item in state.waqfSearchResults) {
      final values = <String>{
        item.id.trim(),
        item.pwfKey.trim(),
        item.displayLabel.trim(),
        (item.community ?? '').trim(),
        (item.municipality ?? '').trim(),
        (item.governorate ?? '').trim(),
      }..removeWhere((e) => e.isEmpty);
      final mapped = values.map((e) => e.toLowerCase()).toSet();
      if (mapped.any((value) => lowered.contains(value))) {
        return item.id.trim().isNotEmpty ? item.id : item.pwfKey;
      }
      if (mapped.any((value) => lowered.any((q) => value.contains(q)))) {
        return item.id.trim().isNotEmpty ? item.id : item.pwfKey;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyExplorerControllerProvider);
    final controller = ref.read(historyExplorerControllerProvider.notifier);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          title: const Text('بوابة التاريخ الوقفي'),
          backgroundColor: Colors.transparent,
          foregroundColor: PwfColors.primaryBlue,
          titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: PwfColors.primaryBlue,
                fontWeight: FontWeight.w900,
              ),
          iconTheme: const IconThemeData(color: PwfColors.primaryBlue),
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            TextButton.icon(
              onPressed: () => showHistoryExplorerQuickGuide(context),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('دليل الاستخدام'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final state = ref.watch(historyExplorerControllerProvider);
              final controller = ref.read(historyExplorerControllerProvider.notifier);
              final wide = constraints.maxWidth >= 1280;
              final medium = constraints.maxWidth >= 940;

              final map = HistoryMapCanvas(
                state: state,
                onFeatureSelected: controller.selectFeature,
                onModernContextSelected: controller.inspectModernContext,
                onWaqfAssetSelected: controller.inspectWaqfAsset,
              );
              final explorer = ExplorerSidebar(
                state: state,
                onPeriodSelected: (periodNo) => controller.selectPeriod(periodNo),
                onFeatureSelected: controller.selectFeature,
                onModernContextSelected: controller.selectModernContext,
                onWaqfAssetSelected: controller.selectWaqfAsset,
              );
              final lineage = LineageSidebar(state: state);
              final timeline = HistoryTimelineStrip(
                periods: state.periods,
                selectedPeriodNo: state.selectedPeriodNo,
                onPeriodSelected: controller.selectPeriod,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  HistoryExplorerHeader(
                    state: state,
                    onModeChanged: (mode) => controller.selectMode(mode),
                    onPeriodChanged: (value) {
                      if (value != null) controller.selectPeriod(value);
                    },
                    onLevelChanged: (value) => controller.selectLevel(value),
                    onSearchChanged: controller.setSearchQuery,
                    onToggleModernContext: controller.toggleModernContext,
                    onToggleWaqfAssets: controller.toggleWaqfAssets,
                    onToggleParcels: controller.toggleParcels,
                    onToggleLineage: controller.toggleLineage,
                    onToggleLabels: controller.toggleLabels,
                    onToggleBoundariesOnly: controller.toggleBoundariesOnly,
                  ),
                  const SizedBox(height: 12),
                  HistoryExplorerOverviewStrip(state: state),
                  const SizedBox(height: 10),
                  const ExplorerSuiteContractPanel(),
                  const SizedBox(height: 10),
                  HistoryExplorerToolSyncPanel(
                    state: state,
                    onModeChanged: (mode) {
                      controller.selectMode(mode);
                    },
                    onToggleModernContext: controller.toggleModernContext,
                    onToggleWaqfAssets: controller.toggleWaqfAssets,
                    onToggleParcels: controller.toggleParcels,
                    onToggleLineage: controller.toggleLineage,
                    onToggleLabels: controller.toggleLabels,
                    onToggleBoundariesOnly: controller.toggleBoundariesOnly,
                    onRefresh: () {
                      controller.refreshCurrentMode();
                    },
                  ),
                  const SizedBox(height: 10),
                  HistoryExplorerInvestigationWorkbench(
                    state: state,
                    onModeChanged: (mode) {
                      controller.selectMode(mode);
                    },
                    onPeriodSelected: controller.selectPeriod,
                    onRefresh: () {
                      controller.refreshCurrentMode();
                    },
                    onToggleModernContext: controller.toggleModernContext,
                    onToggleWaqfAssets: controller.toggleWaqfAssets,
                    onToggleLineage: controller.toggleLineage,
                  ),
                  const SizedBox(height: 10),
                  HistoryExplorerDataGapsPanel(state: state),
                  const SizedBox(height: 10),
                  _WaqfAssetsSearchNotice(state: state),
                  if (state.mode == HistoryExplorerMode.waqf ||
                      state.selectedWaqfAssetRecord != null ||
                      state.selectedWaqfAsset != null ||
                      state.selectedEndowmentFilter != null) ...[
                    const SizedBox(height: 12),
                    _SelectedWaqfAssetSummaryCard(
                      state: state,
                      onApplyEndowmentFilter: controller.applyEndowmentFilter,
                    ),
                  ],
                  if (state.selectedWaqfAssetRecord != null || state.selectedWaqfAsset != null || state.linkedParcels.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ParcelSupportCard(
                      state: state,
                      onToggleParcels: controller.toggleParcels,
                    ),
                  ],
                  if (state.errorMessage != null) ...[
                    _ErrorBanner(message: state.errorMessage!),
                    const SizedBox(height: 12),
                  ],
                  if (wide) ...[
                    SizedBox(
                      height: 760,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 340, child: explorer),
                          const SizedBox(width: 16),
                          Expanded(child: map),
                          const SizedBox(width: 16),
                          SizedBox(width: 340, child: lineage),
                        ],
                      ),
                    ),
                  ] else if (medium) ...[
                    SizedBox(
                      height: 1040,
                      child: Column(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(width: 300, child: explorer),
                                const SizedBox(width: 16),
                                Expanded(child: map),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(height: 320, child: lineage),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: 520, child: map),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: state.mode == HistoryExplorerMode.historical ? 560 : 420,
                      child: explorer,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(height: 480, child: lineage),
                  ],
                  const SizedBox(height: 14),
                  timeline,
                  const SizedBox(height: 14),
                  HistoryExplorerStoryCards(state: state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PwfColors.royalRed.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PwfColors.royalRed.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: PwfColors.royalRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: PwfColors.royalRed, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}


class _WaqfAssetsSearchNotice extends StatelessWidget {
  const _WaqfAssetsSearchNotice({required this.state});

  final dynamic state;

  @override
  Widget build(BuildContext context) {
    final show = state.mode == HistoryExplorerMode.waqf ||
        state.selectedNationalAssetCode != null ||
        state.selectedWaqfAssetRecord != null ||
        state.waqfSearchResults.isNotEmpty;
    if (!show) return const SizedBox.shrink();

    final query = state.searchQuery.trim();
    final hasFilter = (state.selectedEndowmentFilter ?? '').trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.10)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.badge_outlined, color: PwfColors.primaryBlue, size: 18),
          const Text(
            'بحث الأصول الوقفية يعتمد الاسم أو الرقم الوطني السيادي، مع بقاء الأصل ظاهرًا حتى عند غياب الهندسة.',
            style: TextStyle(color: PwfColors.primaryBlue, fontWeight: FontWeight.w700),
          ),
          if (query.isNotEmpty)
            _MiniInfoChip(
              icon: Icons.search,
              label: 'البحث الحالي: $query',
              color: PwfColors.primaryBlue,
            ),
          if (hasFilter)
            _MiniInfoChip(
              icon: Icons.account_tree_outlined,
              label: 'فلتر الوقف المرجعي: ${state.selectedEndowmentFilter}',
              color: PwfColors.warning,
            ),
        ],
      ),
    );
  }
}

class _SelectedWaqfAssetSummaryCard extends StatelessWidget {
  const _SelectedWaqfAssetSummaryCard({
    required this.state,
    required this.onApplyEndowmentFilter,
  });

  final dynamic state;
  final ValueChanged<String?> onApplyEndowmentFilter;

  @override
  Widget build(BuildContext context) {
    final record = state.selectedWaqfAssetRecord;
    final fallback = state.selectedWaqfAsset;
    final nationalCode = (state.selectedNationalAssetCode ?? record?.nationalAssetCode ?? fallback?.pwfKey ?? '').trim();
    final title = (record?.nameAr ?? fallback?.name ?? '').trim();
    final endowment = (record?.endowmentName ?? fallback?.categoryLabel ?? '').trim();
    final status = (record?.status ?? fallback?.statusLabel ?? '').trim();
    final assetType = (record?.assetType ?? fallback?.typeLabel ?? '').trim();
    final usage = (record?.usage ?? fallback?.purpose ?? '').trim();
    final governorate = (record?.currentGovernorate ?? fallback?.governorate ?? '').trim();
    final lgu = (record?.currentLgu ?? fallback?.municipality ?? '').trim();
    final community = (record?.communityName ?? fallback?.community ?? '').trim();
    final parcelsCount = record?.linkedParcelsCount ?? state.linkedParcels.length;
    final hasSelection = nationalCode.isNotEmpty || title.isNotEmpty || endowment.isNotEmpty || parcelsCount > 0;
    if (!hasSelection) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PwfColors.royalRed.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 16,
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
                  color: PwfColors.royalRed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.place_outlined, color: PwfColors.royalRed),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الأصل الوقفي التشغيلي',
                      style: TextStyle(color: PwfColors.primaryBlue, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                  ],
                ),
              ),
              if (nationalCode.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1220),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    nationalCode,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (endowment.isNotEmpty)
                _MiniInfoChip(icon: Icons.account_tree_outlined, label: 'الوقف المرجعي: $endowment', color: PwfColors.warning),
              if (assetType.isNotEmpty)
                _MiniInfoChip(icon: Icons.category_outlined, label: 'النوع: $assetType', color: PwfColors.primaryBlue),
              if (status.isNotEmpty)
                _MiniInfoChip(icon: Icons.flag_outlined, label: 'الحالة: $status', color: PwfColors.royalRed),
              if (usage.isNotEmpty)
                _MiniInfoChip(icon: Icons.design_services_outlined, label: 'الاستعمال: $usage', color: PwfColors.primaryBlue),
              if (governorate.isNotEmpty)
                _MiniInfoChip(icon: Icons.map_outlined, label: 'المحافظة: $governorate', color: PwfColors.primaryBlue),
              if (lgu.isNotEmpty)
                _MiniInfoChip(icon: Icons.location_city_outlined, label: 'الهيئة المحلية: $lgu', color: PwfColors.primaryBlue),
              if (community.isNotEmpty)
                _MiniInfoChip(icon: Icons.hub_outlined, label: 'التجمع: $community', color: PwfColors.primaryBlue),
              _MiniInfoChip(icon: Icons.layers_outlined, label: 'القطع المرتبطة: $parcelsCount', color: PwfColors.warning),
            ],
          ),
          if (endowment.isNotEmpty || (state.selectedEndowmentFilter ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (endowment.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.filter_alt_outlined, size: 18, color: PwfColors.primaryBlue),
                    label: const Text('تصفية النتائج حسب الوقف المرجعي الحالي'),
                    onPressed: () => onApplyEndowmentFilter(endowment),
                  ),
                if ((state.selectedEndowmentFilter ?? '').trim().isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.clear_outlined, size: 18, color: PwfColors.royalRed),
                    label: const Text('إزالة فلتر الوقف المرجعي'),
                    onPressed: () => onApplyEndowmentFilter(null),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ParcelSupportCard extends StatelessWidget {
  const _ParcelSupportCard({
    required this.state,
    required this.onToggleParcels,
  });

  final dynamic state;
  final VoidCallback onToggleParcels;

  @override
  Widget build(BuildContext context) {
    final rows = (state.linkedParcels as List?)?.whereType<Map<String, dynamic>>().toList(growable: false) ?? const <Map<String, dynamic>>[];
    final record = state.selectedWaqfAssetRecord;
    final fallback = state.selectedWaqfAsset;
    final title = (record?.nameAr ?? fallback?.name ?? '').trim();
    final total = rows.length;
    final spatial = rows.where(_hasSpatial).length;
    final show = total > 0 || title.isNotEmpty;
    if (!show) return const SizedBox.shrink();

    final preview = rows.take(4).toList(growable: false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PwfColors.warning.withValues(alpha: 0.16)),
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
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.crop_square_outlined, color: PwfColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'طبقة القطع المرتبطة',
                      style: TextStyle(color: PwfColors.primaryBlue, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    Text(
                      title.isNotEmpty ? 'تخدم الأصل: $title' : 'طبقة دعم مكانية تابعة للأصل الوقفي المحدد',
                      style: TextStyle(color: PwfColors.onSurface.withValues(alpha: 0.72), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              ActionChip(
                avatar: Icon(state.showParcels ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: PwfColors.warning),
                label: Text(state.showParcels ? 'إخفاء القطع' : 'إظهار القطع'),
                onPressed: onToggleParcels,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniInfoChip(icon: Icons.layers_outlined, label: 'إجمالي القطع: $total', color: PwfColors.warning),
              _MiniInfoChip(icon: Icons.map_outlined, label: 'القطع المكانية: $spatial', color: PwfColors.primaryBlue),
              _MiniInfoChip(icon: Icons.visibility_outlined, label: state.showParcels ? 'الطبقة ظاهرة على الخريطة' : 'الطبقة مخفية حاليًا', color: state.showParcels ? PwfColors.success : PwfColors.onSurface),
            ],
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: preview.map((row) {
                final label = _parcelLabel(row);
                final subtitle = _parcelSubtitle(row);
                final hasSpatial = _hasSpatial(row);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasSpatial ? PwfColors.success.withValues(alpha: 0.08) : PwfColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: hasSpatial ? PwfColors.success.withValues(alpha: 0.22) : PwfColors.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: PwfColors.onSurface)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle, style: TextStyle(color: PwfColors.onSurface.withValues(alpha: 0.66), fontSize: 11)),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  static bool _hasSpatial(Map<String, dynamic> row) {
    return row['geom'] != null ||
        row['geom_json'] != null ||
        row['geometry'] != null ||
        row['geometry_json'] != null ||
        row['centroid'] != null ||
        row['centroid_json'] != null ||
        row['center'] != null ||
        row['lat'] != null ||
        row['latitude'] != null ||
        row['center_lat'] != null;
  }

  static String _parcelLabel(Map<String, dynamic> row) {
    final candidates = [
      row['parcel_label'],
      row['parcel_code'],
      row['parcel'],
      row['parcel_no'],
      row['parcel_number'],
      row['national_parcel_code'],
      row['parcel_id'],
      row['id'],
    ];
    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return 'قطعة $text';
    }
    return 'قطعة مرتبطة';
  }

  static String _parcelSubtitle(Map<String, dynamic> row) {
    final parts = <String>[];
    for (final key in ['basin', 'basin_no', 'basin_number']) {
      final text = row[key]?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        parts.add('الحوض: $text');
        break;
      }
    }
    for (final key in ['relation_type', 'link_type', 'relation_status', 'status']) {
      final text = row[key]?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        parts.add(text);
        break;
      }
    }
    return parts.join(' • ');
  }
}

class _MiniInfoChip extends StatelessWidget {
  const _MiniInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
