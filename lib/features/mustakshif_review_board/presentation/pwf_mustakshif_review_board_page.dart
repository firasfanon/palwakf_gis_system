import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pwf_export_file_adapter.dart';
import 'pwf_review_board_providers.dart';
import 'widgets/pwf_review_filter_bar.dart';
import 'widgets/pwf_review_metrics_cards.dart';
import 'widgets/pwf_map_adapter_readiness_card.dart';
import 'widgets/pwf_review_record_details_panel.dart';
import 'widgets/pwf_review_records_table.dart';
import 'widgets/pwf_standalone_map_adapter_panel.dart';
import 'widgets/pwf_real_map_hook_preparation_panel.dart';
import 'widgets/pwf_supabase_integration_status_card.dart';


class PwfMustakshifReviewBoardPage extends ConsumerWidget {
  const PwfMustakshifReviewBoardPage({
    super.key,
    this.embeddedInAdmin = true,
    this.initialRecordId,
  });

  final bool embeddedInAdmin;
  final String? initialRecordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pwfReviewBoardControllerProvider);
    final controller = ref.read(pwfReviewBoardControllerProvider.notifier);
    final requestedRecordId = initialRecordId?.trim();
    if (requestedRecordId != null &&
        requestedRecordId.isNotEmpty &&
        state.records.any((record) => record.id == requestedRecordId) &&
        state.selectedRecord?.id != requestedRecordId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.focusRecordFromExplorerMap(requestedRecordId);
      });
    }

    final content = state.isLoading
        ? const Center(child: CircularProgressIndicator())
        : state.errorMessage != null
            ? Center(child: Text('خطأ: ${state.errorMessage}'))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1120;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PlatformShellHeader(
                          state: state,
                          controller: controller,
                        ),
                        const SizedBox(height: 10),
                        const _HeaderCard(),
                        const SizedBox(height: 10),
                        if (state.persistenceMessage != null) ...[
                          _PersistenceNotice(
                            message: state.persistenceMessage!,
                            lastPersistedAt: state.lastPersistedAt,
                          ),
                          const SizedBox(height: 10),
                        ],
                        _LocalDraftQaCard(
                          state: state,
                          onRefreshHealth: controller.refreshLocalDraftHealth,
                        ),
                        const SizedBox(height: 10),
                        PwfReviewMetricsCards(state: state),
                        const SizedBox(height: 10),
                        const _ReviewWorkflowStrip(),
                        const SizedBox(height: 10),
                        const _RbacAlignmentCard(),
                        const SizedBox(height: 10),
                        PwfSupabaseIntegrationStatusCard(
                          state: state,
                          controller: controller,
                        ),
                        const SizedBox(height: 10),
                        PwfMapAdapterReadinessCard(state: state),
                        const SizedBox(height: 10),
                        PwfStandaloneMapAdapterPanel(record: state.selectedRecord),
                        const SizedBox(height: 10),
                        PwfRealMapHookPreparationPanel(
                          record: state.selectedRecord,
                        ),
                        const SizedBox(height: 10),
                        PwfReviewFilterBar(
                          state: state,
                          onQueryChanged: controller.updateQuery,
                          onQueueChanged: controller.updateQueue,
                          onStatusChanged: controller.updateStatus,
                          onGateChanged: controller.updateGate,
                          onSortChanged: controller.updateSort,
                          onLocalDraftsOnlyChanged:
                              controller.toggleLocalDraftsOnly,
                          onClearFilters: controller.clearFilters,
                        ),
                        const SizedBox(height: 10),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: PwfReviewRecordsTable(
                                  records: state.filteredRecords,
                                  selectedRecordId: state.selectedRecord?.id,
                                  localDraftRecordIds: state.localDraftRecordIds,
                                  onSelectRecord: controller.selectRecord,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 4,
                                child: PwfReviewRecordDetailsPanel(
                                  record: state.selectedRecord,
                                  onSaveLocator: controller.upsertSourceLocator,
                                  onSubmitDecision: controller.submitReviewerDecision,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          PwfReviewRecordsTable(
                            records: state.filteredRecords,
                            selectedRecordId: state.selectedRecord?.id,
                            localDraftRecordIds: state.localDraftRecordIds,
                            onSelectRecord: controller.selectRecord,
                          ),
                          const SizedBox(height: 10),
                          PwfReviewRecordDetailsPanel(
                            record: state.selectedRecord,
                            onSaveLocator: controller.upsertSourceLocator,
                            onSubmitDecision: controller.submitReviewerDecision,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );

    if (embeddedInAdmin) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: content,
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('لوحة مراجعة المستكشف')),
        body: content,
      ),
    );
  }
}

