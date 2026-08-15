// lib/features/platform_admin/presentation/pages/admin_explorer_gap_audits_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/colors.dart';
import '../../../map/data/repositories/map_feedback_repository.dart';
import '../../../map/presentation/services/explorer_export_download_service.dart';
import '../../../tasks_system/data/repositories/audit_task_repository.dart';

class AdminExplorerGapAuditsPage extends ConsumerStatefulWidget {
  const AdminExplorerGapAuditsPage({super.key});

  @override
  ConsumerState<AdminExplorerGapAuditsPage> createState() =>
      _AdminExplorerGapAuditsPageState();
}

class _AdminExplorerGapAuditsPageState
    extends ConsumerState<AdminExplorerGapAuditsPage> {
  String _status = 'new';
  String _domain = 'all';
  bool _loading = false;
  late Future<_GapAuditDashboardData> _future;

  static const List<String> _statuses = <String>[
    'all',
    'new',
    'triaged',
    'accepted',
    'rejected',
    'resolved',
  ];

  static const List<String> _domains = <String>[
    'all',
    'التاريخ',
    'الحديث',
    'الوقف',
    'السلالة',
  ];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_GapAuditDashboardData> _load() async {
    final requests = await ref
        .read(mapFeedbackRepositoryProvider)
        .listExplorerGapAuditRequests(
          status: _status == 'all' ? null : _status,
          domain: _domain == 'all' ? null : _domain,
          limit: 100,
        );

    final tasksBySourceId = <String, AuditTask>{};
    try {
      final tasks = await ref.read(auditTaskRepositoryProvider).listAuditTasks(
            sourceSystem: 'mustakshif',
            limit: 300,
          );
      for (final task in tasks) {
        final sourceId = task.sourceId;
        if (task.sourceType == 'explorer_gap_audit_request' &&
            sourceId != null &&
            sourceId.trim().isNotEmpty) {
          tasksBySourceId[sourceId] = task;
        }
      }
    } catch (_) {
      // Keep the review board usable even if the task bridge RPC is not ready yet.
    }

    return _GapAuditDashboardData(
      requests: requests,
      tasksBySourceId: tasksBySourceId,
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _syncRequestFromTask(
    ExplorerGapAuditRequest request,
    AuditTask task,
  ) async {
    final nextStatus = _recommendedGapStatusForTaskStatus(task.status);
    if (nextStatus == null || nextStatus == request.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد مزامنة مطلوبة لهذا الطلب.')),
      );
      return;
    }

    final note = await _askForNote(
      title: 'مزامنة الطلب من حالة المهمة',
      hint: 'ملاحظة اختيارية؛ سيتم إرفاق حالة المهمة المرتبطة في سجل المراجعة.',
    );
    if (!mounted || note == null) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(mapFeedbackRepositoryProvider)
          .reviewExplorerGapAuditRequest(
            requestId: request.id,
            newStatus: nextStatus,
            reviewerNote: _buildTaskSyncNote(
              task: task,
              note: note,
              nextStatus: nextStatus,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت مزامنة الطلب إلى: ${_statusLabel(nextStatus)}',
          ),
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذرت مزامنة الطلب من المهمة: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _syncVisibleFromTasks(_GapAuditDashboardData data) async {
    final pending = data.pendingSyncRequests;
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('لا توجد طلبات تحتاج مزامنة ضمن النتائج الحالية.')),
      );
      return;
    }

    final note = await _askForNote(
      title: 'مزامنة جماعية من المهام',
      hint: 'ملاحظة اختيارية تُضاف لكل طلب تتم مزامنته.',
    );
    if (!mounted || note == null) return;

    setState(() => _loading = true);
    var ok = 0;
    var failed = 0;
    for (final request in pending) {
      final task = data.taskFor(request.id);
      final nextStatus =
          task == null ? null : _recommendedGapStatusForTaskStatus(task.status);
      if (task == null || nextStatus == null || nextStatus == request.status) {
        continue;
      }
      try {
        await ref
            .read(mapFeedbackRepositoryProvider)
            .reviewExplorerGapAuditRequest(
              requestId: request.id,
              newStatus: nextStatus,
              reviewerNote: _buildTaskSyncNote(
                task: task,
                note: note,
                nextStatus: nextStatus,
              ),
            );
        ok++;
      } catch (_) {
        failed++;
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('اكتملت المزامنة: $ok ناجحة، $failed فاشلة.')),
    );
    _refresh();
  }

  Future<void> _exportReviewBoardCsv(_GapAuditDashboardData data) async {
    final csv = _reviewBoardCsv(data);
    final downloaded = await ExplorerExportDownloadService.downloadTextFile(
      fileName:
          'explorer_review_board_sync_${DateTime.now().millisecondsSinceEpoch}.csv',
      content: csv,
      mimeType: 'text/csv;charset=utf-8',
    );
    if (!mounted) return;
    if (!downloaded) {
      await Clipboard.setData(ClipboardData(text: csv));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          downloaded
              ? 'تم تنزيل CSV للوحة المراجعة.'
              : 'التنزيل غير مدعوم هنا؛ تم نسخ CSV للحافظة.',
        ),
      ),
    );
  }

  Future<void> _review(
    ExplorerGapAuditRequest request,
    String newStatus,
  ) async {
    final note = await _askForNote(
      title: _statusLabel(newStatus),
      hint: 'ملاحظة المراجعة اختيارية',
    );
    if (!mounted || note == null) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(mapFeedbackRepositoryProvider)
          .reviewExplorerGapAuditRequest(
            requestId: request.id,
            newStatus: newStatus,
            reviewerNote: note.trim().isEmpty ? null : note.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تم تحديث الطلب إلى: ${_statusLabel(newStatus)}')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث طلب التدقيق: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acceptAndCreateAuditTask(
      ExplorerGapAuditRequest request) async {
    final note = await _askForNote(
      title: 'قبول الطلب وإنشاء مهمة',
      hint: 'ملاحظة اختيارية؛ ستستخدم كملاحظة مراجعة ووصف أولي للمهمة.',
    );
    if (!mounted || note == null) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(mapFeedbackRepositoryProvider)
          .reviewExplorerGapAuditRequest(
            requestId: request.id,
            newStatus: 'accepted',
            reviewerNote: note.trim().isEmpty ? null : note.trim(),
          );
      final task =
          await ref.read(auditTaskRepositoryProvider).createFromExplorerGap(
                requestId: request.id,
                title: 'مهمة تدقيق فجوة مستكشف: ${request.title}',
                description: note.trim().isEmpty ? null : note.trim(),
                priority: request.priority,
              );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم قبول الطلب وإنشاء مهمة: ${task.title}')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر قبول الطلب وإنشاء المهمة: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createAuditTask(ExplorerGapAuditRequest request) async {
    final description = await _askForNote(
      title: 'إنشاء مهمة تدقيق',
      hint: 'وصف المهمة اختياري. اتركه فارغًا لاستخدام وصف الفجوة.',
    );
    if (!mounted || description == null) return;

    setState(() => _loading = true);
    try {
      final task = await ref
          .read(auditTaskRepositoryProvider)
          .createFromExplorerGap(
            requestId: request.id,
            title: 'مهمة تدقيق فجوة مستكشف: ${request.title}',
            description: description.trim().isEmpty ? null : description.trim(),
            priority: request.priority,
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _attachEvidence(ExplorerGapAuditRequest request) async {
    final draft = await _askForEvidenceAttachment(request);
    if (!mounted || draft == null) return;

    setState(() => _loading = true);
    try {
      final attachment = await ref
          .read(mapFeedbackRepositoryProvider)
          .createExplorerGapAuditEvidence(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرفاق دليل مراجعة: ${attachment.title}')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرفاق دليل المراجعة: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showEvidenceAttachments(ExplorerGapAuditRequest request) async {
    setState(() => _loading = true);
    try {
      final attachments = await ref
          .read(mapFeedbackRepositoryProvider)
          .listExplorerGapAuditEvidence(requestId: request.id, limit: 50);
      if (!mounted) return;
      setState(() => _loading = false);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF111827),
            title: Text(
              'أدلة المراجعة — ${request.title}',
              style: const TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: 780,
              child: attachments.isEmpty
                  ? const Text(
                      'لا توجد مرفقات دليل لهذا الطلب بعد.',
                      style: TextStyle(color: Colors.white70),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: attachments
                            .map(
                              (item) => _EvidenceAttachmentTile(
                                item: item,
                                onAccept: item.reviewState == 'accepted'
                                    ? null
                                    : () {
                                        Navigator.of(dialogContext).pop();
                                        _reviewEvidenceAttachment(
                                          request: request,
                                          item: item,
                                          reviewState: 'accepted',
                                        );
                                      },
                                onReject: item.reviewState == 'rejected'
                                    ? null
                                    : () {
                                        Navigator.of(dialogContext).pop();
                                        _reviewEvidenceAttachment(
                                          request: request,
                                          item: item,
                                          reviewState: 'rejected',
                                        );
                                      },
                                onUnderReview:
                                    item.reviewState == 'under_review'
                                        ? null
                                        : () {
                                            Navigator.of(dialogContext).pop();
                                            _reviewEvidenceAttachment(
                                              request: request,
                                              item: item,
                                              reviewState: 'under_review',
                                            );
                                          },
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إغلاق'),
              ),
              if (attachments.isNotEmpty)
                FilledButton.icon(
                  onPressed: () async {
                    final text =
                        _evidenceAttachmentsReport(request, attachments);
                    await Clipboard.setData(ClipboardData(text: text));
                    if (dialogContext.mounted)
                      Navigator.of(dialogContext).pop();
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('نسخ التقرير'),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل أدلة المراجعة: $e')),
      );
    }
  }

  Future<void> _reviewEvidenceAttachment({
    required ExplorerGapAuditRequest request,
    required ExplorerGapAuditEvidenceAttachment item,
    required String reviewState,
  }) async {
    final note = await _askForNote(
      title: 'مراجعة الدليل: ${_evidenceReviewStateLabel(reviewState)}',
      hint: 'ملاحظة اختيارية على اعتماد/رفض/فرز الدليل.',
    );
    if (!mounted || note == null) return;

    setState(() => _loading = true);
    try {
      final updated = await ref
          .read(mapFeedbackRepositoryProvider)
          .reviewExplorerGapAuditEvidence(
            evidenceId: item.id,
            reviewState: reviewState,
            reviewNote: note.trim().isEmpty ? null : note.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحديث حالة الدليل إلى: ${updated.displayReviewState}',
          ),
        ),
      );
      await _showEvidenceAttachments(request);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث مراجعة الدليل: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showReviewTimeline(ExplorerGapAuditRequest request) async {
    setState(() => _loading = true);
    try {
      final timeline = await ref
          .read(mapFeedbackRepositoryProvider)
          .listExplorerGapAuditTimeline(requestId: request.id, limit: 200);
      if (!mounted) return;
      setState(() => _loading = false);
      await showDialog<void>(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF111827),
            title: Text(
              'خط زمني للمراجعة — ${request.title}',
              style: const TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: 820,
              child: timeline.isEmpty
                  ? const Text(
                      'لا توجد أحداث كافية لبناء الخط الزمني.',
                      style: TextStyle(color: Colors.white70),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: timeline
                            .map((event) => _TimelineEventTile(event: event))
                            .toList(growable: false),
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
              if (timeline.isNotEmpty)
                FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: _timelineReport(request, timeline)),
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('نسخ الخط الزمني'),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل الخط الزمني للمراجعة: $e')),
      );
    }
  }

  Future<void> _showStoragePolicy(ExplorerGapAuditRequest request) async {
    setState(() => _loading = true);
    try {
      final policy = await ref
          .read(mapFeedbackRepositoryProvider)
          .fetchExplorerGapAuditStoragePolicy(requestId: request.id);
      if (!mounted) return;
      setState(() => _loading = false);
      await showDialog<void>(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF111827),
            title: const Text(
              'سياسة تخزين أدلة المراجعة',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: 760,
              child: _StoragePolicyView(policy: policy, request: request),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: _storagePolicyReport(request, policy)),
                  );
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('نسخ السياسة'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل سياسة التخزين: $e')),
      );
    }
  }

  Future<void> _createRoutedAuditTask(
    ExplorerGapAuditRequest request, {
    bool acceptFirst = false,
  }) async {
    final routing = await _askForTaskRouting(
      title: acceptFirst ? 'قبول الطلب وإنشاء مهمة موجهة' : 'إنشاء مهمة موجهة',
      descriptionHint:
          'وصف المهمة اختياري. يمكن تحديد مستخدم مكلف وموعد استحقاق أولي.',
    );
    if (!mounted || routing == null) return;

    setState(() => _loading = true);
    try {
      if (acceptFirst && request.status != 'accepted') {
        await ref
            .read(mapFeedbackRepositoryProvider)
            .reviewExplorerGapAuditRequest(
              requestId: request.id,
              newStatus: 'accepted',
              reviewerNote: _routingReviewNote(routing),
            );
      }

      var task =
          await ref.read(auditTaskRepositoryProvider).createFromExplorerGap(
                requestId: request.id,
                title: 'مهمة تدقيق موجهة: ${request.title}',
                description: routing.descriptionOrNull,
                priority: request.priority,
                dueDate: routing.dueDate,
              );

      if (routing.assignedToUserIdOrNull != null ||
          routing.assignmentNoteOrNull != null ||
          routing.dueDate != null) {
        task = await ref.read(auditTaskRepositoryProvider).assignAuditTask(
              taskId: task.id,
              assignedToUserId: routing.assignedToUserIdOrNull,
              dueDate: routing.dueDate,
              note: routing.assignmentNoteOrNull,
            );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء مهمة موجهة: ${task.title}')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إنشاء المهمة الموجهة: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<ExplorerGapAuditEvidenceDraft?> _askForEvidenceAttachment(
    ExplorerGapAuditRequest request,
  ) {
    final titleController = TextEditingController();
    final typeController = TextEditingController(text: 'source_url');
    final urlController = TextEditingController();
    final storageBucketController = TextEditingController(
      text: 'explorer-review-evidence',
    );
    final storagePathController = TextEditingController(
      text: _suggestEvidenceStoragePath(request),
    );
    final originalFileNameController = TextEditingController();
    final mimeTypeController = TextEditingController();
    final fileSizeController = TextEditingController();
    final checksumController = TextEditingController();
    final noteController = TextEditingController();

    return showDialog<ExplorerGapAuditEvidenceDraft>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: const Text('إرفاق دليل مراجعة',
              style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 760,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _StoragePolicyHint(),
                  const SizedBox(height: 10),
                  _DarkTextField(
                      controller: titleController, label: 'عنوان الدليل'),
                  const SizedBox(height: 10),
                  _DarkTextField(
                    controller: typeController,
                    label: 'نوع الدليل',
                    hint:
                        'source_url / document / map_snapshot / field_note / photo',
                  ),
                  const SizedBox(height: 10),
                  _DarkTextField(
                      controller: urlController, label: 'رابط مرجعي اختياري'),
                  const SizedBox(height: 10),
                  _DarkTextField(
                    controller: storageBucketController,
                    label: 'Storage bucket',
                    hint: 'explorer-review-evidence',
                  ),
                  const SizedBox(height: 10),
                  _DarkTextField(
                    controller: storagePathController,
                    label: 'Storage object path',
                    hint: 'gap-audits/{request_id}/YYYY/MM/file.ext',
                  ),
                  const SizedBox(height: 10),
                  _DarkTextField(
                    controller: originalFileNameController,
                    label: 'اسم الملف الأصلي بعد الرفع اختياري',
                    hint: 'مثال: field_photo_001.jpg أو evidence.pdf',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DarkTextField(
                          controller: mimeTypeController,
                          label: 'MIME type اختياري',
                          hint: 'application/pdf أو image/png',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DarkTextField(
                          controller: fileSizeController,
                          label: 'حجم الملف bytes اختياري',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _DarkTextField(
                    controller: checksumController,
                    label: 'SHA-256 اختياري للملفات الثنائية',
                  ),
                  const SizedBox(height: 10),
                  _DarkTextField(
                    controller: noteController,
                    label: 'ملاحظة الدليل',
                    minLines: 3,
                    maxLines: 6,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                Navigator.of(context).pop(
                  ExplorerGapAuditEvidenceDraft(
                    requestId: request.id,
                    evidenceType: typeController.text.trim().isEmpty
                        ? 'note'
                        : typeController.text.trim(),
                    title: title,
                    referenceUrl: _blankToNull(urlController.text),
                    storageBucket: storageBucketController.text.trim().isEmpty
                        ? 'explorer-review-evidence'
                        : storageBucketController.text.trim(),
                    storageObjectPath: _blankToNull(storagePathController.text),
                    filePath: _blankToNull(storagePathController.text),
                    fileSizeBytes: _parseOptionalInt(fileSizeController.text),
                    mimeType: _blankToNull(mimeTypeController.text),
                    checksumSha256: _blankToNull(checksumController.text),
                    note: _blankToNull(noteController.text),
                    metadata: <String, dynamic>{
                      'source':
                          'bridge_batch_p_evidence_timeline_storage_policy',
                      'request_title': request.title,
                      'request_status': request.status,
                      'request_domain': request.domain,
                      'storage_policy': 'explorer-review-evidence/private/10mb',
                      'original_file_name':
                          _blankToNull(originalFileNameController.text),
                      'bridge_batch': 'Q_evidence_upload_ux_reviewer_identity',
                    },
                  ),
                );
              },
              child: const Text('إرفاق'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      titleController.dispose();
      typeController.dispose();
      urlController.dispose();
      storageBucketController.dispose();
      storagePathController.dispose();
      originalFileNameController.dispose();
      mimeTypeController.dispose();
      fileSizeController.dispose();
      checksumController.dispose();
      noteController.dispose();
    });
  }

  Future<_TaskRoutingDraft?> _askForTaskRouting({
    required String title,
    required String descriptionHint,
  }) {
    final descriptionController = TextEditingController();
    final assignedToController = TextEditingController();
    final dueDateController = TextEditingController();
    final noteController = TextEditingController();

    return showDialog<_TaskRoutingDraft>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 680,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DarkTextField(
                    controller: descriptionController,
                    label: 'وصف المهمة',
                    hint: descriptionHint,
                    minLines: 3,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 10),
                  _DarkTextField(
                    controller: assignedToController,
                    label: 'معرّف المستخدم المكلف اختياري UUID',
                  ),
                  const SizedBox(height: 10),
                  _DarkTextField(
                    controller: dueDateController,
                    label: 'موعد الاستحقاق اختياري YYYY-MM-DD',
                  ),
                  const SizedBox(height: 10),
                  _DarkTextField(
                    controller: noteController,
                    label: 'ملاحظة التوجيه',
                    minLines: 2,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _TaskRoutingDraft(
                  description: descriptionController.text,
                  assignedToUserId: assignedToController.text,
                  dueDateText: dueDateController.text,
                  assignmentNote: noteController.text,
                ),
              ),
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      descriptionController.dispose();
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
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.1)),
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
              _Header(
                loading: _loading,
                onRefresh: _refresh,
              ),
              const SizedBox(height: 14),
              _Filters(
                status: _status,
                domain: _domain,
                statuses: _statuses,
                domains: _domains,
                onStatusChanged: (value) {
                  setState(() {
                    _status = value ?? 'new';
                    _future = _load();
                  });
                },
                onDomainChanged: (value) {
                  setState(() {
                    _domain = value ?? 'all';
                    _future = _load();
                  });
                },
              ),
              const SizedBox(height: 14),
              const _InfoBanner(),
              const SizedBox(height: 14),
              Expanded(
                child: FutureBuilder<_GapAuditDashboardData>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _ErrorCard(error: snapshot.error.toString());
                    }
                    final data =
                        snapshot.data ?? const _GapAuditDashboardData();
                    final items = data.requests;
                    if (items.isEmpty) return const _EmptyCard();

                    final grouped = _groupByStatus(items);
                    return RefreshIndicator(
                      onRefresh: () async => _refresh(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _SummaryStrip(
                            items: items,
                            linkedTaskCount: data.tasksBySourceId.length,
                            pendingSyncCount: data.pendingSyncCount,
                          ),
                          const SizedBox(height: 12),
                          _ReviewBoardHardeningPanel(
                            data: data,
                            onExportCsv: () => _exportReviewBoardCsv(data),
                            onSyncVisible: () => _syncVisibleFromTasks(data),
                          ),
                          const SizedBox(height: 12),
                          ...grouped.entries.expand(
                            (entry) => [
                              _GroupHeader(
                                title: _statusLabel(entry.key),
                                count: entry.value.length,
                              ),
                              const SizedBox(height: 8),
                              ...entry.value.map((request) {
                                final linkedTask = data.taskFor(request.id);
                                return _GapAuditCard(
                                  request: request,
                                  linkedTask: linkedTask,
                                  onTriaged: () => _review(request, 'triaged'),
                                  onAccepted: () =>
                                      _review(request, 'accepted'),
                                  onRejected: () =>
                                      _review(request, 'rejected'),
                                  onResolved: () =>
                                      _review(request, 'resolved'),
                                  onTask: request.status == 'accepted' &&
                                          linkedTask == null
                                      ? () => _createAuditTask(request)
                                      : null,
                                  onAcceptAndTask: request.status !=
                                              'accepted' &&
                                          request.status != 'rejected' &&
                                          request.status != 'resolved' &&
                                          linkedTask == null
                                      ? () => _acceptAndCreateAuditTask(request)
                                      : null,
                                  onSyncFromTask: linkedTask != null &&
                                          _requestNeedsTaskSync(
                                              request, linkedTask)
                                      ? () => _syncRequestFromTask(
                                          request, linkedTask)
                                      : null,
                                  onAttachEvidence: () =>
                                      _attachEvidence(request),
                                  onShowEvidence: () =>
                                      _showEvidenceAttachments(request),
                                  onReviewTimeline: () =>
                                      _showReviewTimeline(request),
                                  onStoragePolicy: () =>
                                      _showStoragePolicy(request),
                                  onRoutedTask: request.status == 'accepted' &&
                                          linkedTask == null
                                      ? () => _createRoutedAuditTask(request)
                                      : null,
                                  onAcceptAndRoutedTask:
                                      request.status != 'accepted' &&
                                              request.status != 'rejected' &&
                                              request.status != 'resolved' &&
                                              linkedTask == null
                                          ? () => _createRoutedAuditTask(
                                                request,
                                                acceptFirst: true,
                                              )
                                          : null,
                                );
                              }),
                              const SizedBox(height: 12),
                            ],
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

  Map<String, List<ExplorerGapAuditRequest>> _groupByStatus(
    List<ExplorerGapAuditRequest> items,
  ) {
    final map = <String, List<ExplorerGapAuditRequest>>{};
    for (final item in items) {
      map.putIfAbsent(item.status, () => <ExplorerGapAuditRequest>[]).add(item);
    }
    return map;
  }
}

class _GapAuditDashboardData {
  final List<ExplorerGapAuditRequest> requests;
  final Map<String, AuditTask> tasksBySourceId;

  const _GapAuditDashboardData({
    this.requests = const <ExplorerGapAuditRequest>[],
    this.tasksBySourceId = const <String, AuditTask>{},
  });

  AuditTask? taskFor(String requestId) => tasksBySourceId[requestId];

  int get pendingSyncCount => pendingSyncRequests.length;

  List<ExplorerGapAuditRequest> get pendingSyncRequests =>
      requests.where((request) {
        final task = taskFor(request.id);
        return task != null && _requestNeedsTaskSync(request, task);
      }).toList(growable: false);
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
          child: const Icon(Icons.fact_check_outlined,
              color: PwfColors.primaryGold),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مراجعة فجوات المستكشف',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'طلبات التدقيق الناتجة من مستكشف التاريخ والحديث والوقف.',
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
  final String domain;
  final List<String> statuses;
  final List<String> domains;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onDomainChanged;

  const _Filters({
    required this.status,
    required this.domain,
    required this.statuses,
    required this.domains,
    required this.onStatusChanged,
    required this.onDomainChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _DarkDropdown(
          label: 'الحالة',
          value: status,
          values: statuses,
          labelFor: _statusLabel,
          onChanged: onStatusChanged,
        ),
        _DarkDropdown(
          label: 'النطاق',
          value: domain,
          values: domains,
          labelFor: (v) => v == 'all' ? 'كل النطاقات' : v,
          onChanged: onDomainChanged,
        ),
      ],
    );
  }
}

class _DarkDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final String Function(String) labelFor;
  final ValueChanged<String?> onChanged;

  const _DarkDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: DropdownButtonFormField<String>(
        value: value,
        items: values
            .map((v) => DropdownMenuItem(value: v, child: Text(labelFor(v))))
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
        border:
            Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.25)),
      ),
      child: const Text(
        'هذه اللوحة تنشئ الآن مهام تدقيق فعلية داخل tasks_system للطلبات المقبولة، مع بقاء سجل المراجعة وسياق الفجوة محفوظين ومربوطين بالمهمة.',
        style: TextStyle(color: Colors.white70, height: 1.5),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final List<ExplorerGapAuditRequest> items;
  final int linkedTaskCount;
  final int pendingSyncCount;

  const _SummaryStrip({
    required this.items,
    this.linkedTaskCount = 0,
    this.pendingSyncCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    int count(String status) => items.where((e) => e.status == status).length;
    int high = items.where((e) => e.severity == 'high').length;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MiniMetric(label: 'الإجمالي', value: '${items.length}'),
        _MiniMetric(label: 'جديد', value: '${count('new')}'),
        _MiniMetric(label: 'مقبول', value: '${count('accepted')}'),
        _MiniMetric(label: 'مهام منشأة', value: '$linkedTaskCount'),
        _MiniMetric(
          label: 'تحتاج مزامنة',
          value: '$pendingSyncCount',
          highlight: pendingSyncCount > 0,
        ),
        _MiniMetric(label: 'حرج', value: '$high', highlight: high > 0),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _MiniMetric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFB22222).withValues(alpha: 0.2)
            : const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? const Color(0xFFB22222).withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String title;
  final int count;

  const _GroupHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: PwfColors.primaryGold,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 8),
        Text('($count)', style: const TextStyle(color: Colors.white54)),
      ],
    );
  }
}

class _GapAuditCard extends StatelessWidget {
  final ExplorerGapAuditRequest request;
  final AuditTask? linkedTask;
  final VoidCallback onTriaged;
  final VoidCallback onAccepted;
  final VoidCallback onRejected;
  final VoidCallback onResolved;
  final VoidCallback? onTask;
  final VoidCallback? onAcceptAndTask;
  final VoidCallback? onSyncFromTask;
  final VoidCallback? onAttachEvidence;
  final VoidCallback? onShowEvidence;
  final VoidCallback? onReviewTimeline;
  final VoidCallback? onStoragePolicy;
  final VoidCallback? onRoutedTask;
  final VoidCallback? onAcceptAndRoutedTask;

  const _GapAuditCard({
    required this.request,
    this.linkedTask,
    required this.onTriaged,
    required this.onAccepted,
    required this.onRejected,
    required this.onResolved,
    this.onTask,
    this.onAcceptAndTask,
    this.onSyncFromTask,
    this.onAttachEvidence,
    this.onShowEvidence,
    this.onReviewTimeline,
    this.onStoragePolicy,
    this.onRoutedTask,
    this.onAcceptAndRoutedTask,
  });

  @override
  Widget build(BuildContext context) {
    final sourceType = request.context['source_type']?.toString() ?? '';
    final bridgeBatch = request.context['bridge_batch']?.toString() ?? '';
    final assetCode = request.context['asset_code']?.toString() ?? '';
    final isSmartBridge = sourceType == 'smart_explorer_bridge_handoff';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: _severityColor(request.severity).withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Chip(text: request.domain, icon: Icons.category_outlined),
              _Chip(
                  text: _severityLabel(request.severity),
                  color: _severityColor(request.severity)),
              _Chip(text: request.displayStatus, icon: Icons.flag_outlined),
              _Chip(text: request.explorerMode, icon: Icons.travel_explore),
              if (isSmartBridge)
                const _Chip(
                  text: 'من جسر المستكشف الذكي',
                  icon: Icons.hub_outlined,
                  color: Color(0xFF0F766E),
                ),
              if (assetCode.trim().isNotEmpty)
                _Chip(text: 'رمز: $assetCode', icon: Icons.tag_outlined),
              if (bridgeBatch.trim().isNotEmpty)
                _Chip(text: bridgeBatch, icon: Icons.verified_outlined),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            request.detail,
            style: const TextStyle(color: Colors.white70, height: 1.45),
          ),
          if ((request.recommendedAction ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'الإجراء المقترح: ${request.recommendedAction}',
              style:
                  const TextStyle(color: PwfColors.primaryGold, height: 1.45),
            ),
          ],
          if (request.sample.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: request.sample
                  .take(4)
                  .map<Widget>((e) => _SampleChip(text: e))
                  .toList(growable: false),
            ),
          ],
          if ((request.reviewerNote ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'آخر ملاحظة مراجعة: ${request.reviewerNote}',
              style: const TextStyle(color: Colors.white60, height: 1.4),
            ),
          ],
          if (linkedTask != null) ...[
            const SizedBox(height: 10),
            _LinkedTaskBanner(task: linkedTask!),
            if (_requestNeedsTaskSync(request, linkedTask!)) ...[
              const SizedBox(height: 8),
              _TaskSyncBanner(request: request, task: linkedTask!),
            ],
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onTriaged,
                icon: const Icon(Icons.filter_alt_outlined, size: 18),
                label: const Text('فرز'),
              ),
              OutlinedButton.icon(
                onPressed: onAccepted,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('قبول'),
              ),
              OutlinedButton.icon(
                onPressed: onRejected,
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('رفض'),
              ),
              OutlinedButton.icon(
                onPressed: onResolved,
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('إغلاق'),
              ),
              if (onAcceptAndTask != null)
                FilledButton.icon(
                  onPressed: onAcceptAndTask,
                  icon: const Icon(Icons.task_alt, size: 18),
                  label: const Text('قبول + مهمة'),
                ),
              if (onTask != null)
                FilledButton.icon(
                  onPressed: onTask,
                  icon: const Icon(Icons.task_alt, size: 18),
                  label: const Text('إنشاء مهمة'),
                ),
              if (onSyncFromTask != null)
                FilledButton.icon(
                  onPressed: onSyncFromTask,
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('مزامنة من المهمة'),
                ),
              if (onAttachEvidence != null)
                OutlinedButton.icon(
                  onPressed: onAttachEvidence,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('إرفاق دليل'),
                ),
              if (onShowEvidence != null)
                OutlinedButton.icon(
                  onPressed: onShowEvidence,
                  icon: const Icon(Icons.folder_open_outlined, size: 18),
                  label: const Text('الأدلة'),
                ),
              if (onReviewTimeline != null)
                OutlinedButton.icon(
                  onPressed: onReviewTimeline,
                  icon: const Icon(Icons.timeline_outlined, size: 18),
                  label: const Text('الخط الزمني'),
                ),
              if (onStoragePolicy != null)
                OutlinedButton.icon(
                  onPressed: onStoragePolicy,
                  icon: const Icon(Icons.policy_outlined, size: 18),
                  label: const Text('سياسة التخزين'),
                ),
              if (onAcceptAndRoutedTask != null)
                FilledButton.icon(
                  onPressed: onAcceptAndRoutedTask,
                  icon: const Icon(Icons.route_outlined, size: 18),
                  label: const Text('قبول + مهمة موجهة'),
                ),
              if (onRoutedTask != null)
                FilledButton.icon(
                  onPressed: onRoutedTask,
                  icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                  label: const Text('مهمة موجهة'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewBoardHardeningPanel extends StatelessWidget {
  final _GapAuditDashboardData data;
  final VoidCallback onExportCsv;
  final VoidCallback onSyncVisible;

  const _ReviewBoardHardeningPanel({
    required this.data,
    required this.onExportCsv,
    required this.onSyncVisible,
  });

  @override
  Widget build(BuildContext context) {
    final smartBridgeCount = data.requests.where(_isSmartBridgeRequest).length;
    final pending = data.pendingSyncCount;
    final orphanAccepted = data.requests.where((request) {
      return request.status == 'accepted' && data.taskFor(request.id) == null;
    }).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تقوية لوحة المراجعة ومزامنة المهام',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'تراقب هذه اللوحة العلاقة بين طلبات فجوات المستكشف ومهام التدقيق الفعلية، وتُظهر ما يحتاج مزامنة دون تعديل سيادي مباشر.',
            style: TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                  text: 'طلبات من الجسر الذكي: $smartBridgeCount',
                  icon: Icons.hub_outlined),
              _Chip(text: 'تحتاج مزامنة: $pending', icon: Icons.sync),
              _Chip(
                  text: 'مقبولة بلا مهمة: $orphanAccepted',
                  icon: Icons.rule_folder_outlined),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: pending == 0 ? null : onSyncVisible,
                icon: const Icon(Icons.sync, size: 18),
                label: const Text('مزامنة النتائج الظاهرة'),
              ),
              OutlinedButton.icon(
                onPressed: onExportCsv,
                icon: const Icon(Icons.table_view_outlined, size: 18),
                label: const Text('تصدير CSV للوحة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskSyncBanner extends StatelessWidget {
  final ExplorerGapAuditRequest request;
  final AuditTask task;

  const _TaskSyncBanner({required this.request, required this.task});

  @override
  Widget build(BuildContext context) {
    final next = _recommendedGapStatusForTaskStatus(task.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PwfColors.primaryGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: PwfColors.primaryGold.withValues(alpha: 0.28)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.sync_problem_outlined,
              color: PwfColors.primaryGold, size: 18),
          const Text(
            'مزامنة مطلوبة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          _Chip(
              text: 'الطلب: ${request.displayStatus}',
              icon: Icons.fact_check_outlined),
          _Chip(text: 'المهمة: ${task.displayStatus}', icon: Icons.task_alt),
          if (next != null)
            _Chip(
                text: 'المقترح: ${_statusLabel(next)}',
                icon: Icons.arrow_forward),
        ],
      ),
    );
  }
}

class _LinkedTaskBanner extends StatelessWidget {
  final AuditTask task;

  const _LinkedTaskBanner({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.28)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.task_alt, color: Colors.green, size: 18),
          const Text(
            'مهمة مرتبطة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          _Chip(
              text: task.displayStatus,
              icon: Icons.flag_outlined,
              color: Colors.green),
          _Chip(
              text: task.displayPriority,
              icon: Icons.priority_high,
              color: PwfColors.primaryGold),
          Text(
            task.title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;

  const _Chip({required this.text, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? PwfColors.primaryBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: c, size: 15),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SampleChip extends StatelessWidget {
  final String text;
  const _SampleChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white60, fontSize: 12)),
    );
  }
}

class _StoragePolicyHint extends StatelessWidget {
  const _StoragePolicyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PwfColors.primaryBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.28)),
      ),
      child: const Text(
        'Bridge Batch Q: ارفع الملف أولًا إلى bucket explorer-review-evidence ضمن gap-audits/{request_id}/YYYY/MM، ثم الصق Storage object path هنا. الواجهة لا تحفظ الملف الثنائي مباشرة دون مسار Storage، وتعرض الآن هوية منشئ/مراجع الدليل بدل UUID عند توفرها.',
        style: TextStyle(color: Colors.white70, height: 1.45, fontSize: 12),
      ),
    );
  }
}

class _StoragePolicyView extends StatelessWidget {
  final ExplorerGapAuditStoragePolicy policy;
  final ExplorerGapAuditRequest request;

  const _StoragePolicyView({required this.policy, required this.request});

  @override
  Widget build(BuildContext context) {
    final mimeTypes = policy.allowedMimeTypes.isEmpty
        ? 'غير محدد من RPC'
        : policy.allowedMimeTypes.join('\n');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                  text: 'bucket: ${policy.bucketId}',
                  icon: Icons.storage_outlined),
              _Chip(
                text: policy.isPublic ? 'عام' : 'خاص',
                icon: policy.isPublic ? Icons.public : Icons.lock_outline,
                color: policy.isPublic ? PwfColors.primaryGold : Colors.green,
              ),
              _Chip(
                  text: 'الحد: ${policy.maxFileSizeLabel}',
                  icon: Icons.sd_storage_outlined),
              _Chip(
                  text: policy.retentionPolicy, icon: Icons.history_toggle_off),
            ],
          ),
          const SizedBox(height: 12),
          _PolicyLine(label: 'request_id', value: request.id),
          _PolicyLine(label: 'path_prefix', value: policy.pathPrefix),
          _PolicyLine(label: 'path_template', value: policy.pathTemplate),
          const SizedBox(height: 10),
          const Text(
            'أنواع الملفات المسموحة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          SelectableText(
            mimeTypes,
            style: const TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 10),
          const Text(
            'قواعد تشغيلية',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'لا leading slash، لا parent traversal، لا bucket عام. أدلة المراجعة تشغيلية وتحتاج اعتماد/رفض قبل استخدامها في قرار نهائي.',
            style: TextStyle(color: Colors.white70, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _PolicyLine extends StatelessWidget {
  final String label;
  final String value;

  const _PolicyLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SelectableText(
        '$label: $value',
        style: const TextStyle(color: Colors.white70, height: 1.4),
      ),
    );
  }
}

class _TimelineEventTile extends StatelessWidget {
  final ExplorerGapAuditTimelineEvent event;

  const _TimelineEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(text: event.displayType, icon: Icons.timeline_outlined),
              if ((event.eventStatus ?? '').trim().isNotEmpty)
                _Chip(text: event.eventStatus!, icon: Icons.flag_outlined),
              if (event.occurredAt != null)
                _Chip(
                    text: _dateTimeLabel(event.occurredAt!),
                    icon: Icons.schedule),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.eventTitle,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          if ((event.eventDetail ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              event.eventDetail!,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
          if ((event.actorLabel ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'المراجع/الفاعل: ${event.actorLabel}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ] else if ((event.actorUserId ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'actor_user_id: ${event.actorUserId}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
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

class _EvidenceAttachmentTile extends StatelessWidget {
  final ExplorerGapAuditEvidenceAttachment item;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onUnderReview;

  const _EvidenceAttachmentTile({
    required this.item,
    this.onAccept,
    this.onReject,
    this.onUnderReview,
  });

  @override
  Widget build(BuildContext context) {
    final storedPath = item.storageObjectPath ?? item.filePath;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(text: item.evidenceType, icon: Icons.label_outline),
              _Chip(
                text: item.displayReviewState,
                icon: Icons.fact_check_outlined,
                color: _evidenceReviewStateColor(item.reviewState),
              ),
              if (item.createdAt != null)
                _Chip(text: _dateLabel(item.createdAt!), icon: Icons.schedule),
              if ((item.createdByLabel ?? '').trim().isNotEmpty)
                _Chip(
                  text: 'أضافه: ${item.createdByLabel}',
                  icon: Icons.person_add_alt_1_outlined,
                ),
              if ((item.reviewedByLabel ?? '').trim().isNotEmpty)
                _Chip(
                  text: 'راجعه: ${item.reviewedByLabel}',
                  icon: Icons.verified_user_outlined,
                  color: PwfColors.primaryGold,
                ),
              if (item.fileSizeBytes != null)
                _Chip(
                  text: _fileSizeLabel(item.fileSizeBytes!),
                  icon: Icons.sd_storage_outlined,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if ((item.referenceUrl ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            SelectableText(
              'الرابط: ${item.referenceUrl}',
              style: const TextStyle(color: PwfColors.primaryGold),
            ),
          ],
          if ((storedPath ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            SelectableText(
              'Storage: ${item.displayStoragePath}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          if ((item.mimeType ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'MIME: ${item.mimeType}',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
          if ((item.checksumSha256 ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            SelectableText(
              'SHA-256: ${item.checksumSha256}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
          if ((item.note ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.note!,
              style: const TextStyle(color: Colors.white60, height: 1.4),
            ),
          ],
          if ((item.reviewNote ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'ملاحظة مراجعة الدليل: ${item.reviewNote}',
              style: const TextStyle(color: Colors.white54, height: 1.4),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onUnderReview,
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('قيد المراجعة'),
              ),
              FilledButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: const Text('اعتماد الدليل'),
              ),
              OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.block_outlined, size: 18),
                label: const Text('رفض الدليل'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskRoutingDraft {
  final String description;
  final String assignedToUserId;
  final String dueDateText;
  final String assignmentNote;

  const _TaskRoutingDraft({
    required this.description,
    required this.assignedToUserId,
    required this.dueDateText,
    required this.assignmentNote,
  });

  String? get descriptionOrNull => _blankToNull(description);
  String? get assignedToUserIdOrNull => _blankToNull(assignedToUserId);
  String? get assignmentNoteOrNull => _blankToNull(assignmentNote);

  DateTime? get dueDate {
    final text = dueDateText.trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Text(
          'لا توجد طلبات تدقيق ضمن الفلتر الحالي.',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFB22222).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFB22222).withValues(alpha: 0.3)),
      ),
      child: Text(
        'تعذر تحميل طلبات فجوات المستكشف:\n$error',
        style: const TextStyle(color: Colors.white70, height: 1.5),
      ),
    );
  }
}

int? _parseOptionalInt(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  return int.tryParse(text);
}

String _suggestEvidenceStoragePath(ExplorerGapAuditRequest request) {
  final now = DateTime.now();
  final year = now.year.toString().padLeft(4, '0');
  final month = now.month.toString().padLeft(2, '0');
  final safeTitle = request.title
      .trim()
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'[^A-Za-z0-9_\-\u0600-\u06FF]'), '')
      .takeSafe(36);
  final suffix = safeTitle.isEmpty ? 'evidence' : safeTitle;
  return 'gap-audits/${request.id}/$year/$month/$suffix';
}

String _evidenceReviewStateLabel(String state) => switch (state) {
      'submitted' => 'مقدم',
      'under_review' => 'قيد المراجعة',
      'accepted' => 'مقبول',
      'rejected' => 'مرفوض',
      'superseded' => 'مستبدل',
      _ => state,
    };

Color _evidenceReviewStateColor(String state) => switch (state) {
      'accepted' => Colors.green,
      'rejected' => const Color(0xFFB22222),
      'under_review' => PwfColors.primaryGold,
      'superseded' => Colors.blueGrey,
      _ => PwfColors.primaryBlue,
    };

String _dateTimeLabel(DateTime date) {
  final local = date.toLocal();
  final datePart =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  final timePart =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$datePart $timePart';
}

String _fileSizeLabel(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _timelineReport(
  ExplorerGapAuditRequest request,
  List<ExplorerGapAuditTimelineEvent> timeline,
) {
  final lines = <String>[
    'خط زمني لمراجعة فجوة المستكشف',
    'request_id: ${request.id}',
    'title: ${request.title}',
    'status: ${request.status}',
    'events: ${timeline.length}',
    '---',
  ];
  for (final event in timeline) {
    lines.add('at: ${event.occurredAt?.toIso8601String() ?? ''}');
    lines.add('type: ${event.eventType}');
    lines.add('title: ${event.eventTitle}');
    if ((event.eventStatus ?? '').trim().isNotEmpty) {
      lines.add('status: ${event.eventStatus}');
    }
    if ((event.actorLabel ?? '').trim().isNotEmpty) {
      lines.add('actor_label: ${event.actorLabel}');
    } else if ((event.actorUserId ?? '').trim().isNotEmpty) {
      lines.add('actor_user_id: ${event.actorUserId}');
    }
    if ((event.eventDetail ?? '').trim().isNotEmpty) {
      lines.add('detail: ${event.eventDetail}');
    }
    lines.add('---');
  }
  return lines.join('\n');
}

String _storagePolicyReport(
  ExplorerGapAuditRequest request,
  ExplorerGapAuditStoragePolicy policy,
) {
  return [
    'سياسة تخزين أدلة مراجعة فجوة المستكشف',
    'request_id: ${request.id}',
    'bucket_id: ${policy.bucketId}',
    'is_public: ${policy.isPublic}',
    'max_file_size_bytes: ${policy.maxFileSizeBytes}',
    'path_prefix: ${policy.pathPrefix}',
    'path_template: ${policy.pathTemplate}',
    'retention_policy: ${policy.retentionPolicy}',
    'allowed_mime_types:',
    ...policy.allowedMimeTypes.map((e) => '- $e'),
  ].join('\n');
}

String? _blankToNull(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

String _routingReviewNote(_TaskRoutingDraft routing) {
  final lines = <String>[
    'قبول وتوجيه من Bridge Batch O.',
  ];
  if (routing.assignedToUserIdOrNull != null) {
    lines.add('assigned_to_user_id: ${routing.assignedToUserIdOrNull}');
  }
  if (routing.dueDate != null) {
    lines.add('due_date: ${_dateLabel(routing.dueDate!)}');
  }
  if (routing.assignmentNoteOrNull != null) {
    lines.add('ملاحظة التوجيه: ${routing.assignmentNoteOrNull}');
  }
  return lines.join('\n');
}

String _evidenceAttachmentsReport(
  ExplorerGapAuditRequest request,
  List<ExplorerGapAuditEvidenceAttachment> attachments,
) {
  final lines = <String>[
    'تقرير أدلة مراجعة فجوة المستكشف',
    'request_id: ${request.id}',
    'title: ${request.title}',
    'status: ${request.status}',
    'domain: ${request.domain}',
    'attachments: ${attachments.length}',
    '---',
  ];
  for (final item in attachments) {
    lines.add('id: ${item.id}');
    lines.add('type: ${item.evidenceType}');
    lines.add('title: ${item.title}');
    if ((item.createdByLabel ?? '').trim().isNotEmpty) {
      lines.add('created_by: ${item.createdByLabel}');
    }
    if ((item.reviewedByLabel ?? '').trim().isNotEmpty) {
      lines.add('reviewed_by: ${item.reviewedByLabel}');
    }
    if ((item.referenceUrl ?? '').trim().isNotEmpty) {
      lines.add('reference_url: ${item.referenceUrl}');
    }
    if ((item.filePath ?? '').trim().isNotEmpty) {
      lines.add('file_path: ${item.filePath}');
    }
    if ((item.note ?? '').trim().isNotEmpty) {
      lines.add('note: ${item.note}');
    }
    lines.add('---');
  }
  return lines.join('\n');
}

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String _buildTaskSyncNote({
  required AuditTask task,
  required String note,
  required String nextStatus,
}) {
  final lines = <String>[
    'مزامنة من مهمة التدقيق المرتبطة.',
    'task_id: ${task.id}',
    'task_status: ${task.status}',
    'gap_status: $nextStatus',
  ];
  if (note.trim().isNotEmpty) lines.add('ملاحظة المراجع: ${note.trim()}');
  return lines.join('\n');
}

bool _isSmartBridgeRequest(ExplorerGapAuditRequest request) {
  return request.context['source_type']?.toString() ==
      'smart_explorer_bridge_handoff';
}

bool _requestNeedsTaskSync(ExplorerGapAuditRequest request, AuditTask task) {
  final nextStatus = _recommendedGapStatusForTaskStatus(task.status);
  return nextStatus != null && nextStatus != request.status;
}

String? _recommendedGapStatusForTaskStatus(String taskStatus) =>
    switch (taskStatus) {
      'done' => 'resolved',
      'cancelled' => 'rejected',
      'blocked' => 'triaged',
      'in_progress' => 'accepted',
      _ => null,
    };

String _reviewBoardCsv(_GapAuditDashboardData data) {
  String esc(String value) => '"${value.replaceAll('"', '""')}"';
  final rows = <List<String>>[
    <String>[
      'request_id',
      'request_title',
      'domain',
      'severity',
      'request_status',
      'priority',
      'source_type',
      'task_id',
      'task_status',
      'task_priority',
      'sync_needed',
      'recommended_gap_status',
      'created_at',
    ],
  ];
  for (final request in data.requests) {
    final task = data.taskFor(request.id);
    final recommended = task == null
        ? ''
        : (_recommendedGapStatusForTaskStatus(task.status) ?? '');
    final needsSync = task != null && _requestNeedsTaskSync(request, task);
    rows.add(<String>[
      request.id,
      request.title,
      request.domain,
      request.severity,
      request.status,
      request.priority,
      request.context['source_type']?.toString() ?? '',
      task?.id ?? '',
      task?.status ?? '',
      task?.priority ?? '',
      '$needsSync',
      recommended,
      request.createdAt?.toIso8601String() ?? '',
    ]);
  }
  return rows.map((row) => row.map(esc).join(',')).join('\n');
}

String _statusLabel(String status) => switch (status) {
      'all' => 'كل الحالات',
      'new' => 'جديد',
      'triaged' => 'قيد الفرز',
      'accepted' => 'مقبول',
      'rejected' => 'مرفوض',
      'resolved' => 'مغلق',
      _ => status,
    };

String _severityLabel(String severity) => switch (severity) {
      'high' => 'عالية',
      'medium' => 'متوسطة',
      'low' => 'منخفضة',
      _ => severity,
    };

Color _severityColor(String severity) => switch (severity) {
      'high' => const Color(0xFFB22222),
      'medium' => PwfColors.primaryGold,
      'low' => Colors.green,
      _ => Colors.white54,
    };

extension _SafeTakeExtension on String {
  String takeSafe(int maxLength) {
    if (length <= maxLength) return this;
    return substring(0, maxLength);
  }
}
