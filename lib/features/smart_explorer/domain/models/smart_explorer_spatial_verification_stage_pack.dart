/// SMART_EXPLORER / المستكشف الذكي — Spatial Verification & Survey Plan Intelligence.
///
/// This pack is an operational contract for matching any point/vector/document
/// plan against settlement parcels, generating analytical survey-plan outputs,
/// and routing all results through mustakshif review workflows. It is deliberately
/// read-only toward sovereign schemas: public is wrappers only, mustakshif is
/// analysis/review, and core/waqf/awqaf_system are never written by AI/GIS tools.
class SmartExplorerSpatialVerificationStagePack {
  const SmartExplorerSpatialVerificationStagePack({
    required this.generatedAt,
    required this.stageLabelAr,
    required this.queryAr,
    required this.readinessLabelAr,
    required this.scopeItems,
    required this.stages,
    required this.spatialEngines,
    required this.requiredTables,
    required this.requiredRpcWrappers,
    required this.gates,
    required this.integrationSteps,
    required this.uatScenarios,
    required this.errorRecords,
    required this.finalArtifacts,
  });

  final DateTime generatedAt;
  final String stageLabelAr;
  final String queryAr;
  final String readinessLabelAr;
  final List<SmartExplorerSpatialScopeItem> scopeItems;
  final List<SmartExplorerSpatialStageItem> stages;
  final List<SmartExplorerSpatialEngineItem> spatialEngines;
  final List<SmartExplorerSpatialSchemaItem> requiredTables;
  final List<SmartExplorerSpatialSchemaItem> requiredRpcWrappers;
  final List<SmartExplorerSpatialGateItem> gates;
  final List<SmartExplorerSpatialIntegrationStep> integrationSteps;
  final List<SmartExplorerSpatialUatScenario> uatScenarios;
  final List<SmartExplorerSpatialErrorRecord> errorRecords;
  final List<SmartExplorerSpatialArtifact> finalArtifacts;

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('# $stageLabelAr')
      ..writeln()
      ..writeln('تاريخ التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('نطاق البحث الحالي: ${queryAr.trim().isEmpty ? 'غير محدد' : queryAr.trim()}')
      ..writeln('حالة الجاهزية: $readinessLabelAr')
      ..writeln()
      ..writeln('## القرار الحاكم')
      ..writeln('- الخدمة تطابق أي طبقة نقطية أو حدود أو مخطط PDF/Image/DWG/DXF مع قطع التسوية.')
      ..writeln('- المخرجات مخططات مساحة تحليلية وتقرير تداخل ومجاورين، وليست اعتمادًا قانونيًا تلقائيًا.')
      ..writeln('- public للـ RPC wrappers فقط؛ mustakshif للتحليل والمراجعة؛ core/waqf/awqaf_system مصادر سيادية لا يكتب فيها AI/GIS مباشرة.')
      ..writeln('- waqf_assets يبقى الكيان التشغيلي المركزي؛ أي ربط ينتج كمرشح مراجعة فقط.')
      ..writeln()
      ..writeln('## نطاق الخدمة');
    for (final item in scopeItems) {
      buffer.writeln('- ${item.titleAr}: ${item.detailAr}');
    }

    buffer
      ..writeln()
      ..writeln('## المراحل SV-1 إلى SV-6');
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
      ..writeln('## محركات التحقق المكاني');
    for (final engine in spatialEngines) {
      buffer
        ..writeln('- ${engine.code}: ${engine.titleAr}')
        ..writeln('  - الوظائف: ${engine.functions.join(', ')}')
        ..writeln('  - المخرج: ${engine.outputAr}');
    }

    buffer
      ..writeln()
      ..writeln('## الجداول المطلوبة داخل mustakshif');
    for (final table in requiredTables) {
      buffer.writeln('- `${table.name}` — ${table.purposeAr} — ${table.policyAr}');
    }

    buffer
      ..writeln()
      ..writeln('## RPC wrappers المطلوبة داخل public');
    for (final rpc in requiredRpcWrappers) {
      buffer.writeln('- `${rpc.name}` — ${rpc.purposeAr} — ${rpc.policyAr}');
    }

    buffer
      ..writeln()
      ..writeln('## بوابات المراجعة والقبول');
    for (final gate in gates) {
      buffer.writeln('- ${gate.code}: ${gate.titleAr} — ${gate.ruleAr}');
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
      ...spatialEngines.map((item) => <String>['engine', item.code, item.titleAr, item.outputAr]),
      ...requiredTables.map((item) => <String>['mustakshif_table', item.name, item.purposeAr, item.policyAr]),
      ...requiredRpcWrappers.map((item) => <String>['public_rpc_wrapper', item.name, item.purposeAr, item.policyAr]),
      ...gates.map((item) => <String>['review_gate', item.code, item.titleAr, item.ruleAr]),
    ];
    return rows.map((row) => row.map(_csv).join(',')).join('\n');
  }