class _PlatformShellHeader extends StatelessWidget {
  const _PlatformShellHeader({
    required this.state,
    required this.controller,
  });

  final PwfReviewBoardState state;
  final PwfReviewBoardController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            const SizedBox(
              width: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'لوحة مراجعة المستكشف',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'وضع مدمج داخل لوحة تحكم PalWakf — مراجعة فقط، دون كتابة على core أو waqf.',
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _ShellBadge(
                  icon: Icons.integration_instructions_outlined,
                  label: 'Integration Mode',
                  value: 'Explorer Admin Shell',
                ),
                _ShellBadge(
                  icon: Icons.verified_user_outlined,
                  label: 'RBAC',
                  value: 'AdminShell access',
                ),
                _ShellBadge(
                  icon: Icons.lock_outline,
                  label: 'Policy',
                  value: 'review-only',
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => controller.load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة تحميل CSV'),
                ),
                _ExportMenu(state: state, controller: controller),
                OutlinedButton.icon(
                  onPressed: state.localDraftCount == 0
                      ? null
                      : () => controller.clearLocalDrafts(),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('مسح المسودات'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellBadge extends StatelessWidget {
  const _ShellBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
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


class _ReviewWorkflowStrip extends StatelessWidget {
  const _ReviewWorkflowStrip();

  @override
  Widget build(BuildContext context) {
    const stages = [
      ('1', 'تحديد السجل'),
      ('2', 'تثبيت المصدر/الموقع'),
      ('3', 'قرار المراجع الأول'),
      ('4', 'قرار المراجع الثاني'),
      ('5', 'حزمة قرار داخلية'),
    ];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final stage in stages)
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: CircleAvatar(
                  radius: 10,
                  child: Text(
                    stage.$1,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                label: Text(stage.$2),
              ),
          ],
        ),
      ),
    );
  }
}

class _RbacAlignmentCard extends StatelessWidget {
  const _RbacAlignmentCard();

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('نطاق الدخول', 'داخل AdminShell فقط'),
      ('حالة الصلاحيات', 'تهيئة UX/RBAC labels بدون تشديد جديد'),
      ('مصدر البيانات', 'CSV seed + local drafts'),
      ('الكتابة السيادية', 'core=0 / waqf=0 / awqaf_system=0'),
      ('الخريطة', 'navigation-only preparation'),
    ];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in items)
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.check_circle_outline, size: 18),
                label: Text('${item.$1}: ${item.$2}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExportMenu extends StatelessWidget {
  const _ExportMenu({
    required this.state,
    required this.controller,
  });

  final PwfReviewBoardState state;
  final PwfReviewBoardController controller;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ExportAction>(
      tooltip: 'تصدير',
      icon: const Icon(Icons.download_outlined),
      itemBuilder: (context) => const [
        PopupMenuItem(value: _ExportAction.filtered, child: Text('تصدير المعروض بعد الفلترة CSV')),
        PopupMenuItem(value: _ExportAction.localDrafts, child: Text('تصدير المسودات المحلية CSV')),
        PopupMenuItem(value: _ExportAction.decisionPackage, child: Text('تصدير حزمة القرار الداخلية CSV')),
        PopupMenuItem(value: _ExportAction.mapEvidence, child: Text('تصدير أدلة الخريطة CSV')),
        PopupMenuItem(value: _ExportAction.mapHookDiagnostics, child: Text('تصدير تشخيص Real Map Hook CSV')),
        PopupMenuItem(value: _ExportAction.all, child: Text('تصدير كل السجلات CSV')),
        PopupMenuDivider(),
        PopupMenuItem(value: _ExportAction.copyPreview, child: Text('معاينة/نسخ CSV')),
        PopupMenuItem(value: _ExportAction.verificationManifest, child: Text('نسخ سجل تحقق التصدير')),
      ],
      onSelected: (action) async {
        final filename = _filenameFor(action);
        final csv = switch (action) {
          _ExportAction.filtered => state.exportFilteredRecordsCsv(),
          _ExportAction.localDrafts => state.exportLocalDraftsCsv(),
          _ExportAction.decisionPackage => state.exportDecisionPackageCsv(),
          _ExportAction.mapEvidence => state.exportMapEvidenceCsv(),
          _ExportAction.mapHookDiagnostics => state.exportMapHookDiagnosticsCsv(),
          _ExportAction.all => state.exportAllRecordsCsv(),
          _ExportAction.copyPreview => state.exportFilteredRecordsCsv(),
          _ExportAction.verificationManifest => _buildVerificationManifest(state),
        };

        if (action == _ExportAction.verificationManifest) {
          await Clipboard.setData(ClipboardData(text: csv));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم نسخ سجل تحقق التصدير إلى الحافظة.')),
            );
          }
          return;
        }

        if (action == _ExportAction.copyPreview) {
          await _showLocalDraftExportDialog(context, csv);
          return;
        }

        final result = await const PwfExportFileAdapter().downloadCsv(filename: filename, csvContent: csv);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${result.message} — rows=${result.rowCount}; bytes=${result.bytesLength}; checksum=${result.checksum}')),
          );
          controller.recordExportVerification(result.verificationLine);
          await _showExportResultDialog(context, result);
        }
      },
    );
  }

  static String _filenameFor(_ExportAction action) {
    final stamp = _timestampForFile(DateTime.now());
    return switch (action) {
      _ExportAction.filtered => 'mustakshif_filtered_review_records_$stamp.csv',
      _ExportAction.localDrafts => 'mustakshif_local_drafts_$stamp.csv',
      _ExportAction.decisionPackage => 'mustakshif_internal_decision_package_$stamp.csv',
      _ExportAction.mapEvidence => 'mustakshif_map_evidence_payloads_$stamp.csv',
      _ExportAction.mapHookDiagnostics => 'mustakshif_real_map_hook_diagnostics_$stamp.csv',
      _ExportAction.all => 'mustakshif_all_review_records_$stamp.csv',
      _ExportAction.copyPreview => 'mustakshif_preview_$stamp.csv',
      _ExportAction.verificationManifest => 'mustakshif_export_verification_$stamp.txt',
    };
  }

  static String _timestampForFile(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}_${two(value.hour)}${two(value.minute)}${two(value.second)}';
  }
}

