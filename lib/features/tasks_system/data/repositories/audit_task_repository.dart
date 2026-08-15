// lib/features/tasks_system/data/repositories/audit_task_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';

final auditTaskRepositoryProvider = Provider<AuditTaskRepository>((ref) {
  return AuditTaskRepository(ref.watch(supabaseClientProvider));
});

class AuditTask {
  final String id;
  final String title;
  final String? description;
  final String taskType;
  final String status;
  final String priority;
  final String? sourceSystem;
  final String? sourceType;
  final String? sourceId;
  final Map<String, dynamic> sourcePayload;
  final String? assignedToUserId;
  final DateTime? dueDate;
  final String? createdByUserId;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AuditTask({
    required this.id,
    required this.title,
    this.description,
    required this.taskType,
    required this.status,
    required this.priority,
    this.sourceSystem,
    this.sourceType,
    this.sourceId,
    this.sourcePayload = const <String, dynamic>{},
    this.assignedToUserId,
    this.dueDate,
    this.createdByUserId,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  String get displayStatus => switch (status) {
        'open' => 'مفتوحة',
        'in_progress' => 'قيد التنفيذ',
        'blocked' => 'متوقفة',
        'done' => 'منجزة',
        'cancelled' => 'ملغاة',
        _ => status,
      };

  String get displayPriority => switch (priority) {
        'low' => 'منخفضة',
        'high' => 'مرتفعة',
        'urgent' => 'عاجلة',
        _ => 'عادية',
      };

  factory AuditTask.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final text = value?.toString();
      if (text == null || text.trim().isEmpty) return null;
      return DateTime.tryParse(text);
    }

    Map<String, dynamic> parseMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return value.cast<String, dynamic>();
      return const <String, dynamic>{};
    }

    return AuditTask(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      taskType: (json['task_type'] ?? 'audit').toString(),
      status: (json['status'] ?? 'open').toString(),
      priority: (json['priority'] ?? 'normal').toString(),
      sourceSystem: json['source_system']?.toString(),
      sourceType: json['source_type']?.toString(),
      sourceId: json['source_id']?.toString(),
      sourcePayload: parseMap(json['source_payload']),
      assignedToUserId: json['assigned_to_user_id']?.toString(),
      dueDate: parseDate(json['due_date']),
      createdByUserId: json['created_by_user_id']?.toString(),
      completedAt: parseDate(json['completed_at']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}


class AuditTaskAssignmentDraft {
  final String taskId;
  final String? assignedToUserId;
  final DateTime? dueDate;
  final String? note;

  const AuditTaskAssignmentDraft({
    required this.taskId,
    this.assignedToUserId,
    this.dueDate,
    this.note,
  });
}

class AuditTaskRepository {
  final SupabaseClient _client;

  const AuditTaskRepository(this._client);

  Future<AuditTask> createFromMapFeedback({
    required String reportId,
    String? title,
    String? description,
    String priority = 'normal',
    DateTime? dueDate,
  }) async {
    final rows = await _client.schema('tasks').rpc(
      'rpc_create_audit_task_from_map_feedback_v1',
      params: {
        'p_report_id': reportId,
        'p_title': title,
        'p_description': description,
        'p_priority': priority,
        'p_due_date': _dateOnly(dueDate),
      },
    );
    return _firstTask(rows);
  }

  Future<AuditTask> createFromExplorerGap({
    required String requestId,
    String? title,
    String? description,
    String priority = 'normal',
    DateTime? dueDate,
  }) async {
    final rows = await _client.schema('tasks').rpc(
      'rpc_create_audit_task_from_explorer_gap_v1',
      params: {
        'p_request_id': requestId,
        'p_title': title,
        'p_description': description,
        'p_priority': priority,
        'p_due_date': _dateOnly(dueDate),
      },
    );
    return _firstTask(rows);
  }


  Future<AuditTask> assignAuditTask({
    required String taskId,
    String? assignedToUserId,
    DateTime? dueDate,
    String? note,
  }) async {
    final rows = await _client.schema('tasks').rpc(
      'rpc_audit_task_assign_v1',
      params: {
        'p_task_id': taskId,
        'p_assigned_to_user_id': _nullableUuid(assignedToUserId),
        'p_due_date': _dateOnly(dueDate),
        'p_note': note,
      },
    );
    return _firstTask(rows);
  }

  Future<List<AuditTask>> listAuditTasks({
    String? status,
    String? sourceSystem,
    int limit = 100,
    int offset = 0,
  }) async {
    final rows = await _client.schema('tasks').rpc(
      'rpc_audit_task_list_v1',
      params: {
        'p_status': status,
        'p_source_system': sourceSystem,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return _taskList(rows);
  }

  Future<AuditTask> updateStatus({
    required String taskId,
    required String newStatus,
    String? note,
  }) async {
    final rows = await _client.schema('tasks').rpc(
      'rpc_audit_task_update_status_v1',
      params: {
        'p_task_id': taskId,
        'p_new_status': newStatus,
        'p_note': note,
      },
    );
    return _firstTask(rows);
  }


  String? _nullableUuid(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  AuditTask _firstTask(dynamic rows) {
    final list = _taskList(rows);
    if (list.isEmpty) {
      throw StateError('لم يرجع RPC أي مهمة تدقيق.');
    }
    return list.first;
  }

  List<AuditTask> _taskList(dynamic rows) {
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map((e) => AuditTask.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    }
    if (rows is Map) {
      return [AuditTask.fromJson(rows.cast<String, dynamic>())];
    }
    return const [];
  }
}