  String toIntegrationInstructionsText() {
    final buffer = StringBuffer()
      ..writeln('# تعليمات دمج Spatial Verification & Survey Plan Intelligence')
      ..writeln()
      ..writeln('## ينسخ من حزمة المستكشف الذكي')
      ..writeln('- lib/features/smart_explorer/**')
      ..writeln('- docs/smart_explorer/**')
      ..writeln('- instructions/**')
      ..writeln('- sql_sandbox/smart_explorer_spatial_verification/**')
      ..writeln()
      ..writeln('## لا ينسخ ولا يستبدل')
      ..writeln('- lib/router.dart')
      ..writeln('- lib/features/map/**')
      ..writeln('- أي ملفات activeLayers أو search أو navigation-only من المستكشف الأصلي')
      ..writeln()
      ..writeln('## قواعد الدمج')
      ..writeln('1. طبّق ملفات smart_explorer فقط فوق baseline الحالي.')
      ..writeln('2. شغّل flutter analyze بعد الدمج.')
      ..writeln('3. افتح /admin/smart-explorer وتحقق من ظهور أزرار: التحقق المكاني، CSV التحقق المكاني، SQL مكاني، تعليمات مكاني، دليل مكاني.')
      ..writeln('4. SQL الموجود مسودة sandbox؛ لا يطبق على الإنتاج قبل RBAC/RLS ومراجعة DBA.')
      ..writeln('5. أي نتيجة مطابقة أو مخطط أو تداخل تبقى في mustakshif وReview Board، ولا تكتب في core/waqf/awqaf_system مباشرة.')
      ..writeln('6. عند قراءة طبقات الخريطة، القراءة فقط؛ لا تغيير activeLayers ولا صناديق البحث.')
      ..writeln()
      ..writeln('## فحص قبول سريع');
    for (final scenario in uatScenarios) {
      buffer.writeln('- ${scenario.code}: ${scenario.acceptanceAr}');
    }
    return buffer.toString();
  }

  String toSqlDraftText() => _smartExplorerSpatialVerificationSqlDraft;

  String toUserGuideAddendumText() {
    return '''# ملحق دليل استخدام المستكشف الذكي — التحقق المكاني ومخططات المساحة

هذه المرحلة تضيف مسارًا للتحقق المكاني من أي طبقة نقطية أو حدود أو مخطط PDF/Image/DWG/DXF مقابل قطع التسوية.

## سير العمل المختصر
1. اختر مصدرًا: نقطة، طبقة نقطية كاملة، حدود، PDF/Image، أو DWG/DXF.
2. نفذ المطابقة مع طبقة التسوية عبر wrappers عامة.
3. استعرض الحوض والقطعة والمساحة والتداخل والمجاورين ودرجة الثقة.
4. ولّد مخطط مساحة تحليلي أو تقرير فرق الحدود.
5. أرسل النتيجة إلى Review Board قبل أي اعتماد أو ربط مع waqf_asset_id.

## تحذير تشغيلي
أي مخطط صادر من هذه المرحلة هو مخرج تحليلي داخلي للمراجعة، وليس مخطط مساحة رسميًا معتمدًا إلا بعد تحقق واعتماد الجهة المختصة.
''';
  }

  static String _csv(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }
}

class SmartExplorerSpatialScopeItem {
  const SmartExplorerSpatialScopeItem({required this.titleAr, required this.detailAr});
  final String titleAr;
  final String detailAr;
}

class SmartExplorerSpatialStageItem {
  const SmartExplorerSpatialStageItem({required this.code, required this.titleAr, required this.statusAr, required this.descriptionAr, required this.outputsAr, required this.blockersAr});
  final String code;
  final String titleAr;
  final String statusAr;
  final String descriptionAr;
  final List<String> outputsAr;
  final List<String> blockersAr;
}

