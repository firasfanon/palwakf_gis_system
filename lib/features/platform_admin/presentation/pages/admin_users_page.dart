// lib/features/platform_admin/presentation/pages/admin_users_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/enums.dart' as rbac;
import '../../data/repositories/admin_users_repository.dart';
import '../providers/admin_users_providers.dart';

class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  static const _bg = Color(0xFF0B1220);
  static const _card = Color(0xFF111827);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRows = ref.watch(adminUsersRowsProvider);
    final repo = ref.watch(adminUsersRepositoryProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              onChanged: (v) =>
                  ref.read(adminUsersQueryProvider.notifier).state = v,
              onRefresh: () => ref.invalidate(adminUsersRowsProvider),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: asyncRows.when(
                  data: (rows) {
                    if (rows.isEmpty) {
                      return const Center(
                        child: Text('لا يوجد بيانات',
                            style: TextStyle(color: Colors.white70)),
                      );
                    }
                    return ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 18, color: Colors.white10),
                      itemBuilder: (context, i) => _RowCard(
                        row: rows[i],
                        onToggleActive: (v) async {
                          await repo.setAdminUserFlags(
                              userId: rows[i].user.id, isActive: v);
                          ref.invalidate(adminUsersRowsProvider);
                        },
                        onToggleSuper: (v) async {
                          await repo.setAdminUserFlags(
                              userId: rows[i].user.id, isSuperuser: v);
                          ref.invalidate(adminUsersRowsProvider);
                        },
                        onSetPlatformRole: (role) async {
                          await repo.upsertSystemRole(
                            userId: rows[i].user.id,
                            systemKey: rbac.SystemKey.platformAdmin,
                            role: role,
                          );
                          ref.invalidate(adminUsersRowsProvider);
                        },
                        onTogglePerm: (perm, enabled) async {
                          await repo.setSystemPermission(
                            userId: rows[i].user.id,
                            systemKey: rbac.SystemKey.platformAdmin,
                            permission: perm,
                            enabled: enabled,
                          );
                          ref.invalidate(adminUsersRowsProvider);
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorBox(error: e.toString()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onRefresh;

  const _Header({required this.onChanged, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'إدارة المستخدمين',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        SizedBox(
          width: 320,
          child: TextField(
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'بحث بالإيميل/الدور…',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: 'تحديث',
        ),
      ],
    );
  }
}

class _RowCard extends StatelessWidget {
  final AdminUserRowView row;
  final ValueChanged<bool> onToggleActive;
  final ValueChanged<bool> onToggleSuper;
  final ValueChanged<String> onSetPlatformRole;
  final void Function(rbac.Permission perm, bool enabled) onTogglePerm;

  const _RowCard({
    required this.row,
    required this.onToggleActive,
    required this.onToggleSuper,
    required this.onSetPlatformRole,
    required this.onTogglePerm,
  });

  static const _roles = <String>['viewer', 'user', 'admin', 'superuser'];

  @override
  Widget build(BuildContext context) {
    final u = row.user;
    final role = (row.platformAdminRole ?? '').isNotEmpty
        ? row.platformAdminRole!
        : 'viewer';
    final perms = row.platformAdminPermissions;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              u.email,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Chip(text: u.role.isEmpty ? '—' : u.role, icon: Icons.badge),
                  _Chip(text: 'platformAdmin: $role', icon: Icons.shield),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('نشط', style: TextStyle(color: Colors.white70)),
                Switch(value: u.isActive, onChanged: onToggleActive),
                const SizedBox(width: 10),
                const Text('Super', style: TextStyle(color: Colors.white70)),
                Switch(value: u.isSuperuser, onChanged: onToggleSuper),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('الدور', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _roles.contains(role) ? role : 'viewer',
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white),
                  items: _roles
                      .map((r) => DropdownMenuItem<String>(
                            value: r,
                            child: Text(r),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    onSetPlatformRole(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              children: [
                _PermToggle(
                  title: 'manageUsers',
                  value: perms.contains(rbac.Permission.manageUsers),
                  onChanged: (v) =>
                      onTogglePerm(rbac.Permission.manageUsers, v),
                ),
                _PermToggle(
                  title: 'manageMapLayers',
                  value: perms.contains(rbac.Permission.manageMapLayers),
                  onChanged: (v) =>
                      onTogglePerm(rbac.Permission.manageMapLayers, v),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _PermToggle extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PermToggle(
      {required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (v) => onChanged(v == true),
          side: const BorderSide(color: Colors.white38),
          checkColor: Colors.black,
          activeColor: Colors.amber,
        ),
        Text(title, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Chip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white60),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;
  const _ErrorBox({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        error,
        style: const TextStyle(color: Colors.redAccent),
        textAlign: TextAlign.center,
      ),
    );
  }
}