enum _ExportAction { filtered, localDrafts, decisionPackage, mapEvidence, mapHookDiagnostics, all, copyPreview, verificationManifest }

String _buildVerificationManifest(PwfReviewBoardState state) {
  final now = DateTime.now().toIso8601String();
  return [
    'Mustakshif Export Verification Manifest v0.50',
    'generated_at=$now',
    'runtime_scope=explorer_admin_shell_review_board',
    'governance=review_only_not_final',
    'core_writes=0',
    'waqf_writes=0',
    'supabase_writes=0',
    'records_total=${state.records.length}',
    'records_filtered=${state.filteredRecords.length}',
    'local_drafts=${state.localDraftCount}',
    'local_draft_health=${state.localDraftHealthLabel ?? 'not_checked'}',
    'last_save_verification=${state.lastSaveVerificationLine ?? 'none'}',
    'last_export_verification=${state.lastExportVerificationLine ?? 'none'}',
    'export_qa_summary=${state.exportQaSummary}',
    'decision_package_ready=${state.decisionPackageReadyCount}',
    'map_evidence_ready=${state.mapEvidenceReadyCount}',
    'full_map_evidence=${state.fullMapEvidenceCount}',
    'map_hook_ready=${state.mapHookReadyCount}',
    'note=المتصفح لا يسمح بالتحقق من حفظ الملف على قرص المستخدم. v0.50 يتحقق من payload قبل إطلاق التنزيل ويعرض checksum/bytes/rows ويحتفظ بسطر تحقق آخر تصدير.',
  ].join('\n');
}