class SmartExplorerSpatialEngineItem {
  const SmartExplorerSpatialEngineItem({required this.code, required this.titleAr, required this.functions, required this.outputAr});
  final String code;
  final String titleAr;
  final List<String> functions;
  final String outputAr;
}

class SmartExplorerSpatialSchemaItem {
  const SmartExplorerSpatialSchemaItem({required this.name, required this.purposeAr, required this.policyAr});
  final String name;
  final String purposeAr;
  final String policyAr;
}

class SmartExplorerSpatialGateItem {
  const SmartExplorerSpatialGateItem({required this.code, required this.titleAr, required this.ruleAr});
  final String code;
  final String titleAr;
  final String ruleAr;
}

class SmartExplorerSpatialIntegrationStep {
  const SmartExplorerSpatialIntegrationStep({required this.order, required this.titleAr, required this.detailAr});
  final int order;
  final String titleAr;
  final String detailAr;
}

class SmartExplorerSpatialUatScenario {
  const SmartExplorerSpatialUatScenario({required this.code, required this.titleAr, required this.stepsAr, required this.acceptanceAr});
  final String code;
  final String titleAr;
  final List<String> stepsAr;
  final String acceptanceAr;
}

class SmartExplorerSpatialErrorRecord {
  const SmartExplorerSpatialErrorRecord({required this.code, required this.summaryAr, required this.causeAr, required this.resolutionAr, required this.lastStableBaselineAr});
  final String code;
  final String summaryAr;
  final String causeAr;
  final String resolutionAr;
  final String lastStableBaselineAr;
}

class SmartExplorerSpatialArtifact {
  const SmartExplorerSpatialArtifact({required this.nameAr, required this.pathHintAr});
  final String nameAr;
  final String pathHintAr;
}

