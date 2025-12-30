import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/enums/mustakshif_content_type.dart';
import '../../domain/enums/mustakshif_publish_status.dart';
import '../../domain/models/mustakshif_content_item.dart';
import '../state/content_form_providers.dart';
import '../state/content_list_providers.dart';
import '../widgets/content_form_fields.dart';

class AdminMustakshifContentEditScreen extends ConsumerStatefulWidget {
  const AdminMustakshifContentEditScreen({
    super.key,
    required this.type,
    this.id,
  });

  final MustakshifContentType type;
  final String? id;

  bool get isNew => id == null || id!.trim().isEmpty;

  @override
  ConsumerState<AdminMustakshifContentEditScreen> createState() => _AdminMustakshifContentEditScreenState();
}

class _AdminMustakshifContentEditScreenState extends ConsumerState<AdminMustakshifContentEditScreen> {
  final _title = TextEditingController();
  final _excerpt = TextEditingController();
  final _content = TextEditingController();
  final _priority = TextEditingController(text: '0');

  MustakshifPublishStatus _status = MustakshifPublishStatus.draft;
  DateTime? _publishDate;
  int? _historicalPeriodId;

  bool _isPinned = false;
  DateTime? _expireAt;

  bool _loadingItem = false;
  MustakshifContentItem? _loaded;

  @override
  void initState() {
    super.initState();
    _loadIfEdit();
  }

  Future<void> _loadIfEdit() async {
    if (widget.isNew) return;
    setState(() => _loadingItem = true);

    final repo = ref.read(mustakshifContentRepositoryProvider);
    final item = await repo.fetchById(type: widget.type, id: widget.id!);

    if (!mounted) return;
    if (item != null) {
      _loaded = item;
      _title.text = item.title;
      _excerpt.text = item.excerpt ?? '';
      _content.text = item.content;

      _status = item.status;
      _publishDate = item.publishDate;
      _historicalPeriodId = item.historicalPeriodId;

      if (widget.type == MustakshifContentType.announcements) {
        _isPinned = item.isPinned ?? false;
        _priority.text = (item.priority ?? 0).toString();
        _expireAt = item.expireAt;
      }
    }
    setState(() => _loadingItem = false);
  }

  @override
  void dispose() {
    _title.dispose();
    _excerpt.dispose();
    _content.dispose();
    _priority.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isExpire}) async {
    final now = DateTime.now();
    final initial = (isExpire ? _expireAt : _publishDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() {
      if (isExpire) {
        _expireAt = picked;
      } else {
        _publishDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('العنوان والمحتوى مطلوبان')),
      );
      return;
    }

    final notifier = ref.read(mustakshifContentFormProvider.notifier);

    final saved = await notifier.save(
      type: widget.type,
      idOrEmpty: widget.isNew ? '' : widget.id!,
      title: _title.text,
      content: _content.text,
      excerpt: _excerpt.text,
      status: _status,
      publishDate: _publishDate,
      historicalPeriodId: _historicalPeriodId,
      isPinned: widget.type == MustakshifContentType.announcements ? _isPinned : null,
      priority: widget.type == MustakshifContentType.announcements
          ? int.tryParse(_priority.text.trim()) ?? 0
          : null,
      expireAt: widget.type == MustakshifContentType.announcements ? _expireAt : null,
    );

    if (!mounted) return;
    if (saved == null) {
      final err = ref.read(mustakshifContentFormProvider).error ?? 'فشل الحفظ';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    // refresh list
    ref.invalidate(mustakshifContentListProvider(ContentListArgs(type: widget.type, adminMode: true)));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم الحفظ بنجاح')),
    );

    // If new, go to edit route with id.
    if (widget.isNew) {
      context.go('/admin/mustakshif/${widget.type.name}/${saved.id}/edit');
    } else {
      // stay
      setState(() => _loaded = saved);
    }
  }

  Future<void> _delete() async {
    if (widget.isNew) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('سيتم نقل العنصر إلى الأرشيف (حذف منطقي).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );

    if (ok != true) return;

    final notifier = ref.read(mustakshifContentFormProvider.notifier);
    final success = await notifier.delete(type: widget.type, id: widget.id!);

    if (!mounted) return;
    if (!success) {
      final err = ref.read(mustakshifContentFormProvider).error ?? 'فشل الحذف';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    ref.invalidate(mustakshifContentListProvider(ContentListArgs(type: widget.type, adminMode: true)));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم الحذف')),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(mustakshifContentFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'إضافة ${widget.type.labelAr}' : 'تعديل ${widget.type.labelAr}'),
        actions: [
          if (!widget.isNew)
            IconButton(
              tooltip: 'حذف',
              onPressed: formState.isSaving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          IconButton(
            tooltip: 'حفظ',
            onPressed: formState.isSaving ? null : _save,
            icon: const Icon(Icons.save),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loadingItem
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ContentFormFields(
                      type: widget.type,
                      titleController: _title,
                      contentController: _content,
                      excerptController: _excerpt,
                      historicalPeriodId: _historicalPeriodId,
                      onChangedHistoricalPeriodId: (v) => setState(() => _historicalPeriodId = v),
                      status: _status,
                      onChangedStatus: (s) => setState(() => _status = s),
                      publishDate: _publishDate,
                      onPickPublishDate: () => _pickDate(isExpire: false),
                      isPinned: _isPinned,
                      onChangedPinned: (v) => setState(() => _isPinned = v),
                      priorityController: _priority,
                      expireAt: _expireAt,
                      onPickExpireAt: () => _pickDate(isExpire: true),
                    ),
                    const SizedBox(height: 12),
                    if (formState.error != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          formState.error!,
                          style: const TextStyle(color: Colors.red),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (_loaded != null && !widget.isNew)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'المعرّف: ${_loaded!.id}',
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
