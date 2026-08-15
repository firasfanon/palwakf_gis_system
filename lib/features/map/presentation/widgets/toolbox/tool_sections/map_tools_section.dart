import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/enums.dart';
import '../../../providers/map_provider.dart';
import '../../../providers/map_ui_providers.dart';
import '../../../providers/toolbox_providers.dart';
import '../../../../data/repositories/map_feedback_repository.dart';
import '../../../../data/repositories/map_layer_manager_repository.dart';
import '../../../../../tasks_system/data/repositories/audit_task_repository.dart';
import '../../../../domain/models/gis_feature_model.dart';
import '../../../../domain/models/gis_layer_model.dart';
import '../../../services/explorer_bookmark_storage.dart';
import '../../../services/explorer_export_download_service.dart';

import '../tools/compare_tool.dart';
import '../tools/coordinates_tool.dart';
import '../tools/directions_tool.dart';
import '../tools/draw_tool.dart';
import '../tools/measure_tool.dart';
import '../tools/share_location_dialog.dart';

class MapToolsSection extends ConsumerWidget {
  const MapToolsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void openDrawPanel() {
      ref.read(measureEditingProvider.notifier).state = false;
      ref.read(measureModeProvider.notifier).state = null;
      ref.read(measurePointsProvider.notifier).state = const [];
      ref.read(measureResultLabelProvider.notifier).state = null;
      ref.read(activeToolsSubPanelProvider.notifier).state = ToolsSubPanel.draw;
    }

    void openMeasurePanel() {
      ref.read(drawEditingProvider.notifier).state = false;
      ref.read(drawShapeTypeProvider.notifier).state = null;
      ref.read(drawPointsProvider.notifier).state = const [];
      ref.read(activeToolsSubPanelProvider.notifier).state =
          ToolsSubPanel.measure;
    }

    final audience = ref.watch(mapToolAudienceProvider);
    final canUseEmployeeTools = audience.canUseEmployeeTools;
    final canUseManagerTools = audience.canUseManagerTools;
    final sub = ref.watch(activeToolsSubPanelProvider);
    final subAllowed = sub == null ||
        (canUseManagerTools && sub == ToolsSubPanel.layerManager) ||
        (canUseEmployeeTools && sub == ToolsSubPanel.bookmarks) ||
        (canUseManagerTools && sub == ToolsSubPanel.layerPresetsGovernance) ||
        (canUseEmployeeTools && sub == ToolsSubPanel.printLayout) ||
        (canUseEmployeeTools && sub == ToolsSubPanel.measurementReport) ||
        sub == ToolsSubPanel.toolPermissions ||
        sub == ToolsSubPanel.reportIssue ||
        (canUseManagerTools && sub == ToolsSubPanel.reviewReports) ||
        sub == ToolsSubPanel.coordinates ||
        sub == ToolsSubPanel.share ||
        sub == ToolsSubPanel.directions ||
        (canUseEmployeeTools &&
            (sub == ToolsSubPanel.identify ||
                sub == ToolsSubPanel.exportSnapshot ||
                sub == ToolsSubPanel.layerHealth ||
                sub == ToolsSubPanel.modernOverlay ||
                sub == ToolsSubPanel.dataGaps ||
                sub == ToolsSubPanel.operations ||
                sub == ToolsSubPanel.megaOps ||
                sub == ToolsSubPanel.realInteractions ||
                sub == ToolsSubPanel.draw ||
                sub == ToolsSubPanel.measure)) ||
        (canUseManagerTools && sub == ToolsSubPanel.compare);

    if (!subAllowed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeToolsSubPanelProvider.notifier).state = null;
      });
    }

    if (sub != null && subAllowed) {
      switch (sub) {
        case ToolsSubPanel.layerManager:
          return LayerManagerToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.bookmarks:
          return ExplorerBookmarksToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.layerPresetsGovernance:
          return LayerPresetsGovernanceToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.printLayout:
          return PrintExportLayoutToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.measurementReport:
          return MeasurementReportToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.toolPermissions:
          return ToolPermissionsPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.identify:
          return IdentifyToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.exportSnapshot:
          return ExportSnapshotToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.layerHealth:
          return LayerHealthToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.modernOverlay:
          return ModernExplorerOverlayToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.reportIssue:
          return ReportIssueToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.reviewReports:
          return MapFeedbackReviewPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.dataGaps:
          return DataGapsToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.operations:
          return ExplorerOperationsToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.megaOps:
          return ExplorerMegaOpsToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.realInteractions:
          return ExplorerRealMapInteractionsToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.draw:
          return DrawToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.measure:
          return MeasureToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.directions:
          return DirectionsToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.coordinates:
          return CoordinatesToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.share:
          return ShareLocationPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
        case ToolsSubPanel.compare:
          return CompareToolPanel(
              onClose: () =>
                  ref.read(activeToolsSubPanelProvider.notifier).state = null);
      }
    }

    final snapEnabled = ref.watch(snapEnabledProvider);
    final showCoords = ref.watch(showCoordinatesProvider);
    final measureMode = ref.watch(measureModeProvider);
    final measureEditing = ref.watch(measureEditingProvider);
    final measurePoints = ref.watch(measurePointsProvider);
    final drawShape = ref.watch(drawShapeTypeProvider);
    final drawEditing = ref.watch(drawEditingProvider);
    final drawPoints = ref.watch(drawPointsProvider);
    final compareEnabled = ref.watch(compareEnabledProvider);
    final compareLeft = ref.watch(compareLeftSourceProvider);
    final compareRight = ref.watch(compareRightSourceProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _Header(
          title: 'أدوات الخريطة',
          onClose: () =>
              ref.read(activeToolSectionProvider.notifier).state = null,
        ),
        const SizedBox(height: 12),
        _AudienceNotice(audience: audience),
        const SizedBox(height: 10),
        if (canUseEmployeeTools)
          _ActionTile(
            title: 'العروض المحفوظة / Bookmarks',
            icon: Icons.bookmarks_outlined,
            trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
            onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.bookmarks,
          ),
        if (canUseEmployeeTools)
          _ActionTile(
            title: 'قالب طباعة / تصدير',
            icon: Icons.print_outlined,
            trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
            onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.printLayout,
          ),
        if (canUseEmployeeTools)
          _ActionTile(
            title: 'تقرير القياس',
            icon: Icons.assessment_outlined,
            trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
            onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.measurementReport,
          ),
        _ActionTile(
          title: 'صلاحيات الأدوات',
          icon: Icons.admin_panel_settings_outlined,
          trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
          onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
              ToolsSubPanel.toolPermissions,
        ),
        if (canUseManagerTools)
          _ActionTile(
            title: 'حوكمة حزم الطبقات',
            icon: Icons.rule_outlined,
            trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
            onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.layerPresetsGovernance,
          ),
        if (canUseManagerTools)
          _ActionTile(
            title: 'إدارة الطبقات',
            icon: Icons.layers_outlined,
            trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
            onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.layerManager,
          ),
        if (canUseEmployeeTools)
          _ActionTile(
            title: 'تعريف العنصر (Identify)',
            icon: Icons.ads_click_outlined,
            trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
            onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.identify,
          ),
        if (canUseEmployeeTools)
          _ActionTile(
            title: 'تصدير لقطة تشغيل',
            icon: Icons.file_download_outlined,
            trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
            onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.exportSnapshot,
          ),
        if (canUseEmployeeTools)
          _ActionTile(
            title: 'صحة الطبقات',
            icon: Icons.health_and_safety_outlined,
            trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
            onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.layerHealth,
          ),
        if (canUseEmployeeTools)
          _ActionTile(
            title: 'Modern Explorer Overlay',
            icon: Icons.travel_explore_outlined,
            trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
            onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.modernOverlay,
          ),
        _ActionTile(
          title: 'بلاغ خطأ / ملاحظة تدقيق',
          icon: Icons.report_problem_outlined,
          trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
          onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
              ToolsSubPanel.reportIssue,
        ),
        if (canUseManagerTools)
          _ActionTile(
            title: 'مراجعة البلاغات',
            icon: Icons.fact_check_outlined,
            trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
            onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.reviewReports,
          ),
        if (canUseEmployeeTools)
          _ActionTile(
            title: 'فجوات البيانات الظاهرة',
            icon: Icons.rule_folder_outlined,
            trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
            onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.dataGaps,
          ),
        if (canUseEmployeeTools)
          _ActionTile(
            title: 'مركز تشغيل المستكشف',
            icon: Icons.space_dashboard_outlined,
            trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
            onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.operations,
          ),
        if (canUseEmployeeTools)
          _ActionTile(
            title: 'حزمة تشغيل المستكشف الكبرى',
            icon: Icons.dashboard_customize_outlined,
            trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
            onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.megaOps,
          ),
        if (canUseEmployeeTools)
          _ActionTile(
            title: 'أدوات التفاعل الحقيقي',
            icon: Icons.touch_app_outlined,
            trailing: const Icon(Icons.chevron_left, color: PwfColors.onSurface),
            onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.realInteractions,
          ),
        const SizedBox(height: 10),
        if (canUseEmployeeTools) ...[
          _PrimaryToggleTile(
            title: 'تفعيل التجاذب (Snapping)',
            value: snapEnabled,
            onTap: () =>
                ref.read(snapEnabledProvider.notifier).state = !snapEnabled,
          ),
          const SizedBox(height: 10),
        ],
        _ActionTile(
          title: 'الذهاب إلى الإحداثيات',
          icon: Icons.my_location,
          onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
              ToolsSubPanel.coordinates,
        ),
        _ActionTile(
          title: 'الاتجاهات والملاحة',
          icon: Icons.alt_route,
          onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
              ToolsSubPanel.directions,
        ),
        _ActionTile(
          title: 'عرض الإحداثيات',
          icon: Icons.gps_fixed,
          trailing: Switch(
            value: showCoords,
            onChanged: (v) =>
                ref.read(showCoordinatesProvider.notifier).state = v,
            activeColor: PwfColors.royalRed,
          ),
          onTap: () =>
              ref.read(showCoordinatesProvider.notifier).state = !showCoords,
        ),
        _ActionTile(
          title: 'مشاركة الموقع',
          icon: Icons.share,
          onTap: () {
            ref.read(directionsPickTargetProvider.notifier).state = null;
            ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.share;
          },
        ),
        if (canUseManagerTools)
          _ActionTile(
            title: 'المقارنة',
            icon: Icons.compare,
            trailing: compareEnabled
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: PwfColors.royalRed.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: PwfColors.royalRed.withValues(alpha: 0.22)),
                  ),
                  child: Text(
                    'نشطة • ${compareLeft == null ? 'يسار: —' : 'يسار'} • ${compareRight == null ? 'يمين: —' : 'يمين'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: PwfColors.royalRed,
                    ),
                  ),
                )
              : null,
            onTap: () => ref.read(activeToolsSubPanelProvider.notifier).state =
                ToolsSubPanel.compare,
          ),
        if (canUseEmployeeTools) ...[
          const SizedBox(height: 10),
          const Divider(height: 26),
          _ActionTile(
            title: 'أدوات الرسم',
          icon: Icons.edit,
          trailing: drawShape == null
              ? const Icon(Icons.chevron_left, color: PwfColors.onSurface)
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (drawEditing
                            ? PwfColors.primaryBlue
                            : PwfColors.royalRed)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: (drawEditing
                              ? PwfColors.primaryBlue
                              : PwfColors.royalRed)
                          .withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    '${_drawLabel(drawShape)} • ${drawPoints.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: drawEditing
                          ? PwfColors.primaryBlue
                          : PwfColors.royalRed,
                    ),
                  ),
                ),
          onTap: openDrawPanel,
        ),
        _ActionTile(
          title: 'القياس',
          icon: Icons.straighten,
          trailing: measureMode == null
              ? const Icon(Icons.chevron_left, color: PwfColors.onSurface)
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (measureEditing
                            ? PwfColors.royalRed
                            : PwfColors.primaryBlue)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: (measureEditing
                              ? PwfColors.royalRed
                              : PwfColors.primaryBlue)
                          .withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    '${measureMode == MeasureMode.distance ? 'مسافة' : 'مساحة'} • ${measurePoints.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: measureEditing
                          ? PwfColors.royalRed
                          : PwfColors.primaryBlue,
                    ),
                  ),
                ),
            onTap: openMeasurePanel,
          ),
        ],
      ],
    );
  }
}



class ExplorerOperationsToolPanel extends ConsumerWidget {
  const ExplorerOperationsToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapNotifierProvider);
    final runtime = state.runtimeInfo;
    final audience = ref.watch(mapToolAudienceProvider);
    final hasViewport = state.viewport != null;
    final hasLayers = state.gisLayers.isNotEmpty;
    final activeLayerCount = state.activeLayers.length;
    final blockedMessage = runtime.hasBlockedLayers
        ? runtime.blockedReasons.first
        : 'لا توجد طبقات محجوبة حاليًا';

    return _ToolPanelScaffold(
      title: 'مركز تشغيل المستكشف',
      icon: Icons.space_dashboard_outlined,
      onClose: onClose,
      children: [
        _HintBox(
          icon: Icons.map_outlined,
          text:
              'هذه لوحة تشغيل خاصة بالمستكشف نفسه: تختصر حالة الخريطة، وتفعّل حزم طبقات آمنة، وتراجع جاهزية BBOX/Zoom قبل تشغيل الطبقات الثقيلة.',
        ),
        const SizedBox(height: 12),
        _ExplorerOpsSummary(
          hasViewport: hasViewport,
          activeLayerCount: activeLayerCount,
          loadedFeatureCount: runtime.featureCount,
          queryLayerCount: runtime.queryLayerKeys.length,
          blockedLayerCount: runtime.blockedLayerKeys.length,
          zoom: state.zoom,
          audienceLabel: audience.labelAr,
        ),
        const SizedBox(height: 12),
        _LayerPresetCard(
          title: 'حزمة فتح خفيفة',
          subtitle: 'حدود فلسطين + المحافظات + الهيئات المحلية إن وجدت.',
          icon: Icons.rocket_launch_outlined,
          enabled: hasLayers,
          onTap: () => _applyPreset(ref, _ExplorerLayerPreset.light),
        ),
        _LayerPresetCard(
          title: 'حزمة تدقيق وقفي ميداني',
          subtitle: 'الحدود الأساسية مع طبقات gis_waqf النقطية المناسبة للتدقيق.',
          icon: Icons.account_balance_outlined,
          enabled: hasLayers,
          onTap: () => _applyPreset(ref, _ExplorerLayerPreset.waqfFieldAudit),
        ),
        _LayerPresetCard(
          title: 'حزمة الأحواض الطبيعية',
          subtitle: 'تفعّل natural_blocks_full مع الحماية الآلية عبر overview/zoom.',
          icon: Icons.layers_outlined,
          enabled: hasLayers,
          onTap: () => _applyPreset(ref, _ExplorerLayerPreset.naturalBlocks),
        ),
        _LayerPresetCard(
          title: 'إخلاء الخريطة',
          subtitle: 'إيقاف كل الطبقات النشطة لإعادة بدء نظيفة.',
          icon: Icons.layers_clear_outlined,
          enabled: activeLayerCount > 0,
          isDestructive: true,
          onTap: () => ref.read(mapNotifierProvider.notifier).deactivateAllLayers(),
        ),
        const SizedBox(height: 12),
        _OperationalReadinessCard(
          hasViewport: hasViewport,
          hasCatalog: hasLayers,
          hasQueryLayers: runtime.hasQueryLayers,
          runtimeMessage: blockedMessage,
          usingOverview: runtime.usingNaturalBlocksOverview,
          servedFromCache: runtime.servedFromCache,
          simplifyMeters: runtime.simplifyMeters,
          featureLimit: runtime.featureLimit,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(activeToolSectionProvider.notifier).state =
                      ToolSection.layers;
                },
                icon: const Icon(Icons.layers_outlined),
                label: const Text('فتح الطبقات'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(activeToolsSubPanelProvider.notifier).state =
                      ToolsSubPanel.dataGaps;
                },
                icon: const Icon(Icons.rule_folder_outlined),
                label: const Text('فحص الفجوات'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _applyPreset(
    WidgetRef ref,
    _ExplorerLayerPreset preset,
  ) async {
    final state = ref.read(mapNotifierProvider);
    final keys = _keysForPreset(state.gisLayers, preset);
    await ref.read(mapNotifierProvider.notifier).setActiveLayers(keys);
  }

  List<String> _keysForPreset(
    List<GisLayerModel> layers,
    _ExplorerLayerPreset preset,
  ) {
    final keys = <String>[];

    bool allowed(GisLayerModel layer) => layer.isActive && layer.isPublic;

    bool match(
      GisLayerModel layer, {
      List<String> keyTokens = const [],
      List<String> arTokens = const [],
      List<String> enTokens = const [],
    }) {
      final key = layer.key.trim().toLowerCase();
      final nameAr = layer.nameAr.trim().toLowerCase();
      final nameEn = (layer.nameEn ?? '').trim().toLowerCase();
      return keyTokens.any(key.contains) ||
          arTokens.any(nameAr.contains) ||
          enTokens.any(nameEn.contains);
    }

    void addMatches({
      List<String> keyTokens = const [],
      List<String> arTokens = const [],
      List<String> enTokens = const [],
      int max = 99,
    }) {
      for (final layer in layers) {
        if (!allowed(layer)) continue;
        if (!match(
          layer,
          keyTokens: keyTokens,
          arTokens: arTokens,
          enTokens: enTokens,
        )) {
          continue;
        }
        if (!keys.contains(layer.key)) keys.add(layer.key);
        if (keys.length >= max) break;
      }
    }

    void addBase() {
      addMatches(
        keyTokens: const ['westbank_gaza', 'west_bank_gaza', 'palestine'],
        arTokens: const ['فلسطين', 'الضفة وغزة', 'الضفة الغربية وغزة'],
        enTokens: const ['palestine', 'west bank and gaza', 'westbank gaza'],
        max: 1,
      );
      addMatches(
        keyTokens: const ['governorates_boundary', 'v_governorates_core', 'governorate'],
        arTokens: const ['المحافظات'],
        enTokens: const ['governorates', 'governorate boundaries'],
        max: keys.length + 1,
      );
      addMatches(
        keyTokens: const ['lgus_boundary', 'v_lgus_core', 'v_lgus_light', 'lgu'],
        arTokens: const ['الهيئات المحلية', 'حدود الهيئات'],
        enTokens: const ['local government', 'lgus', 'lgu boundaries'],
        max: keys.length + 1,
      );
    }

    addBase();

    switch (preset) {
      case _ExplorerLayerPreset.light:
        break;
      case _ExplorerLayerPreset.waqfFieldAudit:
        addMatches(
          keyTokens: const ['gis_waqf_', 'mosque', 'maqamat', 'cemeteries', 'takaya', 'archaeological'],
          arTokens: const ['المساجد', 'المقامات', 'المقابر', 'التكايا', 'الأثرية'],
          enTokens: const ['mosque', 'maqamat', 'cemeteries', 'takaya', 'archaeological'],
          max: keys.length + 12,
        );
        break;
      case _ExplorerLayerPreset.naturalBlocks:
        addMatches(
          keyTokens: const ['natural_blocks_full'],
          arTokens: const ['الأحواض الطبيعية'],
          enTokens: const ['natural blocks full'],
          max: keys.length + 1,
        );
        break;
    }

    return keys;
  }
}

enum _ExplorerLayerPreset { light, waqfFieldAudit, naturalBlocks }

class _ExplorerOpsSummary extends StatelessWidget {
  const _ExplorerOpsSummary({
    required this.hasViewport,
    required this.activeLayerCount,
    required this.loadedFeatureCount,
    required this.queryLayerCount,
    required this.blockedLayerCount,
    required this.zoom,
    required this.audienceLabel,
  });

  final bool hasViewport;
  final int activeLayerCount;
  final int loadedFeatureCount;
  final int queryLayerCount;
  final int blockedLayerCount;
  final double zoom;
  final String audienceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PwfColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.14)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ExplorerOpsPill(
            icon: hasViewport ? Icons.crop_free : Icons.crop_square_outlined,
            label: hasViewport ? 'BBOX جاهز' : 'BBOX غير جاهز',
            color: hasViewport ? PwfColors.success : PwfColors.warning,
          ),
          _ExplorerOpsPill(
            icon: Icons.zoom_in_map_outlined,
            label: 'Zoom ${zoom.toStringAsFixed(1)}',
            color: PwfColors.primaryBlue,
          ),
          _ExplorerOpsPill(
            icon: Icons.visibility_outlined,
            label: '$activeLayerCount طبقة مفعلة',
            color: PwfColors.royalRed,
          ),
          _ExplorerOpsPill(
            icon: Icons.layers_outlined,
            label: '$queryLayerCount طبقة محمّلة',
            color: PwfColors.primaryGold,
          ),
          _ExplorerOpsPill(
            icon: Icons.map_outlined,
            label: '$loadedFeatureCount عنصر',
            color: PwfColors.success,
          ),
          _ExplorerOpsPill(
            icon: Icons.block_outlined,
            label: '$blockedLayerCount محجوبة',
            color: blockedLayerCount > 0 ? PwfColors.warning : PwfColors.primaryBlue,
          ),
          _ExplorerOpsPill(
            icon: Icons.admin_panel_settings_outlined,
            label: audienceLabel,
            color: PwfColors.onSurface,
          ),
        ],
      ),
    );
  }
}

