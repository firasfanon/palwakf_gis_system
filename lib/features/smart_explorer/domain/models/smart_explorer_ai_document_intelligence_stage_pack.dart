/// SMART_EXPLORER / المستكشف الذكي — AI OCR LLM RAG Review Board stage.
///
/// This model is local and read-only. It describes the operational contract
/// for OCR + LLM + RAG + Review Board without writing to sovereign schemas.
class SmartExplorerAiDocumentIntelligenceStagePack {
  const SmartExplorerAiDocumentIntelligenceStagePack({
    required this.generatedAt,
    required this.stageLabelAr,
    required this.queryAr,
    required this.readinessLabelAr,
    required this.stages,
    required this.serviceBoundaries,
    required this.requiredTables,
    required this.requiredRpcWrappers,
    required this.reviewGates,
    required this.integrationSteps,
    required this.uatScenarios,
    required this.errorRecords,
    required this.finalArtifacts,
  });

  final DateTime generatedAt;
  final String stageLabelAr;
  final String queryAr;
  final String readinessLabelAr;
  final List<SmartExplorerAiStageItem> stages;
  final List<SmartExplorerAiBoundaryItem> serviceBoundaries;
  final List<SmartExplorerAiSchemaItem> requiredTables;
  final List<SmartExplorerAiSchemaItem> requiredRpcWrappers;
  final List<SmartExplorerAiGateItem> reviewGates;
  final List<SmartExplorerAiIntegrationStep> integrationSteps;
  final List<SmartExplorerAiUatScenario> uatScenarios;
  final List<SmartExplorerAiErrorRecord> errorRecords;
  final List<SmartExplorerAiArtifact> finalArtifacts;

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('# $stageLabelAr')
      ..writeln()
      ..writeln('تاريخ التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('نطاق البحث الحالي: ${queryAr.trim().isEmpty ? 'غير محدد' : queryAr.trim()}')
      ..writeln('حالة الجاهزية: $readinessLabelAr')
      ..writeln()
      ..writeln('## القرار الحاكم')
      ..writeln('- OCR لا ينتج حقيقة سيادية؛ ينتج نصًا أوليًا قابلًا للمراجعة.')
      ..writeln('- LLM لا يقرر ولا يعتمد؛ يقترح ويحلل ويصنف فقط.')
      ..writeln('- RAG إلزامي لأي جواب تحليلي، مع citation واضح ودرجة ثقة.')
      ..writeln('- Review Board هو بوابة الاعتماد أو الرفض أو طلب الاستكمال.')
      ..writeln('- public للـ RPC wrappers فقط، وmustakshif للتحليل والمراجعة، وcore/waqf/awqaf_system مصادر سيادية لا يكتب فيها AI مباشرة.')
      ..writeln()
      ..writeln('## المراحل AI-1 إلى AI-6');
    for (final stage in stages) {
      buffer
        ..writeln()
        ..writeln('### ${stage.code} — ${stage.titleAr}')
        ..writeln('الحالة: ${stage.statusAr}')
        ..writeln(stage.descriptionAr)
        ..writeln('المخرجات:');
      for (final output in stage.outputsAr) {
        buffer.writeln('- $output');
      }
      buffer.writeln('موانع الاعتماد:');
      for (final blocker in stage.blockersAr) {
        buffer.writeln('- $blocker');
      }
    }

    buffer
      ..writeln()
      ..writeln('## حدود الخدمة والسيادة');
    for (final item in serviceBoundaries) {
      buffer.writeln('- **${item.scopeAr}**: ${item.ruleAr}');
    }

    buffer
      ..writeln()
      ..writeln('## الجداول المطلوبة داخل mustakshif');
    for (final table in requiredTables) {
      buffer.writeln('- `${table.name}` — ${table.purposeAr} — ${table.writePolicyAr}');
    }

    buffer
      ..writeln()
      ..writeln('## RPC wrappers المطلوبة داخل public');
    for (final rpc in requiredRpcWrappers) {
      buffer.writeln('- `${rpc.name}` — ${rpc.purposeAr} — ${rpc.writePolicyAr}');
    }

    buffer
      ..writeln()
      ..writeln('## بوابات Review Board');
    for (final gate in reviewGates) {
      buffer.writeln('- ${gate.code}: ${gate.titleAr} — ${gate.acceptanceRuleAr}');
    }

    buffer
      ..writeln()
      ..writeln('## خطوات الاندماج مع المستكشف الأصلي');
    for (final step in integrationSteps) {
      buffer.writeln('${step.order}. ${step.titleAr}: ${step.detailAr}');
    }

    buffer
      ..writeln()
      ..writeln('## UAT المطلوب');
    for (final scenario in uatScenarios) {
      buffer
        ..writeln('- ${scenario.code}: ${scenario.titleAr}')
        ..writeln('  - خطوات: ${scenario.stepsAr.join(' ← ')}')
        ..writeln('  - قبول: ${scenario.acceptanceAr}');
    }

    buffer
      ..writeln()
      ..writeln('## Error Records احترازية');
    for (final error in errorRecords) {
      buffer
        ..writeln('- ${error.code}: ${error.summaryAr}')
        ..writeln('  - السبب: ${error.causeAr}')
        ..writeln('  - الحل: ${error.resolutionAr}')
        ..writeln('  - آخر baseline مستقر: ${error.lastStableBaselineAr}');
    }

    buffer
      ..writeln()
      ..writeln('## المخرجات النهائية');
    for (final artifact in finalArtifacts) {
      buffer.writeln('- ${artifact.nameAr}: ${artifact.pathHintAr}');
    }
    return buffer.toString();
  }

