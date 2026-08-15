import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/pwf_real_map_hook_contract.dart';
import '../../domain/pwf_review_record.dart';
import 'pwf_status_chip.dart';

class PwfRealMapHookPreparationPanel extends StatelessWidget {
  const PwfRealMapHookPreparationPanel({
    super.key,
    required this.record,
    this.adapter = const PwfStandaloneRealMapHookAdapter(),
  });

  final PwfReviewRecord? record;
  final PwfRealMapHookAdapter adapter;

  @override
  Widget build(BuildContext context) {
    final selected = record;
    if (selected == null) {
      return const Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('اختر سجلًا لتجهيز ربط الخريطة.'),
        ),
      );
    }

    final envelope = adapter.buildEnvelope(selected);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hub_outlined),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Explorer Map Hook Preparation — ${selected.id}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                PwfStatusChip(label: envelope.validationLabelAr, compact: true),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'تجهيز أوامر camera فقط للدمج اللاحق مع flutter_map/PostGIS. لا رسم طبقات، لا تغيير activeLayers، ولا كتابة على Supabase.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: envelope.commands.map((command) => _HookCommandTile(command: command)).toList(growable: false),
            ),
            const SizedBox(height: 10),
            Text('تحذيرات الحوكمة', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...envelope.warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(warning)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SelectableText(envelope.compactPayload),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _copy(context, envelope.compactPayload, 'تم نسخ payload الربط الحقيقي.'),
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('نسخ hook payload'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copy(
                    context,
                    envelope.commands.map((command) => command.debugLine).join('\n'),
                    'تم نسخ أوامر الخريطة التحضيرية.',
                  ),
                  icon: const Icon(Icons.integration_instructions_outlined),
                  label: const Text('نسخ أوامر camera'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _copy(BuildContext context, String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _HookCommandTile extends StatelessWidget {
  const _HookCommandTile({required this.command});

  final PwfMapHookCommand command;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: command.enabled ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(command.enabled ? Icons.check_circle_outline : Icons.block_outlined, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(command.labelAr, style: const TextStyle(fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 6),
          Text(command.reasonAr),
          const SizedBox(height: 6),
          Text(command.commandCode, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
