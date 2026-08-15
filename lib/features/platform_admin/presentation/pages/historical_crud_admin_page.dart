import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../data/repositories/historical_crud_admin_repository.dart';
import '../../domain/models/historical_admin_relation_crud_row.dart';
import '../../domain/models/historical_admin_spatial_link_row.dart';
import '../../domain/models/historical_admin_unit_row.dart';
import '../../domain/models/historical_manual_predecessor_map_row.dart';
import '../../domain/models/historical_period_row.dart';
import '../../domain/models/historical_topology_queue_row.dart';
import '../providers/historical_crud_admin_providers.dart';

class HistoricalCrudAdminPage extends ConsumerStatefulWidget {
  const HistoricalCrudAdminPage({super.key});

  @override
  ConsumerState<HistoricalCrudAdminPage> createState() => _HistoricalCrudAdminPageState();
}

class _HistoricalCrudAdminPageState extends ConsumerState<HistoricalCrudAdminPage> with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF0B1220);
  static const _card = Color(0xFF111827);

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(historicalPeriodsCrudProvider);
    ref.invalidate(historicalAdminUnitsCrudProvider);
    ref.invalidate(historicalRelationsCrudProvider);
    ref.invalidate(historicalQueueCrudProvider);
    ref.invalidate(historicalManualMappingsCrudProvider);
    ref.invalidate(historicalSpatialLinksCrudProvider);
  }

  Future<void> _confirmDelete({required String title, required Future<void> Function() onDelete}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('هل أنت متأكد من الحذف؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      await onDelete();
      _refreshAll();
    }
  }

  Future<void> _showPeriodDialog([HistoricalPeriodRow? row]) async {
    final target = row?.titleAr ?? 'سجل الفترات';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(row == null ? 'مرجع الفترات التاريخية' : 'الفترة: $target'),
        content: Text(
          row == null
              ? 'قائمة الفترات التاريخية أصبحت تُقرأ من hist.period_registry عبر rpc_historical_period_list_v1، لذلك تتم إدارة هذا المرجع من طبقة SQL السيادية وليس من شاشة CRUD القديمة.'
              : 'هذه الفترة تُدار الآن من hist.period_registry عبر period_no = ${row.periodNo}. النوع الحالي: ${row.kindLabelAr}. ${row.hasOverlay ? 'يمكن فتحها على الخريطة من هذه البطاقة.' : 'لا توجد لها طبقة هندسية مستقلة حاليًا، وتُعرض كبطاقة مرجعية/وصفية.'}',
          textAlign: TextAlign.right,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUnitDialog([HistoricalAdminUnitRow? row]) async {
    final repo = ref.read(historicalCrudAdminRepositoryProvider);
    final code = TextEditingController(text: row?.code ?? '');
    final periodId = TextEditingController(text: row?.periodId.toString() ?? '');
    final origin = TextEditingController(text: row?.originCommunityCode ?? '');
    final parentId = TextEditingController(text: row?.parentId?.toString() ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(row == null ? 'إضافة وحدة تاريخية' : 'تعديل وحدة تاريخية'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(code, 'الكود *'),
                _field(periodId, 'period_id *', isNumber: true),
                _field(origin, 'origin_community_code'),
                _field(parentId, 'parent_id', isNumber: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              await repo.saveUnit(
                id: row?.id,
                code: code.text.trim(),
                periodId: int.tryParse(periodId.text.trim()) ?? 0,
                originCommunityCode: origin.text.trim().isEmpty ? null : origin.text.trim(),
                parentId: int.tryParse(parentId.text.trim()),
              );
              if (!mounted) return;
              Navigator.pop(context);
              _refreshAll();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRelationDialog([HistoricalAdminRelationCrudRow? row]) async {
    final repo = ref.read(historicalCrudAdminRepositoryProvider);
    final source = TextEditingController(text: row?.sourceHistoricalAdminUnitId.toString() ?? '');
    final target = TextEditingController(text: row?.targetHistoricalAdminUnitId.toString() ?? '');
    final relationType = TextEditingController(text: row?.relationType ?? 'predecessor_of');
    final confidence = TextEditingController(text: row?.confidence.toString() ?? '0.9000');
    final notes = TextEditingController(text: row?.notes ?? '');
    var isActive = row?.isActive ?? true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(row == null ? 'إضافة علاقة تاريخية' : 'تعديل علاقة تاريخية'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(source, 'source_historical_admin_unit_id *', isNumber: true),
                  _field(target, 'target_historical_admin_unit_id *', isNumber: true),
                  _field(relationType, 'relation_type *'),
                  _field(confidence, 'confidence *', isNumber: true),
                  _field(notes, 'notes', maxLines: 3),
                  SwitchListTile(
                    value: isActive,
                    onChanged: (v) => setState(() => isActive = v),
                    title: const Text('فعال'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                await repo.saveRelation(
                  id: row?.id,
                  sourceHistoricalAdminUnitId: int.tryParse(source.text.trim()) ?? 0,
                  targetHistoricalAdminUnitId: int.tryParse(target.text.trim()) ?? 0,
                  relationType: relationType.text.trim(),
                  confidence: double.tryParse(confidence.text.trim()) ?? 0.9,
                  isActive: isActive,
                  notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);
                _refreshAll();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQueueDialog([HistoricalTopologyQueueRow? row]) async {
    final repo = ref.read(historicalCrudAdminRepositoryProvider);
    final historicalAdminUnitId = TextEditingController(text: row?.historicalAdminUnitId ?? '');
    final code = TextEditingController(text: row?.code ?? '');
    final periodId = TextEditingController(text: row?.periodId.toString() ?? '');
    final periodTitleAr = TextEditingController(text: row?.periodTitleAr ?? '');
    final origin = TextEditingController(text: row?.originCommunityCode ?? '');
    final finalGapReason = TextEditingController(text: row?.finalGapReason ?? 'isolated_needs_review');
    final family = TextEditingController(text: row?.suggestedEventFamily ?? '');
    final reviewNote = TextEditingController(text: row?.reviewNote ?? '');
    final relationDirection = TextEditingController(text: row?.relationDirection ?? 'queue_is_source');
    final decisionStatus = TextEditingController(text: row?.decisionStatus ?? 'pending');
    final approvedRelationType = TextEditingController(text: row?.approvedRelationType ?? '');
    final confidence = TextEditingController(text: row?.confidence?.toString() ?? '');
    final adminNotes = TextEditingController(text: row?.adminNotes ?? '');
    final targetUnitId = TextEditingController(text: row?.candidateTargetUnitId ?? '');
    final targetCode = TextEditingController(text: row?.candidateTargetCode ?? '');
    final targetPeriodId = TextEditingController(text: row?.candidateTargetPeriodId?.toString() ?? '');
    final targetPeriodTitle = TextEditingController(text: row?.candidateTargetPeriodTitleAr ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(row == null ? 'إضافة صف Queue' : 'تعديل صف Queue'),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(historicalAdminUnitId, 'historical_admin_unit_id *', isNumber: true),
                _field(code, 'code *'),
                _field(periodId, 'period_id *', isNumber: true),
                _field(periodTitleAr, 'period_title_ar'),
                _field(origin, 'origin_community_code'),
                _field(finalGapReason, 'final_gap_reason *'),
                _field(family, 'suggested_event_family'),
                _field(reviewNote, 'review_note', maxLines: 2),
                _field(relationDirection, 'relation_direction'),
                _field(decisionStatus, 'decision_status'),
                _field(approvedRelationType, 'approved_relation_type'),
                _field(confidence, 'confidence', isNumber: true),
                _field(adminNotes, 'admin_notes', maxLines: 2),
                _field(targetUnitId, 'candidate_target_unit_id', isNumber: true),
                _field(targetCode, 'candidate_target_code'),
                _field(targetPeriodId, 'candidate_target_period_id', isNumber: true),
                _field(targetPeriodTitle, 'candidate_target_period_title_ar'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              await repo.saveQueueRow(
                id: row?.id,
                historicalAdminUnitId: int.tryParse(historicalAdminUnitId.text.trim()) ?? 0,
                code: code.text.trim(),
                periodId: int.tryParse(periodId.text.trim()) ?? 0,
                periodTitleAr: periodTitleAr.text.trim().isEmpty ? null : periodTitleAr.text.trim(),
                originCommunityCode: origin.text.trim().isEmpty ? null : origin.text.trim(),
                finalGapReason: finalGapReason.text.trim(),
                suggestedEventFamily: family.text.trim().isEmpty ? null : family.text.trim(),
                reviewNote: reviewNote.text.trim().isEmpty ? null : reviewNote.text.trim(),
                relationDirection: relationDirection.text.trim().isEmpty ? null : relationDirection.text.trim(),
                decisionStatus: decisionStatus.text.trim().isEmpty ? null : decisionStatus.text.trim(),
                approvedRelationType: approvedRelationType.text.trim().isEmpty ? null : approvedRelationType.text.trim(),
                confidence: double.tryParse(confidence.text.trim()),
                adminNotes: adminNotes.text.trim().isEmpty ? null : adminNotes.text.trim(),
                candidateTargetUnitId: int.tryParse(targetUnitId.text.trim()),
                candidateTargetCode: targetCode.text.trim().isEmpty ? null : targetCode.text.trim(),
                candidateTargetPeriodId: int.tryParse(targetPeriodId.text.trim()),
                candidateTargetPeriodTitleAr: targetPeriodTitle.text.trim().isEmpty ? null : targetPeriodTitle.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(context);
              _refreshAll();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMappingDialog([HistoricalManualPredecessorMapRow? row]) async {
    final repo = ref.read(historicalCrudAdminRepositoryProvider);
    final reviewQueueId = TextEditingController(text: row?.reviewQueueId.toString() ?? '');
    final targetUnitId = TextEditingController(text: row?.targetUnitId.toString() ?? '');
    final targetCode = TextEditingController(text: row?.targetCode ?? '');
    final targetPeriodId = TextEditingController(text: row?.targetPeriodId.toString() ?? '');
    final targetPeriodTitleAr = TextEditingController(text: row?.targetPeriodTitleAr ?? '');
    final sourceUnitId = TextEditingController(text: row?.sourceUnitId.toString() ?? '');
    final sourceCode = TextEditingController(text: row?.sourceCode ?? '');
    final sourcePeriodId = TextEditingController(text: row?.sourcePeriodId.toString() ?? '');
    final sourcePeriodTitleAr = TextEditingController(text: row?.sourcePeriodTitleAr ?? '');
    final relationType = TextEditingController(text: row?.suggestedRelationType ?? 'transferred_to');
    final confidence = TextEditingController(text: row?.confidence.toString() ?? '0.9');
    final notes = TextEditingController(text: row?.notes ?? '');
    var isSelected = row?.isSelected ?? false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(row == null ? 'إضافة Mapping يدوي' : 'تعديل Mapping يدوي'),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(reviewQueueId, 'review_queue_id *', isNumber: true),
                  _field(targetUnitId, 'target_unit_id *', isNumber: true),
                  _field(targetCode, 'target_code *'),
                  _field(targetPeriodId, 'target_period_id *', isNumber: true),
                  _field(targetPeriodTitleAr, 'target_period_title_ar'),
                  _field(sourceUnitId, 'source_unit_id *', isNumber: true),
                  _field(sourceCode, 'source_code *'),
                  _field(sourcePeriodId, 'source_period_id *', isNumber: true),
                  _field(sourcePeriodTitleAr, 'source_period_title_ar'),
                  _field(relationType, 'suggested_relation_type *'),
                  _field(confidence, 'confidence *', isNumber: true),
                  _field(notes, 'notes', maxLines: 3),
                  SwitchListTile(
                    value: isSelected,
                    onChanged: (v) => setState(() => isSelected = v),
                    title: const Text('Selected'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                await repo.saveManualMapping(
                  id: row?.id,
                  reviewQueueId: int.tryParse(reviewQueueId.text.trim()) ?? 0,
                  targetUnitId: int.tryParse(targetUnitId.text.trim()) ?? 0,
                  targetCode: targetCode.text.trim(),
                  targetPeriodId: int.tryParse(targetPeriodId.text.trim()) ?? 0,
                  targetPeriodTitleAr: targetPeriodTitleAr.text.trim().isEmpty ? null : targetPeriodTitleAr.text.trim(),
                  sourceUnitId: int.tryParse(sourceUnitId.text.trim()) ?? 0,
                  sourceCode: sourceCode.text.trim(),
                  sourcePeriodId: int.tryParse(sourcePeriodId.text.trim()) ?? 0,
                  sourcePeriodTitleAr: sourcePeriodTitleAr.text.trim().isEmpty ? null : sourcePeriodTitleAr.text.trim(),
                  suggestedRelationType: relationType.text.trim(),
                  confidence: double.tryParse(confidence.text.trim()) ?? 0.9,
                  notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
                  isSelected: isSelected,
                );
                if (!mounted) return;
                Navigator.pop(context);
                _refreshAll();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSpatialDialog([HistoricalAdminSpatialLinkRow? row]) async {
    final repo = ref.read(historicalCrudAdminRepositoryProvider);
    final historicalAdminUnitId = TextEditingController(text: row?.historicalAdminUnitId.toString() ?? '');
    final histLevel = TextEditingController(text: row?.histLevel ?? 'kada');
    final histPeriodNo = TextEditingController(text: row?.histPeriodNo.toString() ?? '');
    final histAdminNo = TextEditingController(text: row?.histAdminNo.toString() ?? '');
    final matchMethod = TextEditingController(text: row?.matchMethod ?? 'manual');
    final confidence = TextEditingController(text: row?.confidence.toString() ?? '0.9');
    final notes = TextEditingController(text: row?.notes ?? '');
    var isPrimary = row?.isPrimary ?? false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(row == null ? 'إضافة رابط مكاني' : 'تعديل رابط مكاني'),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(historicalAdminUnitId, 'historical_admin_unit_id *', isNumber: true),
                  _field(histLevel, 'hist_level *'),
                  _field(histPeriodNo, 'hist_period_no *', isNumber: true),
                  _field(histAdminNo, 'hist_admin_no *', isNumber: true),
                  _field(matchMethod, 'match_method *'),
                  _field(confidence, 'confidence *', isNumber: true),
                  _field(notes, 'notes', maxLines: 3),
                  SwitchListTile(
                    value: isPrimary,
                    onChanged: (v) => setState(() => isPrimary = v),
                    title: const Text('Primary'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                await repo.saveSpatialLink(
                  id: row?.id,
                  historicalAdminUnitId: int.tryParse(historicalAdminUnitId.text.trim()) ?? 0,
                  histLevel: histLevel.text.trim(),
                  histPeriodNo: int.tryParse(histPeriodNo.text.trim()) ?? 0,
                  histAdminNo: int.tryParse(histAdminNo.text.trim()) ?? 0,
                  matchMethod: matchMethod.text.trim(),
                  confidence: double.tryParse(confidence.text.trim()) ?? 0.9,
                  isPrimary: isPrimary,
                  notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);
                _refreshAll();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }


  void _openHistoryMap(Map<String, String?> params) {
    final cleaned = <String, String>{};
    params.forEach((key, value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) cleaned[key] = v;
    });
    final uri = Uri(path: '/admin/history-map', queryParameters: cleaned.isEmpty ? null : cleaned);
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'إدارة الجداول التاريخية (CRUD Foundation)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/admin/history-map'),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('لوحة الخريطة'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _refreshAll,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث الكل'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'تبويب الفترات يقرأ الآن من hist.period_registry عبر rpc_historical_period_list_v1، بينما تبقى بقية التبويبات مرتبطة بجداول الإدارة الأصلية والعلاقات وQueue والروابط المكانية.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.5),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: PwfColors.primaryGold,
              unselectedLabelColor: Colors.white70,
              dividerColor: Colors.white12,
              tabs: const [
                Tab(text: 'الفترات'),
                Tab(text: 'الوحدات'),
                Tab(text: 'العلاقات'),
                Tab(text: 'Queue'),
                Tab(text: 'Manual Map'),
                Tab(text: 'Spatial Links'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CrudSection<HistoricalPeriodRow>(
                    title: 'الفترات التاريخية (مرجع سيادي + بطاقات عرض)',
                    onAdd: () => _showPeriodDialog(),
                    provider: historicalPeriodsCrudProvider,
                    buildRow: (row) => _buildPeriodRow(row),
                  ),
                  _CrudSection<HistoricalAdminUnitRow>(
                    title: 'إدارة الوحدات الإدارية التاريخية',
                    onAdd: () => _showUnitDialog(),
                    provider: historicalAdminUnitsCrudProvider,
                    buildRow: (row) => _buildUnitRow(row),
                  ),
                  _CrudSection<HistoricalAdminRelationCrudRow>(
                    title: 'إدارة العلاقات التاريخية',
                    onAdd: () => _showRelationDialog(),
                    provider: historicalRelationsCrudProvider,
                    buildRow: (row) => _buildRelationRow(row),
                  ),
                  _CrudSection<HistoricalTopologyQueueRow>(
                    title: 'إدارة Queue المراجعة',
                    onAdd: () => _showQueueDialog(),
                    provider: historicalQueueCrudProvider,
                    buildRow: (row) => _buildQueueRow(row),
                  ),
                  _CrudSection<HistoricalManualPredecessorMapRow>(
                    title: 'إدارة الـ Manual Mapping',
                    onAdd: () => _showMappingDialog(),
                    provider: historicalManualMappingsCrudProvider,
                    buildRow: (row) => _buildMappingRow(row),
                  ),
                  _CrudSection<HistoricalAdminSpatialLinkRow>(
                    title: 'إدارة الروابط المكانية',
                    onAdd: () => _showSpatialDialog(),
                    provider: historicalSpatialLinksCrudProvider,
                    buildRow: (row) => _buildSpatialRow(row),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodRow(HistoricalPeriodRow row) {
    final chips = <String>[
      row.kindLabelAr,
      if (row.scopeLabelAr != null) row.scopeLabelAr!,
      if (row.defaultLevelKey != null) 'المستوى الافتراضي: ${row.defaultLevelLabelAr}',
      if (row.hasOverlay) 'عناصر قابلة للرسم: ${row.totalOverlayRows}',
      if (!row.hasOverlay) 'لا توجد طبقة هندسية بعد',
    ];

    final subtitle = 'period_no: ${row.periodNo} • ${row.rangeLabelAr}';
    final description = row.summaryAr ?? row.statusHintAr;

    return _RecordCard(
      title: row.titleAr,
      subtitle: subtitle,
      description: description,
      imageUrl: row.imageUrl,
      chips: chips,
      onOpenMap: row.hasOverlay
          ? () => _openHistoryMap({
                'table': 'period_registry',
                'period_no': row.periodNo.toString(),
                'period_id': row.periodNo.toString(),
                'title': row.titleAr,
                'focus': row.titleAr,
                'period_title': row.titleAr,
                'type': 'historical_period',
              })
          : null,
      onEdit: () => _showPeriodDialog(row),
      onDelete: null,
    );
  }

  Widget _buildUnitRow(HistoricalAdminUnitRow row) => _RecordCard(
        title: row.code,
        subtitle: 'ID: ${row.id} • ${row.periodLabel} (${row.periodRangeLabel}) • الأصل الحديث: ${row.originCommunityCode ?? '—'} • الأب: ${row.parentId ?? '—'}',
        onOpenMap: () => _openHistoryMap({
          'table': 'historical_admin_units',
          'id': row.id.toString(),
          'title': row.code,
          'focus': row.code,
          'period_id': row.periodId.toString(),
          'period': row.periodLabel,
          'period_range': row.periodRangeLabel,
          'origin': row.originCommunityCode,
          'type': 'historical_unit',
        }),
        onEdit: () => _showUnitDialog(row),
        onDelete: () => _confirmDelete(title: 'حذف الوحدة ${row.code}', onDelete: () => ref.read(historicalCrudAdminRepositoryProvider).deleteUnit(row.id)),
      );

  Widget _buildRelationRow(HistoricalAdminRelationCrudRow row) => _RecordCard(
        title: '${row.sourceHistoricalAdminUnitId} → ${row.targetHistoricalAdminUnitId}',
        subtitle: 'ID: ${row.id} • النوع: ${row.relationType} • الثقة: ${row.confidence.toStringAsFixed(4)}',
        chips: [row.isActive ? 'فعال' : 'معطل', if ((row.notes ?? '').isNotEmpty) row.notes!],
        onOpenMap: () => _openHistoryMap({
          'table': 'topology.historical_admin_relations',
          'id': row.id.toString(),
          'title': 'Historical relation #${row.id}',
          'source': row.sourceHistoricalAdminUnitId.toString(),
          'target': row.targetHistoricalAdminUnitId.toString(),
          'type': row.relationType,
        }),
        onEdit: () => _showRelationDialog(row),
        onDelete: () => _confirmDelete(title: 'حذف العلاقة ${row.id}', onDelete: () => ref.read(historicalCrudAdminRepositoryProvider).deleteRelation(row.id)),
      );

  Widget _buildQueueRow(HistoricalTopologyQueueRow row) => _RecordCard(
        title: row.code,
        subtitle: 'ID: ${row.id} • الفترة: ${row.periodId} • الحالة: ${row.decisionStatus ?? 'pending'} • السبب: ${row.finalGapReason}',
        chips: [
          if ((row.suggestedEventFamily ?? '').isNotEmpty) row.suggestedEventFamily!,
          if ((row.approvedRelationType ?? '').isNotEmpty) row.approvedRelationType!,
          if (row.isApplied) 'مطبق #${row.appliedRelationId ?? ''}',
        ],
        onOpenMap: () => _openHistoryMap({
          'table': 'topology.historical_topology_review_queue',
          'id': row.id.toString(),
          'title': row.code,
          'source': row.sourceCodeForDisplay,
          'target': row.targetCodeForDisplay,
          'focus': row.code,
          'period_id': row.periodId.toString(),
          'period': row.periodTitleAr ?? row.periodId.toString(),
          'type': row.approvedRelationType ?? row.finalGapReason,
          'origin': row.originCommunityCode,
        }),
        onEdit: () => _showQueueDialog(row),
        onDelete: () => _confirmDelete(title: 'حذف صف Queue ${row.code}', onDelete: () => ref.read(historicalCrudAdminRepositoryProvider).deleteQueueRow(row.id)),
      );

  Widget _buildMappingRow(HistoricalManualPredecessorMapRow row) => _RecordCard(
        title: '${row.sourceCode} → ${row.targetCode}',
        subtitle: 'ID: ${row.id} • review_queue_id: ${row.reviewQueueId} • النوع: ${row.suggestedRelationType} • الثقة: ${row.confidence.toStringAsFixed(4)}',
        chips: [if (row.isSelected) 'Selected', if ((row.notes ?? '').isNotEmpty) row.notes!],
        onOpenMap: () => _openHistoryMap({
          'table': 'topology.historical_manual_predecessor_map',
          'id': row.id.toString(),
          'title': 'Manual mapping #${row.id}',
          'source': row.sourceCode,
          'target': row.targetCode,
          'period_id': row.targetPeriodId.toString(),
          'period': '${row.sourcePeriodTitleAr ?? row.sourcePeriodId} → ${row.targetPeriodTitleAr ?? row.targetPeriodId}',
          'type': row.suggestedRelationType,
        }),
        onEdit: () => _showMappingDialog(row),
        onDelete: () => _confirmDelete(title: 'حذف mapping ${row.id}', onDelete: () => ref.read(historicalCrudAdminRepositoryProvider).deleteManualMapping(row.id)),
      );

  Widget _buildSpatialRow(HistoricalAdminSpatialLinkRow row) => _RecordCard(
        title: 'Unit ${row.historicalAdminUnitId} ↔ ${row.histLevel}/${row.histPeriodNo}/${row.histAdminNo}',
        subtitle: 'ID: ${row.id} • الطريقة: ${row.matchMethod} • الثقة: ${row.confidence.toStringAsFixed(4)}',
        chips: [if (row.isPrimary) 'Primary', if ((row.notes ?? '').isNotEmpty) row.notes!],
        onOpenMap: () => _openHistoryMap({
          'table': 'topology.historical_admin_spatial_links',
          'id': row.id.toString(),
          'title': 'Spatial link #${row.id}',
          'focus': row.historicalAdminUnitId.toString(),
          'period_id': row.histPeriodNo.toString(),
          'period': row.histPeriodNo.toString(),
          'type': row.histLevel,
        }),
        onEdit: () => _showSpatialDialog(row),
        onDelete: () => _confirmDelete(title: 'حذف الرابط المكاني ${row.id}', onDelete: () => ref.read(historicalCrudAdminRepositoryProvider).deleteSpatialLink(row.id)),
      );
}

class _CrudSection<T> extends ConsumerWidget {
  final String title;
  final VoidCallback onAdd;
  final Refreshable<AsyncValue<List<T>>> provider;
  final Widget Function(T row) buildRow;

  const _CrudSection({
    required this.title,
    required this.onAdd,
    required this.provider,
    required this.buildRow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRows = ref.watch(provider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('إضافة')),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () { ref.refresh(provider); },
                icon: const Icon(Icons.refresh, color: Colors.white70),
                tooltip: 'تحديث',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: asyncRows.when(
              data: (rows) {
                if (rows.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox_outlined, size: 44, color: Colors.white38),
                        const SizedBox(height: 12),
                        const Text('لا يوجد بيانات بعد', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          'ابدأ بإضافة أول سجل أو راجع سياسات RLS/الصلاحيات إذا كنت تتوقع ظهور بيانات موجودة في القاعدة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), height: 1.5),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة أول سجل'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => buildRow(rows[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => ref.refresh(provider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? description;
  final String? imageUrl;
  final List<String> chips;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenMap;

  const _RecordCard({
    required this.title,
    required this.subtitle,
    this.description,
    this.imageUrl,
    this.chips = const [],
    this.onEdit,
    this.onDelete,
    this.onOpenMap,
  });

  bool get _hasRemoteImage {
    final uri = Uri.tryParse(imageUrl ?? '');
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              if (onOpenMap != null)
                IconButton(
                  onPressed: onOpenMap,
                  tooltip: 'فتح على الخريطة',
                  icon: const Icon(Icons.map_outlined, color: Colors.lightBlueAccent),
                ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'تفاصيل',
                  icon: const Icon(Icons.info_outline, color: PwfColors.primaryGold),
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'حذف',
                  icon: const Icon(Icons.delete_outline, color: PwfColors.royalRed),
                ),
            ],
          ),
          Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.5)),
          if (description != null && description!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), height: 1.5),
            ),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 132,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                border: Border.all(color: Colors.white10),
              ),
              child: _hasRemoteImage
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips
                  .where((e) => e.trim().isNotEmpty)
                  .map(
                    (chip) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(chip, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.history_edu_outlined, size: 34, color: Colors.white54),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'صورة مرجعية للفترة التاريخية',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
          ),
        ),
      ],
    );
  }
}


Widget _field(TextEditingController controller, String label, {bool isNumber = false, int maxLines = 1}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