  String toCsv() {
    final rows = <List<String>>[
      <String>['type', 'code_or_name', 'title_or_purpose', 'status_or_policy'],
      ...stages.map((item) => <String>['stage', item.code, item.titleAr, item.statusAr]),
      ...requiredTables.map((item) => <String>['mustakshif_table', item.name, item.purposeAr, item.writePolicyAr]),
      ...requiredRpcWrappers.map((item) => <String>['public_rpc_wrapper', item.name, item.purposeAr, item.writePolicyAr]),
      ...reviewGates.map((item) => <String>['review_gate', item.code, item.titleAr, item.acceptanceRuleAr]),
    ];
    return rows.map((row) => row.map(_csv).join(',')).join('\n');
  }

  String toIntegrationInstructionsText() {
    final buffer = StringBuffer()
      ..writeln('# تعليمات دمج مرحلة OCR + LLM + RAG + Review Board')
      ..writeln()
      ..writeln('## ينسخ من حزمة المستكشف الذكي')
      ..writeln('- lib/features/smart_explorer/**')
      ..writeln('- docs/smart_explorer/**')
      ..writeln('- instructions/**')
      ..writeln('- sql_sandbox/smart_explorer_ai_document_intelligence/**')
      ..writeln()
      ..writeln('## لا ينسخ ولا يستبدل')
      ..writeln('- lib/router.dart')
      ..writeln('- lib/features/map/**')
      ..writeln('- أي ملف activeLayers أو search أو navigation-only من المستكشف الأصلي')
      ..writeln()
      ..writeln('## قواعد الدمج')
      ..writeln('1. طبّق ملفات smart_explorer فقط فوق baseline الحالي.')
      ..writeln('2. شغّل flutter analyze بعد الدمج.')
      ..writeln('3. افتح /admin/smart-explorer وتحقق من ظهور أزرار: ذكاء الوثائق، CSV ذكاء الوثائق، SQL AI، تعليمات AI.')
      ..writeln('4. لا تفعل SQL على الإنتاج قبل مراجعة RBAC/RLS.')
      ..writeln('5. SQL الموجود مسودة sandbox؛ الجداول في mustakshif والـ wrappers في public فقط.')
      ..writeln('6. أي نتيجة OCR/LLM تبقى تحت Review Board ولا تكتب في core/waqf/awqaf_system.')
      ..writeln()
      ..writeln('## فحص قبول سريع');
    for (final scenario in uatScenarios) {
      buffer.writeln('- ${scenario.code}: ${scenario.acceptanceAr}');
    }
    return buffer.toString();
  }

  String toSqlDraftText() => _smartExplorerAiSqlDraft;