Future<void> _showLocalDraftExportDialog(BuildContext context, String csvContent) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('معاينة CSV'),
        content: SizedBox(
          width: 760,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'هذا التصدير تشغيلي فقط. لا يمثل اعتمادًا ولا يكتب على Supabase أو core أو waqf.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(csvContent.isEmpty ? 'لا توجد بيانات للتصدير.' : csvContent),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
          FilledButton.icon(
            onPressed: csvContent.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: csvContent));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ CSV إلى الحافظة.')),
                      );
                      Navigator.of(context).pop();
                    }
                  },
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('نسخ CSV'),
          ),
        ],
      );
    },
  );
}


Future<void> _showExportResultDialog(BuildContext context, PwfExportResult result) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('نتيجة التصدير'),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message),
              const SizedBox(height: 8),
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.verified_outlined, size: 18),
                label: Text(result.qualityLabelAr),
              ),
              const SizedBox(height: 8),
              SelectableText(result.verificationLine),
              const SizedBox(height: 8),
              SelectableText(result.manifestText),
              const SizedBox(height: 8),
              const Text('تنبيه: المتصفح لا يسمح للتطبيق بالتأكد من أن الملف كُتب فعليًا على قرص المستخدم. هذا التحقق يثبت payload قبل إطلاق التنزيل فقط.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق')),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: result.manifestText));
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('نسخ Manifest'),
          ),
        ],
      );
    },
  );
}


class _LocalDraftQaCard extends StatelessWidget {
  const _LocalDraftQaCard({
    required this.state,
    required this.onRefreshHealth,
  });

  final PwfReviewBoardState state;
  final Future<void> Function() onRefreshHealth;

  @override
  Widget build(BuildContext context) {
    final health = state.localDraftHealthLabel ?? 'لم يتم فحص المسودات بعد';
    final saveLine = state.lastSaveVerificationLine ?? 'لا يوجد تحقق حفظ بعد';
    final exportLine = state.lastExportVerificationLine ?? 'لا يوجد تحقق تصدير بعد';

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Chip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(Icons.storage_outlined, size: 18),
              label: Text('Local Draft QA'),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                health,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                saveLine,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                exportLine,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                onRefreshHealth();
              },
              icon: const Icon(Icons.health_and_safety_outlined),
              label: const Text('فحص المسودات'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersistenceNotice extends StatelessWidget {
  const _PersistenceNotice({required this.message, required this.lastPersistedAt});

  final String message;
  final DateTime? lastPersistedAt;

  @override
  Widget build(BuildContext context) {
    final timeLabel = lastPersistedAt == null
        ? ''
        : " — آخر تحديث محلي: ${lastPersistedAt!.hour.toString().padLeft(2, '0')}:${lastPersistedAt!.minute.toString().padLeft(2, '0')}";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.save_outlined),
          const SizedBox(width: 10),
          Expanded(child: Text('$message$timeLabel')),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لوحة مراجعة المستكشف — Explorer Integration v0.50',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'صفحة مراجعة تشغيلية مدمجة داخل المستكشف. تعمل افتراضيًا بنمط CSV/local drafts، وتملك بوابة Supabase staging اختيارية بعد نجاح V1C.',
            ),
            const SizedBox(height: 8),
            const Text(
              'قاعدة الحوكمة: review-only، لا كتابة على core أو waqf أو awqaf_system، وأوامر الخريطة navigation-only/preparation-only دون تشغيل أو إيقاف طبقات.',
            ),
          ],
        ),
      ),
    );
  }
}
