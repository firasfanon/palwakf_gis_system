// lib/features/admin/users/presentation/admin_users_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/permissions.dart';
import '../../domain/user_account.dart';
import 'users_controller.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncUsers = ref.watch(usersControllerProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  onAdd: () => _openUserDialog(context),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'بحث بالبريد أو الاسم',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: Card(
                    child: asyncUsers.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => _ErrorState(
                        message: 'تعذر تحميل المستخدمين: $e',
                        onRetry: () => ref.invalidate(usersControllerProvider),
                      ),
                      data: (users) {
                        final q = _searchCtrl.text.trim().toLowerCase();
                        final filtered = q.isEmpty
                            ? users
                            : users.where((u) {
                                final email = u.email.toLowerCase();
                                final name = (u.fullName ?? '').toLowerCase();
                                return email.contains(q) || name.contains(q);
                              }).toList();

                        if (filtered.isEmpty) {
                          return const _EmptyState(message: 'لا توجد نتائج مطابقة.');
                        }

                        final isWide = MediaQuery.sizeOf(context).width >= 900;

                        return isWide
                            ? _UsersTable(
                                users: filtered,
                                onEdit: (u) => _openUserDialog(context, user: u),
                                onDelete: (u) => _confirmDelete(context, u),
                              )
                            : _UsersList(
                                users: filtered,
                                onEdit: (u) => _openUserDialog(context, user: u),
                                onDelete: (u) => _confirmDelete(context, u),
                              );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, UserAccount user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف المستخدم: ${user.email} ؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await ref.read(usersControllerProvider.notifier).delete(user.id);
    }
  }

  Future<void> _openUserDialog(BuildContext context, {UserAccount? user}) async {
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');

    UserRole role = user?.role ?? UserRole.viewer;
    final selected = <Permission>{...?(user?.permissions.toSet())};

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isSuper = role == UserRole.superuser;
            if (isSuper) {
              selected
                ..clear()
                ..addAll(Permission.values);
            }

            return AlertDialog(
              title: Text(user == null ? 'إضافة مستخدم' : 'تعديل مستخدم'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: emailCtrl,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserRole>(
                        value: role,
                        decoration: const InputDecoration(labelText: 'الدور'),
                        items: UserRole.values
                            .map((r) => DropdownMenuItem(value: r, child: Text(_roleText(r))))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            role = v;
                            if (role == UserRole.superuser) {
                              selected
                                ..clear()
                                ..addAll(Permission.values);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'الصلاحيات',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: Permission.values.map((p) {
                          return FilterChip(
                            label: Text(p.displayName),
                            selected: selected.contains(p),
                            onSelected: isSuper
                                ? null
                                : (v) => setState(() {
                                      if (v) {
                                        selected.add(p);
                                      } else {
                                        selected.remove(p);
                                      }
                                    }),
                          );
                        }).toList(),
                      ),
                      if (isSuper) ...[
                        const SizedBox(height: 10),
                        const Text('سوبر يوزر: كافة الصلاحيات مفعّلة تلقائيًا.'),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                FilledButton(
                  onPressed: () async {
                    final email = emailCtrl.text.trim();
                    if (email.isEmpty || !email.contains('@')) return;

                    final payload = UserAccount(
                      id: user?.id ?? '',
                      email: email,
                      fullName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                      role: role,
                      permissions: (role == UserRole.superuser)
                          ? Permission.values
                          : selected.toList()..sort((a, b) => a.name.compareTo(b.name)),
                      createdAt: user?.createdAt,
                    );

                    final notifier = ref.read(usersControllerProvider.notifier);

                    if (user == null) {
                      await notifier.create(payload);
                    } else {
                      await notifier.updateUser(payload);
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _roleText(UserRole r) {
    switch (r) {
      case UserRole.superuser:
        return 'سوبر يوزر';
      case UserRole.admin:
        return 'مسؤول';
      case UserRole.user:
        return 'مستخدم';
      case UserRole.viewer:
        return 'عارض';
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            'إدارة المستخدمين',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('إضافة مستخدم'),
        ),
      ],
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.users,
    required this.onEdit,
    required this.onDelete,
  });

  final List<UserAccount> users;
  final ValueChanged<UserAccount> onEdit;
  final ValueChanged<UserAccount> onDelete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('البريد')),
            DataColumn(label: Text('الاسم')),
            DataColumn(label: Text('الدور')),
            DataColumn(label: Text('الصلاحيات')),
            DataColumn(label: Text('إجراءات')),
          ],
          rows: users.map((u) {
            return DataRow(
              cells: [
                DataCell(SelectableText(u.email, textDirection: TextDirection.ltr)),
                DataCell(Text(u.fullName ?? '-')),
                DataCell(Text(_roleText(u.role))),
                DataCell(Text(u.permissions.isEmpty ? '-' : '${u.permissions.length}')),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'تعديل',
                        onPressed: () => onEdit(u),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        tooltip: 'حذف',
                        onPressed: () => onDelete(u),
                        icon: const Icon(Icons.delete_outline),
                        color: const Color(0xFFB22222),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  static String _roleText(UserRole r) {
    switch (r) {
      case UserRole.superuser:
        return 'سوبر يوزر';
      case UserRole.admin:
        return 'مسؤول';
      case UserRole.user:
        return 'مستخدم';
      case UserRole.viewer:
        return 'عارض';
    }
  }
}

class _UsersList extends StatelessWidget {
  const _UsersList({
    required this.users,
    required this.onEdit,
    required this.onDelete,
  });

  final List<UserAccount> users;
  final ValueChanged<UserAccount> onEdit;
  final ValueChanged<UserAccount> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: users.length,
      separatorBuilder: (_, __) => const Divider(height: 18),
      itemBuilder: (_, i) {
        final u = users[i];
        return ListTile(
          leading: CircleAvatar(child: Text(u.email.isNotEmpty ? u.email[0].toUpperCase() : '?')),
          title: Text(u.email, textDirection: TextDirection.ltr),
          subtitle: Text('${u.fullName ?? '-'} • ${_roleText(u.role)}'),
          trailing: Wrap(
            spacing: 0,
            children: [
              IconButton(
                tooltip: 'تعديل',
                onPressed: () => onEdit(u),
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                tooltip: 'حذف',
                onPressed: () => onDelete(u),
                icon: const Icon(Icons.delete_outline),
                color: const Color(0xFFB22222),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _roleText(UserRole r) {
    switch (r) {
      case UserRole.superuser:
        return 'سوبر يوزر';
      case UserRole.admin:
        return 'مسؤول';
      case UserRole.user:
        return 'مستخدم';
      case UserRole.viewer:
        return 'عارض';
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ]),
      ),
    );
  }
}
