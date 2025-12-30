import 'package:flutter/material.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم استلام رسالتك (تجريبيًا). سيتم ربط الإرسال لاحقًا.')),
    );

    _nameCtrl.clear();
    _emailCtrl.clear();
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تواصل معنا',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'يمكنك إرسال رسالة مباشرة لفريق الإدارة. (سيتم تفعيل الإرسال الفعلي لاحقًا عبر خدمة بريد أو API).',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'نموذج الرسالة',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(labelText: 'الاسم'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _emailCtrl,
                                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                                textDirection: TextDirection.ltr,
                                validator: (v) {
                                  final s = (v ?? '').trim();
                                  if (s.isEmpty) return 'البريد مطلوب';
                                  if (!s.contains('@')) return 'البريد غير صالح';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _msgCtrl,
                                decoration: const InputDecoration(labelText: 'الرسالة'),
                                maxLines: 5,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'الرسالة مطلوبة' : null,
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: _submit,
                                  icon: const Icon(Icons.send),
                                  label: const Text('إرسال'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'معلومات التواصل',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 10),
                                const _InfoRow(icon: Icons.location_on_outlined, text: 'فلسطين — وزارة الأوقاف والشؤون الدينية'),
                                const SizedBox(height: 8),
                                const _InfoRow(icon: Icons.phone_outlined, text: 'هاتف: — (يُحدّث لاحقًا)'),
                                const SizedBox(height: 8),
                                const _InfoRow(icon: Icons.mail_outline, text: 'Email: info@waqf.ps (مثال)'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'قنوات إضافية',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: const [
                                    Chip(label: Text('Facebook')),
                                    Chip(label: Text('X')),
                                    Chip(label: Text('YouTube')),
                                    Chip(label: Text('WhatsApp')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Text(
                'ملاحظة: سيتم لاحقًا ربط النموذج بخدمة إرسال فعلية (EmailJS/SMTP/API) مع سجل رسائل.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