class _ExplorerOpsPill extends StatelessWidget {
  const _ExplorerOpsPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerPresetCard extends StatelessWidget {
  const _LayerPresetCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.isDestructive = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? PwfColors.royalRed : PwfColors.primaryBlue;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PwfColors.outline),
      ),
      child: ListTile(
        enabled: enabled,
        onTap: enabled ? onTap : null,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: enabled ? 0.10 : 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: enabled ? color : PwfColors.onSurface.withValues(alpha: 0.32),
            size: 19,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: enabled ? PwfColors.onSurface : PwfColors.onSurface.withValues(alpha: 0.45),
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: PwfColors.onSurface.withValues(alpha: enabled ? 0.68 : 0.38),
            fontWeight: FontWeight.w700,
            fontSize: 10.8,
            height: 1.35,
          ),
        ),
        trailing: Icon(
          Icons.chevron_left_rounded,
          color: enabled ? color : PwfColors.onSurface.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

class _OperationalReadinessCard extends StatelessWidget {
  const _OperationalReadinessCard({
    required this.hasViewport,
    required this.hasCatalog,
    required this.hasQueryLayers,
    required this.runtimeMessage,
    required this.usingOverview,
    required this.servedFromCache,
    required this.simplifyMeters,
    required this.featureLimit,
  });

  final bool hasViewport;
  final bool hasCatalog;
  final bool hasQueryLayers;
  final String runtimeMessage;
  final bool usingOverview;
  final bool servedFromCache;
  final double simplifyMeters;
  final int featureLimit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'جاهزية التشغيل',
            style: TextStyle(
              color: PwfColors.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'كتالوج الطبقات', value: hasCatalog ? 'جاهز' : 'غير محمّل'),
          _InfoRow(label: 'حدود الشاشة BBOX', value: hasViewport ? 'جاهزة' : 'بانتظار حركة الخريطة'),
          _InfoRow(label: 'استعلام طبقات فعلي', value: hasQueryLayers ? 'نشط' : 'غير نشط'),
          _InfoRow(label: 'Natural Blocks Overview', value: usingOverview ? 'مستخدم' : 'غير مستخدم'),
          _InfoRow(label: 'Cache', value: servedFromCache ? 'من الذاكرة المؤقتة' : 'استعلام جديد أو غير متاح'),
          _InfoRow(label: 'التبسيط الهندسي', value: simplifyMeters <= 0 ? 'بدون تبسيط' : '${simplifyMeters.toStringAsFixed(0)} متر'),
          _InfoRow(label: 'حد العناصر', value: featureLimit <= 0 ? 'غير محدد بعد' : '$featureLimit'),
          const SizedBox(height: 10),
          _HintBox(
            icon: Icons.info_outline,
            text: runtimeMessage,
          ),
        ],
      ),
    );
  }
}



class LayerManagerToolPanel extends ConsumerStatefulWidget {
  const LayerManagerToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<LayerManagerToolPanel> createState() =>
      _LayerManagerToolPanelState();
}

