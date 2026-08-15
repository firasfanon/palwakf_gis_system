// lib/features/map/presentation/providers/toolbox_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/enums.dart' as rbac;
import '../../../auth/presentation/providers/auth_provider.dart';

enum ToolSection { search, layers, tools, import, settings }

enum MapToolAudience { public, employee, manager }

extension MapToolAudienceX on MapToolAudience {
  String get labelAr => switch (this) {
        MapToolAudience.public => 'الجمهور',
        MapToolAudience.employee => 'الموظف',
        MapToolAudience.manager => 'مدير الخريطة',
      };

  String get descriptionAr => switch (this) {
        MapToolAudience.public => 'أدوات عرض وبحث ومشاركة فقط دون تشغيل داخلي.',
        MapToolAudience.employee => 'أدوات تشغيل وتدقيق ميداني ضمن الصلاحيات.',
        MapToolAudience.manager => 'إدارة طبقات واستيراد وتحكم تشغيلي موسّع.',
      };

  bool get canUseEmployeeTools => this != MapToolAudience.public;
  bool get canUseManagerTools => this == MapToolAudience.manager;

  bool canAccessSection(ToolSection section) {
    return switch (section) {
      ToolSection.search => true,
      ToolSection.layers => true,
      ToolSection.tools => true,
      ToolSection.settings => true,
      ToolSection.import => canUseManagerTools,
    };
  }
}

final toolboxExpandedProvider = StateProvider<bool>((ref) => true);
final activeToolSectionProvider = StateProvider<ToolSection?>((ref) => null);

/// Role-aware tool surface for the map.
///
/// Public visitors keep a light viewer toolbox. Authenticated Mustakshif users
/// get operational tools. Platform/mustakshif managers and users with GIS/admin
/// permissions get manager tools. This is UI gating only; database/RPC access
/// must still remain protected by RBAC/RLS.
final mapToolAudienceProvider = Provider<MapToolAudience>((ref) {
  final auth = ref.watch(authNotifierProvider);
  final access = auth.access;
  final roleRaw = (auth.user?.role ?? '').trim().toLowerCase();

  final roleLooksLikeManager = {
    'admin',
    'super_admin',
    'superadmin',
    'superuser',
    'power_admin',
    'manager',
  }.contains(roleRaw);

  if (access == null) {
    if (auth.user == null) return MapToolAudience.public;
    return roleLooksLikeManager
        ? MapToolAudience.manager
        : MapToolAudience.employee;
  }

  if (access.isSuperuser) return MapToolAudience.manager;

  final canManageMap = access.can(
        rbac.SystemKey.platformAdmin,
        rbac.Permission.manageMapLayers,
      ) ||
      access.can(
        rbac.SystemKey.mustakshif,
        rbac.Permission.manageMapLayers,
      );
  final canImport = access.can(
        rbac.SystemKey.mustakshif,
        rbac.Permission.importData,
      ) ||
      access.can(
        rbac.SystemKey.platformAdmin,
        rbac.Permission.importData,
      );
  final isAdmin = access.hasRoleAtLeast(
        rbac.SystemKey.mustakshif,
        rbac.UserRole.admin,
      ) ||
      access.hasRoleAtLeast(
        rbac.SystemKey.platformAdmin,
        rbac.UserRole.admin,
      );

  if (roleLooksLikeManager || canManageMap || canImport || isAdmin) {
    return MapToolAudience.manager;
  }

  final isEmployee = access.hasRoleAtLeast(
        rbac.SystemKey.mustakshif,
        rbac.UserRole.user,
      ) ||
      access.can(rbac.SystemKey.mustakshif, rbac.Permission.read) ||
      access.can(rbac.SystemKey.mustakshif, rbac.Permission.viewReports) ||
      auth.user != null;

  return isEmployee ? MapToolAudience.employee : MapToolAudience.public;
});

