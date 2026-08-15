import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/pwf_review_record.dart';
import '../pwf_review_board_providers.dart';
import 'pwf_status_chip.dart';

class PwfSupabaseIntegrationStatusCard extends StatelessWidget {
  const PwfSupabaseIntegrationStatusCard({
    super.key,
    required this.state,
    required this.controller,
  });

  final PwfReviewBoardState state;
  final PwfReviewBoardController controller;

  @override
  Widget build(BuildContext context) {
    final diagnostics = state.stagingDiagnostics;
    final canWrite = diagnostics?.writeAllowed ?? false;
    final canRead = diagnostics?.readAllowed ?? false;
    final selectedRecord = state.selectedRecord;
    final selectedHasMapEvidence = selectedRecord?.hasMapEvidence ?? false;
    final hasAuthenticatedActor = diagnostics?.userId != null || diagnostics?.effectiveActorId != null;
    final needsRuntimeSandboxEnable =
        diagnostics != null && !canWrite && !diagnostics.sqlEditorContext && hasAuthenticatedActor;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.hub_outlined, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'بوابة اندماج Supabase staging',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                PwfStatusChip(
                  label: state.runtimeBackendLabel,
                  tone: state.isSupabaseRuntime ? PwfStatusTone.success : PwfStatusTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'هذه البوابة تنهي مرحلة الاندماج التحضيري: قراءة queue، حفظ draft، تسجيل map hook، وتسجيل export QA عبر public RPC wrappers فقط. لا تغيّر طبقات الخريطة ولا تكتب على core/waqf/awqaf_system/gis. مسار Production RBAC ما زال Draft Mapping ولا يفعّل إنتاجيًا قبل اعتماد جداول وصلاحيات المنصة.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PwfStatusChip(
                  label: canRead ? 'read: allowed' : 'read: pending diagnostics',
                  tone: canRead ? PwfStatusTone.success : PwfStatusTone.warning,
                ),
                PwfStatusChip(
                  label: canWrite ? 'write: allowed' : 'write: guarded',
                  tone: canWrite ? PwfStatusTone.success : PwfStatusTone.warning,
                ),
                if (needsRuntimeSandboxEnable)
                  const PwfStatusChip(
                    label: 'runtime sandbox enable required',
                    tone: PwfStatusTone.warning,
                  ),
                PwfStatusChip(
                  label: selectedHasMapEvidence ? 'map hook: ready' : 'map hook: blocked, no coordinates',
                  tone: selectedHasMapEvidence ? PwfStatusTone.success : PwfStatusTone.warning,
                ),
                const PwfStatusChip(
                  label: 'map: navigation-only',
                  tone: PwfStatusTone.success,
                ),
                const PwfStatusChip(
                  label: 'production RBAC: mapping draft',
                  tone: PwfStatusTone.warning,
                ),
                const PwfStatusChip(
                  label: 'integration: final closure pack',
                  tone: PwfStatusTone.success,
                ),
                const PwfStatusChip(
                  label: 'sandbox flags: temporary',
                  tone: PwfStatusTone.warning,
                ),
                const PwfStatusChip(
                  label: 'public RPC wrappers only',
                  tone: PwfStatusTone.neutral,
                ),
              ],
            ),
            if (diagnostics != null) ...[
              const SizedBox(height: 8),
              Text(
                diagnostics.labelAr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'actor=${diagnostics.effectiveActorId ?? diagnostics.userId ?? "n/a"}; '
                'auth_role=${diagnostics.authRole ?? "n/a"}; jwt_role=${diagnostics.jwtRole ?? "n/a"}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (needsRuntimeSandboxEnable) ...[
                const SizedBox(height: 4),
                Text(
                  'المستخدم الحالي مصادَق لكنه غير مفعّل داخل جدول sandbox overrides. فعّل sandbox لهذا المستخدم ثم أعد تحميل queue.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFFB22222)),
                ),
              ],
            ],
            if (selectedRecord != null && !selectedHasMapEvidence) ...[
              const SizedBox(height: 8),
              Text(
                'السجل المحدد لا يملك نقطة تاريخية أو centroid أو bbox؛ لذلك يتم حجب زر map hook بدل إرسال RPC بنتيجة ok=false.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF8A5A00)),
              ),
            ],
            if (selectedRecord != null && selectedHasMapEvidence) ...[
              const SizedBox(height: 8),
              Text(
                'السجل المحدد يملك payload مكانيًا؛ زر map hook سيرسل أمر كاميرا فقط دون تشغيل طبقات أو تعديل activeLayers.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF0F766E)),
              ),
            ],
            if (state.stagingLastRpcLine != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                state.stagingLastRpcLine!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (state.stagingErrorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                state.stagingErrorMessage!,
                style: const TextStyle(color: Color(0xFFB22222)),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: state.isStagingBusy ? null : controller.refreshStagingDiagnostics,
                  icon: state.isStagingBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.health_and_safety_outlined),
                  label: const Text('تشخيص الصلاحيات'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isStagingBusy ? null : controller.verifyProductionRbacMapping,
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('فحص RBAC الإنتاجي'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isStagingBusy ? null : controller.verifyFinalIntegrationReadiness,
                  icon: const Icon(Icons.task_alt_outlined),
                  label: const Text('فحص إغلاق الاندماج'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isStagingBusy || !needsRuntimeSandboxEnable
                      ? null
                      : controller.enableAuthenticatedStagingSandbox,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('تفعيل sandbox للمستخدم'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isStagingBusy || !canWrite
                      ? null
                      : controller.retireAuthenticatedSandboxOverrideIfProductionReady,
                  icon: const Icon(Icons.lock_reset_outlined),
                  label: const Text('تقاعد sandbox عند جاهزية RBAC'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isStagingBusy ? null : controller.loadFromStagingQueue,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('تحميل queue من staging'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isStagingBusy || !canWrite
                      ? null
                      : controller.createPositiveSpatialSmokeRecordInStaging,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('إنشاء اختبار مكاني'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isStagingBusy || selectedRecord == null
                      ? null
                      : () => controller.saveSelectedDraftToStaging(),
                  icon: const Icon(Icons.save_as_outlined),
                  label: const Text('حفظ السجل المحدد'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isStagingBusy || selectedRecord == null || !selectedHasMapEvidence
                      ? null
                      : () => context.go(_reviewMapRouteFor(selectedRecord)),
                  icon: const Icon(Icons.travel_explore_outlined),
                  label: const Text('فتح داخل خريطة المستكشف'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isStagingBusy || selectedRecord == null || !selectedHasMapEvidence
                      ? null
                      : () => controller.logSelectedMapHookToStaging(),
                  icon: const Icon(Icons.map_outlined),
                  label: Text(selectedHasMapEvidence ? 'تسجيل map hook' : 'map hook محجوب'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isStagingBusy ? null : controller.logFilteredExportQaToStaging,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('تسجيل Export QA'),
                ),
              ],
            ),
            if (state.stagingMessage != null) ...[
              const SizedBox(height: 8),
              Text(state.stagingMessage!),
            ],
          ],
        ),
      ),
    );
  }

  String _reviewMapRouteFor(PwfReviewRecord record) {
    final query = <String, String>{
      'source': 'mustakshif_review_board_runtime',
      'record_id': record.id,
      'label': record.placeNameAr,
      'candidate': record.currentCandidateAr,
      'cmd': record.mapCameraIntentCode,
      'layer_policy': 'navigation_only_no_layer_mutation',
      'rpc_policy': 'log_only_no_gis_write',
      if (record.historicalLat != null) 'historical_lat': record.historicalLat!.toStringAsFixed(6),
      if (record.historicalLon != null) 'historical_lon': record.historicalLon!.toStringAsFixed(6),
      if (record.candidateLat != null) 'candidate_lat': record.candidateLat!.toStringAsFixed(6),
      if (record.candidateLon != null) 'candidate_lon': record.candidateLon!.toStringAsFixed(6),
      if (record.bboxSouth != null) 'bbox_south': record.bboxSouth!.toStringAsFixed(6),
      if (record.bboxWest != null) 'bbox_west': record.bboxWest!.toStringAsFixed(6),
      if (record.bboxNorth != null) 'bbox_north': record.bboxNorth!.toStringAsFixed(6),
      if (record.bboxEast != null) 'bbox_east': record.bboxEast!.toStringAsFixed(6),
    };
    return Uri(path: '/admin/mustakshif/review-map', queryParameters: query).toString();
  }
}
