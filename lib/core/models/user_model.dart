// ============================================
// 4. CORE MODELS - USER MODEL
// ============================================

// lib/core/models/user_model.dart
import '../constants/enums.dart';

class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final PlatformRole role;
  final List<PermissionKey> permissions;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.permissions,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      role: PlatformRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => PlatformRole.public,
      ),
      permissions: (json['permissions'] as List?)
              ?.map((e) => PermissionKey.values.firstWhere(
                    (p) => p.name == e,
                    orElse: () => PermissionKey.viewPublicMap,
                  ))
              .toList() ??
          [PermissionKey.viewPublicMap],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