  String toUserGuideAddendumText() {
    return '''# ملحق دليل استخدام المستكشف الذكي — ذكاء الوثائق

هذه المرحلة تضيف مسار OCR + LLM + RAG + Review Board كطبقة تحليل ومراجعة، وليست مصدر حقيقة سيادي.

## سير العمل
1. رفع أو تسجيل وثيقة داخل Document Intake.
2. إنشاء OCR Job لاستخراج النص الخام.
3. مراجعة النص المستخرج واعتماده أو رفضه.
4. إنشاء LLM Analysis Job على النص المراجع فقط.
5. ربط النتيجة بمراجع RAG citations ومؤشرات ثقة.
6. إرسال Evidence Candidates إلى Review Board.
7. قبول/رفض/طلب استكمال، ثم تصدير تقرير قابل للتدقيق.

## تحذير تشغيلي
لا تعتمد أي نتيجة ذكاء صناعي قبل وجود مصدر، citation، درجة ثقة، وقرار Review Board.
''';
  }

  static String _csv(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }
}

class SmartExplorerAiStageItem {
  const SmartExplorerAiStageItem({required this.code, required this.titleAr, required this.statusAr, required this.descriptionAr, required this.outputsAr, required this.blockersAr});
  final String code;
  final String titleAr;
  final String statusAr;
  final String descriptionAr;
  final List<String> outputsAr;
  final List<String> blockersAr;
}

class SmartExplorerAiBoundaryItem {
  const SmartExplorerAiBoundaryItem({required this.scopeAr, required this.ruleAr});
  final String scopeAr;
  final String ruleAr;
}

class SmartExplorerAiSchemaItem {
  const SmartExplorerAiSchemaItem({required this.name, required this.purposeAr, required this.writePolicyAr});
  final String name;
  final String purposeAr;
  final String writePolicyAr;
}

class SmartExplorerAiGateItem {
  const SmartExplorerAiGateItem({required this.code, required this.titleAr, required this.acceptanceRuleAr});
  final String code;
  final String titleAr;
  final String acceptanceRuleAr;
}

class SmartExplorerAiIntegrationStep {
  const SmartExplorerAiIntegrationStep({required this.order, required this.titleAr, required this.detailAr});
  final int order;
  final String titleAr;
  final String detailAr;
}

class SmartExplorerAiUatScenario {
  const SmartExplorerAiUatScenario({required this.code, required this.titleAr, required this.stepsAr, required this.acceptanceAr});
  final String code;
  final String titleAr;
  final List<String> stepsAr;
  final String acceptanceAr;
}

class SmartExplorerAiErrorRecord {
  const SmartExplorerAiErrorRecord({required this.code, required this.summaryAr, required this.causeAr, required this.resolutionAr, required this.lastStableBaselineAr});
  final String code;
  final String summaryAr;
  final String causeAr;
  final String resolutionAr;
  final String lastStableBaselineAr;
}

class SmartExplorerAiArtifact {
  const SmartExplorerAiArtifact({required this.nameAr, required this.pathHintAr});
  final String nameAr;
  final String pathHintAr;
}

