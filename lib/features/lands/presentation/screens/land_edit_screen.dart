// lib/features/lands/presentation/screens/land_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/lands_providers.dart';
import '../../domain/models/waqf_land.dart';
import '../state/land_form_notifier.dart';
import '../state/land_form_providers.dart';
import '../widgets/land_form_fields.dart';

class LandEditScreen extends ConsumerWidget {
  const LandEditScreen.newLand({super.key}) : id = null;

  const LandEditScreen.edit({super.key, required this.id});

  final int? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id == null) {
      final state = ref.watch(landFormNotifierProvider);
      final notifier = ref.read(landFormNotifierProvider.notifier);
      return _LandEditScaffold(
        isNew: true,
        state: state,
        notifier: notifier,
      );
    }

    final landAsync = ref.watch(landByIdProvider(id!));

    return landAsync.when(
      data: (land) {
        if (land == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('تحرير أرض'),
            ),
            body: const Center(
              child: Text('لم يتم العثور على الأرض'),
            ),
          );
        }

        final notifier =
        ref.read(landFormNotifierByExistingProvider(land).notifier);
        final state =
        ref.watch(landFormNotifierByExistingProvider(land));

        return _LandEditScaffold(
          isNew: false,
          state: state,
          notifier: notifier,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('تحرير أرض'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(
          title: const Text('تحرير أرض'),
        ),
        body: Center(child: Text('خطأ: $e')),
      ),
    );
  }
}

class _LandEditScaffold extends StatelessWidget {
  const _LandEditScaffold({
    required this.isNew,
    required this.state,
    required this.notifier,
  });

  final bool isNew;
  final LandFormState state;
  final LandFormNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final title = isNew ? 'إضافة أرض جديدة' : 'تعديل بيانات الأرض';

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
                        'هل أنت متأكد من حذف هذه الأرض بشكل نهائي؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('إلغاء'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
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
                  LandFormFields(state: state, notifier: notifier),
                  const SizedBox(height: 24),
                  if (state.error != null) ...[
                    Text(
                      state.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
                      child: Text(isNew ? 'حفظ الأرض' : 'حفظ التعديلات'),
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
