// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/theme.dart';
import 'core/services/supabase_config.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env if present (preferred for local/dev). Falls back to --dart-define.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // ignore if missing
  }

  final envUrl = (dotenv.env['SUPABASE_URL'] ?? '').trim();
  final envKey = (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();

  final url = (envUrl.startsWith('http') && !envUrl.contains('YOUR_SUPABASE'))
      ? envUrl
      : SupabaseConfig.url;

  final anonKey = (envKey.isNotEmpty && !envKey.contains('YOUR_SUPABASE'))
      ? envKey
      : SupabaseConfig.anonKey;

  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );

  runApp(const ProviderScope(child: PalWakfApp()));
}

class PalWakfApp extends ConsumerWidget {
  const PalWakfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final isConfigured = Supabase.instance.client.rest.url
            .toString()
            .startsWith('http') &&
        !Supabase.instance.client.rest.url.toString().contains('YOUR_SUPABASE');

    return MaterialApp.router(
      title: 'مستكشف الوقف | Waqf Explorer',
      debugShowCheckedModeBanner: false,
      theme: PwfTheme.lightTheme,
      darkTheme: PwfTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      locale: const Locale('ar'),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        // شريط تحذير خفيف عند عدم تمرير مفاتيح Supabase
        return Stack(
          children: [
            child,
            if (!isConfigured)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Material(
                    color: const Color(0xFFB22222),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: const [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Supabase غير مُهيّأ: ضع SUPABASE_URL و SUPABASE_ANON_KEY في ملف .env أو مرّرها عبر --dart-define لتفعيل تسجيل الدخول والبيانات.',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
