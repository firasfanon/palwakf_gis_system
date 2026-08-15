// lib/features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/enums/enums.dart' as rbac;
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final ProviderSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();

    // بعد نجاح تسجيل الدخول (وصول AdminUser + AccessProfile) قم بالتوجيه:
    // - إن كانت صفحة الدخول ضمن /admin/* أو من= يشير لمسار admin → dashboard
    // - إن كان المستخدم يملك وصول platformAdmin/superuser → dashboard
    // - خلاف ذلك → /map
    _authSub = ref.listenManual<AuthState>(authNotifierProvider, (prev, next) {
      final wasLoggedIn = prev?.user != null;
      final isLoggedIn = next.user != null;
      if (wasLoggedIn || !isLoggedIn) return;

      if (!mounted) return;

      final access = next.access;
      final roleRaw = (next.user?.role ?? '').toString().toLowerCase();
      final roleFallback = <String>{
        'super_admin',
        'superadmin',
        'superuser',
        'admin',
      }.contains(roleRaw);

      final canEnterAdmin = (access?.hasRoleAtLeast(
                  rbac.SystemKey.platformAdmin, rbac.UserRole.viewer) ??
              false) ||
          (access?.isSuperuser ?? false) ||
          roleFallback;

      final uri = GoRouterState.of(context).uri;
      final fromRaw = uri.queryParameters['from'];
      String? from;
      if (fromRaw != null && fromRaw.isNotEmpty) {
        try {
          from = Uri.decodeComponent(fromRaw);
        } catch (_) {
          from = fromRaw;
        }
      }

      final currentPath = uri.path;
      final isAdminLogin =
          currentPath == '/admin/login' || currentPath.startsWith('/admin/');
      final wantsAdmin =
          (from != null && from.startsWith('/admin')) || isAdminLogin;

      final target = wantsAdmin
          ? (canEnterAdmin ? '/admin/dashboard' : '/forbidden')
          : (canEnterAdmin ? '/admin/dashboard' : '/map');

      // نفّذ التوجيه في microtask لتجنّب setState/build conflicts.
      Future.microtask(() {
        if (!mounted) return;
        context.go(target);
      });
    });
  }

  @override
  void dispose() {
    _authSub.close();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance,
                    size: 64, color: PwfColors.primaryBlue),
                const SizedBox(height: 24),
                const Text(
                  'تسجيل الدخول',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('مستكشف الوقف - PalWakf',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : () {
                            ref.read(authNotifierProvider.notifier).signIn(
                                  _emailController.text.trim(),
                                  _passwordController.text,
                                );
                          },
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('دخول'),
                  ),
                ),
                if (authState.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    authState.error!,
                    style: const TextStyle(color: PwfColors.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
