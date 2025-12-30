import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'core/env/supabase_env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final url = SupabaseEnv.url.trim();
  final key = SupabaseEnv.anonKey.trim();

  if (url.isEmpty || key.isEmpty) {
    runApp(const _BootstrapErrorApp(
      message: 'SupabaseEnv.url أو SupabaseEnv.anonKey فارغة. تحقق من supabase_env.dart',
    ));
    return;
  }

  try {
    await Supabase.initialize(url: url, anonKey: key);
  } catch (e) {
    runApp(_BootstrapErrorApp(message: 'فشل تهيئة Supabase: $e'));
    return;
  }

  runApp(const ProviderScope(child: WaqfApp()));
}

class WaqfApp extends StatelessWidget {
  const WaqfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'مستكشف الوقف',
        routerConfig: appRouter,
      ),
    );
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                message,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
