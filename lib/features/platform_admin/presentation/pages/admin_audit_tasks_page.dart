// lib/features/platform_admin/presentation/pages/admin_audit_tasks_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/colors.dart';
import '../../../map/data/repositories/map_feedback_repository.dart';
import '../../../tasks_system/data/repositories/audit_task_repository.dart';

class AdminAuditTasksPage extends ConsumerStatefulWidget {
  const AdminAuditTasksPage({super.key});

  @override
  ConsumerState<AdminAuditTasksPage> createState() => _AdminAuditTasksPageState();
}

class _AdminAuditTasksPageState extends ConsumerState<AdminAuditTasksPage> {
  String _status = 'all';
  String _sourceSystem = 'mustakshif';
  bool _loading = false;
  late Future<List<AuditTask>> _future;

  static const List<String> _statuses = <String>[
    'all',
    'open',
    'in_progress',
    'blocked',
    'done',
    'cancelled',
  ];

  static const List<String> _sources = <String>[
    'all',
    'mustakshif',
  ];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AuditTask>> _load() {
    return ref.read(auditTaskRepositoryProvider).listAuditTasks(
          status: _status == 'all' ? null : _status,
          sourceSystem: _sourceSystem == 'all' ? null : _sourceSystem,
          limit: 150,
        );
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  Future<void> _updateStatus(
    AuditTask task,
    String status, {
    bool syncExplorerGap = false,
  }) async {
    final note = await _askForNote(
      title: syncExplorerGap
          ? '${_statusLabel(status)} + مزامنة طلب الفجوة'
          : _statusLabel(status),
      hint: syncExplorerGap
          ? 'ملاحظة اختيارية؛ سيتم تحديث المهمة ثم مزامنة طلب فجوة المستكشف المرتبط.'
          : 'ملاحظة اختيارية على تغيير حالة المهمة',
    );
    if (!mounted || note == null) return;

    setState(() => _loading = true);
    try {
      final updatedTask = await ref.read(auditTaskRepositoryProvider).updateStatus(
            taskId: task.id,
            newStatus: status,
            note: note.trim().isEmpty ? null : note.trim(),
          );

      var syncMessage = '';
      if (syncExplorerGap) {
        syncMessage = await _syncExplorerGapFromTask(
          task: updatedTask,
          note: note,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحديث المهمة إلى: ${_statusLabel(status)}$syncMessage',
          ),
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث المهمة: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String> _syncExplorerGapFromTask({
    required AuditTask task,
    required String note,
  }) async {
    if (task.sourceType != 'explorer_gap_audit_request' ||
        (task.sourceId ?? '').trim().isEmpty) {
      return '؛ لا يوجد طلب فجوة مرتبط للمزامنة.';
    }

    final gapStatus = _gapStatusForTaskStatus(task.status);
    if (gapStatus == null) {
      return '؛ لا توجد حالة فجوة مقابلة لهذه الحالة.';
    }

    await ref.read(mapFeedbackRepositoryProvider).reviewExplorerGapAuditRequest(
          requestId: task.sourceId!,
          newStatus: gapStatus,
          reviewerNote: _taskFeedbackSyncNote(
            task: task,
            note: note,
            gapStatus: gapStatus,
          ),
        );
    return '؛ وتمت مزامنة طلب الفجوة إلى: ${_gapStatusLabel(gapStatus)}';
  }


  Future<void> _assignTask(AuditTask task) async {
    final draft = await _askForAssignmentDraft(task);
    if (!mounted || draft == null) return;

    setState(() => _loading = true);
    try {
      final updated = await ref.read(auditTaskRepositoryProvider).assignAuditTask(
            taskId: task.id,
            assignedToUserId: draft.assignedToUserIdOrNull,
            dueDate: draft.dueDate,
            note: draft.noteOrNull,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث توجيه المهمة: ${updated.title}')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر توجيه المهمة: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<_TaskAssignmentDraft?> _askForAssignmentDraft(AuditTask task) {
    final assignedToController = TextEditingController(
      text: task.assignedToUserId ?? '',
    );
    final dueDateController = TextEditingController(
      text: task.dueDate == null ? '' : _dateLabel(task.dueDate!),
    );
    final noteController = TextEditingController();

    return showDialog<_TaskAssignmentDraft>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: const Text('توجيه مهمة التدقيق', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 620,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DarkTextField(
                  controller: assignedToController,
                  label: 'معرّف المستخدم المكلف UUID',
                  hint: 'اتركه فارغًا لإزالة التخصيص أو إبقائه غير محدد',
                ),
                const SizedBox(height: 10),
                _DarkTextField(
                  controller: dueDateController,
                  label: 'موعد الاستحقاق YYYY-MM-DD',
                ),
                const SizedBox(height: 10),
                _DarkTextField(
                  controller: noteController,
                  label: 'ملاحظة التوجيه',
                  minLines: 3,
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _TaskAssignmentDraft(
                  assignedToUserId: assignedToController.text,
                  dueDateText: dueDateController.text,
                  note: noteController.text,
                ),
              ),
              child: const Text('حفظ التوجيه'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      assignedToController.dispose();
      dueDateController.dispose();
      noteController.dispose();
    });
  }

  Future<String?> _askForNote({required String title, required String hint}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
              filled: true,
              fillColor: const Color(0xFF0B1220),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(loading: _loading, onRefresh: _refresh),
              const SizedBox(height: 14),
              _Filters(
                status: _status,
                sourceSystem: _sourceSystem,
                statuses: _statuses,
                sources: _sources,
                onStatusChanged: (value) {
                  setState(() {
                    _status = value ?? 'all';
                    _future = _load();
                  });
                },
                onSourceChanged: (value) {
                  setState(() {
                    _sourceSystem = value ?? 'mustakshif';
                    _future = _load();
                  });
                },
              ),
              const SizedBox(height: 14),
              const _InfoBanner(),
              const SizedBox(height: 14),
              Expanded(
                child: FutureBuilder<List<AuditTask>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _MessageCard(
                        icon: Icons.error_outline,
                        title: 'تعذر تحميل المهام',
                        message: snapshot.error.toString(),
                      );
                    }
                    final items = snapshot.data ?? const [];
                    if (items.isEmpty) {
                      return const _MessageCard(
                        icon: Icons.task_alt_outlined,
                        title: 'لا توجد مهام تدقيق',
                        message: 'ستظهر هنا المهام المنشأة من البلاغات أو فجوات المستكشف المقبولة.',
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => _refresh(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _SummaryStrip(items: items),
                          const SizedBox(height: 12),
                          ...items.map(
                            (task) => _AuditTaskCard(
                              task: task,
                              onStart: task.status == 'open'
                                  ? () => _updateStatus(task, 'in_progress')
                                  : null,
                              onBlocked: task.status != 'done' && task.status != 'cancelled'
                                  ? () => _updateStatus(task, 'blocked')
                                  : null,
                              onBlockedAndSync: task.status != 'done' &&
                                      task.status != 'cancelled' &&
                                      _isExplorerGapTask(task)
                                  ? () => _updateStatus(
                                        task,
                                        'blocked',
                                        syncExplorerGap: true,
                                      )
                                  : null,
                              onDone: task.status != 'done'
                                  ? () => _updateStatus(task, 'done')
                                  : null,
                              onDoneAndSync: task.status != 'done' &&
                                      _isExplorerGapTask(task)
                                  ? () => _updateStatus(
                                        task,
                                        'done',
                                        syncExplorerGap: true,
                                      )
                                  : null,
                              onCancel: task.status != 'cancelled' && task.status != 'done'
                                  ? () => _updateStatus(task, 'cancelled')
                                  : null,
                              onCancelAndSync: task.status != 'cancelled' &&
                                      task.status != 'done' &&
                                      _isExplorerGapTask(task)
                                  ? () => _updateStatus(
                                        task,
                                        'cancelled',
                                        syncExplorerGap: true,
                                      )
                                  : null,
                              onAssign: task.status != 'done' &&
                                      task.status != 'cancelled'
                                  ? () => _assignTask(task)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool loading;
  final VoidCallback onRefresh;

  const _Header({required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: PwfColors.primaryBlue.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.task_alt, color: PwfColors.primaryGold),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مهام التدقيق',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'مهام محكومة منشأة من بلاغات الخريطة وفجوات المستكشف المقبولة.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'تحديث',
          onPressed: loading ? null : onRefresh,
          icon: const Icon(Icons.refresh, color: Colors.white70),
        ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  final String status;
  final String sourceSystem;
  final List<String> statuses;
  final List<String> sources;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onSourceChanged;

  const _Filters({
    required this.status,
    required this.sourceSystem,
    required this.statuses,
    required this.sources,
    required this.onStatusChanged,
    required this.onSourceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Dropdown(
          label: 'الحالة',
          value: status,
          values: statuses,
          labelOf: _statusLabel,
          onChanged: onStatusChanged,
        ),
        _Dropdown(
          label: 'المصدر',
          value: sourceSystem,
          values: sources,
          labelOf: _sourceLabel,
          onChanged: onSourceChanged,
        ),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final String Function(String) labelOf;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: DropdownButtonFormField<String>(
        value: value,
        items: values
            .map((v) => DropdownMenuItem(value: v, child: Text(labelOf(v))))
            .toList(growable: false),
        onChanged: onChanged,
        dropdownColor: const Color(0xFF111827),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF111827),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PwfColors.primaryBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.25)),
      ),
      child: const Text(
        'هذه الصفحة تعرض مهام التدقيق الفعلية داخل tasks_system. مصدر المهمة يبقى محفوظًا كرابط وسياق، ولا يتم تعديل الجداول السيادية مباشرة.',
        style: TextStyle(color: Colors.white70, height: 1.5),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final List<AuditTask> items;

  const _SummaryStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    int count(String status) => items.where((e) => e.status == status).length;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryPill(label: 'الإجمالي', value: items.length),
        _SummaryPill(label: 'مفتوحة', value: count('open')),
        _SummaryPill(label: 'قيد التنفيذ', value: count('in_progress')),
        _SummaryPill(label: 'متوقفة', value: count('blocked')),
        _SummaryPill(label: 'منجزة', value: count('done')),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final int value;

  const _SummaryPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text('$label: $value', style: const TextStyle(color: Colors.white70)),
    );
  }
}

class _AuditTaskCard extends StatelessWidget {
  final AuditTask task;
  final VoidCallback? onStart;
  final VoidCallback? onBlocked;
  final VoidCallback? onBlockedAndSync;
  final VoidCallback? onDone;
  final VoidCallback? onDoneAndSync;
  final VoidCallback? onCancel;
  final VoidCallback? onCancelAndSync;
  final VoidCallback? onAssign;

  const _AuditTaskCard({
    required this.task,
    this.onStart,
    this.onBlocked,
    this.onBlockedAndSync,
    this.onDone,
    this.onDoneAndSync,
    this.onCancel,
    this.onCancelAndSync,
    this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final gapSyncLabel = _gapStatusLabel(
      _gapStatusForTaskStatus(task.status) ?? 'none',
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF111827),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                _Chip(text: task.displayPriority, icon: Icons.flag_outlined),
                const SizedBox(width: 8),
                _Chip(text: task.displayStatus, icon: Icons.task_alt_outlined),
              ],
            ),
            if ((task.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: const TextStyle(color: Colors.white70, height: 1.4),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if ((task.sourceType ?? '').trim().isNotEmpty)
                  _Chip(text: _sourceTypeLabel(task.sourceType!), icon: Icons.link_outlined),
                if ((task.sourceSystem ?? '').trim().isNotEmpty)
                  _Chip(text: _sourceLabel(task.sourceSystem!), icon: Icons.hub_outlined),
                if (_isExplorerGapTask(task))
                  _Chip(
                    text: 'مزامنة مقترحة: $gapSyncLabel',
                    icon: Icons.sync,
                  ),
                if ((task.assignedToUserId ?? '').trim().isNotEmpty)
                  _Chip(
                    text: 'مكلف: ${_shortId(task.assignedToUserId!)}',
                    icon: Icons.person_outline,
                  ),
                if (task.dueDate != null)
                  _Chip(
                    text: 'استحقاق: ${_dateLabel(task.dueDate!)}',
                    icon: Icons.event_available_outlined,
                  ),
                if (task.createdAt != null)
                  _Chip(text: _dateLabel(task.createdAt!), icon: Icons.schedule),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onStart != null)
                  OutlinedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('بدء التنفيذ'),
                  ),
                if (onBlocked != null)
                  OutlinedButton.icon(
                    onPressed: onBlocked,
                    icon: const Icon(Icons.pause_circle_outline, size: 18),
                    label: const Text('إيقاف'),
                  ),
                if (onBlockedAndSync != null)
                  OutlinedButton.icon(
                    onPressed: onBlockedAndSync,
                    icon: const Icon(Icons.sync_problem_outlined, size: 18),
                    label: const Text('إيقاف + فرز الطلب'),
                  ),
                if (onDone != null)
                  FilledButton.icon(
                    onPressed: onDone,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('إنجاز'),
                  ),
                if (onDoneAndSync != null)
                  FilledButton.icon(
                    onPressed: onDoneAndSync,
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('إنجاز + إغلاق الطلب'),
                  ),
                if (onCancel != null)
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('إلغاء'),
                  ),
                if (onCancelAndSync != null)
                  OutlinedButton.icon(
                    onPressed: onCancelAndSync,
                    icon: const Icon(Icons.cancel_presentation_outlined, size: 18),
                    label: const Text('إلغاء + رفض الطلب'),
                  ),
                if (onAssign != null)
                  FilledButton.icon(
                    onPressed: onAssign,
                    icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                    label: const Text('توجيه'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData? icon;

  const _Chip({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PwfColors.primaryBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: PwfColors.primaryGold),
            const SizedBox(width: 5),
          ],
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}


class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int minLines;
  final int maxLines;

  const _DarkTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
        filled: true,
        fillColor: const Color(0xFF0B1220),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
    );
  }
}

class _TaskAssignmentDraft {
  final String assignedToUserId;
  final String dueDateText;
  final String note;

  const _TaskAssignmentDraft({
    required this.assignedToUserId,
    required this.dueDateText,
    required this.note,
  });

  String? get assignedToUserIdOrNull => _blankToNull(assignedToUserId);
  String? get noteOrNull => _blankToNull(note);

  DateTime? get dueDate {
    final text = dueDateText.trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: PwfColors.primaryGold, size: 34),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}



String? _blankToNull(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

String _shortId(String id) {
  final text = id.trim();
  if (text.length <= 12) return text;
  return '${text.substring(0, 8)}…${text.substring(text.length - 4)}';
}

bool _isExplorerGapTask(AuditTask task) {
  return task.sourceType == 'explorer_gap_audit_request' &&
      (task.sourceId ?? '').trim().isNotEmpty;
}

String? _gapStatusForTaskStatus(String taskStatus) => switch (taskStatus) {
      'in_progress' => 'accepted',
      'blocked' => 'triaged',
      'done' => 'resolved',
      'cancelled' => 'rejected',
      _ => null,
    };

String _taskFeedbackSyncNote({
  required AuditTask task,
  required String note,
  required String gapStatus,
}) {
  final lines = <String>[
    'مزامنة من حالة مهمة التدقيق.',
    'task_id: ${task.id}',
    'task_status: ${task.status}',
    'gap_status: $gapStatus',
  ];
  if (note.trim().isNotEmpty) lines.add('ملاحظة منفذ المهمة: ${note.trim()}');
  return lines.join('\n');
}

String _gapStatusLabel(String status) => switch (status) {
      'accepted' => 'مقبول',
      'triaged' => 'قيد الفرز',
      'resolved' => 'مغلق',
      'rejected' => 'مرفوض',
      'none' => 'لا شيء',
      _ => status,
    };

String _statusLabel(String status) => switch (status) {
      'all' => 'الكل',
      'open' => 'مفتوحة',
      'in_progress' => 'قيد التنفيذ',
      'blocked' => 'متوقفة',
      'done' => 'منجزة',
      'cancelled' => 'ملغاة',
      _ => status,
    };

String _sourceLabel(String source) => switch (source) {
      'all' => 'كل المصادر',
      'mustakshif' => 'مستكشف الوقف',
      _ => source,
    };

String _sourceTypeLabel(String sourceType) => switch (sourceType) {
      'map_feedback_report' => 'بلاغ خريطة',
      'explorer_gap_audit_request' => 'فجوة مستكشف',
      _ => sourceType,
    };

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
