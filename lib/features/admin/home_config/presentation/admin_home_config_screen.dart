// lib/features/admin/home_config/presentation/admin_home_config_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_home_config_controller.dart';
import '../../domain/home_config.dart';

class AdminHomeConfigScreen extends ConsumerWidget {
  const AdminHomeConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(adminHomeConfigControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الصفحة الرئيسية'),
      ),
      body: configAsync.when(
        data: (config) {
          if (config == null) {
            return const Center(
              child: Text('لم يتم العثور على الإعدادات'),
            );
          }

          return _HomeConfigForm(initialConfig: config);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('خطأ في تحميل الإعدادات: $e'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(adminHomeConfigControllerProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeConfigForm extends ConsumerStatefulWidget {
  const _HomeConfigForm({required this.initialConfig});

  final HomeConfig initialConfig;

  @override
  ConsumerState<_HomeConfigForm> createState() => _HomeConfigFormState();
}

class _HomeConfigFormState extends ConsumerState<_HomeConfigForm> {
  late TextEditingController _heroTitleController;
  late TextEditingController _heroSubtitleController;

  @override
  void initState() {
    super.initState();
    _heroTitleController =
        TextEditingController(text: widget.initialConfig.heroTitle);
    _heroSubtitleController =
        TextEditingController(text: widget.initialConfig.heroSubtitle);
  }

  @override
  void dispose() {
    _heroTitleController.dispose();
    _heroSubtitleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updatedConfig = widget.initialConfig.copyWith(
      heroTitle: _heroTitleController.text,
      heroSubtitle: _heroSubtitleController.text,
    );

    await ref
        .read(adminHomeConfigControllerProvider.notifier)
        .save(updatedConfig);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الإعدادات بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قسم البطل (Hero Section)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _heroTitleController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان الرئيسي',
                    border: OutlineInputBorder(),
                    helperText: 'العنوان الذي يظهر في أعلى الصفحة الرئيسية',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _heroSubtitleController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان الفرعي',
                    border: OutlineInputBorder(),
                    helperText: 'الوصف التوضيحي أسفل العنوان الرئيسي',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('حفظ التغييرات'),
          ),
        ),
      ],
    );
  }
}