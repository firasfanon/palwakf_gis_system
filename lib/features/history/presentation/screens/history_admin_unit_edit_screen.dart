// lib/features/history/presentation/screens/history_admin_unit_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/history_admin_providers.dart';
import '../../domain/models/history_admin_models.dart';
import '../state/admin_unit_form_notifier.dart';
import '../state/admin_unit_form_providers.dart';
import '../widgets/admin_unit_form_fields.dart';

class HistoryAdminUnitEditScreen extends ConsumerWidget {
  const HistoryAdminUnitEditScreen.newUnit({
    super.key,
    required this.periodId,
    required this.level,
  }) : id = null;

  const HistoryAdminUnitEditScreen.edit({
    super.key,
    required this.id,
  })  : periodId = null,
        level = null;

  final int? id;
  final int? periodId;
  final HistoricalAdminLevel? level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id == null) {
      final args = (periodId: periodId!, level: level!);
      final state = ref.watch(adminUnitFormNewProvider(args));
      final notifier = ref.read(adminUnitFormNewProvider(args).notifier);

      return _AdminUnitEditScaffold(
        title: 'إضافة وحدة إدارية جديدة',
        state: state,
        notifier: notifier,
        isNew: true,
      );
    }

    final unitAsync = ref.watch(adminUnitByIdProvider(id!));

    return unitAsync.when(
      data: (unit) {
        if (unit == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('تحرير وحدة إدارية'),
            ),
            body: const Center(
              child: Text('لم يتم العثور على الوحدة'),
            ),
          );
        }

        final notifier =
        ref.read(adminUnitFormExistingProvider(unit).notifier);
        final state = ref.watch(adminUnitFormExistingProvider(unit));

        return _AdminUnitEditScaffold(
          title: 'تحرير وحدة إدارية',
          state: state,
          notifier: notifier,
          isNew: false,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('تحرير وحدة إدارية'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(
          title: const Text('تحرير وحدة إدارية'),
        ),
        body: Center(child: Text('خطأ: $e')),
      ),
    );
  }
}

class _AdminUnitEditScaffold extends StatelessWidget {
  const _AdminUnitEditScaffold({
    required this.title,
    required this.state,
    required this.notifier,
    required this.isNew,
  });

  final String title;
  final AdminUnitFormState state;
  final AdminUnitFormNotifier notifier;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!isNew && !state.isDeleting)
            IconButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تأكيد الحذف'),
                    content: const Text(
                        'هل أنت متأكد من حذف هذه الوحدة الإدارية؟'),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(false),
                        child: const Text('إلغاء'),
                      ),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(true),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                ) ??
                    false;

                if (confirmed) {
                  await notifier.delete();
                  if (context.mounted) {
                    context.pop();
                  }
                }
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: state.isSaving || state.isDeleting,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  AdminUnitFormFields(
                    state: state,
                    notifier: notifier,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await notifier.save();
                        if (state.error == null && state.saveSuccess) {
                          if (context.mounted) {
                            context.pop();
                          }
                        }
                      },
                      child: Text(isNew ? 'حفظ الوحدة' : 'حفظ التعديلات'),
                    ),
                  ),
                ],
              ),
            ),
            if (state.isSaving || state.isDeleting)
              Container(
                color: Colors.black.withValues(alpha: 0.15),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
