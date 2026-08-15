import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../data/repositories/historical_topology_admin_repository.dart';
import '../../domain/models/historical_admin_relation_review_row.dart';
import '../../domain/models/historical_admin_review_metric.dart';
import '../../domain/models/historical_gap_summary_item.dart';
import '../../domain/models/historical_topology_queue_row.dart';
import '../providers/historical_topology_providers.dart';

class HistoricalTopologyAdminPage extends ConsumerStatefulWidget {
  const HistoricalTopologyAdminPage({super.key});

  @override
  ConsumerState<HistoricalTopologyAdminPage> createState() =>
      _HistoricalTopologyAdminPageState();
}

class _HistoricalTopologyAdminPageState
    extends ConsumerState<HistoricalTopologyAdminPage> {
  final TextEditingController _relationSearch = TextEditingController();
  final TextEditingController _queueSearch = TextEditingController();
  final TextEditingController _appliedSearch = TextEditingController();

  String _relationType = 'all';
  String _relationTransition = 'all';
  String _queueReason = 'all';
  String _queueFamily = 'all';
  String _queueStatus = 'all';
  String _queuePeriod = 'all';
  String _queueApplyState = 'all';
  String _appliedType = 'all';
  String _appliedPeriod = 'all';

  final Set<int> _selectedQueueIds = <int>{};

  @override
  void dispose() {
    _relationSearch.dispose();
    _queueSearch.dispose();
    _appliedSearch.dispose();
    super.dispose();
  }

  void _refreshAll() {
    setState(() => _selectedQueueIds.clear());
    ref.invalidate(historicalTopologySummaryProvider);
    ref.invalidate(historicalTopologyGapSummaryProvider);
    ref.invalidate(historicalTopologyRelationsProvider);
    ref.invalidate(historicalTopologyQueueProvider);
    ref.invalidate(historicalTopologyAppliedEventsProvider);
    ref.invalidate(historicalTopologySpatialLinksProvider);
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(historicalTopologySummaryProvider);
    final gapAsync = ref.watch(historicalTopologyGapSummaryProvider);
    final relationsAsync = ref.watch(historicalTopologyRelationsProvider);
    final queueAsync = ref.watch(historicalTopologyQueueProvider);
    final appliedAsync = ref.watch(historicalTopologyAppliedEventsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: const Color(0xFF0B1220),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إدارة التاريخ والطوبولوجيا',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'لوحة تشغيلية لعرض العلاقات التاريخية المؤكدة، الفجوات المتبقية، وقرارات المراجعة اليدوية.',
                            style:
                                TextStyle(color: Colors.white70, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go('/admin/history-map'),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('لوحة الخريطة'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'تحديث الكل',
                      onPressed: _refreshAll,
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _CombinedSummary(
                  summaryAsync: summaryAsync,
                  gapAsync: gapAsync,
                  relationsAsync: relationsAsync,
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const TabBar(
                    isScrollable: true,
                    labelColor: PwfColors.primaryGold,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: PwfColors.primaryGold,
                    tabs: [
                      Tab(icon: Icon(Icons.query_stats), text: 'ملخص التحولات'),
                      Tab(
                          icon: Icon(Icons.alt_route),
                          text: 'العلاقات المؤكدة'),
                      Tab(icon: Icon(Icons.fact_check), text: 'Queue المراجعة'),
                      Tab(icon: Icon(Icons.task_alt), text: 'الأحداث المطبقة'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: TabBarView(
                    children: [
                      _SummaryTab(
                        summaryAsync: summaryAsync,
                        gapAsync: gapAsync,
                        relationsAsync: relationsAsync,
                      ),
                      relationsAsync.when(
                        data: (rows) => _RelationsTab(
                          rows: _filterRelations(rows),
                          allRows: rows,
                          relationType: _relationType,
                          relationTransition: _relationTransition,
                          searchController: _relationSearch,
                          onRelationTypeChanged: (value) =>
                              setState(() => _relationType = value),
                          onRelationTransitionChanged: (value) =>
                              setState(() => _relationTransition = value),
                          onSearchChanged: (_) => setState(() {}),
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) => _InlineError(
                            message: 'تعذر تحميل العلاقات المؤكدة: $error'),
                      ),
                      queueAsync.when(
                        data: (rows) {
                          final filteredRows = _filterQueue(rows);
                          return _QueueTab(
                            rows: filteredRows,
                            allRows: rows,
                            queueReason: _queueReason,
                            queueFamily: _queueFamily,
                            queueStatus: _queueStatus,
                            queuePeriod: _queuePeriod,
                            queueApplyState: _queueApplyState,
                            selectedIds: _selectedQueueIds,
                            searchController: _queueSearch,
                            onQueueReasonChanged: (value) =>
                                setState(() => _queueReason = value),
                            onQueueFamilyChanged: (value) =>
                                setState(() => _queueFamily = value),
                            onQueueStatusChanged: (value) =>
                                setState(() => _queueStatus = value),
                            onQueuePeriodChanged: (value) =>
                                setState(() => _queuePeriod = value),
                            onQueueApplyStateChanged: (value) =>
                                setState(() => _queueApplyState = value),
                            onSearchChanged: (_) => setState(() {}),
                            onQuickIgnore: _quickIgnoreQueueRow,
                            onQuickReject: _quickRejectQueueRow,
                            onEdit: _openQueueEditor,
                            onToggleSelection: _toggleQueueSelection,
                            onSelectAllVisible: () =>
                                _selectAllVisibleQueue(filteredRows),
                            onClearSelection: _clearQueueSelection,
                            onBatchIgnore: () =>
                                _batchSetQueueStatus(filteredRows, 'ignored'),
                            onBatchReject: () =>
                                _batchSetQueueStatus(filteredRows, 'rejected'),
                            onBatchPending: () =>
                                _batchSetQueueStatus(filteredRows, 'pending'),
                            onBatchApplyApproved: () =>
                                _batchApplyApproved(filteredRows),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) => _InlineError(
                            message: 'تعذر تحميل Queue المراجعة: $error'),
                      ),
                      appliedAsync.when(
                        data: (rows) => _AppliedEventsTab(
                          rows: _filterApplied(rows),
                          allRows: rows,
                          appliedType: _appliedType,
                          appliedPeriod: _appliedPeriod,
                          searchController: _appliedSearch,
                          onAppliedTypeChanged: (value) =>
                              setState(() => _appliedType = value),
                          onAppliedPeriodChanged: (value) =>
                              setState(() => _appliedPeriod = value),
                          onSearchChanged: (_) => setState(() {}),
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) => _InlineError(
                            message: 'تعذر تحميل الأحداث المطبقة: $error'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openHistoryMap({
    String? sourceCode,
    String? targetCode,
    String? focusCode,
    String? period,
    String? relationType,
    String? originCode,
    String? title,
  }) {
    final params = <String, String>{
      if ((sourceCode ?? '').trim().isNotEmpty) 'source': sourceCode!.trim(),
      if ((targetCode ?? '').trim().isNotEmpty) 'target': targetCode!.trim(),
      if ((focusCode ?? '').trim().isNotEmpty) 'focus': focusCode!.trim(),
      if ((period ?? '').trim().isNotEmpty) 'period': period!.trim(),
      if ((relationType ?? '').trim().isNotEmpty) 'type': relationType!.trim(),
      if ((originCode ?? '').trim().isNotEmpty) 'origin': originCode!.trim(),
      if ((title ?? '').trim().isNotEmpty) 'title': title!.trim(),
    };
    final uri = Uri(
        path: '/admin/history-map',
        queryParameters: params.isEmpty ? null : params);
    context.go(uri.toString());
  }

  List<HistoricalAdminRelationReviewRow> _filterRelations(
      List<HistoricalAdminRelationReviewRow> rows) {
    final query = _relationSearch.text.trim().toLowerCase();
    return rows.where((row) {
      if (_relationType != 'all' && row.relationType != _relationType)
        return false;
      if (_relationTransition != 'all' &&
          _transitionKey(row) != _relationTransition) return false;
      if (query.isEmpty) return true;
      final haystack = [
        row.sourceCode,
        row.targetCode,
        row.sourcePeriodTitleAr ?? '',
        row.targetPeriodTitleAr ?? '',
        row.sourceOriginCommunityCode ?? '',
        row.targetOriginCommunityCode ?? '',
        row.notes ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<HistoricalTopologyQueueRow> _filterQueue(
      List<HistoricalTopologyQueueRow> rows) {
    final query = _queueSearch.text.trim().toLowerCase();
    return rows.where((row) {
      if (_queueReason != 'all' && row.finalGapReason != _queueReason)
        return false;
      if (_queueFamily != 'all' &&
          (row.suggestedEventFamily ?? '') != _queueFamily) return false;
      if (_queueStatus != 'all' && (row.decisionStatus ?? '') != _queueStatus)
        return false;
      if (_queuePeriod != 'all' && row.periodId.toString() != _queuePeriod)
        return false;
      if (_queueApplyState == 'approved_waiting_apply' &&
          !row.isApprovedPendingApply) return false;
      if (_queueApplyState == 'applied' && !row.isApplied) return false;
      if (_queueApplyState == 'not_applied' && row.isApplied) return false;
      if (_queueApplyState == 'backlog_only' &&
          (row.isApplied || row.isIgnored || row.isRejected)) return false;
      if (query.isEmpty) return true;
      final haystack = [
        row.code,
        row.periodTitleAr ?? '',
        row.finalGapReason,
        row.suggestedEventFamily ?? '',
        row.adminNotes ?? '',
        row.reviewNote ?? '',
        row.candidateTargetCode ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<HistoricalTopologyQueueRow> _filterApplied(
      List<HistoricalTopologyQueueRow> rows) {
    final query = _appliedSearch.text.trim().toLowerCase();
    return rows.where((row) {
      if (_appliedType != 'all' &&
          (row.approvedRelationType ?? '') != _appliedType) return false;
      if (_appliedPeriod != 'all') {
        final key =
            '${row.sourcePeriodForDisplay ?? '-'}→${row.targetPeriodForDisplay ?? '-'}';
        if (key != _appliedPeriod) return false;
      }
      if (query.isEmpty) return true;
      final haystack = [
        row.sourceCodeForDisplay,
        row.targetCodeForDisplay,
        row.approvedRelationType ?? '',
        row.adminNotes ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  void _toggleQueueSelection(int queueId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedQueueIds.add(queueId);
      } else {
        _selectedQueueIds.remove(queueId);
      }
    });
  }

  void _selectAllVisibleQueue(List<HistoricalTopologyQueueRow> rows) {
    setState(() {
      _selectedQueueIds.addAll(rows.map((e) => e.id));
    });
  }

  void _clearQueueSelection() {
    setState(() => _selectedQueueIds.clear());
  }

  Future<void> _batchSetQueueStatus(
      List<HistoricalTopologyQueueRow> visibleRows,
      String decisionStatus) async {
    final repo = ref.read(historicalTopologyAdminRepositoryProvider);
    final ids = visibleRows
        .where((row) => _selectedQueueIds.contains(row.id))
        .map((e) => e.id)
        .toList();
    if (ids.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('اختر صفًا واحدًا على الأقل من Queue أولًا.')),
      );
      return;
    }
    try {
      await repo.batchSetQueueStatus(
          queueIds: ids, decisionStatus: decisionStatus);
      _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'تم تحديث ${ids.length} صف/صفوف إلى ${_decisionStatusLabel(decisionStatus)}.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تنفيذ الإجراء الجماعي: $error')),
      );
    }
  }

  Future<void> _batchApplyApproved(
      List<HistoricalTopologyQueueRow> visibleRows) async {
    final repo = ref.read(historicalTopologyAdminRepositoryProvider);
    final selectedRows = visibleRows
        .where((row) => _selectedQueueIds.contains(row.id))
        .where((row) => row.isApprovedPendingApply)
        .toList();
    if (selectedRows.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'لا توجد صفوف معتمدة وبانتظار التطبيق ضمن التحديد الحالي.')),
      );
      return;
    }
    try {
      final appliedCount = await repo.applyApprovedQueueRows(selectedRows);
      _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تطبيق $appliedCount علاقة/علاقات معتمدة.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تطبيق العلاقات المعتمدة: $error')),
      );
    }
  }

  Future<void> _quickIgnoreQueueRow(HistoricalTopologyQueueRow row) async {
    final repo = ref.read(historicalTopologyAdminRepositoryProvider);
    try {
      await repo.quickSetQueueStatus(
          queueId: row.id, decisionStatus: 'ignored');
      _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تجاهل ${row.code}.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تجاهل السجل: $error')),
      );
    }
  }

  Future<void> _quickRejectQueueRow(HistoricalTopologyQueueRow row) async {
    final repo = ref.read(historicalTopologyAdminRepositoryProvider);
    try {
      await repo.quickSetQueueStatus(
          queueId: row.id, decisionStatus: 'rejected');
      _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم رفض ${row.code}.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر رفض السجل: $error')),
      );
    }
  }

  Future<void> _openQueueEditor(HistoricalTopologyQueueRow row) async {
    final repo = ref.read(historicalTopologyAdminRepositoryProvider);
    final suggestedController =
        TextEditingController(text: row.suggestedEventFamily ?? '');
    final reviewNoteController =
        TextEditingController(text: row.reviewNote ?? '');
    final adminNotesController =
        TextEditingController(text: row.adminNotes ?? '');
    final targetUnitController =
        TextEditingController(text: row.candidateTargetUnitId ?? '');
    final targetCodeController =
        TextEditingController(text: row.candidateTargetCode ?? '');
    final targetPeriodController = TextEditingController(
        text: row.candidateTargetPeriodId?.toString() ?? '');
    final targetPeriodTitleController =
        TextEditingController(text: row.candidateTargetPeriodTitleAr ?? '');

    var decisionStatus = row.decisionStatus ?? 'pending';
    var relationDirection = row.relationDirection ?? 'queue_is_source';
    var approvedRelationType = row.approvedRelationType ?? 'predecessor_of';
    var confidence = row.confidence ?? 0.90;
    var saving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocalState) {
              Future<void> save() async {
                if (decisionStatus == 'approved') {
                  if (targetUnitController.text.trim().isEmpty ||
                      targetCodeController.text.trim().isEmpty ||
                      targetPeriodController.text.trim().isEmpty ||
                      approvedRelationType.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'عند الاعتماد يجب تعبئة target ونوع العلاقة على الأقل.')),
                    );
                    return;
                  }
                }
                setLocalState(() => saving = true);
                try {
                  await repo.updateQueueRow(
                    queueId: row.id,
                    decisionStatus: decisionStatus,
                    suggestedEventFamily:
                        _cleanNullable(suggestedController.text),
                    reviewNote: _cleanNullable(reviewNoteController.text),
                    relationDirection: relationDirection,
                    approvedRelationType: decisionStatus == 'approved'
                        ? approvedRelationType
                        : null,
                    confidence:
                        decisionStatus == 'approved' ? confidence : null,
                    adminNotes: _cleanNullable(adminNotesController.text),
                    candidateTargetUnitId:
                        int.tryParse(targetUnitController.text.trim()),
                    candidateTargetCode:
                        _cleanNullable(targetCodeController.text),
                    candidateTargetPeriodId:
                        int.tryParse(targetPeriodController.text.trim()),
                    candidateTargetPeriodTitleAr:
                        _cleanNullable(targetPeriodTitleController.text),
                  );
                  _refreshAll();
                  if (!mounted) return;
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حفظ قرار المراجعة.')),
                  );
                } catch (error) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تعذر حفظ القرار: $error')),
                  );
                  if (ctx.mounted) setLocalState(() => saving = false);
                }
              }

              return AlertDialog(
                backgroundColor: const Color(0xFF111827),
                title: const Text('تحرير قرار المراجعة',
                    style: TextStyle(color: Colors.white)),
                content: SizedBox(
                  width: 720,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DialogReadOnlyInfo(label: 'الكود', value: row.code),
                        const SizedBox(height: 8),
                        _DialogReadOnlyInfo(
                            label: 'الفترة',
                            value:
                                '${row.periodTitleAr ?? '—'} (${row.periodId})'),
                        const SizedBox(height: 8),
                        _DialogReadOnlyInfo(
                            label: 'سبب الفجوة',
                            value: _gapReasonLabel(row.finalGapReason)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: decisionStatus,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.white),
                          decoration: _dialogInputDecoration('الحالة'),
                          items: const [
                            DropdownMenuItem(
                                value: 'pending', child: Text('معلّق')),
                            DropdownMenuItem(
                                value: 'approved', child: Text('معتمد')),
                            DropdownMenuItem(
                                value: 'rejected', child: Text('مرفوض')),
                            DropdownMenuItem(
                                value: 'ignored', child: Text('متجاهل')),
                          ],
                          onChanged: saving
                              ? null
                              : (value) => setLocalState(() =>
                                  decisionStatus = value ?? decisionStatus),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: suggestedController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _dialogInputDecoration('عائلة الحدث'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: reviewNoteController,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white),
                          decoration: _dialogInputDecoration('ملاحظة المراجعة'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: relationDirection,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.white),
                          decoration: _dialogInputDecoration('اتجاه العلاقة'),
                          items: const [
                            DropdownMenuItem(
                                value: 'queue_is_source',
                                child: Text('الصف الحالي هو المصدر')),
                            DropdownMenuItem(
                                value: 'queue_is_target',
                                child: Text('الصف الحالي هو الهدف')),
                          ],
                          onChanged: saving
                              ? null
                              : (value) => setLocalState(() =>
                                  relationDirection =
                                      value ?? relationDirection),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: approvedRelationType,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.white),
                          decoration: _dialogInputDecoration('نوع العلاقة'),
                          items: const [
                            DropdownMenuItem(
                                value: 'predecessor_of',
                                child: Text('سابق إداري')),
                            DropdownMenuItem(
                                value: 'split_into', child: Text('انقسام إلى')),
                            DropdownMenuItem(
                                value: 'merged_into', child: Text('اندماج في')),
                            DropdownMenuItem(
                                value: 'renamed_to',
                                child: Text('إعادة تسمية إلى')),
                            DropdownMenuItem(
                                value: 'transferred_to',
                                child: Text('نقل إلى')),
                            DropdownMenuItem(
                                value: 'administratively_attached_to',
                                child: Text('إلحاق إداري')),
                          ],
                          onChanged: saving
                              ? null
                              : (value) => setLocalState(() =>
                                  approvedRelationType =
                                      value ?? approvedRelationType),
                        ),
                        const SizedBox(height: 12),
                        Text('الثقة: ${confidence.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70)),
                        Slider(
                          value: confidence.clamp(0.0, 1.0),
                          min: 0,
                          max: 1,
                          divisions: 20,
                          onChanged: saving
                              ? null
                              : (value) =>
                                  setLocalState(() => confidence = value),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: targetUnitController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration:
                                    _dialogInputDecoration('Target unit id'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: targetCodeController,
                                style: const TextStyle(color: Colors.white),
                                decoration:
                                    _dialogInputDecoration('Target code'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: targetPeriodController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration:
                                    _dialogInputDecoration('Target period id'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: targetPeriodTitleController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _dialogInputDecoration(
                                    'Target period title'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: adminNotesController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              _dialogInputDecoration('ملاحظات القرار الإداري'),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: saving ? null : save,
                    child: Text(saving ? 'جارٍ الحفظ...' : 'حفظ'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      suggestedController.dispose();
      reviewNoteController.dispose();
      adminNotesController.dispose();
      targetUnitController.dispose();
      targetCodeController.dispose();
      targetPeriodController.dispose();
      targetPeriodTitleController.dispose();
    }
  }
}

class _CombinedSummary extends StatelessWidget {
  final AsyncValue<List<HistoricalAdminReviewMetric>> summaryAsync;
  final AsyncValue<List<HistoricalGapSummaryItem>> gapAsync;
  final AsyncValue<List<HistoricalAdminRelationReviewRow>> relationsAsync;

  const _CombinedSummary({
    required this.summaryAsync,
    required this.gapAsync,
    required this.relationsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return summaryAsync.when(
      data: (summary) => gapAsync.when(
        data: (gap) => relationsAsync.when(
          data: (relations) {
            final summaryMap = {
              for (final item in summary) item.metric: item.value
            };
            final gapMap = {
              for (final item in gap) item.finalGapReason: item.rowsCount
            };
            final splitCount =
                relations.where((e) => e.relationType == 'split_into').length;
            final cards = <_MetricCardData>[
              _MetricCardData(
                  'بداية سلسلة طبيعية',
                  gapMap['root_period_ok'] ?? 0,
                  Icons.first_page,
                  _MetricTone.success),
              _MetricCardData(
                  'وحدات عليا متوقعة',
                  gapMap['expected_non_anchor_unit'] ?? 0,
                  Icons.layers,
                  _MetricTone.info),
              _MetricCardData('فجوات backlog', _computeBacklog(gapMap),
                  Icons.pending_actions, _MetricTone.danger),
              _MetricCardData(
                  'predecessor_of',
                  summaryMap['relations_predecessor_of'] ?? 0,
                  Icons.timeline,
                  _MetricTone.warning),
              _MetricCardData(
                  'إجمالي العلاقات',
                  summaryMap['relations_total'] ?? 0,
                  Icons.account_tree,
                  _MetricTone.info),
              _MetricCardData(
                  'نهاية سلسلة طبيعية',
                  gapMap['terminal_period_ok'] ?? 0,
                  Icons.last_page,
                  _MetricTone.neutral),
            ];
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards.map((card) => _MetricCard(card: card)).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(minHeight: 4),
          error: (error, _) =>
              _InlineError(message: 'تعذر تحميل إحصاءات العلاقات: $error'),
        ),
        loading: () => const LinearProgressIndicator(minHeight: 4),
        error: (error, _) =>
            _InlineError(message: 'تعذر تحميل الفجوات: $error'),
      ),
      loading: () => const LinearProgressIndicator(minHeight: 4),
      error: (error, _) => _InlineError(message: 'تعذر تحميل الملخص: $error'),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final AsyncValue<List<HistoricalAdminReviewMetric>> summaryAsync;
  final AsyncValue<List<HistoricalGapSummaryItem>> gapAsync;
  final AsyncValue<List<HistoricalAdminRelationReviewRow>> relationsAsync;

  const _SummaryTab({
    required this.summaryAsync,
    required this.gapAsync,
    required this.relationsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          relationsAsync.when(
            data: (rows) => _TransitionSummaryCard(rows: rows),
            loading: () => const LinearProgressIndicator(minHeight: 4),
            error: (error, _) =>
                _InlineError(message: 'تعذر تحميل ملخص التحولات: $error'),
          ),
          const SizedBox(height: 16),
          gapAsync.when(
            data: (rows) => _GapSummarySection(rows: rows),
            loading: () => const LinearProgressIndicator(minHeight: 4),
            error: (error, _) =>
                _InlineError(message: 'تعذر تحميل ملخص الفجوات: $error'),
          ),
          const SizedBox(height: 16),
          summaryAsync.when(
            data: (rows) => _RawMetricsSection(rows: rows),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _RelationsTab extends StatelessWidget {
  final List<HistoricalAdminRelationReviewRow> rows;
  final List<HistoricalAdminRelationReviewRow> allRows;
  final String relationType;
  final String relationTransition;
  final TextEditingController searchController;
  final ValueChanged<String> onRelationTypeChanged;
  final ValueChanged<String> onRelationTransitionChanged;
  final ValueChanged<String> onSearchChanged;

  const _RelationsTab({
    required this.rows,
    required this.allRows,
    required this.relationType,
    required this.relationTransition,
    required this.searchController,
    required this.onRelationTypeChanged,
    required this.onRelationTransitionChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final transitions = _relationTransitionOptions(allRows);
    return Column(
      children: [
        _FilterCard(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _DropdownFilter(
                label: 'نوع الحدث',
                value: relationType,
                width: 240,
                items: {
                  'all': 'كل الأنواع',
                  ..._relationTypeItems(allRows),
                },
                onChanged: onRelationTypeChanged,
              ),
              _DropdownFilter(
                label: 'الفترة',
                value: relationTransition,
                width: 250,
                items: {'all': 'كل الفترات', ...transitions},
                onChanged: onRelationTransitionChanged,
              ),
              SizedBox(
                width: 340,
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: _filterInputDecoration(
                      'بحث بالكود أو الأصل أو ملاحظات الاعتماد...'),
                ),
              ),
              Text('النتائج ${rows.length}',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: rows.isEmpty
              ? const _EmptyState(
                  message: 'لا توجد علاقات مطابقة للفلاتر الحالية.')
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final sensitive =
                        _isSensitiveRow(row.sourceCode, row.targetCode);
                    return _AdminCard(
                      borderColor: sensitive
                          ? PwfColors.royalRed.withValues(alpha: 0.35)
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _Tag(
                                            text: _relationTypeLabel(
                                                row.relationType),
                                            tone: _eventTone(row.relationType)),
                                        _Tag(
                                            text:
                                                'الثقة ${row.confidence.toStringAsFixed(2)}',
                                            tone: _TagTone.info),
                                        _Tag(
                                          text:
                                              row.isActive ? 'مفعّل' : 'معطّل',
                                          tone: row.isActive
                                              ? _TagTone.success
                                              : _TagTone.warning,
                                        ),
                                        if (sensitive)
                                          const _Tag(
                                              text: 'حالة حساسة',
                                              tone: _TagTone.danger),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _SourceTargetFlow(
                                      sourceLabel: 'المصدر',
                                      sourceCode: row.sourceCode,
                                      sourcePeriodText:
                                          row.sourcePeriodTitleAr ??
                                              'الفترة ${row.sourcePeriodId}',
                                      targetLabel: 'الهدف',
                                      targetCode: row.targetCode,
                                      targetPeriodText:
                                          row.targetPeriodTitleAr ??
                                              'الفترة ${row.targetPeriodId}',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _MiniInfo(
                                      label: 'الأصل الحديث',
                                      value:
                                          '${row.sourceOriginCommunityCode ?? '—'} → ${row.targetOriginCommunityCode ?? '—'}'),
                                  const SizedBox(height: 8),
                                  _MiniInfo(
                                      label: 'فرق الفترة',
                                      value: '${row.periodDelta}'),
                                ],
                              ),
                            ],
                          ),
                          if ((row.notes ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.06)),
                              ),
                              child: Text(row.notes!,
                                  style: const TextStyle(
                                      color: Colors.white70, height: 1.5)),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () => (context.findAncestorStateOfType<
                                      _HistoricalTopologyAdminPageState>())
                                  ?._openHistoryMap(
                                sourceCode: row.sourceCode,
                                targetCode: row.targetCode,
                                focusCode: row.targetCode,
                                period:
                                    '${row.sourcePeriodTitleAr ?? row.sourcePeriodId} → ${row.targetPeriodTitleAr ?? row.targetPeriodId}',
                                relationType: row.relationType,
                                originCode: row.targetOriginCommunityCode ??
                                    row.sourceOriginCommunityCode,
                                title: 'العلاقات المؤكدة',
                              ),
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text('عرض على الخريطة'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _QueueTab extends StatelessWidget {
  final List<HistoricalTopologyQueueRow> rows;
  final List<HistoricalTopologyQueueRow> allRows;
  final String queueReason;
  final String queueFamily;
  final String queueStatus;
  final String queuePeriod;
  final String queueApplyState;
  final Set<int> selectedIds;
  final TextEditingController searchController;
  final ValueChanged<String> onQueueReasonChanged;
  final ValueChanged<String> onQueueFamilyChanged;
  final ValueChanged<String> onQueueStatusChanged;
  final ValueChanged<String> onQueuePeriodChanged;
  final ValueChanged<String> onQueueApplyStateChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<HistoricalTopologyQueueRow> onQuickIgnore;
  final ValueChanged<HistoricalTopologyQueueRow> onQuickReject;
  final ValueChanged<HistoricalTopologyQueueRow> onEdit;
  final void Function(int queueId, bool isSelected) onToggleSelection;
  final VoidCallback onSelectAllVisible;
  final VoidCallback onClearSelection;
  final VoidCallback onBatchIgnore;
  final VoidCallback onBatchReject;
  final VoidCallback onBatchPending;
  final VoidCallback onBatchApplyApproved;

  const _QueueTab({
    required this.rows,
    required this.allRows,
    required this.queueReason,
    required this.queueFamily,
    required this.queueStatus,
    required this.queuePeriod,
    required this.queueApplyState,
    required this.selectedIds,
    required this.searchController,
    required this.onQueueReasonChanged,
    required this.onQueueFamilyChanged,
    required this.onQueueStatusChanged,
    required this.onQueuePeriodChanged,
    required this.onQueueApplyStateChanged,
    required this.onSearchChanged,
    required this.onQuickIgnore,
    required this.onQuickReject,
    required this.onEdit,
    required this.onToggleSelection,
    required this.onSelectAllVisible,
    required this.onClearSelection,
    required this.onBatchIgnore,
    required this.onBatchReject,
    required this.onBatchPending,
    required this.onBatchApplyApproved,
  });

  @override
  Widget build(BuildContext context) {
    final reasonItems = <String, String>{'all': 'كل الأسباب'};
    for (final value in allRows.map((e) => e.finalGapReason).toSet().toList()
      ..sort()) {
      reasonItems[value] = _gapReasonLabel(value);
    }
    final familyItems = <String, String>{'all': 'كل العائلات'};
    for (final value in allRows
        .map((e) => e.suggestedEventFamily)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort()) {
      familyItems[value] = value;
    }
    final periodItems = <String, String>{'all': 'كل الفترات'};
    for (final value in allRows.map((e) => e.periodId).toSet().toList()
      ..sort()) {
      periodItems['$value'] = 'الفترة $value';
    }
    final selectedVisibleRows =
        rows.where((row) => selectedIds.contains(row.id)).toList();
    final selectedVisibleCount = selectedVisibleRows.length;
    final selectedApprovedWaitingApply =
        selectedVisibleRows.where((row) => row.isApprovedPendingApply).length;

    return Column(
      children: [
        _FilterCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _DropdownFilter(
                    label: 'سبب الفجوة',
                    value: queueReason,
                    width: 230,
                    items: reasonItems,
                    onChanged: onQueueReasonChanged,
                  ),
                  _DropdownFilter(
                    label: 'عائلة الحدث',
                    value: queueFamily,
                    width: 280,
                    items: familyItems,
                    onChanged: onQueueFamilyChanged,
                  ),
                  _DropdownFilter(
                    label: 'الحالة',
                    value: queueStatus,
                    width: 180,
                    items: const {
                      'all': 'كل الحالات',
                      'pending': 'معلّق',
                      'approved': 'معتمد',
                      'rejected': 'مرفوض',
                      'ignored': 'متجاهل',
                    },
                    onChanged: onQueueStatusChanged,
                  ),
                  _DropdownFilter(
                    label: 'التطبيق',
                    value: queueApplyState,
                    width: 220,
                    items: const {
                      'all': 'كل الصفوف',
                      'backlog_only': 'backlog فقط',
                      'approved_waiting_apply': 'معتمد بانتظار التطبيق',
                      'applied': 'مطبق فقط',
                      'not_applied': 'غير مطبق',
                    },
                    onChanged: onQueueApplyStateChanged,
                  ),
                  _DropdownFilter(
                    label: 'الفترة',
                    value: queuePeriod,
                    width: 170,
                    items: periodItems,
                    onChanged: onQueuePeriodChanged,
                  ),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      style: const TextStyle(color: Colors.white),
                      decoration: _filterInputDecoration(
                          'بحث بالكود أو الملاحظات أو target...'),
                    ),
                  ),
                  Text('النتائج ${rows.length}',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ActionChipButton(
                      label: 'تحديد الكل الظاهر',
                      onTap: rows.isEmpty ? null : onSelectAllVisible),
                  _ActionChipButton(
                      label: 'إلغاء التحديد',
                      onTap: selectedIds.isEmpty ? null : onClearSelection),
                  _ActionChipButton(
                    label: 'تجاهل المحدد',
                    onTap: selectedVisibleCount == 0 ? null : onBatchIgnore,
                    tone: _TagTone.neutral,
                  ),
                  _ActionChipButton(
                    label: 'رفض المحدد',
                    onTap: selectedVisibleCount == 0 ? null : onBatchReject,
                    tone: _TagTone.danger,
                  ),
                  _ActionChipButton(
                    label: 'إعادة إلى معلّق',
                    onTap: selectedVisibleCount == 0 ? null : onBatchPending,
                    tone: _TagTone.info,
                  ),
                  _ActionChipButton(
                    label: 'تطبيق المعتمد',
                    onTap: selectedApprovedWaitingApply == 0
                        ? null
                        : onBatchApplyApproved,
                    tone: _TagTone.success,
                  ),
                  Text(
                    'المحدد ${selectedIds.length} • الجاهز للتطبيق $selectedApprovedWaitingApply',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: rows.isEmpty
              ? const _EmptyState(
                  message: 'لا توجد عناصر في Queue مطابقة للفلاتر الحالية.')
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final isSelected = selectedIds.contains(row.id);
                    return _AdminCard(
                      borderColor: _queueBorderColor(row),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) =>
                                    onToggleSelection(row.id, value ?? false),
                                activeColor: PwfColors.primaryGold,
                                side: BorderSide(
                                    color:
                                        Colors.white.withValues(alpha: 0.35)),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _Tag(
                                            text: _decisionStatusLabel(
                                                row.decisionStatus),
                                            tone: _decisionTone(
                                                row.decisionStatus)),
                                        if (row.isApplied)
                                          const _Tag(
                                              text: 'مطبّق',
                                              tone: _TagTone.success)
                                        else if (row.isApprovedPendingApply)
                                          const _Tag(
                                              text: 'بانتظار التطبيق',
                                              tone: _TagTone.warning),
                                        _Tag(
                                            text: _gapReasonLabel(
                                                row.finalGapReason),
                                            tone: _TagTone.warning),
                                        if ((row.suggestedEventFamily ?? '')
                                            .isNotEmpty)
                                          _Tag(
                                              text: row.suggestedEventFamily!,
                                              tone: _TagTone.info),
                                        if ((row.approvedRelationType ?? '')
                                            .isNotEmpty)
                                          _Tag(
                                              text: _relationTypeLabel(
                                                  row.approvedRelationType!),
                                              tone: _eventTone(
                                                  row.approvedRelationType!)),
                                        if (row.confidence != null)
                                          _Tag(
                                              text:
                                                  'الثقة ${row.confidence!.toStringAsFixed(2)}',
                                              tone: _TagTone.info),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _LabeledCodeBlock(
                                        label: 'السجل', code: row.code),
                                    const SizedBox(height: 8),
                                    Text(
                                      row.periodTitleAr ??
                                          'الفترة ${row.periodId}',
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    ),
                                    if ((row.candidateTargetCode ?? '')
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      _SourceTargetFlow(
                                        sourceLabel: row.queueIsTarget
                                            ? 'المصدر/الجهة السابقة'
                                            : 'المصدر',
                                        sourceCode: row.sourceCodeForDisplay,
                                        sourcePeriodText:
                                            row.sourcePeriodTitleForDisplay ??
                                                '—',
                                        targetLabel: row.queueIsTarget
                                            ? 'الهدف'
                                            : 'الهدف/الجهة الجديدة',
                                        targetCode: row.targetCodeForDisplay,
                                        targetPeriodText:
                                            row.targetPeriodTitleForDisplay ??
                                                '—',
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: OutlinedButton.icon(
                                      onPressed: () => onEdit(row),
                                      icon:
                                          const Icon(Icons.edit_note, size: 18),
                                      label: const Text('تحرير'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 120,
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          (context.findAncestorStateOfType<
                                                  _HistoricalTopologyAdminPageState>())
                                              ?._openHistoryMap(
                                        sourceCode: row.sourceCodeForDisplay,
                                        targetCode: row.targetCodeForDisplay,
                                        focusCode:
                                            row.targetCodeForDisplay.isNotEmpty
                                                ? row.targetCodeForDisplay
                                                : row.code,
                                        period: row.periodTitleAr ??
                                            'الفترة ${row.periodId}',
                                        relationType:
                                            row.approvedRelationType ??
                                                row.finalGapReason,
                                        originCode: row.originCommunityCode,
                                        title: 'Queue المراجعة',
                                      ),
                                      icon: const Icon(Icons.map_outlined,
                                          size: 18),
                                      label: const Text('الخريطة'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (!row.isApplied)
                                    SizedBox(
                                      width: 120,
                                      child: TextButton.icon(
                                        onPressed: () => onQuickIgnore(row),
                                        icon: const Icon(Icons.visibility_off,
                                            size: 18, color: Colors.white70),
                                        label: const Text('تجاهل',
                                            style: TextStyle(
                                                color: Colors.white70)),
                                      ),
                                    ),
                                  if (!row.isApplied)
                                    SizedBox(
                                      width: 120,
                                      child: TextButton.icon(
                                        onPressed: () => onQuickReject(row),
                                        icon: const Icon(Icons.close,
                                            size: 18,
                                            color: PwfColors.royalRed),
                                        label: const Text('رفض',
                                            style: TextStyle(
                                                color: PwfColors.royalRed)),
                                      ),
                                    ),
                                  if (row.appliedRelationId != null) ...[
                                    const SizedBox(height: 8),
                                    _MiniInfo(
                                        label: 'relation id',
                                        value: '${row.appliedRelationId}'),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoParagraph(
                            label: row.isApplied
                                ? 'ملاحظات الاعتماد'
                                : 'ملاحظة المراجعة',
                            text: row.adminNotes ??
                                row.reviewNote ??
                                'لا توجد ملاحظات بعد.',
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AppliedEventsTab extends StatelessWidget {
  final List<HistoricalTopologyQueueRow> rows;
  final List<HistoricalTopologyQueueRow> allRows;
  final String appliedType;
  final String appliedPeriod;
  final TextEditingController searchController;
  final ValueChanged<String> onAppliedTypeChanged;
  final ValueChanged<String> onAppliedPeriodChanged;
  final ValueChanged<String> onSearchChanged;

  const _AppliedEventsTab({
    required this.rows,
    required this.allRows,
    required this.appliedType,
    required this.appliedPeriod,
    required this.searchController,
    required this.onAppliedTypeChanged,
    required this.onAppliedPeriodChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final relationTypes = <String, String>{'all': 'كل الأنواع'};
    for (final value in allRows
        .map((e) => e.approvedRelationType)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort()) {
      relationTypes[value] = _relationTypeLabel(value);
    }
    final periods = <String, String>{'all': 'كل الفترات'};
    for (final row in allRows) {
      final key =
          '${row.sourcePeriodForDisplay ?? '-'}→${row.targetPeriodForDisplay ?? '-'}';
      periods[key] =
          '${row.sourcePeriodForDisplay ?? '-'} → ${row.targetPeriodForDisplay ?? '-'}';
    }

    return Column(
      children: [
        _FilterCard(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _DropdownFilter(
                label: 'نوع الحدث',
                value: appliedType,
                width: 240,
                items: relationTypes,
                onChanged: onAppliedTypeChanged,
              ),
              _DropdownFilter(
                label: 'الفترة',
                value: appliedPeriod,
                width: 220,
                items: periods,
                onChanged: onAppliedPeriodChanged,
              ),
              SizedBox(
                width: 360,
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: _filterInputDecoration(
                      'بحث بالكود أو الهدف أو ملاحظات الاعتماد...'),
                ),
              ),
              Text('النتائج ${rows.length}',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: rows.isEmpty
              ? const _EmptyState(
                  message: 'لا توجد أحداث مطبقة مطابقة للفلاتر الحالية.')
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return _AdminCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        const _Tag(
                                            text: 'مطبّق',
                                            tone: _TagTone.success),
                                        if ((row.approvedRelationType ?? '')
                                            .isNotEmpty)
                                          _Tag(
                                              text: _relationTypeLabel(
                                                  row.approvedRelationType!),
                                              tone: _eventTone(
                                                  row.approvedRelationType!)),
                                        if (row.confidence != null)
                                          _Tag(
                                              text:
                                                  'الثقة ${row.confidence!.toStringAsFixed(2)}',
                                              tone: _TagTone.info),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _SourceTargetFlow(
                                      sourceLabel: 'المصدر',
                                      sourceCode: row.sourceCodeForDisplay,
                                      sourcePeriodText:
                                          row.sourcePeriodTitleForDisplay ??
                                              '—',
                                      targetLabel: 'الهدف',
                                      targetCode: row.targetCodeForDisplay,
                                      targetPeriodText:
                                          row.targetPeriodTitleForDisplay ??
                                              '—',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (row.appliedRelationId != null)
                                    _MiniInfo(
                                        label: 'relation id',
                                        value: '${row.appliedRelationId}'),
                                  if (row.appliedAt != null) ...[
                                    const SizedBox(height: 8),
                                    _MiniInfo(
                                        label: 'وقت التطبيق',
                                        value: _formatDateTime(row.appliedAt)),
                                  ],
                                  const SizedBox(height: 8),
                                  _MiniInfo(
                                    label: 'الفترة',
                                    value:
                                        '${row.sourcePeriodForDisplay ?? '—'} → ${row.targetPeriodForDisplay ?? '—'}',
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        (context.findAncestorStateOfType<
                                                _HistoricalTopologyAdminPageState>())
                                            ?._openHistoryMap(
                                      sourceCode: row.sourceCodeForDisplay,
                                      targetCode: row.targetCodeForDisplay,
                                      focusCode: row.targetCodeForDisplay,
                                      period:
                                          '${row.sourcePeriodForDisplay ?? '—'} → ${row.targetPeriodForDisplay ?? '—'}',
                                      relationType: row.approvedRelationType,
                                      originCode: row.originCommunityCode,
                                      title: 'الأحداث المطبقة',
                                    ),
                                    icon: const Icon(Icons.map_outlined,
                                        size: 18),
                                    label: const Text('الخريطة'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoParagraph(
                            label: 'ملاحظات الاعتماد',
                            text: row.adminNotes ?? 'بدون ملاحظات.',
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TransitionSummaryCard extends StatelessWidget {
  final List<HistoricalAdminRelationReviewRow> rows;
  const _TransitionSummaryCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    final labels = <String, String>{};
    for (final row in rows) {
      final key =
          '${row.sourcePeriodId}->${row.targetPeriodId}:${row.relationType}';
      counts[key] = (counts[key] ?? 0) + 1;
      labels[key] =
          '${row.sourcePeriodTitleAr ?? 'الفترة ${row.sourcePeriodId}'} → ${row.targetPeriodTitleAr ?? 'الفترة ${row.targetPeriodId}'} • ${_relationTypeLabel(row.relationType)}';
    }
    final sortedKeys = counts.keys.toList()
      ..sort((a, b) {
        final ap = int.tryParse(a.split('->').first) ?? 0;
        final bp = int.tryParse(b.split('->').first) ?? 0;
        return ap.compareTo(bp);
      });
    return _SectionCard(
      title: 'ملخص التحولات',
      child: Column(
        children: sortedKeys.map((key) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    labels[key] ?? key,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                _Tag(text: '${counts[key] ?? 0}', tone: _TagTone.info),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GapSummarySection extends StatelessWidget {
  final List<HistoricalGapSummaryItem> rows;
  const _GapSummarySection({required this.rows});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ملخص الفجوات',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: rows.map((row) {
          return _Tag(
            text: '${_gapReasonLabel(row.finalGapReason)}: ${row.rowsCount}',
            tone: row.finalGapReason.contains('pending')
                ? _TagTone.warning
                : _gapTone(row.finalGapReason),
          );
        }).toList(),
      ),
    );
  }
}

class _RawMetricsSection extends StatelessWidget {
  final List<HistoricalAdminReviewMetric> rows;
  const _RawMetricsSection({required this.rows});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'مقاييس خام من قاعدة البيانات',
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                    child: Text(row.metric,
                        style: const TextStyle(color: Colors.white70))),
                Text('${row.value}',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricCardData card;
  const _MetricCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final palette = _metricPalette(card.tone);
    return Container(
      width: 245,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.title,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  '${card.value}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(card.icon, color: palette.icon),
          ),
        ],
      ),
    );
  }
}

class _MetricCardData {
  final String title;
  final int value;
  final IconData icon;
  final _MetricTone tone;
  const _MetricCardData(this.title, this.value, this.icon, this.tone);
}

enum _MetricTone { success, info, warning, danger, neutral }

class _MetricPalette {
  final Color border;
  final Color background;
  final Color icon;
  const _MetricPalette(this.border, this.background, this.icon);
}

_MetricPalette _metricPalette(_MetricTone tone) {
  switch (tone) {
    case _MetricTone.success:
      return _MetricPalette(PwfColors.success,
          PwfColors.success.withValues(alpha: 0.12), PwfColors.success);
    case _MetricTone.info:
      return _MetricPalette(PwfColors.primaryBlue,
          PwfColors.primaryBlue.withValues(alpha: 0.14), PwfColors.primaryGold);
    case _MetricTone.warning:
      return _MetricPalette(PwfColors.primaryGold,
          PwfColors.primaryGold.withValues(alpha: 0.14), PwfColors.primaryGold);
    case _MetricTone.danger:
      return _MetricPalette(PwfColors.royalRed,
          PwfColors.royalRed.withValues(alpha: 0.14), PwfColors.royalRed);
    case _MetricTone.neutral:
      return _MetricPalette(
          const Color(0xFFB7791F),
          const Color(0xFFB7791F).withValues(alpha: 0.14),
          const Color(0xFFD69E2E));
  }
}

class _SourceTargetFlow extends StatelessWidget {
  final String sourceLabel;
  final String sourceCode;
  final String sourcePeriodText;
  final String targetLabel;
  final String targetCode;
  final String targetPeriodText;

  const _SourceTargetFlow({
    required this.sourceLabel,
    required this.sourceCode,
    required this.sourcePeriodText,
    required this.targetLabel,
    required this.targetCode,
    required this.targetPeriodText,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _DirectionalCodeCard(
            label: sourceLabel, code: sourceCode, subtitle: sourcePeriodText),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.arrow_back, color: Colors.white54, size: 18),
        ),
        _DirectionalCodeCard(
            label: targetLabel, code: targetCode, subtitle: targetPeriodText),
      ],
    );
  }
}

class _DirectionalCodeCard extends StatelessWidget {
  final String label;
  final String code;
  final String subtitle;
  const _DirectionalCodeCard(
      {required this.label, required this.code, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 360),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              code,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LabeledCodeBlock extends StatelessWidget {
  final String label;
  final String code;
  const _LabeledCodeBlock({required this.label, required this.code});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(code,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  const _MiniInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _InfoParagraph extends StatelessWidget {
  final String label;
  final String text;
  const _InfoParagraph({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          Text(text,
              style: const TextStyle(color: Colors.white70, height: 1.5)),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final _TagTone tone;

  const _ActionChipButton({
    required this.label,
    required this.onTap,
    this.tone = _TagTone.warning,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _tagPalette(tone);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.border),
          ),
          child: Text(
            label,
            style: TextStyle(
                color: palette.foreground,
                fontWeight: FontWeight.w700,
                fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final _TagTone tone;
  const _Tag({required this.text, this.tone = _TagTone.neutral});

  @override
  Widget build(BuildContext context) {
    final palette = _tagPalette(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Text(text,
          style: TextStyle(
              color: palette.foreground,
              fontWeight: FontWeight.w600,
              fontSize: 12)),
    );
  }
}

enum _TagTone { neutral, success, warning, danger, info }

class _TagPalette {
  final Color foreground;
  final Color background;
  final Color border;
  const _TagPalette(this.foreground, this.background, this.border);
}

_TagPalette _tagPalette(_TagTone tone) {
  switch (tone) {
    case _TagTone.success:
      return _TagPalette(
          PwfColors.success,
          PwfColors.success.withValues(alpha: 0.12),
          PwfColors.success.withValues(alpha: 0.35));
    case _TagTone.warning:
      return _TagPalette(
          PwfColors.primaryGold,
          PwfColors.primaryGold.withValues(alpha: 0.12),
          PwfColors.primaryGold.withValues(alpha: 0.35));
    case _TagTone.danger:
      return _TagPalette(
          PwfColors.royalRed,
          PwfColors.royalRed.withValues(alpha: 0.12),
          PwfColors.royalRed.withValues(alpha: 0.35));
    case _TagTone.info:
      return _TagPalette(
          const Color(0xFF60A5FA),
          const Color(0xFF1D4ED8).withValues(alpha: 0.12),
          const Color(0xFF1D4ED8).withValues(alpha: 0.35));
    case _TagTone.neutral:
      return _TagPalette(Colors.white70, Colors.white.withValues(alpha: 0.04),
          Colors.white.withValues(alpha: 0.10));
  }
}

class _AdminCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  const _AdminCard({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: borderColor ?? Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _FilterCard extends StatelessWidget {
  final Widget child;
  const _FilterCard({required this.child});

  @override
  Widget build(BuildContext context) => _AdminCard(child: child);
}

class _DropdownFilter extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final double width;
  final ValueChanged<String> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF0F172A),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F172A),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            items: items.entries
                .map((entry) => DropdownMenuItem<String>(
                    value: entry.key, child: Text(entry.value)))
                .toList(),
            onChanged: (value) => onChanged(value ?? 'all'),
          ),
        ],
      ),
    );
  }
}

class _DialogReadOnlyInfo extends StatelessWidget {
  final String label;
  final String value;
  const _DialogReadOnlyInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      borderColor: PwfColors.royalRed.withValues(alpha: 0.35),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: PwfColors.royalRed),
          const SizedBox(width: 10),
          Expanded(
              child:
                  Text(message, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}

InputDecoration _filterInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38),
    prefixIcon: const Icon(Icons.search, color: Colors.white54),
    filled: true,
    fillColor: const Color(0xFF0F172A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    ),
  );
}

InputDecoration _dialogInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: const Color(0xFF0F172A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    ),
  );
}

Map<String, String> _relationTypeItems(
    List<HistoricalAdminRelationReviewRow> rows) {
  final map = <String, String>{};
  for (final value in rows.map((e) => e.relationType).toSet().toList()
    ..sort()) {
    map[value] = _relationTypeLabel(value);
  }
  return map;
}

Map<String, String> _relationTransitionOptions(
    List<HistoricalAdminRelationReviewRow> rows) {
  final map = <String, String>{};
  for (final row in rows) {
    final key = _transitionKey(row);
    map[key] =
        '${row.sourcePeriodTitleAr ?? row.sourcePeriodId} → ${row.targetPeriodTitleAr ?? row.targetPeriodId}';
  }
  return map;
}

String _transitionKey(HistoricalAdminRelationReviewRow row) =>
    '${row.sourcePeriodId}→${row.targetPeriodId}';

String _relationTypeLabel(String value) {
  switch (value) {
    case 'predecessor_of':
      return 'سابق إداري';
    case 'split_into':
      return 'انقسام إلى';
    case 'merged_into':
      return 'اندماج في';
    case 'renamed_to':
      return 'إعادة تسمية إلى';
    case 'transferred_to':
      return 'نقل إلى';
    case 'administratively_attached_to':
      return 'إلحاق إداري';
    default:
      return value;
  }
}

_TagTone _eventTone(String value) {
  switch (value) {
    case 'split_into':
      return _TagTone.warning;
    case 'renamed_to':
      return _TagTone.info;
    case 'transferred_to':
      return _TagTone.success;
    case 'administratively_attached_to':
      return _TagTone.info;
    default:
      return _TagTone.neutral;
  }
}

String _gapReasonLabel(String value) {
  switch (value) {
    case 'expected_non_anchor_unit':
      return 'وحدة عليا متوقعة';
    case 'isolated_needs_review':
      return 'معزول يحتاج مراجعة';
    case 'missing_incoming_link':
      return 'رابط وارد مفقود';
    case 'missing_outgoing_link':
      return 'رابط صادر مفقود';
    case 'true_missing_origin':
      return 'أصل حديث مفقود';
    case 'root_period_ok':
      return 'بداية سلسلة طبيعية';
    case 'terminal_period_ok':
      return 'نهاية سلسلة طبيعية';
    case 'linked':
      return 'مرتبط';
    default:
      return value;
  }
}

_TagTone _gapTone(String value) {
  switch (value) {
    case 'expected_non_anchor_unit':
      return _TagTone.info;
    case 'isolated_needs_review':
      return _TagTone.warning;
    case 'missing_incoming_link':
      return _TagTone.danger;
    case 'root_period_ok':
    case 'terminal_period_ok':
      return _TagTone.success;
    case 'linked':
      return _TagTone.success;
    default:
      return _TagTone.neutral;
  }
}

String _decisionStatusLabel(String? value) {
  switch (value) {
    case 'approved':
      return 'معتمد';
    case 'rejected':
      return 'مرفوض';
    case 'ignored':
      return 'متجاهل';
    case 'pending':
    default:
      return 'معلّق';
  }
}

_TagTone _decisionTone(String? value) {
  switch (value) {
    case 'approved':
      return _TagTone.success;
    case 'rejected':
      return _TagTone.danger;
    case 'ignored':
      return _TagTone.neutral;
    case 'pending':
    default:
      return _TagTone.warning;
  }
}

Color? _queueBorderColor(HistoricalTopologyQueueRow row) {
  if (row.isApplied) {
    return PwfColors.info.withValues(alpha: 0.32);
  }
  switch (row.decisionStatus) {
    case 'approved':
      return PwfColors.success.withValues(alpha: 0.28);
    case 'rejected':
      return PwfColors.royalRed.withValues(alpha: 0.28);
    default:
      return null;
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

bool _isSensitiveRow(String sourceCode, String targetCode) {
  const keys = ['JE043', 'JER001', 'TU001'];
  return keys
      .any((key) => sourceCode.contains(key) || targetCode.contains(key));
}

int _computeBacklog(Map<String, int> gapMap) {
  return (gapMap['isolated_needs_review'] ?? 0) +
      (gapMap['missing_incoming_link'] ?? 0) +
      (gapMap['true_missing_origin'] ?? 0);
}

String? _cleanNullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
