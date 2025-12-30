import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';
import 'app/router.dart';
import 'data/services/storage_service.dart';
import 'domain/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ ENV loaded');
  } catch (e) {
    debugPrint('⚠️ ENV load failed: $e');
  }

  // تهيئة StorageService
  final storageService = await StorageService.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // توفير StorageService للتطبيق
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const WaqfApp(),
    ),
  );
}

class WaqfApp extends StatefulWidget {
  const WaqfApp({super.key});

  @override
  State<WaqfApp> createState() => _WaqfAppState();
}

class _WaqfAppState extends State<WaqfApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isArabic = true;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light 
          ? ThemeMode.dark 
          : ThemeMode.light;
    });
  }

  void _toggleLanguage() {
    setState(() {
      _isArabic = !_isArabic;
    });
    debugPrint('تم تبديل اللغة إلى: ${_isArabic ? "العربية" : "English"}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: _isArabic ? 'مستكشف الوقف' : 'Waqf Explorer',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: _themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        return _AppScope(
          onToggleTheme: _toggleTheme,
          onToggleLanguage: _toggleLanguage,
          isArabic: _isArabic,
          isDarkMode: _themeMode == ThemeMode.dark,
          child: Directionality(
            textDirection: _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _AppScope extends InheritedWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;
  final bool isArabic;
  final bool isDarkMode;

  const _AppScope({
    required this.onToggleTheme,
    required this.onToggleLanguage,
    required this.isArabic,
    required this.isDarkMode,
    required super.child,
  });

  static _AppScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AppScope>();
  }

  @override
  bool updateShouldNotify(_AppScope oldWidget) {
    return isArabic != oldWidget.isArabic || isDarkMode != oldWidget.isDarkMode;
  }
}

class AppState {
  static void toggleTheme(BuildContext context) {
    _AppScope.of(context)?.onToggleTheme();
  }

  static void toggleLanguage(BuildContext context) {
    _AppScope.of(context)?.onToggleLanguage();
  }

  static bool isArabic(BuildContext context) {
    return _AppScope.of(context)?.isArabic ?? true;
  }

  static bool isDarkMode(BuildContext context) {
    return _AppScope.of(context)?.isDarkMode ?? false;
  }

  static VoidCallback? getToggleTheme(BuildContext context) {
    return _AppScope.of(context)?.onToggleTheme;
  }

  static VoidCallback? getToggleLanguage(BuildContext context) {
    return _AppScope.of(context)?.onToggleLanguage;
  }
}
