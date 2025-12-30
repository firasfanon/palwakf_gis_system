// lib/features/admin/domain/user_account.dart

import 'permissions.dart';

enum UserRole {
  superuser,
  admin,
  user,
  viewer,
}

class UserAccount {
  final String id;
  final String email;
  final String? fullName;
  final UserRole role;
  final List<Permission> permissions;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  const UserAccount({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.permissions,
    this.createdAt,
    this.lastLogin,
  });

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String?,
      role: UserRole.values.firstWhere(
            (e) => e.name == map['role'],
        orElse: () => UserRole.user,
      ),
      permissions: (map['permissions'] as List?)
          ?.map((p) => Permission.values.firstWhere(
            (e) => e.name == p,
        orElse: () => Permission.viewReports,
      ))
          .toList() ??
          [],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      lastLogin: map['last_login'] != null
          ? DateTime.parse(map['last_login'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'permissions': permissions.map((p) => p.name).toList(),
      'created_at': createdAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  UserAccount copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    List<Permission>? permissions,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}