enum ToolsSubPanel {
  layerManager,
  bookmarks,
  layerPresetsGovernance,
  printLayout,
  measurementReport,
  toolPermissions,
  identify,
  exportSnapshot,
  layerHealth,
  modernOverlay,
  reportIssue,
  reviewReports,
  dataGaps,
  operations,
  megaOps,
  realInteractions,
  draw,
  measure,
  directions,
  coordinates,
  share,
  compare,
}

final activeToolsSubPanelProvider =
    StateProvider<ToolsSubPanel?>((ref) => null);


class ExplorerMapBookmark {
  const ExplorerMapBookmark({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.zoom,
    required this.centerLat,
    required this.centerLng,
    required this.west,
    required this.south,
    required this.east,
    required this.north,
    required this.layerKeys,
    this.note,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final double zoom;
  final double centerLat;
  final double centerLng;
  final double west;
  final double south;
  final double east;
  final double north;
  final List<String> layerKeys;
  final String? note;

  String get bboxLabel =>
      'W: ${west.toStringAsFixed(5)}, S: ${south.toStringAsFixed(5)}, E: ${east.toStringAsFixed(5)}, N: ${north.toStringAsFixed(5)}';

  String get centerLabel =>
      '${centerLat.toStringAsFixed(6)}, ${centerLng.toStringAsFixed(6)}';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'zoom': zoom,
      'center_lat': centerLat,
      'center_lng': centerLng,
      'west': west,
      'south': south,
      'east': east,
      'north': north,
      'layer_keys': layerKeys,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
    };
  }

  static ExplorerMapBookmark? fromJson(Map<String, dynamic> json) {
    double readDouble(String key) {
      final value = json[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    final id = json['id']?.toString().trim();
    final title = json['title']?.toString().trim();
    final createdAt = DateTime.tryParse(
          json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',
        ) ??
        DateTime.now();
    final rawLayers = json['layer_keys'] ?? json['layerKeys'];
    final layerKeys = rawLayers is List
        ? rawLayers.map((item) => item.toString()).toList(growable: false)
        : const <String>[];
    if (id == null || id.isEmpty || title == null || title.isEmpty) {
      return null;
    }
    return ExplorerMapBookmark(
      id: id,
      title: title,
      createdAt: createdAt,
      zoom: readDouble('zoom'),
      centerLat: readDouble('center_lat'),
      centerLng: readDouble('center_lng'),
      west: readDouble('west'),
      south: readDouble('south'),
      east: readDouble('east'),
      north: readDouble('north'),
      layerKeys: layerKeys,
      note: json['note']?.toString(),
    );
  }

  String toJsonLikeText() {
    final layerText = layerKeys.map((layer) => '"$layer"').join(', ');
    return '''{
  "id": "$id",
  "title": "$title",
  "created_at": "${createdAt.toIso8601String()}",
  "zoom": ${zoom.toStringAsFixed(6)},
  "center_lat": ${centerLat.toStringAsFixed(6)},
  "center_lng": ${centerLng.toStringAsFixed(6)},
  "west": ${west.toStringAsFixed(6)},
  "south": ${south.toStringAsFixed(6)},
  "east": ${east.toStringAsFixed(6)},
  "north": ${north.toStringAsFixed(6)},
  "layer_keys": [$layerText]
}''';
  }

  String toSummaryText() {
    final buffer = StringBuffer()
      ..writeln('عرض محفوظ - PalWakf Mustakshif')
      ..writeln('العنوان: $title')
      ..writeln('التاريخ: ${createdAt.toIso8601String()}')
      ..writeln('المركز: $centerLabel')
      ..writeln('Zoom: ${zoom.toStringAsFixed(2)}')
      ..writeln('BBOX: $bboxLabel')
      ..writeln('الطبقات: ${layerKeys.join('|')}');
    final cleanNote = note?.trim();
    if (cleanNote != null && cleanNote.isNotEmpty) {
      buffer.writeln('ملاحظة: $cleanNote');
    }
    return buffer.toString();
  }
}

final explorerMapBookmarksProvider =
    StateProvider<List<ExplorerMapBookmark>>((ref) => const []);