const String _smartExplorerSpatialVerificationSqlDraft = r'''
-- SMART_EXPLORER / المستكشف الذكي - Spatial Verification & Survey Plan Intelligence SQL Draft
-- غير إنتاجي قبل مراجعة DBA/RBAC/RLS.
-- القاعدة: public wrappers فقط، mustakshif للتحليل والمراجعة، ولا كتابة AI/GIS مباشرة في core/waqf/awqaf_system.

create schema if not exists mustakshif;
create extension if not exists postgis;

create table if not exists mustakshif.spatial_document_intake (
  id uuid primary key default gen_random_uuid(),
  source_type text not null check (source_type in ('pdf','image','dwg','dxf','geojson','gpkg','shp','manual_polygon','external_ref')),
  title_ar text not null,
  source_uri text,
  storage_bucket text,
  storage_path text,
  original_srid int,
  target_srid int default 4326,
  ocr_status text not null default 'not_required' check (ocr_status in ('not_required','queued','processing','completed','failed','review')),
  georeference_status text not null default 'not_required' check (georeference_status in ('not_required','draft','queued','processing','completed','failed','review')),
  review_status text not null default 'draft' check (review_status in ('draft','review','accepted','rejected','needs_more_evidence','archived')),
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists mustakshif.spatial_match_requests (
  id uuid primary key default gen_random_uuid(),
  request_type text not null check (request_type in ('point_to_parcel','layer_points_to_parcels','polygon_to_parcel','document_plan_to_parcel','dwg_to_parcel','neighbor_validation')),
  source_layer_key text,
  source_feature_id text,
  source_name_ar text,
  source_type text,
  source_geom geometry(Geometry, 4326),
  document_intake_id uuid references mustakshif.spatial_document_intake(id) on delete set null,
  tolerance_m numeric(12,3) not null default 10,
  target_layer_key text not null default 'gis.parcels_registered_v1',
  target_filters jsonb not null default '{}'::jsonb,
  request_status text not null default 'draft' check (request_status in ('draft','queued','processing','completed','failed','review','archived')),
  requested_by uuid default auth.uid(),
  requested_at timestamptz not null default now(),
  completed_at timestamptz,
  error_message text
);

create table if not exists mustakshif.spatial_match_candidates (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references mustakshif.spatial_match_requests(id) on delete cascade,
  candidate_type text not null check (candidate_type in ('exact_containment','boundary_touch','nearest_within_tolerance','polygon_overlap','document_overlap','neighbor_conflict','no_match')),
  source_feature_id text,
  target_schema text not null default 'gis',
  target_table text not null default 'parcels_registered_v1',
  target_parcel_id text,
  settlement_block_no text,
  settlement_block_name_ar text,
  parcel_no text,
  lgu_name_ar text,
  location_name_ar text,
  distance_m numeric(12,3),
  overlap_area_m2 numeric(18,3),
  overlap_percent numeric(6,3),
  outside_area_m2 numeric(18,3),
  missing_area_m2 numeric(18,3),
  confidence_score numeric(5,2) check (confidence_score is null or (confidence_score >= 0 and confidence_score <= 100)),
  rank_order int not null default 1,
  candidate_payload jsonb not null default '{}'::jsonb,
  review_status text not null default 'review' check (review_status in ('review','accepted','rejected','needs_more_evidence','archived')),
  created_at timestamptz not null default now()
);

create table if not exists mustakshif.plan_georeference_control_points (
  id uuid primary key default gen_random_uuid(),
  document_intake_id uuid not null references mustakshif.spatial_document_intake(id) on delete cascade,
  image_x numeric(18,6) not null,
  image_y numeric(18,6) not null,
  map_x numeric(18,6) not null,
  map_y numeric(18,6) not null,
  srid int not null default 4326,
  control_point_label text,
  residual_error_m numeric(12,3),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists mustakshif.plan_georeference_jobs (
  id uuid primary key default gen_random_uuid(),
  document_intake_id uuid not null references mustakshif.spatial_document_intake(id) on delete cascade,
  method text not null default 'control_points',
  target_srid int not null default 4326,
  rms_error_m numeric(12,3),
  transformation_params jsonb not null default '{}'::jsonb,
  job_status text not null default 'draft' check (job_status in ('draft','queued','processing','completed','failed','review')),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  error_message text
);

create table if not exists mustakshif.extracted_plan_vectors (
  id uuid primary key default gen_random_uuid(),
  document_intake_id uuid not null references mustakshif.spatial_document_intake(id) on delete cascade,
  layer_name text,
  geometry_type text not null,
  geom geometry(Geometry, 4326),
  source_crs text,
  target_srid int not null default 4326,
  extraction_method text not null default 'manual_or_external_vectorization',
  quality_score numeric(5,2),
  vector_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists mustakshif.boundary_comparison_results (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references mustakshif.spatial_match_requests(id) on delete cascade,
  source_geom geometry(Geometry, 4326),
  target_geom geometry(Geometry, 4326),
  intersection_geom geometry(Geometry, 4326),
  difference_geom geometry(Geometry, 4326),
  sym_difference_geom geometry(Geometry, 4326),
  overlap_area_m2 numeric(18,3),
  outside_area_m2 numeric(18,3),
  missing_area_m2 numeric(18,3),
  boundary_shift_m numeric(12,3),
  comparison_score numeric(5,2),
  result_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists mustakshif.adjacency_validation_results (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references mustakshif.spatial_match_requests(id) on delete cascade,
  target_parcel_id text,
  neighbor_parcel_id text,
  settlement_block_no text,
  neighbor_parcel_no text,
  shared_boundary_length_m numeric(18,3),
  overlap_area_m2 numeric(18,3),
  gap_distance_m numeric(12,3),
  relation_type text not null check (relation_type in ('touching','overlapping','gap','inside','contains','crossing','unknown')),
  review_status text not null default 'review' check (review_status in ('review','accepted','rejected','needs_more_evidence','archived')),
  created_at timestamptz not null default now()
);

create table if not exists mustakshif.generated_survey_plans (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references mustakshif.spatial_match_requests(id) on delete cascade,
  approved_candidate_id uuid references mustakshif.spatial_match_candidates(id) on delete set null,
  plan_type text not null check (plan_type in ('point_parcel_plan','basin_plan','boundary_comparison_plan','document_plan','dwg_plan','adjacency_report')),
  plan_title_ar text not null,
  plan_geojson jsonb not null default '{}'::jsonb,
  plan_metadata jsonb not null default '{}'::jsonb,
  export_format text not null default 'geojson' check (export_format in ('geojson','csv','pdf','png','json')),
  export_path text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  review_status text not null default 'review' check (review_status in ('review','accepted','rejected','needs_more_evidence','archived'))
);

create table if not exists mustakshif.spatial_verification_review_events (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references mustakshif.spatial_match_requests(id) on delete cascade,
  candidate_id uuid references mustakshif.spatial_match_candidates(id) on delete set null,
  survey_plan_id uuid references mustakshif.generated_survey_plans(id) on delete set null,
  decision text not null check (decision in ('accepted','rejected','needs_more_evidence','defer_to_surveyor','archive')),
  reviewer_note text,
  reviewer_id uuid default auth.uid(),
  created_at timestamptz not null default now()
);

alter table mustakshif.spatial_document_intake enable row level security;
alter table mustakshif.spatial_match_requests enable row level security;
alter table mustakshif.spatial_match_candidates enable row level security;
alter table mustakshif.plan_georeference_control_points enable row level security;
alter table mustakshif.plan_georeference_jobs enable row level security;
alter table mustakshif.extracted_plan_vectors enable row level security;
alter table mustakshif.boundary_comparison_results enable row level security;
alter table mustakshif.adjacency_validation_results enable row level security;
alter table mustakshif.generated_survey_plans enable row level security;
alter table mustakshif.spatial_verification_review_events enable row level security;

create or replace function public.rpc_mustakshif_create_spatial_match_request_v1(
  p_request_type text,
  p_source_layer_key text default null,
  p_source_feature_id text default null,
  p_source_name_ar text default null,
  p_source_type text default null,
  p_source_geojson jsonb default null,
  p_document_intake_id uuid default null,
  p_tolerance_m numeric default 10,
  p_target_filters jsonb default '{}'::jsonb
) returns uuid
language plpgsql
security definer
set search_path = public, mustakshif, gis
as $$
declare
  v_id uuid;
  v_geom geometry(Geometry, 4326);
begin
  if p_source_geojson is not null then
    v_geom := ST_SetSRID(ST_GeomFromGeoJSON(p_source_geojson::text), 4326);
  end if;

  insert into mustakshif.spatial_match_requests(
    request_type, source_layer_key, source_feature_id, source_name_ar,
    source_type, source_geom, document_intake_id, tolerance_m, target_filters
  ) values (
    p_request_type, p_source_layer_key, p_source_feature_id, p_source_name_ar,
    p_source_type, v_geom, p_document_intake_id, coalesce(p_tolerance_m, 10), coalesce(p_target_filters, '{}'::jsonb)
  ) returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.rpc_mustakshif_generate_point_to_parcel_candidates_v1(
  p_request_id uuid,
  p_settlement_table regclass default 'gis.parcels_registered_v1'::regclass,
  p_tolerance_m numeric default 10
) returns integer
language plpgsql
security definer
set search_path = public, mustakshif, gis
as $$
begin
  -- Implementation note: adapt field names to the actual settlement parcel table.
  -- Required logic: ST_Covers(parcel.geom, point), then ST_DWithin fallback, with rank/confidence.
  raise notice 'Draft wrapper: implement dynamic query after confirming parcel id/block/parcel/area field names.';
  return 0;
end;
$$;

create or replace function public.rpc_mustakshif_generate_layer_points_to_parcels_v1(
  p_source_layer_key text,
  p_limit integer default 500,
  p_tolerance_m numeric default 10
) returns integer
language plpgsql
security definer
set search_path = public, mustakshif, gis, gis_waqf
as $$
begin
  -- Batch matching wrapper draft. It must whitelist source layers before execution.
  raise notice 'Draft wrapper: whitelist point layer and map its id/name/geom fields before production.';
  return 0;
end;
$$;

create or replace function public.rpc_mustakshif_generate_polygon_boundary_comparison_v1(
  p_request_id uuid
) returns uuid
language plpgsql
security definer
set search_path = public, mustakshif, gis
as $$
declare
  v_id uuid;
begin
  -- Required logic: ST_Intersects/ST_Intersection/ST_Difference/ST_SymDifference/ST_Area/ST_HausdorffDistance.
  insert into mustakshif.boundary_comparison_results(request_id, result_payload)
  values (p_request_id, jsonb_build_object('status','draft_pending_field_mapping'))
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.rpc_mustakshif_create_spatial_document_intake_v1(
  p_title_ar text,
  p_source_type text,
  p_source_uri text default null,
  p_storage_bucket text default null,
  p_storage_path text default null,
  p_metadata jsonb default '{}'::jsonb
) returns uuid
language plpgsql
security definer
set search_path = public, mustakshif
as $$
declare
  v_id uuid;
begin
  insert into mustakshif.spatial_document_intake(title_ar, source_type, source_uri, storage_bucket, storage_path, metadata)
  values (p_title_ar, p_source_type, p_source_uri, p_storage_bucket, p_storage_path, coalesce(p_metadata, '{}'::jsonb))
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.rpc_mustakshif_submit_plan_georeference_points_v1(
  p_document_intake_id uuid,
  p_points jsonb
) returns integer
language plpgsql
security definer
set search_path = public, mustakshif
as $$
begin
  -- p_points expected array: [{image_x,image_y,map_x,map_y,srid,label,residual_error_m}]
  insert into mustakshif.plan_georeference_control_points(document_intake_id, image_x, image_y, map_x, map_y, srid, control_point_label, residual_error_m)
  select
    p_document_intake_id,
    (item->>'image_x')::numeric,
    (item->>'image_y')::numeric,
    (item->>'map_x')::numeric,
    (item->>'map_y')::numeric,
    coalesce((item->>'srid')::int, 4326),
    item->>'label',
    nullif(item->>'residual_error_m','')::numeric
  from jsonb_array_elements(coalesce(p_points, '[]'::jsonb)) item;
  return coalesce(jsonb_array_length(p_points), 0);
end;
$$;

create or replace function public.rpc_mustakshif_generate_document_plan_comparison_v1(p_request_id uuid) returns uuid
language plpgsql security definer set search_path = public, mustakshif, gis
as $$
declare v_id uuid;
begin
  insert into mustakshif.boundary_comparison_results(request_id, result_payload)
  values (p_request_id, jsonb_build_object('source','document_plan','status','draft_pending_vectorization')) returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.rpc_mustakshif_generate_dwg_plan_comparison_v1(p_request_id uuid) returns uuid
language plpgsql security definer set search_path = public, mustakshif, gis
as $$
declare v_id uuid;
begin
  insert into mustakshif.boundary_comparison_results(request_id, result_payload)
  values (p_request_id, jsonb_build_object('source','dwg_dxf','status','draft_pending_ogr_qgis_extraction')) returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.rpc_mustakshif_generate_adjacency_validation_v1(p_request_id uuid) returns integer
language plpgsql security definer set search_path = public, mustakshif, gis
as $$
begin
  -- Required logic: ST_Touches/ST_Intersects/shared boundary length/gap/overlap per neighbor parcel.
  raise notice 'Draft wrapper: implement after confirming settlement parcel table fields.';
  return 0;
end;
$$;

create or replace function public.rpc_mustakshif_generate_survey_plan_output_v1(
  p_request_id uuid,
  p_approved_candidate_id uuid default null,
  p_plan_type text default 'point_parcel_plan',
  p_plan_title_ar text default 'مخطط مساحة تحليلي'
) returns uuid
language plpgsql
security definer
set search_path = public, mustakshif
as $$
declare v_id uuid;
begin
  insert into mustakshif.generated_survey_plans(request_id, approved_candidate_id, plan_type, plan_title_ar, plan_metadata)
  values (p_request_id, p_approved_candidate_id, p_plan_type, p_plan_title_ar, jsonb_build_object('legal_notice','analytical_not_official_until_reviewed'))
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.rpc_mustakshif_submit_spatial_verification_review_v1(
  p_request_id uuid,
  p_candidate_id uuid default null,
  p_survey_plan_id uuid default null,
  p_decision text default 'needs_more_evidence',
  p_reviewer_note text default null
) returns uuid
language plpgsql
security definer
set search_path = public, mustakshif
as $$
declare v_id uuid;
begin
  insert into mustakshif.spatial_verification_review_events(request_id, candidate_id, survey_plan_id, decision, reviewer_note)
  values (p_request_id, p_candidate_id, p_survey_plan_id, p_decision, p_reviewer_note)
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.rpc_mustakshif_list_spatial_verification_results_v1(p_limit integer default 50)
returns setof mustakshif.spatial_match_requests
language sql
security definer
set search_path = public, mustakshif
as $$
  select * from mustakshif.spatial_match_requests
  order by requested_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 200));
$$;
''';
