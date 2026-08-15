// lib/data/models/admin_user.dart
class AdminUser {
  /// UUID from Supabase Auth (admin_users.id == auth.users.id)
  final String id;

  final String email;

  /// Optional display name (may be absent in some DB schemas)
  final String name;

  /// DB role string (e.g. super_admin/admin/user/viewer)
  final String role;

  final String? department;

  final bool isActive;

  /// Some deployments store a dedicated flag.
  final bool isSuperuser;

  final DateTime createdAt;
  final DateTime updatedAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.department,
    this.isActive = true,
    this.isSuperuser = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final email = (json['email'] ?? '').toString();
    final role = (json['role'] ?? '').toString();

    DateTime _parseDt(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is DateTime) return v;
      final s = v.toString();
      try {
        return DateTime.parse(s);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    final name = (json['name'] ?? json['full_name'] ?? '').toString().trim();
    final safeName = name.isNotEmpty
        ? name
        : (email.contains('@') ? email.split('@').first : 'User');

    final isSuper = (json['is_superuser'] as bool?) == true ||
        role.toLowerCase() == 'super_admin';

    return AdminUser(
      id: (json['id'] ?? '').toString(),
      email: email,
      name: safeName,
      role: role,
      department: json['department']?.toString(),
      isActive: (json['is_active'] as bool?) ?? true,
      isSuperuser: isSuper,
      createdAt: _parseDt(json['created_at']),
      updatedAt: _parseDt(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'department': department,
      'is_active': isActive,
      'is_superuser': isSuperuser,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AdminUser copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? department,
    bool? isActive,
    bool? isSuperuser,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
      isSuperuser: isSuperuser ?? this.isSuperuser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AdminUser(id: $id, email: $email, role: $role, isActive: $isActive, isSuperuser: $isSuperuser)';
  }
}