const String _smartExplorerAiSqlDraft = r'''
-- SMART_EXPLORER / المستكشف الذكي - AI OCR LLM RAG Review Board SQL Draft
-- غير إنتاجي قبل مراجعة DBA/RBAC/RLS. القاعدة: public wrappers فقط، mustakshif للتحليل والمراجعة.

create schema if not exists mustakshif;

create table if not exists mustakshif.document_intake (
  id uuid primary key default gen_random_uuid(),
  source_type text not null check (source_type in ('pdf','image','scan','external_ref','text')),
  title_ar text not null,
  source_uri text,
  storage_bucket text,
  storage_path text,
  waqf_asset_id uuid,
  explorer_context jsonb not null default '{}'::jsonb,
  intake_status text not null default 'draft' check (intake_status in ('draft','queued','processing','review','approved','rejected','archived')),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists mustakshif.ocr_jobs (
  id uuid primary key default gen_random_uuid(),
  document_intake_id uuid not null references mustakshif.document_intake(id) on delete cascade,
  engine_key text not null default 'manual_or_external_ocr',
  language_hint text not null default 'ar',
  job_status text not null default 'queued' check (job_status in ('queued','processing','completed','failed','cancelled')),
  requested_by uuid default auth.uid(),
  requested_at timestamptz not null default now(),
  completed_at timestamptz,
  error_message text
);

create table if not exists mustakshif.ocr_results (
  id uuid primary key default gen_random_uuid(),
  ocr_job_id uuid not null references mustakshif.ocr_jobs(id) on delete cascade,
  raw_text text not null,
  normalized_text text,
  confidence_score numeric(5,2) check (confidence_score is null or (confidence_score >= 0 and confidence_score <= 100)),
  quality_flags jsonb not null default '[]'::jsonb,
  page_map jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists mustakshif.ocr_review_events (
  id uuid primary key default gen_random_uuid(),
  ocr_result_id uuid not null references mustakshif.ocr_results(id) on delete cascade,
  review_status text not null check (review_status in ('accepted','corrected','rejected','needs_rescan')),
  reviewed_text text,
  reviewer_note text,
  reviewed_by uuid default auth.uid(),
  reviewed_at timestamptz not null default now()
);

create table if not exists mustakshif.llm_analysis_jobs (
  id uuid primary key default gen_random_uuid(),
  document_intake_id uuid not null references mustakshif.document_intake(id) on delete cascade,
  ocr_review_event_id uuid references mustakshif.ocr_review_events(id),
  provider_key text not null default 'reviewed_llm_adapter',
  model_key text,
  prompt_contract_version text not null default 'smart_explorer_ai_v1',
  job_status text not null default 'queued' check (job_status in ('queued','processing','completed','failed','cancelled')),
  requested_by uuid default auth.uid(),
  requested_at timestamptz not null default now(),
  completed_at timestamptz,
  error_message text
);

create table if not exists mustakshif.llm_analysis_results (
  id uuid primary key default gen_random_uuid(),
  llm_analysis_job_id uuid not null references mustakshif.llm_analysis_jobs(id) on delete cascade,
  summary_ar text,
  extracted_entities jsonb not null default '[]'::jsonb,
  temporal_clues jsonb not null default '[]'::jsonb,
  spatial_clues jsonb not null default '[]'::jsonb,
  risk_flags jsonb not null default '[]'::jsonb,
  confidence_score numeric(5,2) check (confidence_score is null or (confidence_score >= 0 and confidence_score <= 100)),
  requires_review boolean not null default true,
  result_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists mustakshif.rag_citations (
  id uuid primary key default gen_random_uuid(),
  llm_analysis_result_id uuid not null references mustakshif.llm_analysis_results(id) on delete cascade,
  citation_type text not null check (citation_type in ('document','ocr_text','waqf_asset','gis_context','review_event','external_reference')),
  source_schema text,
  source_table text,
  source_id text,
  excerpt text,
  confidence_score numeric(5,2),
  created_at timestamptz not null default now()
);

create table if not exists mustakshif.evidence_candidates (
  id uuid primary key default gen_random_uuid(),
  llm_analysis_result_id uuid references mustakshif.llm_analysis_results(id) on delete set null,
  document_intake_id uuid references mustakshif.document_intake(id) on delete set null,
  waqf_asset_id uuid,
  evidence_type text not null check (evidence_type in ('identity','location','parcel','historical','legal','quality_gap','conflict')),
  title_ar text not null,
  detail_ar text not null,
  proposed_action_ar text,
  candidate_status text not null default 'review' check (candidate_status in ('review','accepted','rejected','needs_more_evidence','archived')),
  confidence_score numeric(5,2) check (confidence_score is null or (confidence_score >= 0 and confidence_score <= 100)),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  reviewed_by uuid,
  reviewed_at timestamptz,
  reviewer_note text
);

create table if not exists mustakshif.ai_audit_logs (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  related_table text,
  related_id uuid,
  actor_id uuid default auth.uid(),
  input_digest text,
  output_digest text,
  risk_level text not null default 'medium' check (risk_level in ('low','medium','high','blocking')),
  audit_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table mustakshif.document_intake enable row level security;
alter table mustakshif.ocr_jobs enable row level security;
alter table mustakshif.ocr_results enable row level security;
alter table mustakshif.ocr_review_events enable row level security;
alter table mustakshif.llm_analysis_jobs enable row level security;
alter table mustakshif.llm_analysis_results enable row level security;
alter table mustakshif.rag_citations enable row level security;
alter table mustakshif.evidence_candidates enable row level security;
alter table mustakshif.ai_audit_logs enable row level security;

create or replace function public.rpc_smart_explorer_create_document_intake_v1(
  p_title_ar text,
  p_source_type text,
  p_source_uri text default null,
  p_waqf_asset_id uuid default null,
  p_explorer_context jsonb default '{}'::jsonb
) returns uuid
language plpgsql
security definer
set search_path = public, mustakshif
as $$
declare
  v_id uuid;
begin
  insert into mustakshif.document_intake(title_ar, source_type, source_uri, waqf_asset_id, explorer_context)
  values (p_title_ar, p_source_type, p_source_uri, p_waqf_asset_id, coalesce(p_explorer_context, '{}'::jsonb))
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.rpc_smart_explorer_create_ocr_job_v1(
  p_document_intake_id uuid,
  p_engine_key text default 'manual_or_external_ocr',
  p_language_hint text default 'ar'
) returns uuid
language plpgsql
security definer
set search_path = public, mustakshif
as $$
declare
  v_id uuid;
begin
  insert into mustakshif.ocr_jobs(document_intake_id, engine_key, language_hint)
  values (p_document_intake_id, p_engine_key, p_language_hint)
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.rpc_smart_explorer_submit_ocr_review_v1(
  p_ocr_result_id uuid,
  p_review_status text,
  p_reviewed_text text default null,
  p_reviewer_note text default null
) returns uuid
language plpgsql
security definer
set search_path = public, mustakshif
as $$
declare
  v_id uuid;
begin
  insert into mustakshif.ocr_review_events(ocr_result_id, review_status, reviewed_text, reviewer_note)
  values (p_ocr_result_id, p_review_status, p_reviewed_text, p_reviewer_note)
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.rpc_smart_explorer_create_llm_analysis_job_v1(
  p_document_intake_id uuid,
  p_ocr_review_event_id uuid default null,
  p_provider_key text default 'reviewed_llm_adapter',
  p_model_key text default null
) returns uuid
language plpgsql
security definer
set search_path = public, mustakshif
as $$
declare
  v_id uuid;
begin
  insert into mustakshif.llm_analysis_jobs(document_intake_id, ocr_review_event_id, provider_key, model_key)
  values (p_document_intake_id, p_ocr_review_event_id, p_provider_key, p_model_key)
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.rpc_smart_explorer_submit_evidence_candidate_v1(
  p_llm_analysis_result_id uuid,
  p_document_intake_id uuid,
  p_waqf_asset_id uuid,
  p_evidence_type text,
  p_title_ar text,
  p_detail_ar text,
  p_proposed_action_ar text default null,
  p_confidence_score numeric default null
) returns uuid
language plpgsql
security definer
set search_path = public, mustakshif
as $$
declare
  v_id uuid;
begin
  insert into mustakshif.evidence_candidates(
    llm_analysis_result_id, document_intake_id, waqf_asset_id, evidence_type,
    title_ar, detail_ar, proposed_action_ar, confidence_score
  ) values (
    p_llm_analysis_result_id, p_document_intake_id, p_waqf_asset_id, p_evidence_type,
    p_title_ar, p_detail_ar, p_proposed_action_ar, p_confidence_score
  ) returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.rpc_smart_explorer_review_ai_evidence_candidate_v1(
  p_evidence_candidate_id uuid,
  p_candidate_status text,
  p_reviewer_note text default null
) returns uuid
language plpgsql
security definer
set search_path = public, mustakshif
as $$
begin
  update mustakshif.evidence_candidates
  set candidate_status = p_candidate_status,
      reviewer_note = p_reviewer_note,
      reviewed_by = auth.uid(),
      reviewed_at = now()
  where id = p_evidence_candidate_id;
  return p_evidence_candidate_id;
end;
$$;

comment on schema mustakshif is 'تحليل ومراجعة المستكشف؛ لا يمثل مصدر حقيقة سيادي.';
''';
