// lib/main.dart
import 'package:flutter/foundation.dart' show kIsWeb;
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

  // Web builds must not require .env as a bundled asset.
  // Prefer --dart-define, and only try flutter_dotenv on non-web targets.
  final defineUrl = const String.fromEnvironment('SUPABASE_URL').trim();
  final defineKey = const String.fromEnvironment('SUPABASE_ANON_KEY').trim();

  var dotEnvLoaded = false;
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
      dotEnvLoaded = true;
    } catch (_) {
      // .env is optional and must not be required for app bootstrap.
    }
  }

  final envUrl = defineUrl.isNotEmpty
      ? defineUrl
      : (dotEnvLoaded ? (dotenv.env['SUPABASE_URL'] ?? '').trim() : '');
  final envKey = defineKey.isNotEmpty
      ? defineKey
      : (dotEnvLoaded ? (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim() : '');

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
      title: 'ظ…ط³طھظƒط´ظپ ط§ظ„ظˆظ‚ظپ | Waqf Explorer',
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

        // ط´ط±ظٹط· طھط­ط°ظٹط± ط®ظپظٹظپ ط¹ظ†ط¯ ط¹ط¯ظ… طھظ…ط±ظٹط± ظ…ظپط§طھظٹط­ Supabase
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
                              'Supabase ط؛ظٹط± ظ…ظڈظ‡ظٹظ‘ط£: ط¶ط¹ SUPABASE_URL ظˆ SUPABASE_ANON_KEY ظپظٹ ظ…ظ„ظپ .env ط£ظˆ ظ…ط±ظ‘ط±ظ‡ط§ ط¹ط¨ط± --dart-define ظ„طھظپط¹ظٹظ„ طھط³ط¬ظٹظ„ ط§ظ„ط¯ط®ظˆظ„ ظˆط§ظ„ط¨ظٹط§ظ†ط§طھ.',
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