class _LayerManagerToolPanelState extends ConsumerState<LayerManagerToolPanel> {
  Future<List<MapLayerAdminConfig>>? _future;
  String _category = 'all';
  bool _includeInactive = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MapLayerAdminConfig>> _load() {
    return ref.read(mapLayerManagerRepositoryProvider).listLayerConfigs(
          category: _category == 'all' ? null : _category,
          includeInactive: _includeInactive,
        );
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  List<MapLayerAdminConfig> _filter(List<MapLayerAdminConfig> layers) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return layers;
    return layers.where((layer) {
      return layer.layerKey.toLowerCase().contains(q) ||
          layer.displayName.toLowerCase().contains(q) ||
          (layer.nameEn ?? '').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return _ToolPanelScaffold(
      title: 'إدارة الطبقات',
      icon: Icons.layers_outlined,
      onClose: widget.onClose,
      children: [
        const _HintBox(
          icon: Icons.admin_panel_settings_outlined,
          text:
              'هذه لوحة تأسيسية لإدارة سلوك الطبقات. التعديلات تتم عبر RPC محكوم، ولا تغيّر مصادر GIS السيادية نفسها.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _LayerManagerFilterChip(
              label: 'الكل',
              selected: _category == 'all',
              onTap: () => setState(() {
                _category = 'all';
                _future = _load();
              }),
            ),
            _LayerManagerFilterChip(
              label: 'أساسية',
              selected: _category == 'core',
              onTap: () => setState(() {
                _category = 'core';
                _future = _load();
              }),
            ),
            _LayerManagerFilterChip(
              label: 'GIS',
              selected: _category == 'gis',
              onTap: () => setState(() {
                _category = 'gis';
                _future = _load();
              }),
            ),
            _LayerManagerFilterChip(
              label: 'وقفية',
              selected: _category == 'waqf',
              onTap: () => setState(() {
                _category = 'waqf';
                _future = _load();
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: const InputDecoration(
            labelText: 'بحث في الطبقات',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          value: _includeInactive,
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'إظهار الطبقات غير المفعلة',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          activeColor: PwfColors.royalRed,
          onChanged: (value) => setState(() {
            _includeInactive = value;
            _future = _load();
          }),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<MapLayerAdminConfig>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return _EmptyToolBox(
                text: 'تعذر تحميل إعدادات الطبقات: ${snapshot.error}',
              );
            }
            final layers = _filter(snapshot.data ?? const []);
            if (layers.isEmpty) {
              return const _EmptyToolBox(
                text: 'لا توجد طبقات مطابقة للفلاتر الحالية.',
              );
            }
            final activeCount = layers.where((e) => e.isActive).length;
            final publicCount = layers.where((e) => e.visiblePublic).length;
            final heavyCount = layers.where((e) => e.layerWeight == 'heavy').length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LayerManagerSummaryStrip(
                  total: layers.length,
                  active: activeCount,
                  publicVisible: publicCount,
                  heavy: heavyCount,
                ),
                const SizedBox(height: 10),
                ...layers.map(
                  (layer) => _LayerManagerConfigCard(
                    key: ValueKey(layer.layerKey),
                    config: layer,
                    onChanged: _refresh,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LayerManagerConfigCard extends ConsumerStatefulWidget {
  const _LayerManagerConfigCard({
    super.key,
    required this.config,
    required this.onChanged,
  });

  final MapLayerAdminConfig config;
  final VoidCallback onChanged;

  @override
  ConsumerState<_LayerManagerConfigCard> createState() =>
      _LayerManagerConfigCardState();
}

class _LayerManagerConfigCardState
    extends ConsumerState<_LayerManagerConfigCard> {
  bool _updating = false;
  late final TextEditingController _notesController;
  late final TextEditingController _legendController;
  late final TextEditingController _uniqueFieldController;
  late final TextEditingController _labelFieldController;
  late final TextEditingController _popupTitleFieldController;
  late final TextEditingController _popupFieldsController;
  late final TextEditingController _identifyTitleFieldController;
  late final TextEditingController _identifyFieldsController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.config.adminNotes ?? '');
    _legendController = TextEditingController(text: widget.config.legendLabelAr ?? '');
    _uniqueFieldController = TextEditingController(text: widget.config.uniqueValueField ?? '');
    _labelFieldController = TextEditingController(text: widget.config.labelField ?? '');
    _popupTitleFieldController =
        TextEditingController(text: widget.config.popupTitleField ?? '');
    _popupFieldsController =
        TextEditingController(text: widget.config.popupFields.join(', '));
    _identifyTitleFieldController =
        TextEditingController(text: widget.config.identifyTitleField ?? '');
    _identifyFieldsController =
        TextEditingController(text: widget.config.identifyFields.join(', '));
  }

  @override
  void didUpdateWidget(covariant _LayerManagerConfigCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.adminNotes != widget.config.adminNotes) {
      _notesController.text = widget.config.adminNotes ?? '';
    }
    if (oldWidget.config.legendLabelAr != widget.config.legendLabelAr) {
      _legendController.text = widget.config.legendLabelAr ?? '';
    }
    if (oldWidget.config.uniqueValueField != widget.config.uniqueValueField) {
      _uniqueFieldController.text = widget.config.uniqueValueField ?? '';
    }
    if (oldWidget.config.labelField != widget.config.labelField) {
      _labelFieldController.text = widget.config.labelField ?? '';
    }
    if (oldWidget.config.popupTitleField != widget.config.popupTitleField) {
      _popupTitleFieldController.text = widget.config.popupTitleField ?? '';
    }
    if (oldWidget.config.popupFields.join('|') != widget.config.popupFields.join('|')) {
      _popupFieldsController.text = widget.config.popupFields.join(', ');
    }
    if (oldWidget.config.identifyTitleField != widget.config.identifyTitleField) {
      _identifyTitleFieldController.text = widget.config.identifyTitleField ?? '';
    }
    if (oldWidget.config.identifyFields.join('|') != widget.config.identifyFields.join('|')) {
      _identifyFieldsController.text = widget.config.identifyFields.join(', ');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _legendController.dispose();
    _uniqueFieldController.dispose();
    _labelFieldController.dispose();
    _popupTitleFieldController.dispose();
    _popupFieldsController.dispose();
    _identifyTitleFieldController.dispose();
    _identifyFieldsController.dispose();
    super.dispose();
  }

  Future<void> _update(MapLayerManagerUpdate update) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      await ref.read(mapLayerManagerRepositoryProvider).updateLayerConfig(update);
      await ref.read(mapNotifierProvider.notifier).bootstrapGis();
      if (!mounted) return;
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث إعدادات ${widget.config.displayName}.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث الطبقة: $e')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  MapLayerManagerUpdate _baseUpdate({
    bool? isActive,
    bool? isPublic,
    int? displayOrder,
    bool? visiblePublic,
    bool? visibleEmployee,
    bool? visibleManager,
    double? minZoom,
    double? maxZoom,
    bool? bboxRequired,
    String? layerWeight,
    int? maxFeaturesPerRequest,
    bool? cacheEnabled,
    bool? clusteringEnabled,
    bool? identifyEnabled,
    bool? reportEnabled,
    String? exportPolicy,
    String? adminNotes,
    String? symbologyMode,
    String? strokeColor,
    String? fillColor,
    String? markerColor,
    double? strokeWidth,
    double? fillOpacity,
    double? markerSize,
    String? pointShape,
    String? lineStyle,
    String? stylePreset,
    String? legendLabelAr,
    bool? legendEnabled,
    String? uniqueValueField,
    List<Map<String, dynamic>>? uniqueValueRules,
    bool? labelsEnabled,
    String? labelField,
    double? labelMinZoom,
    int? labelMaxCount,
    String? labelTextColor,
    String? labelHaloColor,
    double? labelFontSize,
    bool? popupEnabled,
    String? popupTitleField,
    List<String>? popupFields,
    Map<String, String>? popupFieldLabels,
    bool? popupShowDetailsAction,
    bool? popupShowReportAction,
    bool? popupShowTaskAction,
    String? identifyTitleField,
    List<String>? identifyFields,
    Map<String, String>? identifyFieldLabels,
    int? identifyMaxFields,
  }) {
    return MapLayerManagerUpdate(
      layerKey: widget.config.layerKey,
      unitId: widget.config.unitId,
      isActive: isActive,
      isPublic: isPublic,
      displayOrder: displayOrder,
      visiblePublic: visiblePublic,
      visibleEmployee: visibleEmployee,
      visibleManager: visibleManager,
      minZoom: minZoom,
      maxZoom: maxZoom,
      bboxRequired: bboxRequired,
      layerWeight: layerWeight,
      maxFeaturesPerRequest: maxFeaturesPerRequest,
      cacheEnabled: cacheEnabled,
      clusteringEnabled: clusteringEnabled,
      identifyEnabled: identifyEnabled,
      reportEnabled: reportEnabled,
      exportPolicy: exportPolicy,
      adminNotes: adminNotes,
      symbologyMode: symbologyMode,
      strokeColor: strokeColor,
      fillColor: fillColor,
      markerColor: markerColor,
      strokeWidth: strokeWidth,
      fillOpacity: fillOpacity,
      markerSize: markerSize,
      pointShape: pointShape,
      lineStyle: lineStyle,
      stylePreset: stylePreset,
      legendLabelAr: legendLabelAr,
      legendEnabled: legendEnabled,
      uniqueValueField: uniqueValueField,
      uniqueValueRules: uniqueValueRules,
      labelsEnabled: labelsEnabled,
      labelField: labelField,
      labelMinZoom: labelMinZoom,
      labelMaxCount: labelMaxCount,
      labelTextColor: labelTextColor,
      labelHaloColor: labelHaloColor,
      labelFontSize: labelFontSize,
      popupEnabled: popupEnabled,
      popupTitleField: popupTitleField,
      popupFields: popupFields,
      popupFieldLabels: popupFieldLabels,
      popupShowDetailsAction: popupShowDetailsAction,
      popupShowReportAction: popupShowReportAction,
      popupShowTaskAction: popupShowTaskAction,
      identifyTitleField: identifyTitleField,
      identifyFields: identifyFields,
      identifyFieldLabels: identifyFieldLabels,
      identifyMaxFields: identifyMaxFields,
    );
  }

  @override
  Widget build(BuildContext context) {
    final layer = widget.config;
    final borderColor = layer.layerWeight == 'heavy'
        ? PwfColors.royalRed.withValues(alpha: 0.28)
        : PwfColors.outline;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: PwfColors.royalRed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.layers, color: PwfColors.royalRed),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      layer.displayName,
                      style: const TextStyle(
                        color: PwfColors.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      layer.layerKey,
                      style: TextStyle(
                        color: PwfColors.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (_updating)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _LayerManagerBadge(text: layer.categoryLabelAr),
              _LayerManagerBadge(text: layer.layerWeightLabelAr),
              _LayerManagerBadge(text: 'Zoom ${layer.minZoom.toStringAsFixed(0)}-${layer.maxZoom.toStringAsFixed(0)}'),
              _LayerManagerBadge(text: 'حد ${layer.maxFeaturesPerRequest}'),
            ],
          ),
          const Divider(height: 22),
          _LayerManagerSwitch(
            label: 'مفعّلة في كتالوج الطبقات',
            value: layer.isActive,
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(isActive: value)),
          ),
          _LayerManagerSwitch(
            label: 'عامة من حيث الكتالوج',
            value: layer.isPublic,
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(isPublic: value)),
          ),
          const SizedBox(height: 6),
          const _LayerManagerSubTitle(text: 'الظهور حسب الدور'),
          _LayerManagerSwitch(
            label: 'الجمهور',
            value: layer.visiblePublic,
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(visiblePublic: value)),
          ),
          _LayerManagerSwitch(
            label: 'الموظف',
            value: layer.visibleEmployee,
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(visibleEmployee: value)),
          ),
          _LayerManagerSwitch(
            label: 'مدير الخريطة',
            value: layer.visibleManager,
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(visibleManager: value)),
          ),
          const SizedBox(height: 6),
          const _LayerManagerSubTitle(text: 'الأداء والتحميل'),
          _LayerManagerSwitch(
            label: 'يتطلب BBOX',
            value: layer.bboxRequired,
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(bboxRequired: value)),
          ),
          _LayerManagerSwitch(
            label: 'Cache محدود',
            value: layer.cacheEnabled,
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(cacheEnabled: value)),
          ),
          _LayerManagerSwitch(
            label: 'Clustering للنقاط',
            value: layer.clusteringEnabled,
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(clusteringEnabled: value)),
          ),
          _LayerManagerSwitch(
            label: 'Identify مسموح',
            value: layer.identifyEnabled,
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(identifyEnabled: value)),
          ),
          _LayerManagerSwitch(
            label: 'بلاغات على الطبقة',
            value: layer.reportEnabled,
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(reportEnabled: value)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: {'light', 'medium', 'heavy'}.contains(layer.layerWeight)
                ? layer.layerWeight
                : 'medium',
            decoration: const InputDecoration(
              labelText: 'وزن الطبقة',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'light', child: Text('خفيفة')),
              DropdownMenuItem(value: 'medium', child: Text('متوسطة')),
              DropdownMenuItem(value: 'heavy', child: Text('ثقيلة')),
            ],
            onChanged: _updating
                ? null
                : (value) => _update(_baseUpdate(layerWeight: value)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _nearestFeatureLimit(layer.maxFeaturesPerRequest),
            decoration: const InputDecoration(
              labelText: 'حد العناصر لكل طلب',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 500, child: Text('500')),
              DropdownMenuItem(value: 1200, child: Text('1200')),
              DropdownMenuItem(value: 2500, child: Text('2500')),
              DropdownMenuItem(value: 3500, child: Text('3500')),
              DropdownMenuItem(value: 5000, child: Text('5000')),
              DropdownMenuItem(value: 12000, child: Text('12000')),
            ],
            onChanged: _updating
                ? null
                : (value) => _update(
                      _baseUpdate(maxFeaturesPerRequest: value),
                    ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: {'none', 'summary', 'visible', 'manager_only'}
                    .contains(layer.exportPolicy)
                ? layer.exportPolicy
                : 'none',
            decoration: const InputDecoration(
              labelText: 'سياسة التصدير',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'none', child: Text('ممنوع')),
              DropdownMenuItem(value: 'summary', child: Text('ملخص')),
              DropdownMenuItem(value: 'visible', child: Text('المعروض فقط')),
              DropdownMenuItem(value: 'manager_only', child: Text('المدير فقط')),
            ],
            onChanged: _updating
                ? null
                : (value) => _update(_baseUpdate(exportPolicy: value)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _LayerManagerMiniButton(
                label: 'كل الزوم',
                enabled: !_updating,
                onTap: () => _update(_baseUpdate(minZoom: 0, maxZoom: 22)),
              ),
              _LayerManagerMiniButton(
                label: 'متوسط+',
                enabled: !_updating,
                onTap: () => _update(_baseUpdate(minZoom: 10, maxZoom: 22)),
              ),
              _LayerManagerMiniButton(
                label: 'قريب فقط',
                enabled: !_updating,
                onTap: () => _update(_baseUpdate(minZoom: 15, maxZoom: 22)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _LayerManagerSubTitle(text: 'الرموز والظهور'),
          _LayerSymbologyPreview(layer: layer),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _safeHexChoice(layer.strokeColor),
            decoration: const InputDecoration(
              labelText: 'لون الحد',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _layerColorChoices
                .map((choice) => DropdownMenuItem(
                      value: choice.value,
                      child: _LayerColorChoiceLabel(choice: choice),
                    ))
                .toList(growable: false),
            onChanged: _updating
                ? null
                : (value) => _update(_baseUpdate(strokeColor: value)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _safeHexChoice(layer.fillColor),
            decoration: const InputDecoration(
              labelText: 'لون التعبئة',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _layerColorChoices
                .map((choice) => DropdownMenuItem(
                      value: choice.value,
                      child: _LayerColorChoiceLabel(choice: choice),
                    ))
                .toList(growable: false),
            onChanged: _updating
                ? null
                : (value) => _update(_baseUpdate(fillColor: value)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _safeHexChoice(layer.markerColor),
            decoration: const InputDecoration(
              labelText: 'لون النقطة',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _layerColorChoices
                .map((choice) => DropdownMenuItem(
                      value: choice.value,
                      child: _LayerColorChoiceLabel(choice: choice),
                    ))
                .toList(growable: false),
            onChanged: _updating
                ? null
                : (value) => _update(_baseUpdate(markerColor: value)),
          ),
          const SizedBox(height: 10),
          _LayerManagerSlider(
            label: 'سماكة الحد',
            value: layer.strokeWidth.clamp(0.5, 8.0).toDouble(),
            min: 0.5,
            max: 8,
            divisions: 15,
            display: layer.strokeWidth.toStringAsFixed(1),
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(strokeWidth: value)),
          ),
          _LayerManagerSlider(
            label: 'شفافية التعبئة',
            value: layer.fillOpacity.clamp(0.0, 0.85).toDouble(),
            min: 0,
            max: 0.85,
            divisions: 17,
            display: '${(layer.fillOpacity * 100).round()}%',
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(fillOpacity: value)),
          ),
          _LayerManagerSlider(
            label: 'حجم النقطة',
            value: layer.markerSize.clamp(18.0, 72.0).toDouble(),
            min: 18,
            max: 72,
            divisions: 18,
            display: layer.markerSize.toStringAsFixed(0),
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(markerSize: value)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _safePointShape(layer.pointShape),
            decoration: const InputDecoration(
              labelText: 'شكل النقطة',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'pin', child: Text('دبوس')),
              DropdownMenuItem(value: 'circle', child: Text('دائرة')),
              DropdownMenuItem(value: 'square', child: Text('مربع')),
              DropdownMenuItem(value: 'diamond', child: Text('معين')),
              DropdownMenuItem(value: 'mosque', child: Text('مسجد')),
              DropdownMenuItem(value: 'cemetery', child: Text('مقبرة')),
              DropdownMenuItem(value: 'landmark', child: Text('معلم')),
            ],
            onChanged: _updating
                ? null
                : (value) => _update(_baseUpdate(pointShape: value)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _safeLineStyle(layer.lineStyle),
            decoration: const InputDecoration(
              labelText: 'نمط الخط',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'solid', child: Text('متصل')),
              DropdownMenuItem(value: 'dashed', child: Text('متقطع')),
              DropdownMenuItem(value: 'dotted', child: Text('منقّط')),
            ],
            onChanged: _updating
                ? null
                : (value) => _update(_baseUpdate(lineStyle: value)),
          ),
          _LayerManagerSwitch(
            label: 'إظهار في مفتاح الخريطة',
            value: layer.legendEnabled,
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(legendEnabled: value)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _legendController,
            enabled: !_updating,
            decoration: const InputDecoration(
              labelText: 'تسمية المفتاح',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _updating
                ? null
                : () => _update(
                      _baseUpdate(
                        legendLabelAr: _legendController.text.trim(),
                      ),
                    ),
            icon: const Icon(Icons.label_outline),
            label: const Text('حفظ تسمية المفتاح'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _LayerManagerMiniButton(
                label: 'نمط وقفي',
                enabled: !_updating,
                onTap: () => _update(
                  _baseUpdate(
                    stylePreset: 'palwakf_waqf',
                    strokeColor: '#1D4ED8',
                    fillColor: '#D4AF37',
                    markerColor: '#D4AF37',
                    fillOpacity: 0.12,
                    strokeWidth: 1.8,
                    pointShape: 'pin',
                  ),
                ),
              ),
              _LayerManagerMiniButton(
                label: 'نمط تدقيق',
                enabled: !_updating,
                onTap: () => _update(
                  _baseUpdate(
                    stylePreset: 'palwakf_audit',
                    strokeColor: '#B22222',
                    fillColor: '#FEE2E2',
                    markerColor: '#B22222',
                    fillOpacity: 0.20,
                    strokeWidth: 2.2,
                    pointShape: 'diamond',
                  ),
                ),
              ),
              _LayerManagerMiniButton(
                label: 'نمط إداري',
                enabled: !_updating,
                onTap: () => _update(
                  _baseUpdate(
                    stylePreset: 'palwakf_admin_boundary',
                    strokeColor: '#1D4ED8',
                    fillColor: '#DBEAFE',
                    markerColor: '#1D4ED8',
                    fillOpacity: 0.07,
                    strokeWidth: 1.4,
                    pointShape: 'circle',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _LayerManagerSubTitle(text: 'الترميز حسب قيمة حقل'),
          DropdownButtonFormField<String>(
            value: layer.usesUniqueValues ? 'unique_value' : 'single',
            decoration: const InputDecoration(
              labelText: 'نمط الترميز',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'single', child: Text('رمز موحد')),
              DropdownMenuItem(value: 'unique_value', child: Text('قيم فريدة حسب حقل')),
            ],
            onChanged: _updating
                ? null
                : (value) => _update(_baseUpdate(symbologyMode: value)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _uniqueFieldController,
            enabled: !_updating,
            decoration: const InputDecoration(
              labelText: 'حقل التصنيف',
              hintText: 'مثال: asset_type / status / governorate / lgu_name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _LayerManagerMiniButton(
                label: 'حفظ الحقل',
                enabled: !_updating,
                onTap: () => _update(
                  _baseUpdate(
                    symbologyMode: 'unique_value',
                    uniqueValueField: _uniqueFieldController.text.trim(),
                  ),
                ),
              ),
              _LayerManagerMiniButton(
                label: 'قالب نوع الأصل',
                enabled: !_updating,
                onTap: () => _update(
                  _baseUpdate(
                    symbologyMode: 'unique_value',
                    uniqueValueField: 'asset_type',
                    uniqueValueRules: _uniqueRulesPreset('asset_type'),
                  ),
                ),
              ),
              _LayerManagerMiniButton(
                label: 'قالب حالة الربط',
                enabled: !_updating,
                onTap: () => _update(
                  _baseUpdate(
                    symbologyMode: 'unique_value',
                    uniqueValueField: 'link_status',
                    uniqueValueRules: _uniqueRulesPreset('link_status'),
                  ),
                ),
              ),
              _LayerManagerMiniButton(
                label: 'قالب البلاغات',
                enabled: !_updating,
                onTap: () => _update(
                  _baseUpdate(
                    symbologyMode: 'unique_value',
                    uniqueValueField: 'status',
                    uniqueValueRules: _uniqueRulesPreset('feedback_status'),
                  ),
                ),
              ),
              _LayerManagerMiniButton(
                label: 'إلغاء الترميز',
                enabled: !_updating,
                onTap: () => _update(
                  _baseUpdate(
                    symbologyMode: 'single',
                    uniqueValueField: '',
                    uniqueValueRules: const <Map<String, dynamic>>[],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _InfoRow(
            label: 'قواعد الترميز',
            value: layer.uniqueValueRules.isEmpty
                ? 'لا توجد قواعد محفوظة؛ سيستخدم الرمز الموحد.'
                : '${layer.uniqueValueRules.length} قاعدة محفوظة',
          ),
          const SizedBox(height: 12),
          const _LayerManagerSubTitle(text: 'التسميات Labels'),
          _LayerManagerSwitch(
            label: 'تفعيل التسميات لهذه الطبقة',
            value: layer.labelsEnabled,
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(labelsEnabled: value)),
          ),
          TextField(
            controller: _labelFieldController,
            enabled: !_updating,
            decoration: const InputDecoration(
              labelText: 'حقل التسمية',
              hintText: 'مثال: name_ar / lgusn / national_asset_code',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _updating
                ? null
                : () => _update(
                      _baseUpdate(
                        labelsEnabled: true,
                        labelField: _labelFieldController.text.trim(),
                      ),
                    ),
            icon: const Icon(Icons.text_fields_outlined),
            label: const Text('حفظ إعدادات حقل التسمية'),
          ),
          const SizedBox(height: 10),
          _LayerManagerSlider(
            label: 'أقل Zoom للتسمية',
            value: layer.labelMinZoom.clamp(0.0, 22.0).toDouble(),
            min: 0,
            max: 22,
            divisions: 22,
            display: layer.labelMinZoom.toStringAsFixed(0),
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(labelMinZoom: value)),
          ),
          _LayerManagerSlider(
            label: 'حجم خط التسمية',
            value: layer.labelFontSize.clamp(8.0, 24.0).toDouble(),
            min: 8,
            max: 24,
            divisions: 16,
            display: layer.labelFontSize.toStringAsFixed(0),
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(labelFontSize: value)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _nearestLabelLimit(layer.labelMaxCount),
            decoration: const InputDecoration(
              labelText: 'حد أقصى للتسميات',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 50, child: Text('50')),
              DropdownMenuItem(value: 150, child: Text('150')),
              DropdownMenuItem(value: 250, child: Text('250')),
              DropdownMenuItem(value: 500, child: Text('500')),
              DropdownMenuItem(value: 1000, child: Text('1000')),
            ],
            onChanged: _updating
                ? null
                : (value) => _update(_baseUpdate(labelMaxCount: value)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _safeHexChoice(layer.labelTextColor),
            decoration: const InputDecoration(
              labelText: 'لون النص',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _layerColorChoices
                .map((choice) => DropdownMenuItem(
                      value: choice.value,
                      child: _LayerColorChoiceLabel(choice: choice),
                    ))
                .toList(growable: false),
            onChanged: _updating
                ? null
                : (value) => _update(_baseUpdate(labelTextColor: value)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _safeHexChoice(layer.labelHaloColor),
            decoration: const InputDecoration(
              labelText: 'لون خلفية/هالة التسمية',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _layerColorChoices
                .map((choice) => DropdownMenuItem(
                      value: choice.value,
                      child: _LayerColorChoiceLabel(choice: choice),
                    ))
                .toList(growable: false),
            onChanged: _updating
                ? null
                : (value) => _update(_baseUpdate(labelHaloColor: value)),
          ),

          const SizedBox(height: 12),
          const _LayerManagerSubTitle(text: 'Popup / بطاقة العنصر'),
          _LayerManagerSwitch(
            label: 'تفعيل Popup لهذه الطبقة',
            value: layer.popupEnabled,
            enabled: !_updating,
            onChanged: (value) => _update(_baseUpdate(popupEnabled: value)),
          ),
          TextField(
            controller: _popupTitleFieldController,
            enabled: !_updating,
            decoration: const InputDecoration(
              labelText: 'حقل عنوان Popup',
              hintText: 'مثال: name_ar / lgusn / national_asset_code',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _popupFieldsController,
            enabled: !_updating,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'حقول Popup',
              hintText: 'افصل الحقول بفاصلة: name_ar, status, lgu_name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _LayerManagerMiniButton(
                label: 'حفظ Popup',
                enabled: !_updating,
                onTap: () => _update(
                  _baseUpdate(
                    popupTitleField: _popupTitleFieldController.text.trim(),
                    popupFields: _csvFields(_popupFieldsController.text),
                  ),
                ),
              ),
              _LayerManagerMiniButton(
                label: 'قالب أصل وقفي',
                enabled: !_updating,
                onTap: () => _update(
                  _baseUpdate(
                    popupTitleField: 'name_ar',
                    popupFields: const [
                      'national_asset_code',
                      'asset_type',
                      'status',
                      'endowment_name',
                      'lgu_name',
                    ],
                    popupFieldLabels: const {
                      'national_asset_code': 'الرمز الوطني',
                      'asset_type': 'نوع الأصل',
                      'status': 'الحالة',
                      'endowment_name': 'الوقف المرجعي',
                      'lgu_name': 'الهيئة المحلية',
                    },
                  ),
                ),
              ),
              _LayerManagerMiniButton(
                label: 'قالب إداري',
                enabled: !_updating,
                onTap: () => _update(
                  _baseUpdate(
                    popupTitleField: 'lgusn',
                    popupFields: const [
                      'governorate',
                      'lgusn',
                      'lgus_code',
                      'communityn',
                    ],
                    popupFieldLabels: const {
                      'governorate': 'المحافظة',
                      'lgusn': 'الهيئة المحلية',
                      'lgus_code': 'رمز الهيئة',
                      'communityn': 'التجمع',
                    },
                  ),
                ),
              ),
            ],
          ),
          _LayerManagerSwitch(
            label: 'إظهار زر التفاصيل في Popup',
            value: layer.popupShowDetailsAction,
            enabled: !_updating,
            onChanged: (value) =>
                _update(_baseUpdate(popupShowDetailsAction: value)),
          ),
          _LayerManagerSwitch(
            label: 'إظهار زر بلاغ/ملاحظة',
            value: layer.popupShowReportAction,
            enabled: !_updating,
            onChanged: (value) =>
                _update(_baseUpdate(popupShowReportAction: value)),
          ),
          _LayerManagerSwitch(
            label: 'إظهار زر مهمة تدقيق',
            value: layer.popupShowTaskAction,
            enabled: !_updating,
            onChanged: (value) =>
                _update(_baseUpdate(popupShowTaskAction: value)),
          ),
          const SizedBox(height: 12),
          const _LayerManagerSubTitle(text: 'Identify / التعريف المكاني'),
          TextField(
            controller: _identifyTitleFieldController,
            enabled: !_updating,
            decoration: const InputDecoration(
              labelText: 'حقل عنوان Identify',
              hintText: 'اتركه فارغًا لاستخدام العنوان الافتراضي',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _identifyFieldsController,
            enabled: !_updating,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'حقول Identify',
              hintText: 'افصل الحقول بفاصلة',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _nearestIdentifyLimit(layer.identifyMaxFields),
            decoration: const InputDecoration(
              labelText: 'حد أقصى لحقول التعريف',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 4, child: Text('4')),
              DropdownMenuItem(value: 6, child: Text('6')),
              DropdownMenuItem(value: 8, child: Text('8')),
              DropdownMenuItem(value: 12, child: Text('12')),
              DropdownMenuItem(value: 16, child: Text('16')),
            ],
            onChanged: _updating
                ? null
                : (value) => _update(_baseUpdate(identifyMaxFields: value)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _updating
                ? null
                : () => _update(
                      _baseUpdate(
                        identifyTitleField:
                            _identifyTitleFieldController.text.trim(),
                        identifyFields: _csvFields(_identifyFieldsController.text),
                      ),
                    ),
            icon: const Icon(Icons.ads_click_outlined),
            label: const Text('حفظ إعدادات Identify'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            enabled: !_updating,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'ملاحظات إدارية',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _updating
                ? null
                : () => _update(
                      _baseUpdate(adminNotes: _notesController.text.trim()),
                    ),
            icon: const Icon(Icons.save_outlined),
            label: const Text('حفظ الملاحظات'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _uniqueRulesPreset(String preset) {
    switch (preset) {
      case 'asset_type':
        return const [
          {'value': 'mosque', 'label': 'مسجد', 'color': '#1D4ED8'},
          {'value': 'cemetery', 'label': 'مقبرة', 'color': '#64748B'},
          {'value': 'maqam', 'label': 'مقام', 'color': '#D4AF37'},
          {'value': 'land', 'label': 'أرض', 'color': '#15803D'},
          {'value': 'building', 'label': 'عقار', 'color': '#B22222'},
        ];
      case 'link_status':
        return const [
          {'value': 'linked', 'label': 'مرتبط', 'color': '#15803D'},
          {'value': 'missing', 'label': 'بلا ربط', 'color': '#B22222'},
          {'value': 'suspected', 'label': 'ربط مشبوه', 'color': '#F59E0B'},
          {'value': 'review', 'label': 'قيد المراجعة', 'color': '#1D4ED8'},
        ];
      case 'feedback_status':
        return const [
          {'value': 'new', 'label': 'جديد', 'color': '#B22222'},
          {'value': 'triaged', 'label': 'قيد الفرز', 'color': '#F59E0B'},
          {'value': 'accepted', 'label': 'مقبول', 'color': '#15803D'},
          {'value': 'rejected', 'label': 'مرفوض', 'color': '#64748B'},
          {'value': 'resolved', 'label': 'مغلق', 'color': '#1D4ED8'},
        ];
      default:
        return const <Map<String, dynamic>>[];
    }
  }

  List<String> _csvFields(String value) {
    final seen = <String>{};
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .where((e) => seen.add(e.toLowerCase()))
        .toList(growable: false);
  }

  int _nearestIdentifyLimit(int value) {
    const options = [4, 6, 8, 12, 16];
    var best = options.first;
    var bestDelta = (value - best).abs();
    for (final option in options.skip(1)) {
      final delta = (value - option).abs();
      if (delta < bestDelta) {
        best = option;
        bestDelta = delta;
      }
    }
    return best;
  }

  int _nearestLabelLimit(int value) {
    const options = [50, 150, 250, 500, 1000];
    var best = options.first;
    var bestDelta = (value - best).abs();
    for (final option in options.skip(1)) {
      final delta = (value - option).abs();
      if (delta < bestDelta) {
        best = option;
        bestDelta = delta;
      }
    }
    return best;
  }


  String _safeHexChoice(String value) {
    final normalized = value.trim().toUpperCase();
    for (final choice in _layerColorChoices) {
      if (choice.value.toUpperCase() == normalized) return choice.value;
    }
    return _layerColorChoices.first.value;
  }

  String _safePointShape(String value) {
    const allowed = {'pin', 'circle', 'square', 'diamond', 'mosque', 'cemetery', 'landmark'};
    final normalized = value.trim().toLowerCase();
    return allowed.contains(normalized) ? normalized : 'pin';
  }

  String _safeLineStyle(String value) {
    const allowed = {'solid', 'dashed', 'dotted'};
    final normalized = value.trim().toLowerCase();
    return allowed.contains(normalized) ? normalized : 'solid';
  }

  int _nearestFeatureLimit(int value) {
    const options = [500, 1200, 2500, 3500, 5000, 12000];
    var best = options.first;
    var bestDelta = (value - best).abs();
    for (final option in options.skip(1)) {
      final delta = (value - option).abs();
      if (delta < bestDelta) {
        best = option;
        bestDelta = delta;
      }
    }
    return best;
  }
}

class _LayerManagerSummaryStrip extends StatelessWidget {
  const _LayerManagerSummaryStrip({
    required this.total,
    required this.active,
    required this.publicVisible,
    required this.heavy,
  });

  final int total;
  final int active;
  final int publicVisible;
  final int heavy;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _LayerManagerMetric(label: 'الطبقات', value: '$total'),
        _LayerManagerMetric(label: 'مفعلة', value: '$active'),
        _LayerManagerMetric(label: 'للجمهور', value: '$publicVisible'),
        _LayerManagerMetric(label: 'ثقيلة', value: '$heavy'),
      ],
    );
  }
}

class _LayerManagerMetric extends StatelessWidget {
  const _LayerManagerMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: PwfColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: PwfColors.primaryBlue,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: PwfColors.onSurface.withValues(alpha: 0.60),
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerManagerFilterChip extends StatelessWidget {
  const _LayerManagerFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: PwfColors.royalRed.withValues(alpha: 0.13),
      labelStyle: TextStyle(
        color: selected ? PwfColors.royalRed : PwfColors.onSurface,
        fontWeight: FontWeight.w900,
      ),
      side: BorderSide(
        color: selected
            ? PwfColors.royalRed.withValues(alpha: 0.30)
            : PwfColors.outline,
      ),
    );
  }
}

class _LayerManagerBadge extends StatelessWidget {
  const _LayerManagerBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: PwfColors.onSurface.withValues(alpha: 0.68),
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _LayerManagerSubTitle extends StatelessWidget {
  const _LayerManagerSubTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: PwfColors.royalRed,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LayerManagerSwitch extends StatelessWidget {
  const _LayerManagerSwitch({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: PwfColors.royalRed,
      title: Text(
        label,
        style: const TextStyle(
          color: PwfColors.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _LayerManagerMiniButton extends StatelessWidget {
  const _LayerManagerMiniButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: PwfColors.royalRed.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}
class _LayerColorChoice {
  const _LayerColorChoice(this.label, this.value);
  final String label;
  final String value;
}

const List<_LayerColorChoice> _layerColorChoices = [
  _LayerColorChoice('أزرق حكومي', '#1D4ED8'),
  _LayerColorChoice('ذهبي وقفي', '#D4AF37'),
  _LayerColorChoice('أحمر ملكي', '#B22222'),
  _LayerColorChoice('أخضر تدقيق', '#15803D'),
  _LayerColorChoice('برتقالي تنبيه', '#F59E0B'),
  _LayerColorChoice('رمادي إداري', '#64748B'),
  _LayerColorChoice('أزرق فاتح', '#DBEAFE'),
  _LayerColorChoice('أحمر فاتح', '#FEE2E2'),
  _LayerColorChoice('أبيض', '#FFFFFF'),
  _LayerColorChoice('أسود نصي', '#111827'),
];

Color _layerManagerHexColor(String value, {Color fallback = PwfColors.primaryBlue}) {
  var v = value.trim();
  if (v.startsWith('#')) v = v.substring(1);
  if (v.length == 6) v = 'FF$v';
  if (v.length != 8) return fallback;
  try {
    return Color(int.parse(v, radix: 16));
  } catch (_) {
    return fallback;
  }
}

class _LayerColorChoiceLabel extends StatelessWidget {
  const _LayerColorChoiceLabel({required this.choice});
  final _LayerColorChoice choice;

  @override
  Widget build(BuildContext context) {
    final color = _layerManagerHexColor(choice.value);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(choice.label),
      ],
    );
  }
}

class _LayerSymbologyPreview extends StatelessWidget {
  const _LayerSymbologyPreview({required this.layer});
  final MapLayerAdminConfig layer;

  @override
  Widget build(BuildContext context) {
    final stroke = _layerManagerHexColor(layer.strokeColor);
    final fill = _layerManagerHexColor(layer.fillColor, fallback: PwfColors.primaryGold);
    final marker = _layerManagerHexColor(layer.markerColor, fallback: PwfColors.primaryGold);
    final markerSize = layer.markerSize.clamp(18.0, 42.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 42,
            decoration: BoxDecoration(
              color: fill.withValues(alpha: layer.fillOpacity.clamp(0.0, 0.85).toDouble()),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: stroke,
                width: layer.strokeWidth.clamp(0.5, 5.0).toDouble(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: markerSize,
            height: markerSize,
            decoration: BoxDecoration(
              color: marker,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Icon(
              _iconForLayerPointShape(layer.pointShape),
              size: (markerSize * 0.48).clamp(11.0, 22.0).toDouble(),
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  layer.legendLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: PwfColors.onSurface,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${layer.pointShapeLabelAr} • ${layer.lineStyleLabelAr} • ${layer.stylePreset}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: PwfColors.onSurface.withValues(alpha: 0.58),
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForLayerPointShape(String shape) {
    switch (shape.trim().toLowerCase()) {
      case 'mosque':
        return Icons.mosque_outlined;
      case 'cemetery':
        return Icons.account_balance_outlined;
      case 'landmark':
        return Icons.location_city_outlined;
      case 'square':
        return Icons.stop_rounded;
      case 'diamond':
        return Icons.diamond_outlined;
      case 'circle':
        return Icons.circle_outlined;
      default:
        return Icons.place;
    }
  }
}

IconData _iconForLayerPointShape(String shape) {
  switch (shape.trim().toLowerCase()) {
    case 'mosque':
      return Icons.mosque_outlined;
    case 'cemetery':
      return Icons.account_balance_outlined;
    case 'landmark':
      return Icons.location_city_outlined;
    case 'square':
      return Icons.stop_rounded;
    case 'diamond':
      return Icons.diamond_outlined;
    case 'circle':
      return Icons.circle_outlined;
    default:
      return Icons.place;
  }
}

class _LayerManagerSlider extends StatelessWidget {
  const _LayerManagerSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: PwfColors.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              display,
              style: const TextStyle(
                color: PwfColors.royalRed,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: PwfColors.royalRed,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

class IdentifyToolPanel extends ConsumerWidget {
  const IdentifyToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  Future<void> _copy(
    BuildContext context, {
    required String text,
    required String successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }

  String _identifySummary(MapIdentifyResult result, GisFeatureModel? feature) {
    final buffer = StringBuffer()
      ..writeln('تقرير Identify - PalWakf')
      ..writeln('الإحداثيات: ${result.point.latitude.toStringAsFixed(6)}, ${result.point.longitude.toStringAsFixed(6)}')
      ..writeln('المصدر: ${result.source}')
      ..writeln("العنصر: ${feature?.displayTitle ?? 'لا يوجد'}")
      ..writeln("الطبقة: ${feature?.layerNameAr ?? feature?.layerKey ?? ''}")
      ..writeln("العلاقة: ${result.relation ?? ''}")
      ..writeln("المسافة: ${result.distanceMeters?.toStringAsFixed(1) ?? ''}")
      ..writeln("درجة المطابقة: ${result.score == null ? '' : ((result.score! * 100).clamp(0, 100)).toStringAsFixed(0)}")
      ..writeln('عدد المرشحات: ${result.candidatesCount}');
    if (feature != null) {
      buffer.writeln('--- خصائص مختصرة ---');
      for (final entry in feature.previewEntries) {
        buffer.writeln('${entry.key}: ${entry.value}');
      }
    }
    return buffer.toString();
  }

  String _identifyCsv(MapIdentifyResult result, GisFeatureModel? feature) {
    final rows = <List<String>>[
      ['metric', 'value'],
      ['lat', result.point.latitude.toStringAsFixed(6)],
      ['lng', result.point.longitude.toStringAsFixed(6)],
      ['source', result.source],
      ['feature_id', feature?.id ?? ''],
      ['feature_title', feature?.displayTitle ?? ''],
      ['layer_key', feature?.layerKey ?? ''],
      ['relation', result.relation ?? ''],
      ['distance_meters', result.distanceMeters?.toStringAsFixed(1) ?? ''],
      ['score', result.score?.toStringAsFixed(4) ?? ''],
      ['candidates_count', '${result.candidatesCount}'],
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(identifyResultProvider);
    final feature = result?.feature;
    return _ToolPanelScaffold(
      title: 'تعريف العنصر',
      icon: Icons.ads_click_outlined,
      onClose: onClose,
      children: [
        const _HintBox(
          icon: Icons.touch_app_outlined,
          text: 'اضغط على الخريطة لتحديد أقرب عنصر محمّل ضمن حدود الشاشة الحالية. لا يتم طلب طبقات جديدة أثناء التعريف.',
        ),
        const SizedBox(height: 12),
        if (result == null)
          const _EmptyToolBox(text: 'لم يتم اختيار نقطة بعد.')
        else ...[
          _InfoRow(label: 'الإحداثيات', value: '${result.point.latitude.toStringAsFixed(6)}, ${result.point.longitude.toStringAsFixed(6)}'),
          _InfoRow(
            label: 'مصدر التعريف',
            value: switch (result.source) {
              'postgis' => 'PostGIS دقيق',
              'local_fallback' => 'محلي احتياطي',
              _ => 'محلي',
            },
          ),
          if (result.isLoading)
            const LinearProgressIndicator(minHeight: 3),
          if (result.message != null && result.message!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _HintBox(icon: Icons.info_outline, text: result.message!),
          ],
          if (feature == null)
            const _EmptyToolBox(text: 'لا يوجد عنصر قريب ضمن الطبقات الحالية أو نطاق التعريف.')
          else ...[
            _InfoRow(label: 'العنصر', value: feature.displayTitle),
            _InfoRow(label: 'الطبقة', value: feature.layerNameAr ?? feature.layerKey),
            if (result.relation != null)
              _InfoRow(
                label: 'العلاقة المكانية',
                value: result.relation == 'contains'
                    ? 'النقطة داخل العنصر'
                    : result.relation == 'nearest'
                        ? 'أقرب عنصر'
                        : result.relation!,
              ),
            if (result.distanceMeters != null)
              _InfoRow(label: 'المسافة التقريبية', value: '${result.distanceMeters!.toStringAsFixed(1)} م'),
            if (result.score != null)
              _InfoRow(label: 'درجة المطابقة', value: '${(result.score! * 100).clamp(0, 100).toStringAsFixed(0)}%'),
            if (result.candidatesCount > 1)
              _InfoRow(label: 'مرشحات قريبة', value: '${result.candidatesCount}'),
            const SizedBox(height: 8),
            _ConfiguredIdentifyProps(feature: feature),
            const SizedBox(height: 10),
            _ExplorerCopyActions(
              primaryLabel: 'نسخ Identify',
              secondaryLabel: 'نسخ CSV',
              onPrimary: () => _copy(
                context,
                text: _identifySummary(result, feature),
                successMessage: 'تم نسخ تقرير Identify.',
              ),
              onSecondary: () => _copy(
                context,
                text: _identifyCsv(result, feature),
                successMessage: 'تم نسخ CSV لتقرير Identify.',
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ConfiguredIdentifyProps extends ConsumerWidget {
  const _ConfiguredIdentifyProps({required this.feature});
  final GisFeatureModel feature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<MapLayerAdminConfig>>(
      future: ref.read(mapLayerManagerRepositoryProvider).listLayerConfigs(),
      builder: (context, snapshot) {
        final config = _findLayerConfig(snapshot.data, feature.layerKey);
        if (config == null) return _PropsPreview(props: feature.props);
        final entries = config.configuredEntries(
          feature.props,
          identify: true,
          fallbackLimit: 8,
        );
        return _ConfiguredPropsPreview(
          title: 'حقول التعريف المعتمدة',
          entries: entries,
          emptyText: 'لا توجد حقول تعريف ظاهرة لهذه الطبقة.',
        );
      },
    );
  }
}

MapLayerAdminConfig? _findLayerConfig(
  List<MapLayerAdminConfig>? configs,
  String layerKey,
) {
  if (configs == null) return null;
  final normalized = layerKey.trim().toLowerCase();
  for (final config in configs) {
    if (config.layerKey.trim().toLowerCase() == normalized) return config;
  }
  return null;
}

class _ConfiguredPropsPreview extends StatelessWidget {
  const _ConfiguredPropsPreview({
    required this.title,
    required this.entries,
    required this.emptyText,
  });

  final String title;
  final List<MapEntry<String, String>> entries;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return _EmptyToolBox(text: emptyText);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: PwfColors.royalRed,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...entries.map((entry) => _InfoRow(label: entry.key, value: entry.value)),
        ],
      ),
    );
  }
}

class ReportIssueToolPanel extends ConsumerStatefulWidget {
  const ReportIssueToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<ReportIssueToolPanel> createState() =>
      _ReportIssueToolPanelState();
}

class _ReportIssueToolPanelState extends ConsumerState<ReportIssueToolPanel> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  bool _submitting = false;
  String _type = 'بيانات غير دقيقة';
  String _priority = 'normal';

  @override
  void dispose() {
    _noteController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  String _categoryCodeFor(String value) {
    return switch (value) {
      'بيانات غير دقيقة' => 'inaccurate_data',
      'موقع غير صحيح' => 'wrong_location',
      'أصل بلا ربط' => 'missing_asset_link',
      'تكرار محتمل' => 'duplicate_suspected',
      _ => 'general_note',
    };
  }

  Future<void> _submitReport(MapReportDraft draft) async {
    final note = _noteController.text.trim();
    if (note.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب ملاحظة مختصرة قبل الإرسال.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final report = await ref.read(mapFeedbackRepositoryProvider).createReport(
            MapFeedbackSubmission(
              categoryCode: _categoryCodeFor(_type),
              categoryLabel: _type,
              note: note,
              point: draft.point,
              feature: draft.feature,
              reporterContact: _contactController.text.trim().isEmpty
                  ? null
                  : _contactController.text.trim(),
              priority: _priority,
              clientContext: {
                'tool': 'modern_map_report_issue',
                'created_at_local': draft.createdAt.toIso8601String(),
              },
            ),
          );
      if (!mounted) return;
      ref.read(mapReportDraftProvider.notifier).state = null;
      _noteController.clear();
      _contactController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ البلاغ رقم ${report.id.substring(0, 8)} للمراجعة.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ البلاغ: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(mapReportDraftProvider);
    final feature = draft?.feature;
    return _ToolPanelScaffold(
      title: 'بلاغ / ملاحظة تدقيق',
      icon: Icons.report_problem_outlined,
      onClose: widget.onClose,
      children: [
        const _HintBox(
          icon: Icons.touch_app_outlined,
          text: 'اضغط على الخريطة لتثبيت موقع البلاغ. سيتم حفظ البلاغ في Supabase عبر RPC محكوم ثم يدخل مسار المراجعة.',
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _type,
          decoration: const InputDecoration(
            labelText: 'نوع الملاحظة',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'بيانات غير دقيقة', child: Text('بيانات غير دقيقة')),
            DropdownMenuItem(value: 'موقع غير صحيح', child: Text('موقع غير صحيح')),
            DropdownMenuItem(value: 'أصل بلا ربط', child: Text('أصل بلا ربط')),
            DropdownMenuItem(value: 'تكرار محتمل', child: Text('تكرار محتمل')),
            DropdownMenuItem(value: 'ملاحظة عامة', child: Text('ملاحظة عامة')),
          ],
          onChanged: _submitting ? null : (v) => setState(() => _type = v ?? _type),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _priority,
          decoration: const InputDecoration(
            labelText: 'الأولوية',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('منخفضة')),
            DropdownMenuItem(value: 'normal', child: Text('عادية')),
            DropdownMenuItem(value: 'high', child: Text('مرتفعة')),
            DropdownMenuItem(value: 'urgent', child: Text('عاجلة')),
          ],
          onChanged: _submitting ? null : (v) => setState(() => _priority = v ?? _priority),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _noteController,
          enabled: !_submitting,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'الملاحظة',
            hintText: 'اكتب وصفًا مختصرًا للمشكلة أو التصحيح المطلوب...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _contactController,
          enabled: !_submitting,
          decoration: const InputDecoration(
            labelText: 'وسيلة تواصل اختيارية',
            hintText: 'بريد أو هاتف عند الحاجة للمتابعة',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        if (draft == null)
          const _EmptyToolBox(text: 'لم يتم تثبيت موقع البلاغ بعد.')
        else ...[
          _InfoRow(label: 'موقع البلاغ', value: '${draft.point.latitude.toStringAsFixed(6)}, ${draft.point.longitude.toStringAsFixed(6)}'),
          if (feature != null) _InfoRow(label: 'العنصر المرتبط', value: feature.displayTitle),
          if (feature != null) _InfoRow(label: 'الطبقة', value: feature.layerNameAr ?? feature.layerKey),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: draft == null || _submitting ? null : () => _submitReport(draft),
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload_outlined),
          label: Text(_submitting ? 'جاري الحفظ...' : 'إرسال البلاغ للمراجعة'),
        ),
      ],
    );
  }
}

class MapFeedbackReviewPanel extends ConsumerStatefulWidget {
  const MapFeedbackReviewPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<MapFeedbackReviewPanel> createState() =>
      _MapFeedbackReviewPanelState();
}

class _MapFeedbackReviewPanelState extends ConsumerState<MapFeedbackReviewPanel> {
  String _status = 'new';
  Future<List<MapFeedbackReport>>? _future;
  Future<List<MapFeedbackStatusCount>>? _statsFuture;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _statsFuture = _loadStats();
  }

  Future<List<MapFeedbackReport>> _load() {
    return ref.read(mapFeedbackRepositoryProvider).listReports(
          status: _status,
          limit: 50,
        );
  }

  Future<List<MapFeedbackStatusCount>> _loadStats() {
    return ref.read(mapFeedbackRepositoryProvider).fetchStatusCounts();
  }

  void _refresh({bool includeStats = true}) {
    setState(() {
      _future = _load();
      if (includeStats) _statsFuture = _loadStats();
    });
  }

  Future<void> _review(
    MapFeedbackReport report,
    String status, {
    String? reviewerNote,
  }) async {
    try {
      await ref.read(mapFeedbackRepositoryProvider).reviewReport(
            reportId: report.id,
            newStatus: status,
            reviewerNote: reviewerNote?.trim().isEmpty == true
                ? 'تمت المراجعة من واجهة الخريطة الحديثة.'
                : reviewerNote,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم نقل البلاغ إلى: ${_feedbackStatusLabel(status)}.')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث البلاغ: $e')),
      );
    }
  }

  Future<void> _createAuditTask(
    MapFeedbackReport report, {
    String? description,
  }) async {
    try {
      final task = await ref.read(auditTaskRepositoryProvider).createFromMapFeedback(
            reportId: report.id,
            title: 'مهمة تدقيق بلاغ خريطة: ${report.displayCategory}',
            description: description,
            priority: report.priority,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء مهمة تدقيق فعلية: ${task.title}')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إنشاء مهمة التدقيق: $e')),
      );
    }
  }

  void _changeStatus(String status) {
    setState(() {
      _status = status;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ToolPanelScaffold(
      title: 'مراجعة البلاغات',
      icon: Icons.fact_check_outlined,
      onClose: widget.onClose,
      children: [
        const _HintBox(
          icon: Icons.verified_user_outlined,
          text: 'دورة البلاغات الآن محكومة عبر Supabase RPC: استقبال، فرز، قبول/رفض، ثم إغلاق مع سجل مراجعة مختصر لكل بلاغ.',
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<MapFeedbackStatusCount>>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const _CompactLoadingBox(text: 'جاري تحميل عدادات البلاغات...');
            }
            if (snapshot.hasError) {
              return _EmptyToolBox(text: 'تعذر تحميل العدادات: ${snapshot.error}');
            }
            return _FeedbackStatusChips(
              counts: snapshot.data ?? const [],
              selectedStatus: _status,
              onSelected: _changeStatus,
            );
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: const InputDecoration(
            labelText: 'فلترة حسب الحالة',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: _feedbackStatuses
              .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(_feedbackStatusLabel(status)),
                  ))
              .toList(growable: false),
          onChanged: (v) {
            if (v == null) return;
            _changeStatus(v);
          },
        ),
        const SizedBox(height: 10),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => _refresh(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('تحديث البلاغات'),
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<MapFeedbackReport>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return _EmptyToolBox(text: 'تعذر تحميل البلاغات: ${snapshot.error}');
            }
            final reports = snapshot.data ?? const [];
            if (reports.isEmpty) {
              return const _EmptyToolBox(text: 'لا توجد بلاغات بهذه الحالة.');
            }
            return Column(
              children: reports
                  .map(
                    (report) => _MapFeedbackReportTile(
                      report: report,
                      onReview: (status, note) => _review(
                        report,
                        status,
                        reviewerNote: note,
                      ),
                      onCreateAuditTask: (note) => _createAuditTask(
                        report,
                        description: note,
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _FeedbackStatusChips extends StatelessWidget {
  const _FeedbackStatusChips({
    required this.counts,
    required this.selectedStatus,
    required this.onSelected,
  });

  final List<MapFeedbackStatusCount> counts;
  final String selectedStatus;
  final ValueChanged<String> onSelected;

  int _countFor(String status) {
    for (final item in counts) {
      if (item.status == status) return item.total;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _feedbackStatuses.map((status) {
        final selected = status == selectedStatus;
        return ChoiceChip(
          selected: selected,
          label: Text('${_feedbackStatusLabel(status)} (${_countFor(status)})'),
          onSelected: (_) => onSelected(status),
          selectedColor: PwfColors.royalRed.withValues(alpha: 0.14),
          labelStyle: TextStyle(
            color: selected ? PwfColors.royalRed : PwfColors.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
          side: BorderSide(
            color: selected
                ? PwfColors.royalRed.withValues(alpha: 0.34)
                : PwfColors.outline,
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _MapFeedbackReportTile extends StatelessWidget {
  const _MapFeedbackReportTile({
    required this.report,
    required this.onReview,
    required this.onCreateAuditTask,
  });

  final MapFeedbackReport report;
  final Future<void> Function(String status, String? reviewerNote) onReview;
  final Future<void> Function(String? note) onCreateAuditTask;

  Future<void> _askAndReview(BuildContext context, String status) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('نقل البلاغ إلى: ${_feedbackStatusLabel(status)}'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'ملاحظة المراجع',
            hintText: 'اكتب سبب القرار أو إجراء المتابعة...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('اعتماد'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null) return;
    await onReview(status, note);
  }

  Future<void> _askAndCreateAuditTask(BuildContext context) async {
    final controller = TextEditingController(
      text: report.reviewerNote ?? report.note ?? '',
    );
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء مهمة تدقيق من البلاغ'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'وصف مهمة التدقيق',
            hintText: 'اكتب ما المطلوب تدقيقه أو متابعته ميدانيًا...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            icon: const Icon(Icons.task_alt_outlined),
            label: const Text('إنشاء المهمة'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null) return;
    await onCreateAuditTask(note);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report.displayCategory,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                _StatusPill(status: report.status),
              ],
            ),
            const SizedBox(height: 6),
            if ((report.note ?? '').trim().isNotEmpty)
              Text(
                report.note!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            _InfoRow(label: 'الأولوية', value: _feedbackPriorityLabel(report.priority)),
            _InfoRow(label: 'الموقع', value: report.locationLabel),
            if ((report.sourceFeatureTitle ?? '').trim().isNotEmpty)
              _InfoRow(label: 'العنصر', value: report.sourceFeatureTitle!),
            if ((report.sourceLayerKey ?? '').trim().isNotEmpty)
              _InfoRow(label: 'الطبقة', value: report.sourceLayerKey!),
            if ((report.reviewerNote ?? '').trim().isNotEmpty)
              _InfoRow(label: 'آخر ملاحظة', value: report.reviewerNote!),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _askAndReview(context, 'triaged'),
                  icon: const Icon(Icons.filter_alt_outlined, size: 18),
                  label: const Text('فرز'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _askAndReview(context, 'accepted'),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('قبول'),
                ),
                if (report.status == 'accepted')
                  FilledButton.tonalIcon(
                    onPressed: () => _askAndCreateAuditTask(context),
                    icon: const Icon(Icons.task_alt_outlined, size: 18),
                    label: const Text('مهمة تدقيق'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _askAndReview(context, 'rejected'),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('رفض'),
                ),
                FilledButton.icon(
                  onPressed: () => _askAndReview(context, 'resolved'),
                  icon: const Icon(Icons.done_all_outlined, size: 18),
                  label: const Text('إغلاق'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _MapFeedbackEventsPreview(reportId: report.id),
          ],
        ),
      ),
    );
  }
}

class _MapFeedbackEventsPreview extends ConsumerStatefulWidget {
  const _MapFeedbackEventsPreview({required this.reportId});

  final String reportId;

  @override
  ConsumerState<_MapFeedbackEventsPreview> createState() =>
      _MapFeedbackEventsPreviewState();
}

class _MapFeedbackEventsPreviewState extends ConsumerState<_MapFeedbackEventsPreview> {
  Future<List<MapFeedbackReviewEvent>>? _future;

  void _loadOnce() {
    _future ??= ref
        .read(mapFeedbackRepositoryProvider)
        .listReviewEvents(reportId: widget.reportId, limit: 10);
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: const Text(
        'سجل المراجعة',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
      ),
      onExpansionChanged: (expanded) {
        if (!expanded) return;
        setState(_loadOnce);
      },
      children: [
        if (_future == null)
          const _EmptyToolBox(text: 'افتح السجل لتحميل أحداث المراجعة.')
        else
          FutureBuilder<List<MapFeedbackReviewEvent>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _CompactLoadingBox(text: 'جاري تحميل السجل...');
              }
              if (snapshot.hasError) {
                return _EmptyToolBox(text: 'تعذر تحميل السجل: ${snapshot.error}');
              }
              final events = snapshot.data ?? const [];
              if (events.isEmpty) {
                return const _EmptyToolBox(text: 'لا توجد أحداث مراجعة بعد.');
              }
              return Column(
                children: events
                    .map((event) => _ReviewEventRow(event: event))
                    .toList(growable: false),
              );
            },
          ),
      ],
    );
  }
}

class _ReviewEventRow extends StatelessWidget {
  const _ReviewEventRow({required this.event});

  final MapFeedbackReviewEvent event;

  @override
  Widget build(BuildContext context) {
    final transition = event.oldStatus == null || event.oldStatus!.isEmpty
        ? _feedbackStatusLabel(event.newStatus)
        : '${_feedbackStatusLabel(event.oldStatus!)} ← ${_feedbackStatusLabel(event.newStatus)}';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            transition,
            style: const TextStyle(
              color: PwfColors.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
            ),
          ),
          if ((event.note ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event.note!,
              style: TextStyle(
                color: PwfColors.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: PwfColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.18)),
      ),
      child: Text(
        _feedbackStatusLabel(status),
        style: const TextStyle(
          color: PwfColors.primaryBlue,
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _CompactLoadingBox extends StatelessWidget {
  const _CompactLoadingBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: PwfColors.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> _feedbackStatuses = [
  'new',
  'triaged',
  'accepted',
  'rejected',
  'resolved',
];

String _feedbackStatusLabel(String status) {
  return switch (status) {
    'new' => 'جديد',
    'triaged' => 'قيد الفرز',
    'accepted' => 'مقبول',
    'rejected' => 'مرفوض',
    'resolved' => 'مغلق',
    _ => status,
  };
}

String _feedbackPriorityLabel(String priority) {
  return switch (priority) {
    'low' => 'منخفضة',
    'normal' => 'عادية',
    'high' => 'مرتفعة',
    'urgent' => 'عاجلة',
    _ => priority,
  };
}

class ExportSnapshotToolPanel extends ConsumerWidget {
  const ExportSnapshotToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  Future<void> _copy(
    BuildContext context, {
    required String text,
    required String successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }


  Future<void> _downloadOrCopy(
    BuildContext context, {
    required String fileName,
    required String content,
    required String mimeType,
    required String fallbackMessage,
    required String downloadedMessage,
  }) async {
    final downloaded = await ExplorerExportDownloadService.downloadTextFile(
      fileName: fileName,
      content: content,
      mimeType: mimeType,
    );
    if (!context.mounted) return;
    if (downloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(downloadedMessage)),
      );
      return;
    }
    await _copy(
      context,
      text: content,
      successMessage: fallbackMessage,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapNotifierProvider);
    final snapshot = _ExplorerSnapshotReport.fromState(mapState);

    return _ToolPanelScaffold(
      title: 'تصدير لقطة تشغيل',
      icon: Icons.file_download_outlined,
      onClose: onClose,
      children: [
        const _HintBox(
          icon: Icons.camera_alt_outlined,
          text: 'هذه اللقطة تصدّر حالة تشغيل المستكشف كنص/CSV: نطاق الشاشة، الزوم، الطبقات، الحجب، والكاش. لا تلتقط صورة بصرية من الخريطة ولا تغيّر أي بيانات.',
        ),
        const SizedBox(height: 12),
        _InfoRow(label: 'تاريخ اللقطة', value: snapshot.generatedAt.toIso8601String()),
        _InfoRow(label: 'BBOX', value: snapshot.viewportLabel),
        _InfoRow(label: 'Zoom', value: snapshot.zoomLabel),
        _InfoRow(label: 'العناصر', value: '${snapshot.featureCount}'),
        _InfoRow(label: 'الطبقات المفعلة', value: '${snapshot.activeLayerKeys.length}'),
        _InfoRow(label: 'الطبقات المحمّلة', value: '${snapshot.queryLayerKeys.length}'),
        _InfoRow(label: 'الطبقات المحجوبة', value: '${snapshot.blockedLayerKeys.length}'),
        const SizedBox(height: 10),
        _ExplorerCopyActions(
          primaryLabel: 'نسخ التقرير',
          secondaryLabel: 'نسخ CSV',
          onPrimary: () => _copy(
            context,
            text: snapshot.toSummaryText(),
            successMessage: 'تم نسخ لقطة تشغيل المستكشف.',
          ),
          onSecondary: () => _copy(
            context,
            text: snapshot.toCsvText(),
            successMessage: 'تم نسخ CSV للقطة التشغيل.',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () {
                final stamp = _fileStamp(DateTime.now());
                _downloadOrCopy(
                  context,
                  fileName: 'palwakf_explorer_snapshot_$stamp.txt',
                  content: snapshot.toSummaryText(),
                  mimeType: 'text/plain;charset=utf-8',
                  fallbackMessage: 'تعذر التنزيل، وتم نسخ لقطة التشغيل بدلًا من ذلك.',
                  downloadedMessage: 'تم تنزيل لقطة التشغيل TXT.',
                );
              },
              icon: const Icon(Icons.description_outlined, size: 17),
              label: const Text('تنزيل TXT'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                final stamp = _fileStamp(DateTime.now());
                _downloadOrCopy(
                  context,
                  fileName: 'palwakf_explorer_snapshot_$stamp.csv',
                  content: snapshot.toCsvText(),
                  mimeType: 'text/csv;charset=utf-8',
                  fallbackMessage: 'تعذر التنزيل، وتم نسخ CSV للقطة التشغيل بدلًا من ذلك.',
                  downloadedMessage: 'تم تنزيل لقطة التشغيل CSV.',
                );
              },
              icon: const Icon(Icons.table_chart_outlined, size: 17),
              label: const Text('تنزيل CSV'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SnapshotSection(
          title: 'الطبقات المفعلة',
          values: snapshot.activeLayerKeys,
          emptyText: 'لا توجد طبقات مفعلة.',
        ),
        const SizedBox(height: 10),
        _SnapshotSection(
          title: 'أسباب الحجب',
          values: snapshot.blockedReasons,
          emptyText: 'لا توجد أسباب حجب مسجلة.',
        ),
      ],
    );
  }
}

class LayerHealthToolPanel extends ConsumerWidget {
  const LayerHealthToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  Future<void> _copy(
    BuildContext context, {
    required String text,
    required String successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapNotifierProvider);
    final report = _LayerHealthReport.fromState(mapState);

    return _ToolPanelScaffold(
      title: 'صحة الطبقات',
      icon: Icons.health_and_safety_outlined,
      onClose: onClose,
      children: [
        const _HintBox(
          icon: Icons.shield_outlined,
          text: 'هذه اللوحة تفحص صحة كتالوج الطبقات محليًا: طبقات غير عامة، معطلة، نشطة وغير موجودة في الكتالوج، ومحجوبة بسبب قواعد الأداء.',
        ),
        const SizedBox(height: 12),
        _LayerHealthScoreCard(report: report),
        const SizedBox(height: 12),
        _InfoRow(label: 'إجمالي الكتالوج', value: '${report.totalLayers}'),
        _InfoRow(label: 'عام وفعال', value: '${report.publicActiveLayers}'),
        _InfoRow(label: 'غير عام', value: '${report.privateLayers.length}'),
        _InfoRow(label: 'معطل', value: '${report.disabledLayers.length}'),
        _InfoRow(label: 'نشط خارج الكتالوج', value: '${report.orphanActiveKeys.length}'),
        _InfoRow(label: 'محجوب تشغيلًا', value: '${report.blockedLayerKeys.length}'),
        const SizedBox(height: 10),
        _ExplorerCopyActions(
          primaryLabel: 'نسخ تقرير الصحة',
          secondaryLabel: 'نسخ CSV',
          onPrimary: () => _copy(
            context,
            text: report.toSummaryText(),
            successMessage: 'تم نسخ تقرير صحة الطبقات.',
          ),
          onSecondary: () => _copy(
            context,
            text: report.toCsvText(),
            successMessage: 'تم نسخ CSV لصحة الطبقات.',
          ),
        ),
        const SizedBox(height: 12),
        _SnapshotSection(
          title: 'تنبيهات الصحة',
          values: report.alerts,
          emptyText: 'لا توجد تنبيهات صحة حالية.',
        ),
      ],
    );
  }
}

class ModernExplorerOverlayToolPanel extends ConsumerWidget {
  const ModernExplorerOverlayToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  Future<void> _copy(
    BuildContext context, {
    required String text,
    required String successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapNotifierProvider);
    final report = _ModernOverlayReport.fromState(mapState);

    return _ToolPanelScaffold(
      title: 'Modern Explorer Overlay',
      icon: Icons.travel_explore_outlined,
      onClose: onClose,
      children: [
        const _HintBox(
          icon: Icons.account_tree_outlined,
          text: 'هذه اللوحة تراجع مؤشرات التراكب الإداري الحديث: حدود المحافظات/الهيئات المحملة، الطبقات الوقفية/المكانية النشطة، وجاهزية الربط ضمن BBOX الحالي.',
        ),
        const SizedBox(height: 12),
        _InfoRow(label: 'BBOX', value: report.viewportLabel),
        _InfoRow(label: 'حدود إدارية محملة', value: '${report.boundaryFeatureCount}'),
        _InfoRow(label: 'طبقات وقفية نشطة', value: '${report.waqfLayerKeys.length}'),
        _InfoRow(label: 'طبقات GIS نشطة', value: '${report.gisLayerKeys.length}'),
        _InfoRow(label: 'طبقات تاريخية نشطة', value: '${report.historicalLayerKeys.length}'),
        _InfoRow(label: 'العناصر المحمّلة', value: '${report.loadedFeatureCount}'),
        const SizedBox(height: 10),
        _ExplorerCopyActions(
          primaryLabel: 'نسخ تقرير التراكب',
          secondaryLabel: 'نسخ CSV',
          onPrimary: () => _copy(
            context,
            text: report.toSummaryText(),
            successMessage: 'تم نسخ تقرير Modern Explorer Overlay.',
          ),
          onSecondary: () => _copy(
            context,
            text: report.toCsvText(),
            successMessage: 'تم نسخ CSV لتقرير التراكب.',
          ),
        ),
        const SizedBox(height: 12),
        _SnapshotSection(
          title: 'ملاحظات التراكب',
          values: report.notes,
          emptyText: 'لا توجد ملاحظات تراكب حالية.',
        ),
      ],
    );
  }
}

class _ExplorerSnapshotReport {
  const _ExplorerSnapshotReport({
    required this.generatedAt,
    required this.viewportLabel,
    required this.zoomLabel,
    required this.featureCount,
    required this.activeLayerKeys,
    required this.queryLayerKeys,
    required this.blockedLayerKeys,
    required this.blockedReasons,
    required this.usingOverview,
    required this.servedFromCache,
    required this.simplifyMeters,
    required this.featureLimit,
    required this.boundsPadding,
  });

  final DateTime generatedAt;
  final String viewportLabel;
  final String zoomLabel;
  final int featureCount;
  final List<String> activeLayerKeys;
  final List<String> queryLayerKeys;
  final List<String> blockedLayerKeys;
  final List<String> blockedReasons;
  final bool usingOverview;
  final bool servedFromCache;
  final double simplifyMeters;
  final int featureLimit;
  final double boundsPadding;

  factory _ExplorerSnapshotReport.fromState(MapState state) {
    final runtime = state.runtimeInfo;
    return _ExplorerSnapshotReport(
      generatedAt: DateTime.now(),
      viewportLabel: _viewportLabel(state.viewport),
      zoomLabel: state.zoom.toStringAsFixed(2),
      featureCount: state.gisFeatures.length,
      activeLayerKeys: List<String>.from(state.activeLayers),
      queryLayerKeys: List<String>.from(runtime.queryLayerKeys),
      blockedLayerKeys: List<String>.from(runtime.blockedLayerKeys),
      blockedReasons: List<String>.from(runtime.blockedReasons),
      usingOverview: runtime.usingNaturalBlocksOverview,
      servedFromCache: runtime.servedFromCache,
      simplifyMeters: runtime.simplifyMeters,
      featureLimit: runtime.featureLimit,
      boundsPadding: runtime.boundsPadding,
    );
  }

  String toSummaryText() {
    final buffer = StringBuffer()
      ..writeln('لقطة تشغيل المستكشف - PalWakf')
      ..writeln('تاريخ الإنشاء: ${generatedAt.toIso8601String()}')
      ..writeln('BBOX: $viewportLabel')
      ..writeln('Zoom: $zoomLabel')
      ..writeln('العناصر المحمّلة: $featureCount')
      ..writeln('الطبقات المفعلة: ${activeLayerKeys.length}')
      ..writeln(activeLayerKeys.isEmpty ? '- لا يوجد' : activeLayerKeys.map((e) => '- $e').join('\n'))
      ..writeln('الطبقات المحمّلة فعليًا: ${queryLayerKeys.length}')
      ..writeln(queryLayerKeys.isEmpty ? '- لا يوجد' : queryLayerKeys.map((e) => '- $e').join('\n'))
      ..writeln('الطبقات المحجوبة: ${blockedLayerKeys.length}')
      ..writeln(blockedReasons.isEmpty ? '- لا يوجد' : blockedReasons.map((e) => '- $e').join('\n'))
      ..writeln('Natural Blocks Overview: ${usingOverview ? 'نعم' : 'لا'}')
      ..writeln('Cache: ${servedFromCache ? 'نعم' : 'لا'}')
      ..writeln('Simplify meters: $simplifyMeters')
      ..writeln('Feature limit: $featureLimit')
      ..writeln('Bounds padding: $boundsPadding');
    return buffer.toString();
  }

  String toCsvText() {
    final rows = <List<String>>[
      ['metric', 'value'],
      ['generated_at', generatedAt.toIso8601String()],
      ['bbox', viewportLabel],
      ['zoom', zoomLabel],
      ['feature_count', '$featureCount'],
      ['active_layers', activeLayerKeys.join('|')],
      ['query_layers', queryLayerKeys.join('|')],
      ['blocked_layers', blockedLayerKeys.join('|')],
      ['blocked_reasons', blockedReasons.join('|')],
      ['using_overview', '$usingOverview'],
      ['served_from_cache', '$servedFromCache'],
      ['simplify_meters', '$simplifyMeters'],
      ['feature_limit', '$featureLimit'],
      ['bounds_padding', '$boundsPadding'],
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }
}

class _LayerHealthReport {
  const _LayerHealthReport({
    required this.totalLayers,
    required this.publicActiveLayers,
    required this.privateLayers,
    required this.disabledLayers,
    required this.orphanActiveKeys,
    required this.blockedLayerKeys,
    required this.alerts,
  });

  final int totalLayers;
  final int publicActiveLayers;
  final List<String> privateLayers;
  final List<String> disabledLayers;
  final List<String> orphanActiveKeys;
  final List<String> blockedLayerKeys;
  final List<String> alerts;

  int get score {
    if (totalLayers == 0) return 0;
    final penalty = privateLayers.length + disabledLayers.length + orphanActiveKeys.length + blockedLayerKeys.length;
    final raw = 100 - ((penalty / totalLayers) * 35).round();
    return raw.clamp(0, 100).toInt();
  }

  factory _LayerHealthReport.fromState(MapState state) {
    final catalogKeys = state.gisLayers.map((e) => e.key).toSet();
    final privateLayers = state.gisLayers
        .where((layer) => !layer.isPublic)
        .map((layer) => layer.key)
        .toList(growable: false);
    final disabledLayers = state.gisLayers
        .where((layer) => !layer.isActive)
        .map((layer) => layer.key)
        .toList(growable: false);
    final orphanActiveKeys = state.activeLayers
        .where((key) => !catalogKeys.contains(key))
        .toList(growable: false);
    final blockedLayerKeys = List<String>.from(state.runtimeInfo.blockedLayerKeys);
    final alerts = <String>[
      if (state.gisLayers.isEmpty) 'كتالوج الطبقات غير محمّل.',
      if (orphanActiveKeys.isNotEmpty) 'توجد مفاتيح طبقات مفعلة وغير موجودة في الكتالوج.',
      if (blockedLayerKeys.isNotEmpty) 'توجد طبقات محجوبة بسبب الزوم أو قواعد الأداء.',
      if (privateLayers.isNotEmpty) 'توجد طبقات غير عامة داخل الكتالوج.',
      if (disabledLayers.isNotEmpty) 'توجد طبقات معطلة داخل الكتالوج.',
      if (state.viewport == null) 'BBOX غير جاهز؛ لن يكون التحميل المكاني مكتملًا.',
      if (state.gisError != null && state.gisError!.trim().isNotEmpty) 'يوجد خطأ GIS حالي: ${state.gisError}',
    ];
    return _LayerHealthReport(
      totalLayers: state.gisLayers.length,
      publicActiveLayers: state.gisLayers.where((layer) => layer.isActive && layer.isPublic).length,
      privateLayers: privateLayers,
      disabledLayers: disabledLayers,
      orphanActiveKeys: orphanActiveKeys,
      blockedLayerKeys: blockedLayerKeys,
      alerts: alerts,
    );
  }

  String toSummaryText() {
    final buffer = StringBuffer()
      ..writeln('تقرير صحة الطبقات - PalWakf')
      ..writeln('الدرجة: $score%')
      ..writeln('إجمالي الكتالوج: $totalLayers')
      ..writeln('عام وفعال: $publicActiveLayers')
      ..writeln('غير عام: ${privateLayers.length}')
      ..writeln('معطل: ${disabledLayers.length}')
      ..writeln('نشط خارج الكتالوج: ${orphanActiveKeys.length}')
      ..writeln('محجوب تشغيلًا: ${blockedLayerKeys.length}')
      ..writeln('---');
    if (alerts.isEmpty) {
      buffer.writeln('لا توجد تنبيهات صحة حالية.');
    } else {
      for (final alert in alerts) {
        buffer.writeln('- $alert');
      }
    }
    return buffer.toString();
  }

  String toCsvText() {
    final rows = <List<String>>[
      ['metric', 'value'],
      ['score', '$score'],
      ['total_layers', '$totalLayers'],
      ['public_active_layers', '$publicActiveLayers'],
      ['private_layers', privateLayers.join('|')],
      ['disabled_layers', disabledLayers.join('|')],
      ['orphan_active_keys', orphanActiveKeys.join('|')],
      ['blocked_layer_keys', blockedLayerKeys.join('|')],
      ['alerts', alerts.join('|')],
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }
}

class _ModernOverlayReport {
  const _ModernOverlayReport({
    required this.viewportLabel,
    required this.boundaryFeatureCount,
    required this.loadedFeatureCount,
    required this.waqfLayerKeys,
    required this.gisLayerKeys,
    required this.historicalLayerKeys,
    required this.notes,
  });

  final String viewportLabel;
  final int boundaryFeatureCount;
  final int loadedFeatureCount;
  final List<String> waqfLayerKeys;
  final List<String> gisLayerKeys;
  final List<String> historicalLayerKeys;
  final List<String> notes;

  factory _ModernOverlayReport.fromState(MapState state) {
    final layerByKey = {for (final layer in state.gisLayers) layer.key: layer};
    List<String> byCategory(LayerCategory category) => state.activeLayers
        .where((key) => layerByKey[key]?.category == category)
        .toList(growable: false);
    final notes = <String>[
      if (state.viewport == null) 'لا يوجد BBOX جاهز للتراكب.',
      if (state.modernExplorerBoundaryFeatures.isEmpty) 'لم تُحمّل حدود إدارية حديثة ضمن حالة الخريطة الحالية.',
      if (state.activeLayers.isEmpty) 'لا توجد طبقات مفعّلة للتراكب.',
      if (state.gisFeatures.isEmpty) 'لا توجد عناصر محمّلة للتحليل ضمن BBOX الحالي.',
      if (state.runtimeInfo.hasBlockedLayers) 'بعض الطبقات محجوبة حاليًا بسبب قواعد الأداء أو الزوم.',
    ];
    return _ModernOverlayReport(
      viewportLabel: _viewportLabel(state.viewport),
      boundaryFeatureCount: state.modernExplorerBoundaryFeatures.length,
      loadedFeatureCount: state.gisFeatures.length,
      waqfLayerKeys: byCategory(LayerCategory.waqf),
      gisLayerKeys: byCategory(LayerCategory.gis),
      historicalLayerKeys: byCategory(LayerCategory.historical),
      notes: notes,
    );
  }

  String toSummaryText() {
    final buffer = StringBuffer()
      ..writeln('تقرير Modern Explorer Overlay - PalWakf')
      ..writeln('BBOX: $viewportLabel')
      ..writeln('حدود إدارية محملة: $boundaryFeatureCount')
      ..writeln('العناصر المحمّلة: $loadedFeatureCount')
      ..writeln('طبقات وقفية: ${waqfLayerKeys.join('|')}')
      ..writeln('طبقات GIS: ${gisLayerKeys.join('|')}')
      ..writeln('طبقات تاريخية: ${historicalLayerKeys.join('|')}')
      ..writeln('---');
    if (notes.isEmpty) {
      buffer.writeln('لا توجد ملاحظات تراكب حالية.');
    } else {
      for (final note in notes) {
        buffer.writeln('- $note');
      }
    }
    return buffer.toString();
  }

  String toCsvText() {
    final rows = <List<String>>[
      ['metric', 'value'],
      ['bbox', viewportLabel],
      ['boundary_feature_count', '$boundaryFeatureCount'],
      ['loaded_feature_count', '$loadedFeatureCount'],
      ['waqf_layers', waqfLayerKeys.join('|')],
      ['gis_layers', gisLayerKeys.join('|')],
      ['historical_layers', historicalLayerKeys.join('|')],
      ['notes', notes.join('|')],
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }
}

class _LayerHealthScoreCard extends StatelessWidget {
  const _LayerHealthScoreCard({required this.report});

  final _LayerHealthReport report;

  @override
  Widget build(BuildContext context) {
    final color = report.score >= 80
        ? PwfColors.success
        : report.score >= 55
            ? PwfColors.warning
            : PwfColors.royalRed;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.health_and_safety_outlined, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'درجة صحة الطبقات: ${report.score}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplorerCopyActions extends StatelessWidget {
  const _ExplorerCopyActions({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: onPrimary,
          icon: const Icon(Icons.copy_all_outlined, size: 17),
          label: Text(primaryLabel),
        ),
        OutlinedButton.icon(
          onPressed: onSecondary,
          icon: const Icon(Icons.table_chart_outlined, size: 17),
          label: Text(secondaryLabel),
        ),
      ],
    );
  }
}

class _SnapshotSection extends StatelessWidget {
  const _SnapshotSection({
    required this.title,
    required this.values,
    required this.emptyText,
  });

  final String title;
  final List<String> values;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final visibleValues = values.where((value) => value.trim().isNotEmpty).take(12).toList(growable: false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: PwfColors.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 8),
          if (visibleValues.isEmpty)
            Text(
              emptyText,
              style: TextStyle(
                color: PwfColors.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            )
          else
            ...visibleValues.map(
              (value) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 6, color: PwfColors.primaryBlue),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: PwfColors.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
class DataGapsToolPanel extends ConsumerWidget {
  const DataGapsToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  Future<void> _copyToClipboard(
    BuildContext context, {
    required String text,
    required String successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapNotifierProvider);
    final report = _buildDataGapsAuditReport(mapState);
    final gaps = report.gaps;
    return _ToolPanelScaffold(
      title: 'تقرير فجوات البيانات',
      icon: Icons.rule_folder_outlined,
      onClose: onClose,
      children: [
        const _HintBox(
          icon: Icons.info_outline,
          text: 'هذا تقرير تدقيق تشغيلي للعناصر المحمّلة داخل BBOX الحالي فقط. لا يستبدل التقرير السيادي الكامل ولا يحمّل طبقات إضافية.',
        ),
        const SizedBox(height: 12),
        _InfoRow(label: 'العناصر الظاهرة', value: '${report.totalFeatures}'),
        _InfoRow(label: 'الطبقات المفعلة', value: '${report.activeLayersCount}'),
        _InfoRow(label: 'مستوى الزوم', value: report.zoomLabel),
        _InfoRow(label: 'نطاق الشاشة', value: report.viewportLabel),
        const SizedBox(height: 10),
        _DataGapsExportActions(
          report: report,
          onCopySummary: () => _copyToClipboard(
            context,
            text: report.toSummaryText(),
            successMessage: 'تم نسخ ملخص تقرير فجوات البيانات.',
          ),
          onCopyCsv: () => _copyToClipboard(
            context,
            text: report.toCsvText(),
            successMessage: 'تم نسخ CSV لتقرير فجوات البيانات.',
          ),
        ),
        const SizedBox(height: 12),
        if (gaps.isEmpty)
          const _EmptyToolBox(text: 'لا توجد فجوات واضحة ضمن العناصر المحمّلة حاليًا.')
        else ...[
          _DataGapsSummaryStrip(gaps: gaps),
          const SizedBox(height: 10),
          ...gaps.map((gap) => _GapTile(gap: gap)),
        ],
      ],
    );
  }
}

class ExplorerBookmarksToolPanel extends ConsumerStatefulWidget {
  const ExplorerBookmarksToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<ExplorerBookmarksToolPanel> createState() =>
      _ExplorerBookmarksToolPanelState();
}

class _ExplorerBookmarksToolPanelState
    extends ConsumerState<ExplorerBookmarksToolPanel> {
  late final TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _copy(
    BuildContext context, {
    required String text,
    required String successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }

  Future<void> _downloadOrCopy(
    BuildContext context, {
    required String fileName,
    required String content,
    required String mimeType,
    required String copiedMessage,
    required String downloadedMessage,
  }) async {
    final downloaded = await ExplorerExportDownloadService.downloadTextFile(
      fileName: fileName,
      content: content,
      mimeType: mimeType,
    );
    if (!context.mounted) return;
    if (downloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(downloadedMessage)),
      );
      return;
    }
    await _copy(
      context,
      text: content,
      successMessage: copiedMessage,
    );
  }

  String _bookmarksJsonText(List<ExplorerMapBookmark> bookmarks) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(bookmarks.map((item) => item.toJson()).toList());
  }

  Future<void> _persistBookmarks(
    BuildContext context,
    List<ExplorerMapBookmark> bookmarks,
  ) async {
    final saved = await ExplorerBookmarkStorage.saveBookmarks(
      bookmarks.map((item) => item.toJson()).toList(growable: false),
    );
    if (!context.mounted) return;
    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ العروض محليًا في المتصفح.')),
      );
      return;
    }
    await _copy(
      context,
      text: _bookmarksJsonText(bookmarks),
      successMessage: 'التخزين المحلي غير متاح هنا، وتم نسخ JSON للعروض بدلًا من ذلك.',
    );
  }

  Future<void> _loadPersistedBookmarks(BuildContext context) async {
    final rows = await ExplorerBookmarkStorage.loadBookmarks();
    final restored = rows
        .map(ExplorerMapBookmark.fromJson)
        .whereType<ExplorerMapBookmark>()
        .take(12)
        .toList(growable: false);
    ref.read(explorerMapBookmarksProvider.notifier).state = restored;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تحميل ${restored.length} عرضًا محفوظًا.')),
    );
  }

  Future<void> _clearPersistedBookmarks(BuildContext context) async {
    ref.read(explorerMapBookmarksProvider.notifier).state = const [];
    final cleared = await ExplorerBookmarkStorage.clearBookmarks();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cleared
              ? 'تم مسح العروض من الجلسة والتخزين المحلي.'
              : 'تم مسح عروض الجلسة. التخزين المحلي غير متاح في هذه البيئة.',
        ),
      ),
    );
  }

  Future<void> _exportBookmarks(
    BuildContext context,
    List<ExplorerMapBookmark> bookmarks,
  ) async {
    final stamp = _fileStamp(DateTime.now());
    await _downloadOrCopy(
      context,
      fileName: 'palwakf_explorer_bookmarks_$stamp.json',
      content: _bookmarksJsonText(bookmarks),
      mimeType: 'application/json;charset=utf-8',
      copiedMessage: 'تم نسخ JSON للعروض المحفوظة.',
      downloadedMessage: 'تم تنزيل ملف JSON للعروض المحفوظة.',
    );
  }

  void _saveBookmark() {
    final state = ref.read(mapNotifierProvider);
    final viewport = state.viewport;
    if (viewport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن حفظ العرض قبل جاهزية BBOX.')),
      );
      return;
    }
    final now = DateTime.now();
    final title = _titleCtrl.text.trim().isEmpty
        ? 'عرض محفوظ ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'
        : _titleCtrl.text.trim();
    final bookmark = ExplorerMapBookmark(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      createdAt: now,
      zoom: state.zoom,
      centerLat: (viewport.south + viewport.north) / 2,
      centerLng: (viewport.west + viewport.east) / 2,
      west: viewport.west,
      south: viewport.south,
      east: viewport.east,
      north: viewport.north,
      layerKeys: List<String>.from(state.activeLayers),
    );
    final current = ref.read(explorerMapBookmarksProvider);
    ref.read(explorerMapBookmarksProvider.notifier).state = [
      bookmark,
      ...current,
    ].take(12).toList(growable: false);
    _titleCtrl.clear();
  }

  Future<void> _restoreBookmark(ExplorerMapBookmark bookmark) async {
    await ref.read(mapNotifierProvider.notifier).setActiveLayers(bookmark.layerKeys);
    ref.read(mapControllerProvider).move(
          LatLng(bookmark.centerLat, bookmark.centerLng),
          bookmark.zoom,
        );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapNotifierProvider);
    final bookmarks = ref.watch(explorerMapBookmarksProvider);
    return _ToolPanelScaffold(
      title: 'العروض المحفوظة',
      icon: Icons.bookmarks_outlined,
      onClose: widget.onClose,
      children: [
        const _HintBox(
          icon: Icons.bookmark_add_outlined,
          text: 'احفظ BBOX/Zoom/الطبقات الحالية كعرض تشغيل سريع. يمكن حفظه محليًا في المتصفح أو تنزيله كـ JSON، أما التخزين السيادي SQL/RBAC فمؤجل لمسار اعتماد لاحق.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'اسم العرض',
            hintText: 'مثال: تدقيق أوقاف بيت لحم',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: mapState.viewport == null ? null : _saveBookmark,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('حفظ العرض الحالي'),
            ),
            OutlinedButton.icon(
              onPressed: () => _loadPersistedBookmarks(context),
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('تحميل المحلي'),
            ),
            OutlinedButton.icon(
              onPressed: bookmarks.isEmpty
                  ? null
                  : () => _persistBookmarks(context, bookmarks),
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ محلي'),
            ),
            OutlinedButton.icon(
              onPressed: bookmarks.isEmpty
                  ? null
                  : () => _exportBookmarks(context, bookmarks),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('تنزيل JSON'),
            ),
            TextButton.icon(
              onPressed: bookmarks.isEmpty
                  ? null
                  : () => _clearPersistedBookmarks(context),
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('مسح العروض'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (bookmarks.isEmpty)
          const _EmptyToolBox(text: 'لا توجد عروض محفوظة في هذه الجلسة.')
        else
          ...bookmarks.map(
            (bookmark) => _BookmarkTile(
              bookmark: bookmark,
              onRestore: () => _restoreBookmark(bookmark),
              onCopy: () => _copy(
                context,
                text: bookmark.toSummaryText(),
                successMessage: 'تم نسخ بيانات العرض المحفوظ.',
              ),
              onDelete: () {
                final next = ref
                    .read(explorerMapBookmarksProvider)
                    .where((item) => item.id != bookmark.id)
                    .toList(growable: false);
                ref.read(explorerMapBookmarksProvider.notifier).state = next;
              },
            ),
          ),
      ],
    );
  }
}

class LayerPresetsGovernanceToolPanel extends ConsumerWidget {
  const LayerPresetsGovernanceToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ تقرير حوكمة حزم الطبقات.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapNotifierProvider);
    final rows = _buildPresetGovernanceRows(state.gisLayers);
    final report = _presetGovernanceReport(rows);
    return _ToolPanelScaffold(
      title: 'حوكمة حزم الطبقات',
      icon: Icons.rule_outlined,
      onClose: onClose,
      children: [
        const _HintBox(
          icon: Icons.policy_outlined,
          text: 'هذه اللوحة تراجع الحزم التشغيلية الموجودة في المستكشف: فتح خفيف، تدقيق وقفي، والأحواض الطبيعية. لا تعدّل تعريفات الطبقات ولا تكتب SQL.',
        ),
        const SizedBox(height: 12),
        _ExplorerCopyActions(
          primaryLabel: 'نسخ التقرير',
          secondaryLabel: 'نسخ CSV',
          onPrimary: () => _copy(context, report.summary),
          onSecondary: () => _copy(context, report.csv),
        ),
        const SizedBox(height: 12),
        ...rows.map((row) => _PresetGovernanceCard(row: row)),
      ],
    );
  }
}

class PrintExportLayoutToolPanel extends ConsumerWidget {
  const PrintExportLayoutToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ قالب الطباعة/التصدير.')),
    );
  }

  Future<void> _downloadOrCopy(
    BuildContext context, {
    required String fileName,
    required String content,
    required String mimeType,
    required String fallbackMessage,
    required String downloadedMessage,
  }) async {
    final downloaded = await ExplorerExportDownloadService.downloadTextFile(
      fileName: fileName,
      content: content,
      mimeType: mimeType,
    );
    if (!context.mounted) return;
    if (downloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(downloadedMessage)),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(fallbackMessage)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapNotifierProvider);
    final layout = _PrintLayoutDraft.fromState(state);
    return _ToolPanelScaffold(
      title: 'قالب طباعة / تصدير',
      icon: Icons.print_outlined,
      onClose: onClose,
      children: [
        const _HintBox(
          icon: Icons.print_outlined,
          text: 'ينشئ ملفات تنزيل فعلية TXT/CSV/HTML للطباعة من حالة الخريطة الحالية. ملف HTML قابل للفتح في المتصفح والطباعة، أما PDF النهائي فيبقى مرحلة لاحقة عند اعتماد مكتبة تصدير رسمية.',
        ),
        const SizedBox(height: 12),
        _InfoRow(label: 'العنوان', value: layout.title),
        _InfoRow(label: 'النطاق', value: layout.viewportLabel),
        _InfoRow(label: 'Zoom', value: layout.zoomLabel),
        _InfoRow(label: 'الطبقات', value: '${layout.activeLayerKeys.length}'),
        _InfoRow(label: 'العناصر', value: '${layout.featureCount}'),
        _InfoRow(label: 'تذييل', value: layout.footer),
        const SizedBox(height: 10),
        _ExplorerCopyActions(
          primaryLabel: 'نسخ القالب',
          secondaryLabel: 'نسخ CSV',
          onPrimary: () => _copy(context, layout.toSummaryText()),
          onSecondary: () => _copy(context, layout.toCsvText()),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () {
                final stamp = _fileStamp(DateTime.now());
                _downloadOrCopy(
                  context,
                  fileName: 'palwakf_explorer_print_$stamp.html',
                  content: layout.toHtmlText(),
                  mimeType: 'text/html;charset=utf-8',
                  fallbackMessage: 'تعذر التنزيل في هذه البيئة، وتم نسخ HTML بدلًا من ذلك.',
                  downloadedMessage: 'تم تنزيل قالب HTML للطباعة.',
                );
              },
              icon: const Icon(Icons.print_outlined, size: 17),
              label: const Text('تنزيل HTML'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                final stamp = _fileStamp(DateTime.now());
                _downloadOrCopy(
                  context,
                  fileName: 'palwakf_explorer_print_$stamp.txt',
                  content: layout.toSummaryText(),
                  mimeType: 'text/plain;charset=utf-8',
                  fallbackMessage: 'تعذر التنزيل في هذه البيئة، وتم نسخ TXT بدلًا من ذلك.',
                  downloadedMessage: 'تم تنزيل ملف TXT للقالب.',
                );
              },
              icon: const Icon(Icons.description_outlined, size: 17),
              label: const Text('تنزيل TXT'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                final stamp = _fileStamp(DateTime.now());
                _downloadOrCopy(
                  context,
                  fileName: 'palwakf_explorer_print_$stamp.csv',
                  content: layout.toCsvText(),
                  mimeType: 'text/csv;charset=utf-8',
                  fallbackMessage: 'تعذر التنزيل في هذه البيئة، وتم نسخ CSV بدلًا من ذلك.',
                  downloadedMessage: 'تم تنزيل CSV للقالب.',
                );
              },
              icon: const Icon(Icons.table_chart_outlined, size: 17),
              label: const Text('تنزيل CSV'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SnapshotSection(
          title: 'عناصر ستظهر في الطباعة لاحقًا',
          values: layout.checklist,
          emptyText: 'لا توجد عناصر قالب.',
        ),
      ],
    );
  }
}

class MeasurementReportToolPanel extends ConsumerWidget {
  const MeasurementReportToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ تقرير القياس.')),
    );
  }

  Future<void> _downloadOrCopy(
    BuildContext context, {
    required String fileName,
    required String content,
    required String mimeType,
    required String fallbackMessage,
    required String downloadedMessage,
  }) async {
    final downloaded = await ExplorerExportDownloadService.downloadTextFile(
      fileName: fileName,
      content: content,
      mimeType: mimeType,
    );
    if (!context.mounted) return;
    if (downloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(downloadedMessage)),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(fallbackMessage)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapNotifierProvider);
    final mode = ref.watch(measureModeProvider);
    final points = ref.watch(measurePointsProvider);
    final label = ref.watch(measureResultLabelProvider);
    final report = _MeasurementReportDraft.fromState(
      mapState: mapState,
      mode: mode,
      points: points,
      resultLabel: label,
    );
    return _ToolPanelScaffold(
      title: 'تقرير القياس',
      icon: Icons.assessment_outlined,
      onClose: onClose,
      children: [
        const _HintBox(
          icon: Icons.straighten,
          text: 'يلخص هذا التقرير القياسات الحالية ضمن المستكشف، مع BBOX والطبقات النشطة، لنسخه في محاضر التدقيق أو طلبات المراجعة.',
        ),
        const SizedBox(height: 12),
        _InfoRow(label: 'نوع القياس', value: report.modeLabel),
        _InfoRow(label: 'عدد النقاط', value: '${report.pointCount}'),
        _InfoRow(label: 'النتيجة', value: report.resultLabel),
        _InfoRow(label: 'النطاق', value: report.viewportLabel),
        const SizedBox(height: 10),
        _ExplorerCopyActions(
          primaryLabel: 'نسخ التقرير',
          secondaryLabel: 'نسخ CSV',
          onPrimary: () => _copy(context, report.toSummaryText()),
          onSecondary: () => _copy(context, report.toCsvText()),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () {
                final stamp = _fileStamp(DateTime.now());
                _downloadOrCopy(
                  context,
                  fileName: 'palwakf_measurement_report_$stamp.txt',
                  content: report.toSummaryText(),
                  mimeType: 'text/plain;charset=utf-8',
                  fallbackMessage: 'تعذر التنزيل في هذه البيئة، وتم نسخ التقرير بدلًا من ذلك.',
                  downloadedMessage: 'تم تنزيل تقرير القياس TXT.',
                );
              },
              icon: const Icon(Icons.description_outlined, size: 17),
              label: const Text('تنزيل TXT'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                final stamp = _fileStamp(DateTime.now());
                _downloadOrCopy(
                  context,
                  fileName: 'palwakf_measurement_report_$stamp.csv',
                  content: report.toCsvText(),
                  mimeType: 'text/csv;charset=utf-8',
                  fallbackMessage: 'تعذر التنزيل في هذه البيئة، وتم نسخ CSV بدلًا من ذلك.',
                  downloadedMessage: 'تم تنزيل تقرير القياس CSV.',
                );
              },
              icon: const Icon(Icons.table_chart_outlined, size: 17),
              label: const Text('تنزيل CSV'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SnapshotSection(
          title: 'نقاط القياس',
          values: report.pointLabels,
          emptyText: 'لا توجد نقاط قياس حالية.',
        ),
      ],
    );
  }
}

class ToolPermissionsPanel extends ConsumerWidget {
  const ToolPermissionsPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audience = ref.watch(mapToolAudienceProvider);
    final permissions = _toolPermissionRows(audience);
    return _ToolPanelScaffold(
      title: 'صلاحيات أدوات المستكشف',
      icon: Icons.admin_panel_settings_outlined,
      onClose: onClose,
      children: [
        _HintBox(
          icon: Icons.verified_user_outlined,
          text: 'وضعك الحالي داخل صندوق أدوات المستكشف: ${audience.labelAr}. هذه واجهة عرض فقط؛ تبقى الحماية النهائية في RLS/RBAC.',
        ),
        const SizedBox(height: 12),
        ...permissions.map((row) => _ToolPermissionTile(row: row)),
      ],
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({
    required this.bookmark,
    required this.onRestore,
    required this.onCopy,
    required this.onDelete,
  });

  final ExplorerMapBookmark bookmark;
  final VoidCallback onRestore;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bookmark.title,
            style: const TextStyle(
              color: PwfColors.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          _InfoRow(label: 'المركز', value: bookmark.centerLabel),
          _InfoRow(label: 'Zoom', value: bookmark.zoom.toStringAsFixed(2)),
          _InfoRow(label: 'الطبقات', value: '${bookmark.layerKeys.length}'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              FilledButton.icon(
                onPressed: onRestore,
                icon: const Icon(Icons.travel_explore_outlined, size: 16),
                label: const Text('استعادة'),
              ),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: const Text('نسخ'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('حذف'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetGovernanceRow {
  const _PresetGovernanceRow({
    required this.name,
    required this.description,
    required this.layerKeys,
    required this.riskLabel,
  });

  final String name;
  final String description;
  final List<String> layerKeys;
  final String riskLabel;
}

class _PresetGovernanceReport {
  const _PresetGovernanceReport({required this.summary, required this.csv});
  final String summary;
  final String csv;
}

class _PresetGovernanceCard extends StatelessWidget {
  const _PresetGovernanceCard({required this.row});
  final _PresetGovernanceRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.name,
            style: const TextStyle(
              color: PwfColors.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            row.description,
            style: TextStyle(
              color: PwfColors.onSurface.withValues(alpha: 0.70),
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'الطبقات', value: '${row.layerKeys.length}'),
          _InfoRow(label: 'المخاطر', value: row.riskLabel),
          _SnapshotSection(
            title: 'مفاتيح الطبقات',
            values: row.layerKeys,
            emptyText: 'لم يتم العثور على طبقات مطابقة لهذه الحزمة.',
          ),
        ],
      ),
    );
  }
}

class _PrintLayoutDraft {
  const _PrintLayoutDraft({
    required this.title,
    required this.viewportLabel,
    required this.zoomLabel,
    required this.activeLayerKeys,
    required this.featureCount,
    required this.footer,
    required this.checklist,
  });

  final String title;
  final String viewportLabel;
  final String zoomLabel;
  final List<String> activeLayerKeys;
  final int featureCount;
  final String footer;
  final List<String> checklist;

  static _PrintLayoutDraft fromState(MapState state) {
    final generatedAt = DateTime.now().toIso8601String();
    return _PrintLayoutDraft(
      title: 'مستكشف الوقف - لقطة تشغيلية',
      viewportLabel: _viewportLabel(state.viewport),
      zoomLabel: state.zoom.toStringAsFixed(2),
      activeLayerKeys: List<String>.from(state.activeLayers),
      featureCount: state.gisFeatures.length,
      footer: 'PalWakf / Mustakshif • $generatedAt',
      checklist: [
        'عنوان الخريطة والجهة المالكة للبيانات.',
        'BBOX ومستوى التكبير وقت التصدير.',
        'قائمة الطبقات النشطة والمحجوبة.',
        'ملاحظة أن اللقطة تشغيلية وليست سندًا مساحيًا نهائيًا.',
      ],
    );
  }

  String toSummaryText() {
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln('BBOX: $viewportLabel')
      ..writeln('Zoom: $zoomLabel')
      ..writeln('العناصر: $featureCount')
      ..writeln('الطبقات: ${activeLayerKeys.join('|')}')
      ..writeln('Footer: $footer');
    return buffer.toString();
  }

  String toCsvText() {
    final rows = <List<String>>[
      ['metric', 'value'],
      ['title', title],
      ['bbox', viewportLabel],
      ['zoom', zoomLabel],
      ['feature_count', '$featureCount'],
      ['active_layers', activeLayerKeys.join('|')],
      ['footer', footer],
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }

  String toHtmlText() {
    final layerRows = activeLayerKeys.isEmpty
        ? '<li>لا توجد طبقات مفعلة.</li>'
        : activeLayerKeys
            .map((layer) => '<li>${_htmlEscape(layer)}</li>')
            .join();
    final checklistRows = checklist
        .map((item) => '<li>${_htmlEscape(item)}</li>')
        .join();
    return '''<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <title>${_htmlEscape(title)}</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 32px; color: #111827; direction: rtl; }
    .card { border: 1px solid #d1d5db; border-radius: 14px; padding: 18px; margin-bottom: 16px; }
    h1 { color: #0B4F8A; margin-top: 0; }
    h2 { color: #B22222; font-size: 18px; }
    .meta { font-weight: 700; line-height: 1.9; }
    .footer { color: #6b7280; margin-top: 24px; font-size: 12px; }
  </style>
</head>
<body>
  <h1>${_htmlEscape(title)}</h1>
  <div class="card meta">
    <div>النطاق: ${_htmlEscape(viewportLabel)}</div>
    <div>Zoom: ${_htmlEscape(zoomLabel)}</div>
    <div>عدد العناصر: $featureCount</div>
  </div>
  <div class="card">
    <h2>الطبقات النشطة</h2>
    <ul>$layerRows</ul>
  </div>
  <div class="card">
    <h2>قائمة التحقق</h2>
    <ul>$checklistRows</ul>
  </div>
  <div class="footer">${_htmlEscape(footer)} • هذه لقطة تشغيلية وليست سندًا مساحيًا نهائيًا.</div>
</body>
</html>''';
  }
}

class _MeasurementReportDraft {
  const _MeasurementReportDraft({
    required this.modeLabel,
    required this.pointCount,
    required this.resultLabel,
    required this.viewportLabel,
    required this.activeLayerKeys,
    required this.pointLabels,
  });

  final String modeLabel;
  final int pointCount;
  final String resultLabel;
  final String viewportLabel;
  final List<String> activeLayerKeys;
  final List<String> pointLabels;

  static _MeasurementReportDraft fromState({
    required MapState mapState,
    required MeasureMode? mode,
    required List<LatLng> points,
    required String? resultLabel,
  }) {
    final modeLabel = mode == null
        ? 'غير مفعل'
        : (mode == MeasureMode.distance ? 'مسافة' : 'مساحة');
    return _MeasurementReportDraft(
      modeLabel: modeLabel,
      pointCount: points.length,
      resultLabel: resultLabel ?? 'لم تكتمل نتيجة القياس بعد.',
      viewportLabel: _viewportLabel(mapState.viewport),
      activeLayerKeys: List<String>.from(mapState.activeLayers),
      pointLabels: points
          .asMap()
          .entries
          .map((entry) =>
              '${entry.key + 1}. ${entry.value.latitude.toStringAsFixed(6)}, ${entry.value.longitude.toStringAsFixed(6)}')
          .toList(growable: false),
    );
  }

  String toSummaryText() {
    final buffer = StringBuffer()
      ..writeln('تقرير قياس - PalWakf Mustakshif')
      ..writeln('نوع القياس: $modeLabel')
      ..writeln('عدد النقاط: $pointCount')
      ..writeln('النتيجة: $resultLabel')
      ..writeln('BBOX: $viewportLabel')
      ..writeln('الطبقات: ${activeLayerKeys.join('|')}')
      ..writeln('---');
    if (pointLabels.isEmpty) {
      buffer.writeln('لا توجد نقاط قياس مسجلة.');
    } else {
      for (final point in pointLabels) {
        buffer.writeln(point);
      }
    }
    return buffer.toString();
  }

  String toCsvText() {
    final rows = <List<String>>[
      ['metric', 'value'],
      ['mode', modeLabel],
      ['point_count', '$pointCount'],
      ['result', resultLabel],
      ['bbox', viewportLabel],
      ['active_layers', activeLayerKeys.join('|')],
      ['points', pointLabels.join('|')],
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }
}


class ExplorerRealMapInteractionsToolPanel extends ConsumerWidget {
  const ExplorerRealMapInteractionsToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  void _activateMode(WidgetRef ref, ExplorerRealMapInteractionMode mode) {
    ref.read(realMapInteractionModeProvider.notifier).state = mode;
    ref.read(activeToolsSubPanelProvider.notifier).state =
        ToolsSubPanel.realInteractions;
    if (mode != ExplorerRealMapInteractionMode.selectionBox) {
      ref.read(selectionBoxPointsProvider.notifier).state = const [];
    }
    ref.read(drawEditingProvider.notifier).state = false;
    ref.read(drawShapeTypeProvider.notifier).state = null;
    ref.read(drawPointsProvider.notifier).state = const [];
    ref.read(measureModeProvider.notifier).state = null;
  }

  void _startMeasure(WidgetRef ref, MeasureMode mode) {
    ref.read(realMapInteractionModeProvider.notifier).state = null;
    ref.read(selectionBoxPointsProvider.notifier).state = const [];
    ref.read(activeToolsSubPanelProvider.notifier).state =
        ToolsSubPanel.realInteractions;
    ref.read(drawEditingProvider.notifier).state = false;
    ref.read(drawShapeTypeProvider.notifier).state = null;
    ref.read(drawPointsProvider.notifier).state = const [];
    ref.read(measureModeProvider.notifier).state = mode;
    ref.read(measureEditingProvider.notifier).state = true;
    ref.read(measurePointsProvider.notifier).state = const [];
    ref.read(measureResultLabelProvider.notifier).state = null;
  }

  Future<void> _copy(
    BuildContext context, {
    required String text,
    required String successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }

  Future<void> _downloadOrCopy(
    BuildContext context, {
    required String fileName,
    required String content,
    required String mimeType,
    required String fallbackMessage,
    required String downloadedMessage,
  }) async {
    final downloaded = await ExplorerExportDownloadService.downloadTextFile(
      fileName: fileName,
      content: content,
      mimeType: mimeType,
    );
    if (!context.mounted) return;
    if (downloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(downloadedMessage)),
      );
      return;
    }
    await _copy(
      context,
      text: content,
      successMessage: fallbackMessage,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapNotifierProvider);
    final mode = ref.watch(realMapInteractionModeProvider);
    final lastTap = ref.watch(lastTapLatLngProvider);
    final selectionPoints = ref.watch(selectionBoxPointsProvider);
    final measureMode = ref.watch(measureModeProvider);
    final measurePoints = ref.watch(measurePointsProvider);
    final measureLabel = ref.watch(measureResultLabelProvider);
    final identifyResult = ref.watch(identifyResultProvider);
    final selectedFeatures = _featuresInSelectionBox(
      mapState.gisFeatures,
      selectionPoints,
    );
    final exportDraft = _RealInteractionExportDraft.fromState(
      mapState: mapState,
      lastTap: lastTap,
      mode: mode,
      selectionPoints: selectionPoints,
      selectedFeatures: selectedFeatures,
      measureMode: measureMode,
      measurePoints: measurePoints,
      measureResultLabel: measureLabel,
      identifyResult: identifyResult,
    );

    return _ToolPanelScaffold(
      title: 'أدوات التفاعل الحقيقي',
      icon: Icons.touch_app_outlined,
      onClose: onClose,
      children: [
        const _HintBox(
          icon: Icons.ads_click_outlined,
          text:
              'هذه اللوحة تشغّل التفاعل الحقيقي مع الخريطة: تعريف عنصر، التقاط إحداثية، تحديد نطاق بنقطتين، قياس مسافة/مساحة، ثم تصدير المعالم المحددة محليًا من العناصر المحمّلة ضمن BBOX الحالي.',
        ),
        const SizedBox(height: 12),
        _InfoRow(label: 'وضع التفاعل', value: mode?.labelAr ?? 'غير مفعل'),
        _InfoRow(
          label: 'آخر نقطة',
          value: lastTap == null
              ? 'غير محددة'
              : '${lastTap.latitude.toStringAsFixed(6)}, ${lastTap.longitude.toStringAsFixed(6)}',
        ),
        _InfoRow(label: 'نقاط نطاق التحديد', value: '${selectionPoints.length}/2'),
        _InfoRow(label: 'المعالم داخل النطاق', value: '${selectedFeatures.length}'),
        _InfoRow(
          label: 'القياس النشط',
          value: measureMode == null
              ? 'غير مفعل'
              : (measureMode == MeasureMode.distance ? 'مسافة' : 'مساحة'),
        ),
        if (measureLabel != null) _InfoRow(label: 'نتيجة القياس', value: measureLabel),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => _activateMode(
                ref,
                ExplorerRealMapInteractionMode.identify,
              ),
              icon: const Icon(Icons.ads_click_outlined, size: 17),
              label: const Text('تفعيل Identify'),
            ),
            OutlinedButton.icon(
              onPressed: () => _activateMode(
                ref,
                ExplorerRealMapInteractionMode.coordinatePicker,
              ),
              icon: const Icon(Icons.gps_fixed, size: 17),
              label: const Text('التقاط إحداثية'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(selectionBoxPointsProvider.notifier).state = const [];
                _activateMode(ref, ExplorerRealMapInteractionMode.selectionBox);
              },
              icon: const Icon(Icons.crop_free_outlined, size: 17),
              label: const Text('تحديد نطاق'),
            ),
            OutlinedButton.icon(
              onPressed: () => _startMeasure(ref, MeasureMode.distance),
              icon: const Icon(Icons.timeline_outlined, size: 17),
              label: const Text('قياس مسافة'),
            ),
            OutlinedButton.icon(
              onPressed: () => _startMeasure(ref, MeasureMode.area),
              icon: const Icon(Icons.crop_square_outlined, size: 17),
              label: const Text('قياس مساحة'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SnapshotSection(
          title: 'المعالم المحددة للتصدير',
          values: selectedFeatures
              .take(12)
              .map((feature) => '${feature.displayTitle} • ${feature.layerKey}')
              .toList(growable: false),
          emptyText:
              'حدد نطاقًا بنقطتين على الخريطة ليتم استخراج المعالم المحمّلة داخله محليًا.',
        ),
        const SizedBox(height: 10),
        _ExplorerCopyActions(
          primaryLabel: 'نسخ تقرير التفاعل',
          secondaryLabel: 'نسخ CSV',
          onPrimary: () => _copy(
            context,
            text: exportDraft.toSummaryText(),
            successMessage: 'تم نسخ تقرير التفاعل الحقيقي.',
          ),
          onSecondary: () => _copy(
            context,
            text: exportDraft.toCsvText(),
            successMessage: 'تم نسخ CSV للتفاعل الحقيقي.',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: selectedFeatures.isEmpty
                  ? null
                  : () {
                      final stamp = _fileStamp(DateTime.now());
                      _downloadOrCopy(
                        context,
                        fileName:
                            'palwakf_selected_features_$stamp.csv',
                        content: exportDraft.toSelectedFeaturesCsvText(),
                        mimeType: 'text/csv;charset=utf-8',
                        fallbackMessage:
                            'تعذر التنزيل، وتم نسخ CSV للمعالم المحددة.',
                        downloadedMessage: 'تم تنزيل CSV للمعالم المحددة.',
                      );
                    },
              icon: const Icon(Icons.download_outlined, size: 17),
              label: const Text('تنزيل المعالم CSV'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(realMapInteractionModeProvider.notifier).state = null;
                ref.read(selectionBoxPointsProvider.notifier).state = const [];
                ref.read(measureModeProvider.notifier).state = null;
                ref.read(measureEditingProvider.notifier).state = false;
                ref.read(measurePointsProvider.notifier).state = const [];
                ref.read(measureResultLabelProvider.notifier).state = null;
              },
              icon: const Icon(Icons.clear_all_outlined, size: 17),
              label: const Text('مسح التفاعل'),
            ),
          ],
        ),
      ],
    );
  }
}

class _RealInteractionExportDraft {
  const _RealInteractionExportDraft({
    required this.generatedAt,
    required this.viewportLabel,
    required this.zoomLabel,
    required this.activeLayerKeys,
    required this.lastTapLabel,
    required this.modeLabel,
    required this.selectionLabels,
    required this.selectedFeatures,
    required this.measureLabel,
    required this.identifyLabel,
  });

  final DateTime generatedAt;
  final String viewportLabel;
  final String zoomLabel;
  final List<String> activeLayerKeys;
  final String lastTapLabel;
  final String modeLabel;
  final List<String> selectionLabels;
  final List<GisFeatureModel> selectedFeatures;
  final String measureLabel;
  final String identifyLabel;

  static _RealInteractionExportDraft fromState({
    required MapState mapState,
    required LatLng? lastTap,
    required ExplorerRealMapInteractionMode? mode,
    required List<LatLng> selectionPoints,
    required List<GisFeatureModel> selectedFeatures,
    required MeasureMode? measureMode,
    required List<LatLng> measurePoints,
    required String? measureResultLabel,
    required MapIdentifyResult? identifyResult,
  }) {
    final modeLabel = mode?.labelAr ?? 'غير مفعل';
    final lastTapLabel = lastTap == null
        ? 'غير محددة'
        : '${lastTap.latitude.toStringAsFixed(6)}, ${lastTap.longitude.toStringAsFixed(6)}';
    final measureName = measureMode == null
        ? 'غير مفعل'
        : (measureMode == MeasureMode.distance ? 'مسافة' : 'مساحة');
    final measureLabel = '$measureName • نقاط: ${measurePoints.length} • ${measureResultLabel ?? 'لا توجد نتيجة بعد'}';
    final identifyLabel = identifyResult == null
        ? 'لا يوجد Identify'
        : '${identifyResult.feature?.displayTitle ?? 'بدون عنصر'} • ${identifyResult.source}';

    return _RealInteractionExportDraft(
      generatedAt: DateTime.now(),
      viewportLabel: _viewportLabel(mapState.viewport),
      zoomLabel: mapState.zoom.toStringAsFixed(2),
      activeLayerKeys: List<String>.from(mapState.activeLayers),
      lastTapLabel: lastTapLabel,
      modeLabel: modeLabel,
      selectionLabels: selectionPoints
          .asMap()
          .entries
          .map((entry) =>
              '${entry.key + 1}. ${entry.value.latitude.toStringAsFixed(6)}, ${entry.value.longitude.toStringAsFixed(6)}')
          .toList(growable: false),
      selectedFeatures: selectedFeatures,
      measureLabel: measureLabel,
      identifyLabel: identifyLabel,
    );
  }

  String toSummaryText() {
    final buffer = StringBuffer()
      ..writeln('تقرير أدوات التفاعل الحقيقي - PalWakf Mustakshif')
      ..writeln('التاريخ: ${generatedAt.toIso8601String()}')
      ..writeln('BBOX: $viewportLabel')
      ..writeln('Zoom: $zoomLabel')
      ..writeln('الوضع: $modeLabel')
      ..writeln('آخر نقطة: $lastTapLabel')
      ..writeln('نقاط نطاق التحديد: ${selectionLabels.join(' | ')}')
      ..writeln('المعالم المحددة: ${selectedFeatures.length}')
      ..writeln('القياس: $measureLabel')
      ..writeln('Identify: $identifyLabel')
      ..writeln('الطبقات: ${activeLayerKeys.join('|')}')
      ..writeln('--- المعالم ---');
    if (selectedFeatures.isEmpty) {
      buffer.writeln('لا توجد معالم محددة للتصدير.');
    } else {
      for (final feature in selectedFeatures.take(50)) {
        buffer.writeln('${feature.id} • ${feature.displayTitle} • ${feature.layerKey}');
      }
    }
    return buffer.toString();
  }

  String toCsvText() {
    final rows = <List<String>>[
      ['metric', 'value'],
      ['generated_at', generatedAt.toIso8601String()],
      ['bbox', viewportLabel],
      ['zoom', zoomLabel],
      ['mode', modeLabel],
      ['last_tap', lastTapLabel],
      ['selection_points', selectionLabels.join('|')],
      ['selected_features_count', '${selectedFeatures.length}'],
      ['measure', measureLabel],
      ['identify', identifyLabel],
      ['active_layers', activeLayerKeys.join('|')],
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }

  String toSelectedFeaturesCsvText() {
    final rows = <List<String>>[
      ['id', 'title', 'layer_key', 'layer_name', 'lat', 'lng'],
      ...selectedFeatures.map((feature) {
        final point = _featureReferencePoint(feature);
        return [
          feature.id,
          feature.displayTitle,
          feature.layerKey,
          feature.layerNameAr ?? '',
          point?.latitude.toStringAsFixed(6) ?? '',
          point?.longitude.toStringAsFixed(6) ?? '',
        ];
      }),
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }
}

List<GisFeatureModel> _featuresInSelectionBox(
  List<GisFeatureModel> features,
  List<LatLng> selectionPoints,
) {
  if (selectionPoints.length < 2) return const [];
  final a = selectionPoints[0];
  final b = selectionPoints[1];
  final minLat = a.latitude < b.latitude ? a.latitude : b.latitude;
  final maxLat = a.latitude > b.latitude ? a.latitude : b.latitude;
  final minLng = a.longitude < b.longitude ? a.longitude : b.longitude;
  final maxLng = a.longitude > b.longitude ? a.longitude : b.longitude;

  return features.where((feature) {
    final point = _featureReferencePoint(feature);
    if (point == null) return false;
    return point.latitude >= minLat &&
        point.latitude <= maxLat &&
        point.longitude >= minLng &&
        point.longitude <= maxLng;
  }).toList(growable: false);
}

LatLng? _featureReferencePoint(GisFeatureModel feature) {
  return _latLngFromGeoJsonPoint(feature.centroid) ??
      _latLngFromGeoJsonPoint(feature.geom) ??
      _latLngFromAnyGeometry(feature.geom);
}

LatLng? _latLngFromGeoJsonPoint(Map<String, dynamic>? geometry) {
  if (geometry == null) return null;
  if (geometry['type'] != 'Point') return null;
  final coords = geometry['coordinates'];
  if (coords is! List || coords.length < 2) return null;
  final lng = (coords[0] as num?)?.toDouble();
  final lat = (coords[1] as num?)?.toDouble();
  if (lat == null || lng == null) return null;
  return LatLng(lat, lng);
}

LatLng? _latLngFromAnyGeometry(Map<String, dynamic>? geometry) {
  if (geometry == null) return null;
  final coords = geometry['coordinates'];
  if (coords is! List) return null;
  final flat = <num>[];
  void scan(dynamic value) {
    if (flat.length >= 2) return;
    if (value is num) {
      flat.add(value);
      return;
    }
    if (value is List) {
      for (final item in value) {
        scan(item);
        if (flat.length >= 2) break;
      }
    }
  }

  scan(coords);
  if (flat.length < 2) return null;
  return LatLng(flat[1].toDouble(), flat[0].toDouble());
}
class _ToolPermissionRow {
  const _ToolPermissionRow({
    required this.title,
    required this.allowed,
    required this.scope,
  });

  final String title;
  final bool allowed;
  final String scope;
}

class _ToolPermissionTile extends StatelessWidget {
  const _ToolPermissionTile({required this.row});
  final _ToolPermissionRow row;

  @override
  Widget build(BuildContext context) {
    final color = row.allowed ? PwfColors.success : PwfColors.royalRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(row.allowed ? Icons.check_circle_outline : Icons.lock_outline,
              size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  row.scope,
                  style: TextStyle(
                    color: PwfColors.onSurface.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<_PresetGovernanceRow> _buildPresetGovernanceRows(
  List<GisLayerModel> layers,
) {
  List<String> findKeys(List<String> tokens) {
    return layers
        .where((layer) {
          if (!layer.isActive || !layer.isPublic) return false;
          final haystack = [layer.key, layer.nameAr, layer.nameEn ?? '']
              .join(' ')
              .toLowerCase();
          return tokens.any((token) => haystack.contains(token));
        })
        .map((layer) => layer.key)
        .take(12)
        .toList(growable: false);
  }

  return [
    _PresetGovernanceRow(
      name: 'فتح خفيف',
      description: 'طبقات حدودية عامة لا تحمّل التفاصيل الثقيلة عند فتح الخريطة.',
      layerKeys: findKeys(['palestine', 'westbank', 'governorate', 'lgu', 'حدود', 'المحافظ']),
      riskLabel: 'منخفضة',
    ),
    _PresetGovernanceRow(
      name: 'تدقيق وقفي ميداني',
      description: 'طبقات نقطية/وقفية مناسبة للتدقيق الأولي دون تحميل كل القطع.',
      layerKeys: findKeys(['gis_waqf', 'mosque', 'cemeter', 'maqam', 'وقف', 'مسجد', 'مقبرة', 'مقام']),
      riskLabel: 'متوسطة: تحتاج BBOX واضح عند التشغيل.',
    ),
    _PresetGovernanceRow(
      name: 'الأحواض الطبيعية',
      description: 'طبقة أحواض كبيرة يجب أن تبقى محكومة بالزوم والـ overview.',
      layerKeys: findKeys(['natural_blocks_full', 'natural_blocks_overview', 'حوض', 'الأحواض']),
      riskLabel: 'مرتفعة إن فُتحت دون Zoom/BBOX.',
    ),
  ];
}

_PresetGovernanceReport _presetGovernanceReport(
  List<_PresetGovernanceRow> rows,
) {
  final summary = StringBuffer()
    ..writeln('تقرير حوكمة حزم الطبقات - PalWakf')
    ..writeln('---');
  for (final row in rows) {
    summary
      ..writeln(row.name)
      ..writeln('الوصف: ${row.description}')
      ..writeln('المخاطر: ${row.riskLabel}')
      ..writeln('الطبقات: ${row.layerKeys.join('|')}')
      ..writeln('---');
  }
  final csvRows = <List<String>>[
    ['preset', 'risk', 'layer_count', 'layers'],
    ...rows.map((row) => [
          row.name,
          row.riskLabel,
          '${row.layerKeys.length}',
          row.layerKeys.join('|'),
        ]),
  ];
  return _PresetGovernanceReport(
    summary: summary.toString(),
    csv: csvRows.map((row) => row.map(_csvCell).join(',')).join('\n'),
  );
}

List<_ToolPermissionRow> _toolPermissionRows(MapToolAudience audience) {
  final employee = audience.canUseEmployeeTools;
  final manager = audience.canUseManagerTools;
  return [
    _ToolPermissionRow(
      title: 'العرض والبحث والمشاركة',
      allowed: true,
      scope: 'متاحة للجمهور دون بيانات حساسة أو تعديل.',
    ),
    _ToolPermissionRow(
      title: 'Identify / Snapshot / قياس / Bookmarks / تفاعل حقيقي',
      allowed: employee,
      scope: 'تحتاج موظفًا أو مدير خريطة لأنها تعرض سياقًا تشغيليًا.',
    ),
    _ToolPermissionRow(
      title: 'فجوات البيانات ومركز التشغيل وحزمة التشغيل الكبرى',
      allowed: employee,
      scope: 'تُظهر نتائج تشغيلية ضمن BBOX الحالي ولا تعتمد كقرار سيادي.',
    ),
    _ToolPermissionRow(
      title: 'إدارة الطبقات وحوكمة الحزم والمقارنة',
      allowed: manager,
      scope: 'مخصصة لمدير الخريطة أو من يملك صلاحيات إدارة الطبقات.',
    ),
    _ToolPermissionRow(
      title: 'الاستيراد أو التعديل السيادي',
      allowed: false,
      scope: 'خارج أدوات الخريطة الحالية ويجب أن يمر عبر Admin/RBAC/RLS.',
    ),
  ];
}

class _ToolPanelScaffold extends StatelessWidget {
  const _ToolPanelScaffold({
    required this.title,
    required this.icon,
    required this.onClose,
    required this.children,
  });

  final String title;
  final IconData icon;
  final VoidCallback onClose;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _Header(title: title, onClose: onClose),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PwfColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: PwfColors.primaryBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: PwfColors.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyToolBox extends StatelessWidget {
  const _EmptyToolBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: PwfColors.onSurface.withValues(alpha: 0.62),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
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
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                color: PwfColors.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                color: PwfColors.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropsPreview extends StatelessWidget {
  const _PropsPreview({required this.props});
  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final entries = props.entries
        .where((entry) => entry.value != null && entry.value.toString().trim().isNotEmpty)
        .take(8)
        .toList(growable: false);
    if (entries.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'حقول مختصرة',
            style: TextStyle(
              color: PwfColors.royalRed,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...entries.map((entry) => _InfoRow(label: entry.key, value: entry.value.toString())),
        ],
      ),
    );
  }
}

class _DataGapsAuditReport {
  const _DataGapsAuditReport({
    required this.generatedAt,
    required this.totalFeatures,
    required this.activeLayersCount,
    required this.zoom,
    required this.viewportLabel,
    required this.gaps,
  });

  final DateTime generatedAt;
  final int totalFeatures;
  final int activeLayersCount;
  final double zoom;
  final String viewportLabel;
  final List<_DataGap> gaps;

  String get zoomLabel => zoom.toStringAsFixed(1);
  int get totalGapItems => gaps.fold<int>(0, (sum, gap) => sum + gap.count);

  String toSummaryText() {
    final buffer = StringBuffer()
      ..writeln('تقرير فجوات البيانات - PalWakf')
      ..writeln('تاريخ الإنشاء: ${generatedAt.toIso8601String()}')
      ..writeln('العناصر الظاهرة: $totalFeatures')
      ..writeln('الطبقات المفعلة: $activeLayersCount')
      ..writeln('مستوى الزوم: $zoomLabel')
      ..writeln('نطاق الشاشة: $viewportLabel')
      ..writeln('إجمالي مؤشرات الفجوات: $totalGapItems')
      ..writeln('---');
    if (gaps.isEmpty) {
      buffer.writeln('لا توجد فجوات واضحة ضمن العناصر المحمّلة حاليًا.');
    } else {
      for (final gap in gaps) {
        buffer
          ..writeln('${gap.title}: ${gap.count}')
          ..writeln('الأولوية: ${gap.priorityLabel}')
          ..writeln(gap.description);
        if (gap.examples.isNotEmpty) {
          buffer.writeln('أمثلة:');
          for (final example in gap.examples.take(5)) {
            buffer.writeln('- ${example.layerKey} | ${example.title} | ${example.id}');
          }
        }
        buffer.writeln('---');
      }
    }
    return buffer.toString();
  }

  String toCsvText() {
    final rows = <List<String>>[
      ['gap_code', 'gap_title', 'priority', 'layer_key', 'feature_id', 'feature_title', 'governorate', 'lgu', 'reason'],
    ];
    for (final gap in gaps) {
      if (gap.examples.isEmpty) {
        rows.add([gap.code, gap.title, gap.priorityLabel, '', '', '', '', '', gap.description]);
      } else {
        for (final example in gap.examples) {
          rows.add([
            gap.code,
            gap.title,
            gap.priorityLabel,
            example.layerKey,
            example.id,
            example.title,
            example.governorate,
            example.lgu,
            gap.description,
          ]);
        }
      }
    }
    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }
}

class _DataGap {
  const _DataGap({
    required this.code,
    required this.title,
    required this.count,
    required this.description,
    required this.priority,
    this.examples = const [],
  });

  final String code;
  final String title;
  final int count;
  final String description;
  final int priority;
  final List<_GapExample> examples;

  String get priorityLabel {
    if (priority >= 3) return 'عالية';
    if (priority == 2) return 'متوسطة';
    return 'منخفضة';
  }
}

class _GapExample {
  const _GapExample({
    required this.layerKey,
    required this.id,
    required this.title,
    required this.governorate,
    required this.lgu,
  });

  final String layerKey;
  final String id;
  final String title;
  final String governorate;
  final String lgu;
}

_DataGapsAuditReport _buildDataGapsAuditReport(MapState mapState) {
  bool isEmptyValue(dynamic value) => value == null || value.toString().trim().isEmpty;
  final features = mapState.gisFeatures;

  List<_GapExample> examplesWhere(bool Function(dynamic feature) test) {
    return features.where(test).take(50).map(_gapExampleFromFeature).toList(growable: false);
  }

  final noGeometryExamples = examplesWhere((f) => f.geom == null && f.centroid == null);
  final noTitleExamples = examplesWhere((f) => f.displayTitle.trim().isEmpty || f.displayTitle == f.id);
  final noLguExamples = examplesWhere(
    (f) => isEmptyValue(f.props['lgusn']) &&
        isEmptyValue(f.props['lgu_name']) &&
        isEmptyValue(f.props['lgus_code']) &&
        isEmptyValue(f.props['lgus_xcode']),
  );
  final noGovExamples = examplesWhere(
    (f) => isEmptyValue(f.props['governorate']) &&
        isEmptyValue(f.props['governor01']) &&
        isEmptyValue(f.props['governorate_no']),
  );
  final duplicateExamples = _possibleDuplicateExamples(features);

  final gaps = <_DataGap>[
    if (noGeometryExamples.isNotEmpty)
      _DataGap(
        code: 'missing_geometry',
        title: 'عناصر بلا هندسة',
        count: features.where((f) => f.geom == null && f.centroid == null).length,
        description: 'تحتاج ربطًا مكانيًا أو نقطة مركزية قبل اعتمادها في التحليل المكاني.',
        priority: 3,
        examples: noGeometryExamples,
      ),
    if (noTitleExamples.isNotEmpty)
      _DataGap(
        code: 'missing_display_title',
        title: 'عناصر بلا اسم واضح',
        count: features.where((f) => f.displayTitle.trim().isEmpty || f.displayTitle == f.id).length,
        description: 'العنوان الظاهر غير كافٍ للعرض أو البحث ويحتاج حقل اسم عربي/إنجليزي واضح.',
        priority: 2,
        examples: noTitleExamples,
      ),
    if (noLguExamples.isNotEmpty)
      _DataGap(
        code: 'missing_lgu',
        title: 'عناصر بلا هيئة محلية',
        count: features.where((f) => isEmptyValue(f.props['lgusn']) && isEmptyValue(f.props['lgu_name']) && isEmptyValue(f.props['lgus_code']) && isEmptyValue(f.props['lgus_xcode'])).length,
        description: 'لا يظهر لها lgusn أو كود هيئة محلية، وهذا يؤثر على فلترة المستكشف الحديثة.',
        priority: 3,
        examples: noLguExamples,
      ),
    if (noGovExamples.isNotEmpty)
      _DataGap(
        code: 'missing_governorate',
        title: 'عناصر بلا محافظة',
        count: features.where((f) => isEmptyValue(f.props['governorate']) && isEmptyValue(f.props['governor01']) && isEmptyValue(f.props['governorate_no'])).length,
        description: 'لا يظهر لها حقل محافظة موثوق، وهذا يضعف الفلترة والربط الإداري.',
        priority: 2,
        examples: noGovExamples,
      ),
    if (duplicateExamples.isNotEmpty)
      _DataGap(
        code: 'possible_duplicates',
        title: 'تكرار محتمل',
        count: duplicateExamples.length,
        description: 'أسماء متكررة ضمن نفس الطبقة ونطاق العرض الحالي وتحتاج مراجعة قبل الدمج أو الربط.',
        priority: 2,
        examples: duplicateExamples,
      ),
  ];

  return _DataGapsAuditReport(
    generatedAt: DateTime.now(),
    totalFeatures: features.length,
    activeLayersCount: mapState.activeLayers.length,
    zoom: mapState.zoom,
    viewportLabel: _viewportLabel(mapState.viewport),
    gaps: gaps,
  );
}

_GapExample _gapExampleFromFeature(dynamic feature) {
  String firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  return _GapExample(
    layerKey: feature.layerKey?.toString() ?? '',
    id: feature.id?.toString() ?? '',
    title: feature.displayTitle?.toString() ?? '',
    governorate: firstNonEmpty([
      feature.props['governorate'],
      feature.props['governor01'],
      feature.props['governorate_no'],
    ]),
    lgu: firstNonEmpty([
      feature.props['lgusn'],
      feature.props['lgu_name'],
      feature.props['lgus_code'],
      feature.props['lgus_xcode'],
    ]),
  );
}

List<_GapExample> _possibleDuplicateExamples(List<dynamic> features) {
  final buckets = <String, List<dynamic>>{};
  for (final dynamic f in features) {
    final title = f.displayTitle?.toString().trim().toLowerCase() ?? '';
    if (title.isEmpty || title == f.id?.toString().toLowerCase()) continue;
    final key = '${f.layerKey}|$title';
    buckets.putIfAbsent(key, () => <dynamic>[]).add(f);
  }
  return buckets.values
      .where((items) => items.length > 1)
      .expand((items) => items)
      .take(50)
      .map(_gapExampleFromFeature)
      .toList(growable: false);
}

String _viewportLabel(ViewportBounds? viewport) {
  if (viewport == null) return 'غير محدد';
  return 'W:${viewport.west.toStringAsFixed(4)} S:${viewport.south.toStringAsFixed(4)} E:${viewport.east.toStringAsFixed(4)} N:${viewport.north.toStringAsFixed(4)}';
}

String _csvCell(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}


String _fileStamp(DateTime dateTime) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${dateTime.year}${two(dateTime.month)}${two(dateTime.day)}_'
      '${two(dateTime.hour)}${two(dateTime.minute)}${two(dateTime.second)}';
}

String _htmlEscape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

class _DataGapsExportActions extends StatelessWidget {
  const _DataGapsExportActions({
    required this.report,
    required this.onCopySummary,
    required this.onCopyCsv,
  });

  final _DataGapsAuditReport report;
  final VoidCallback onCopySummary;
  final VoidCallback onCopyCsv;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تصدير تقرير التدقيق',
            style: TextStyle(
              color: PwfColors.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'يعتمد التصدير على العناصر المحمّلة الآن فقط، ويصلح كقائمة عمل أولية للمراجعة.',
            style: TextStyle(
              color: PwfColors.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
              fontSize: 11.2,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: report.totalFeatures == 0 ? null : onCopySummary,
                icon: const Icon(Icons.summarize_outlined, size: 18),
                label: const Text('نسخ الملخص'),
              ),
              FilledButton.tonalIcon(
                onPressed: report.totalFeatures == 0 ? null : onCopyCsv,
                icon: const Icon(Icons.table_chart_outlined, size: 18),
                label: const Text('نسخ CSV'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataGapsSummaryStrip extends StatelessWidget {
  const _DataGapsSummaryStrip({required this.gaps});

  final List<_DataGap> gaps;

  @override
  Widget build(BuildContext context) {
    final high = gaps.where((gap) => gap.priority >= 3).fold<int>(0, (sum, gap) => sum + gap.count);
    final medium = gaps.where((gap) => gap.priority == 2).fold<int>(0, (sum, gap) => sum + gap.count);
    final low = gaps.where((gap) => gap.priority <= 1).fold<int>(0, (sum, gap) => sum + gap.count);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MiniStatPill(label: 'عالية', value: high, color: PwfColors.royalRed),
        _MiniStatPill(label: 'متوسطة', value: medium, color: PwfColors.primaryGold),
        _MiniStatPill(label: 'منخفضة', value: low, color: PwfColors.primaryBlue),
      ],
    );
  }
}

class _MiniStatPill extends StatelessWidget {
  const _MiniStatPill({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _GapTile extends StatelessWidget {
  const _GapTile({required this.gap});
  final _DataGap gap;

  @override
  Widget build(BuildContext context) {
    final examples = gap.examples.take(3).toList(growable: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PwfColors.royalRed.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${gap.count}',
              style: const TextStyle(
                color: PwfColors.royalRed,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        gap.title,
                        style: const TextStyle(
                          color: PwfColors.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: PwfColors.primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        gap.priorityLabel,
                        style: const TextStyle(
                          color: PwfColors.primaryBlue,
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  gap.description,
                  style: TextStyle(
                    color: PwfColors.onSurface.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.2,
                    height: 1.35,
                  ),
                ),
                if (examples.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...examples.map(
                    (example) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '• ${example.layerKey} | ${example.title.isEmpty ? example.id : example.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: PwfColors.onSurface.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w800,
                          fontSize: 10.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class ExplorerMegaOpsToolPanel extends ConsumerWidget {
  const ExplorerMegaOpsToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ حزمة تشغيل المستكشف.')),
    );
  }

  Future<void> _downloadOrCopy(
    BuildContext context,
    String text,
    String ext,
    String mime,
  ) async {
    final ok = await ExplorerExportDownloadService.downloadTextFile(
      fileName: 'palwakf_explorer_mega_ops_${_megaStamp()}.$ext',
      content: text,
      mimeType: mime,
    );
    if (!ok) await _copy(context, text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapNotifierProvider);
    final bookmarks = ref.watch(explorerMapBookmarksProvider);
    final report = _ExplorerMegaOpsReport.fromState(state, bookmarks);
    return _ToolPanelScaffold(
      title: 'حزمة تشغيل المستكشف الكبرى',
      icon: Icons.dashboard_customize_outlined,
      onClose: onClose,
      children: [
        const _HintBox(
          icon: Icons.dashboard_customize_outlined,
          text:
              'تجمع هذه الأداة خمسة مسارات تشغيلية داخل المستكشف: تخطيط مهمة، اعتماد الطبقات، ضبط الأداء، QA قبل التصدير، وحزمة توريث. لا تعدّل قاعدة البيانات ولا تعتمد نتيجة سيادية.',
        ),
        const SizedBox(height: 12),
        _MegaScoreCard(report: report),
        const SizedBox(height: 12),
        _MegaSectionCard(
          title: '1) مخطط مهمة ميدانية',
          icon: Icons.route_outlined,
          lines: report.missionLines,
        ),
        _MegaSectionCard(
          title: '2) تحليل اعتماد الطبقات',
          icon: Icons.account_tree_outlined,
          lines: report.dependencyLines,
        ),
        _MegaSectionCard(
          title: '3) ضبط الأداء التشغيلي',
          icon: Icons.speed_outlined,
          lines: report.performanceLines,
        ),
        _MegaSectionCard(
          title: '4) بوابة QA قبل التصدير',
          icon: Icons.verified_outlined,
          lines: report.qaLines,
        ),
        _MegaSectionCard(
          title: '5) توريث وتشغيل لاحق',
          icon: Icons.inventory_2_outlined,
          lines: report.handoffLines,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _copy(context, report.toText()),
              icon: const Icon(Icons.copy_outlined),
              label: const Text('نسخ'),
            ),
            OutlinedButton.icon(
              onPressed: () => _downloadOrCopy(
                context,
                report.toText(),
                'txt',
                'text/plain;charset=utf-8',
              ),
              icon: const Icon(Icons.description_outlined),
              label: const Text('TXT'),
            ),
            OutlinedButton.icon(
              onPressed: () => _downloadOrCopy(
                context,
                report.toCsv(),
                'csv',
                'text/csv;charset=utf-8',
              ),
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('CSV'),
            ),
            OutlinedButton.icon(
              onPressed: () => _downloadOrCopy(
                context,
                report.toHtml(),
                'html',
                'text/html;charset=utf-8',
              ),
              icon: const Icon(Icons.html_outlined),
              label: const Text('HTML'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    ref.read(activeToolsSubPanelProvider.notifier).state =
                        ToolsSubPanel.operations,
                icon: const Icon(Icons.space_dashboard_outlined),
                label: const Text('مركز التشغيل'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    ref.read(activeToolSectionProvider.notifier).state =
                        ToolSection.layers,
                icon: const Icon(Icons.layers_outlined),
                label: const Text('الطبقات'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExplorerMegaOpsReport {
  const _ExplorerMegaOpsReport({
    required this.generatedAt,
    required this.score,
    required this.status,
    required this.missionLines,
    required this.dependencyLines,
    required this.performanceLines,
    required this.qaLines,
    required this.handoffLines,
    required this.csvRows,
  });

  final DateTime generatedAt;
  final int score;
  final String status;
  final List<String> missionLines;
  final List<String> dependencyLines;
  final List<String> performanceLines;
  final List<String> qaLines;
  final List<String> handoffLines;
  final List<List<String>> csvRows;

  factory _ExplorerMegaOpsReport.fromState(
    MapState state,
    List<ExplorerMapBookmark> bookmarks,
  ) {
    bool activeHas(List<String> tokens) => state.activeLayers.any((key) {
          final lower = key.toLowerCase();
          return tokens.any(lower.contains);
        });

    final gaps = _buildDataGapsAuditReport(state);
    final highGaps = gaps.gaps
        .where((gap) => gap.priority >= 3)
        .fold<int>(0, (sum, gap) => sum + gap.count);
    final visible = state.gisFeatures.length;
    final missingGeometry =
        state.gisFeatures.where((f) => f.geom == null && f.centroid == null).length;
    final activeCount = state.activeLayers.length;
    final blockedCount = state.runtimeInfo.blockedLayerKeys.length;
    var score = 100;
    if (state.viewport == null) score -= 20;
    if (activeCount == 0) score -= 20;
    if (visible == 0) score -= 15;
    if (blockedCount > 0) score -= 10;
    if (highGaps > 0) score -= 10;
    if (activeCount > 9) score -= 10;
    if (!activeHas(const ['governorate'])) score -= 5;
    if (!activeHas(const ['lgu', 'local'])) score -= 5;
    final safeScore = score.clamp(0, 100).toInt();
    final status = safeScore >= 80
        ? 'جاهز تشغيليًا'
        : (safeScore >= 55 ? 'يحتاج ضبط' : 'غير جاهز للتصدير');

    final missionLines = <String>[
      'العناصر الظاهرة: $visible',
      'الأولوية العالية: $highGaps',
      'بلا هندسة/مركز: $missingGeometry',
      visible == 0
          ? 'فعّل طبقة أو حرّك الخريطة قبل بناء مهمة.'
          : 'ابدأ بتدقيق العناصر ذات الفجوات العالية ثم العناصر بلا سياق إداري.',
    ];
    final dependencyLines = <String>[
      activeHas(const ['palestine', 'westbank', 'west_bank'])
          ? 'السياق الوطني حاضر.'
          : 'يفضل تفعيل حدود فلسطين/الضفة وغزة.',
      activeHas(const ['governorate'])
          ? 'المحافظات حاضرة.'
          : 'المحافظات غير مفعلة.',
      activeHas(const ['lgu', 'local'])
          ? 'الهيئات المحلية حاضرة.'
          : 'الهيئات المحلية غير مفعلة.',
      activeHas(const ['waqf', 'mosque', 'maqam', 'cemeter'])
          ? 'طبقات وقفية/ميدانية نشطة.'
          : 'لا توجد طبقات وقفية نشطة.',
      activeHas(const ['natural_blocks', 'parcel', 'settlement'])
          ? 'سياق أحواض/تسوية نشط.'
          : 'الأحواض/التسوية غير مفعلة.',
    ];
    final performanceLines = <String>[
      'Zoom: ${state.zoom.toStringAsFixed(1)}',
      'الطبقات النشطة: $activeCount',
      'الطبقات المحجوبة: $blockedCount',
      'العناصر المحملة: $visible',
      state.runtimeInfo.usingNaturalBlocksOverview
          ? 'Natural Blocks Overview مستخدم.'
          : 'Natural Blocks Overview غير مستخدم.',
      state.runtimeInfo.servedFromCache
          ? 'النتائج من Cache.'
          : 'استعلام جديد أو Cache غير ظاهر.',
    ];
    final qaLines = <String>[
      state.viewport == null ? 'BBOX غير جاهز.' : 'BBOX جاهز.',
      activeCount == 0 ? 'لا توجد طبقات نشطة.' : 'الطبقات النشطة جاهزة.',
      visible == 0 ? 'لا توجد عناصر محملة.' : 'العناصر المحملة متاحة.',
      highGaps > 0
          ? 'توجد فجوات عالية يجب ذكرها.'
          : 'لا توجد فجوات عالية ظاهرة.',
      bookmarks.isEmpty
          ? 'لا توجد عروض محفوظة للرجوع.'
          : 'يوجد ${bookmarks.length} عرض محفوظ.',
    ];
    final handoffLines = <String>[
      'الحالة: $status',
      'الدرجة: $safeScore%',
      'BBOX: ${_megaViewportLabel(state.viewport)}',
      'الطبقات: ${state.activeLayers.isEmpty ? '—' : state.activeLayers.join('|')}',
      'نقطة الاستئناف: اضبط الطبقات حسب QA ثم صدّر Snapshot/Handoff.',
    ];
    final generatedAt = DateTime.now();
    final csvRows = <List<String>>[
      ['metric', 'value'],
      ['generated_at', generatedAt.toIso8601String()],
      ['status', status],
      ['score', '$safeScore'],
      ['zoom', state.zoom.toStringAsFixed(1)],
      ['bbox', _megaViewportLabel(state.viewport)],
      ['active_layers', '$activeCount'],
      ['features', '$visible'],
      ['blocked_layers', '$blockedCount'],
      ['high_gaps', '$highGaps'],
      ['bookmarks', '${bookmarks.length}'],
    ];
    return _ExplorerMegaOpsReport(
      generatedAt: generatedAt,
      score: safeScore,
      status: status,
      missionLines: missionLines,
      dependencyLines: dependencyLines,
      performanceLines: performanceLines,
      qaLines: qaLines,
      handoffLines: handoffLines,
      csvRows: csvRows,
    );
  }

  String toText() {
    final buffer = StringBuffer()
      ..writeln('حزمة تشغيل المستكشف الكبرى - PalWakf Mustakshif')
      ..writeln('التاريخ: ${generatedAt.toIso8601String()}')
      ..writeln('الحالة: $status')
      ..writeln('الدرجة: $score%')
      ..writeln('--- مهمة ميدانية ---');
    for (final line in missionLines) buffer.writeln('- $line');
    buffer.writeln('--- اعتماد الطبقات ---');
    for (final line in dependencyLines) buffer.writeln('- $line');
    buffer.writeln('--- الأداء ---');
    for (final line in performanceLines) buffer.writeln('- $line');
    buffer.writeln('--- QA ---');
    for (final line in qaLines) buffer.writeln('- $line');
    buffer.writeln('--- توريث ---');
    for (final line in handoffLines) buffer.writeln('- $line');
    return buffer.toString();
  }

  String toCsv() => csvRows.map((row) => row.map(_csvCell).join(',')).join('\n');

  String toHtml() {
    final safe = const HtmlEscape().convert(toText()).replaceAll('\n', '<br>');
    return '<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><title>PalWakf Explorer Mega Ops</title><style>body{font-family:Arial,sans-serif;line-height:1.7;padding:24px;color:#1f2937}h1{color:#B22222}.box{border:1px solid #e5e7eb;border-radius:14px;padding:16px}</style></head><body><h1>حزمة تشغيل المستكشف الكبرى</h1><div class="box">$safe</div></body></html>';
  }
}

class _MegaScoreCard extends StatelessWidget {
  const _MegaScoreCard({required this.report});
  final _ExplorerMegaOpsReport report;

  @override
  Widget build(BuildContext context) {
    final color = report.score >= 80
        ? PwfColors.success
        : (report.score >= 55 ? PwfColors.primaryGold : PwfColors.royalRed);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.dashboard_customize_outlined, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${report.status} • ${report.score}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MegaSectionCard extends StatelessWidget {
  const _MegaSectionCard({
    required this.title,
    required this.icon,
    required this.lines,
  });
  final String title;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: PwfColors.royalRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: PwfColors.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $line',
                style: TextStyle(
                  color: PwfColors.onSurface.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w800,
                  fontSize: 11.4,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _megaViewportLabel(ViewportBounds? viewport) {
  if (viewport == null) return 'غير متاح';
  return 'W:${viewport.west.toStringAsFixed(5)}, S:${viewport.south.toStringAsFixed(5)}, E:${viewport.east.toStringAsFixed(5)}, N:${viewport.north.toStringAsFixed(5)}';
}

String _megaStamp() {
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
}

class _AudienceNotice extends StatelessWidget {
  const _AudienceNotice({required this.audience});

  final MapToolAudience audience;

  @override
  Widget build(BuildContext context) {
    final color = audience.canUseManagerTools
        ? PwfColors.royalRed
        : (audience.canUseEmployeeTools
            ? PwfColors.primaryBlue
            : PwfColors.primaryGold);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_open_outlined, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              audience.descriptionAr,
              style: TextStyle(
                color: PwfColors.onSurface.withValues(alpha: 0.74),
                fontWeight: FontWeight.w800,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _drawLabel(String? shape) {
  switch (shape) {
    case 'point':
      return 'نقطة';
    case 'line':
      return 'خط';
    case 'polygon':
      return 'مضلع';
    default:
      return 'رسم';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose});
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: PwfColors.royalRed,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900))),
          IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white)),
        ],
      ),
    );
  }
}

class _PrimaryToggleTile extends StatelessWidget {
  const _PrimaryToggleTile(
      {required this.title, required this.value, required this.onTap});
  final String title;
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PwfColors.royalRed,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900)),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: value ? 0.95 : 0.20),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(value ? Icons.check : Icons.remove,
                    size: 18, color: value ? PwfColors.royalRed : Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: PwfColors.royalRed.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: PwfColors.royalRed, size: 20),
          ),
          title: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: PwfColors.onSurface)),
          trailing: trailing ??
              const Icon(Icons.chevron_left, color: PwfColors.onSurface),
        ),
      ),
    );
  }
}
