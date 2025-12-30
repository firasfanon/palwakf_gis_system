// lib/presentation/screens/admin/general_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeneralSettingsScreen extends ConsumerStatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  ConsumerState<GeneralSettingsScreen> createState() =>
      _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends ConsumerState<GeneralSettingsScreen> {
  // Settings state
  bool _enableNotifications = true;
  bool _enableAnalytics = true;
  bool _maintenanceMode = false;
  String _siteName = 'مستكشف الوقف الفلسطيني';
  String _contactEmail = 'info@waqf.ps';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات العامة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsCard(
            title: 'معلومات الموقع',
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'اسم الموقع',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: _siteName),
                onChanged: (value) => setState(() => _siteName = value),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: _contactEmail),
                onChanged: (value) => setState(() => _contactEmail = value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            title: 'الإعدادات العامة',
            children: [
              SwitchListTile(
                title: const Text('تفعيل الإشعارات'),
                subtitle: const Text('إرسال إشعارات للمستخدمين'),
                value: _enableNotifications,
                onChanged: (value) {
                  setState(() => _enableNotifications = value);
                },
              ),
              SwitchListTile(
                title: const Text('تفعيل التحليلات'),
                subtitle: const Text('جمع بيانات الاستخدام'),
                value: _enableAnalytics,
                onChanged: (value) {
                  setState(() => _enableAnalytics = value);
                },
              ),
              SwitchListTile(
                title: const Text('وضع الصيانة'),
                subtitle: const Text('إيقاف الوصول للموقع مؤقتاً'),
                value: _maintenanceMode,
                onChanged: (value) {
                  setState(() => _maintenanceMode = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('حفظ الإعدادات'),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    // TODO: حفظ الإعدادات في قاعدة البيانات
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الإعدادات بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}