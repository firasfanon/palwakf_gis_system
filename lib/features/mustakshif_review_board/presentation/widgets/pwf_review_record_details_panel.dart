import 'package:flutter/material.dart';

import '../../domain/pwf_review_enums.dart';
import '../../domain/pwf_review_record.dart';
import '../../domain/pwf_source_locator.dart';
import 'pwf_map_evidence_placeholder.dart';
import 'pwf_status_chip.dart';

class PwfReviewRecordDetailsPanel extends StatelessWidget {
  const PwfReviewRecordDetailsPanel({
    super.key,
    required this.record,
    required this.onSaveLocator,
    required this.onSubmitDecision,
  });

  final PwfReviewRecord? record;
  final void Function(String recordId, PwfSourceLocator locator) onSaveLocator;
  final void Function({
    required String recordId,
    required int reviewerIndex,
    required PwfReviewDecision decision,
    required String note,
  }) onSubmitDecision;

  @override
  Widget build(BuildContext context) {
    final current = record;
    if (current == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('اختر سجلًا من الجدول لعرض التفاصيل.')),
        ),
      );
    }

    return Card(
      elevation: 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              current.placeNameAr,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PwfStatusChip(label: current.queue.labelAr),
                PwfStatusChip(label: current.reviewStatus),
                PwfStatusChip(label: current.locatorStatus.labelAr),
              ],
            ),
            const Divider(height: 20),
            _InfoGrid(record: current),
            const SizedBox(height: 10),
            PwfMapEvidencePlaceholder(record: current),
            const SizedBox(height: 10),
            _GateWarning(record: current),
            const SizedBox(height: 12),
            _SourceLocatorForm(
              key: ValueKey('locator-${current.id}-${current.updatedAt?.millisecondsSinceEpoch ?? 0}'),
              record: current,
              onSave: (locator) => onSaveLocator(current.id, locator),
            ),
            const SizedBox(height: 12),
            _ReviewerDecisionForm(
              key: ValueKey('decisions-${current.id}-${current.updatedAt?.millisecondsSinceEpoch ?? 0}'),
              record: current,
              onSubmitDecision: onSubmitDecision,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.record});

  final PwfReviewRecord record;

  @override
  Widget build(BuildContext context) {
    final items = <_InfoItem>[
      _InfoItem('رقم السجل', record.id),
      _InfoItem('الفترة', record.periodLabelAr),
      _InfoItem('التقسيم الإداري', record.adminDivisionAr),
      _InfoItem('المرشح الحالي', record.currentCandidateAr),
      _InfoItem('نوع المرشح', record.candidateType),
      _InfoItem('المسافة', record.distanceLabel),
      _InfoItem('درجة الثقة', '${record.confidenceScore}%'),
      _InfoItem('حالة الهندسة', record.geometryStatus),
      _InfoItem('آخر تعديل محلي', record.updatedAt == null ? 'لا يوجد' : record.updatedAt!.toIso8601String()),
      _InfoItem('جاهزية الخريطة', record.coordinateEvidenceStatusAr),
      _InfoItem('نقطة تاريخية', record.historicalPointLabel),
      _InfoItem('centroid مرشح', record.candidatePointLabel),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => SizedBox(
              width: 205,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.label, style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 5),
                      Text(item.value, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value);

  final String label;
  final String value;
}

class _GateWarning extends StatelessWidget {
  const _GateWarning({required this.record});

  final PwfReviewRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB22222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('بوابة الحوكمة', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(record.operationalGateStatus),
          const SizedBox(height: 6),
          Text(record.warningLabel),
          const SizedBox(height: 6),
          const Text('هذه اللوحة لا تصدر اعتمادًا سياديًا ولا تعدّل core أو waqf.'),
        ],
      ),
    );
  }
}

class _SourceLocatorForm extends StatefulWidget {
  const _SourceLocatorForm({super.key, required this.record, required this.onSave});

  final PwfReviewRecord record;
  final ValueChanged<PwfSourceLocator> onSave;

  @override
  State<_SourceLocatorForm> createState() => _SourceLocatorFormState();
}

class _SourceLocatorFormState extends State<_SourceLocatorForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _typeController;
  late final TextEditingController _locatorController;
  late final TextEditingController _noteController;
  late final TextEditingController _pageController;
  late final TextEditingController _tableController;
  late final TextEditingController _rowController;

  @override
  void initState() {
    super.initState();
    final locator = widget.record.sourceLocator;
    _titleController = TextEditingController(text: locator?.sourceTitle ?? '');
    _typeController = TextEditingController(text: locator?.sourceType ?? '');
    _locatorController = TextEditingController(text: locator?.locatorText ?? '');
    _noteController = TextEditingController(text: locator?.evidenceNote ?? '');
    _pageController = TextEditingController(text: locator?.page ?? '');
    _tableController = TextEditingController(text: locator?.tableName ?? '');
    _rowController = TextEditingController(text: locator?.rowReference ?? '');
  }

  @override
  void didUpdateWidget(covariant _SourceLocatorForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.id != widget.record.id ||
        oldWidget.record.sourceLocator != widget.record.sourceLocator) {
      _syncControllersFromRecord();
    }
  }

  void _syncControllersFromRecord() {
    final locator = widget.record.sourceLocator;
    _titleController.text = locator?.sourceTitle ?? '';
    _typeController.text = locator?.sourceType ?? '';
    _locatorController.text = locator?.locatorText ?? '';
    _noteController.text = locator?.evidenceNote ?? '';
    _pageController.text = locator?.page ?? '';
    _tableController.text = locator?.tableName ?? '';
    _rowController.text = locator?.rowReference ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _typeController.dispose();
    _locatorController.dispose();
    _noteController.dispose();
    _pageController.dispose();
    _tableController.dispose();
    _rowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      title: const Text('إدخال Source Locator'),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _TextBox(controller: _titleController, label: 'عنوان المصدر', width: 300),
            _TextBox(controller: _typeController, label: 'نوع المصدر', width: 220),
            _TextBox(controller: _pageController, label: 'صفحة/لوحة', width: 150),
            _TextBox(controller: _tableController, label: 'جدول/خريطة', width: 170),
            _TextBox(controller: _rowController, label: 'صف/مرجع', width: 150),
            _TextBox(controller: _locatorController, label: 'locator نصي دقيق', width: 420),
            _TextBox(controller: _noteController, label: 'ملاحظة الدليل', width: 420, maxLines: 3),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () {
              widget.onSave(
                PwfSourceLocator(
                  sourceTitle: _titleController.text,
                  sourceType: _typeController.text,
                  locatorText: _locatorController.text,
                  evidenceNote: _noteController.text,
                  page: _pageController.text,
                  tableName: _tableController.text,
                  rowReference: _rowController.text,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حفظ المصدر محليًا في المتصفح.')),
              );
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('حفظ المصدر محليًا'),
          ),
        ),
      ],
    );
  }
}

class _ReviewerDecisionForm extends StatefulWidget {
  const _ReviewerDecisionForm({
    super.key,
    required this.record,
    required this.onSubmitDecision,
  });

  final PwfReviewRecord record;
  final void Function({
    required String recordId,
    required int reviewerIndex,
    required PwfReviewDecision decision,
    required String note,
  }) onSubmitDecision;

  @override
  State<_ReviewerDecisionForm> createState() => _ReviewerDecisionFormState();
}

class _ReviewerDecisionFormState extends State<_ReviewerDecisionForm> {
  late PwfReviewDecision _reviewerOneDecision;
  late PwfReviewDecision _reviewerTwoDecision;
  late final TextEditingController _reviewerOneNoteController;
  late final TextEditingController _reviewerTwoNoteController;

  @override
  void initState() {
    super.initState();
    _reviewerOneDecision = widget.record.reviewerOneDecision;
    _reviewerTwoDecision = widget.record.reviewerTwoDecision;
    _reviewerOneNoteController = TextEditingController(text: widget.record.reviewerOneNote);
    _reviewerTwoNoteController = TextEditingController(text: widget.record.reviewerTwoNote);
  }

  @override
  void didUpdateWidget(covariant _ReviewerDecisionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.id != widget.record.id ||
        oldWidget.record.reviewerOneDecision != widget.record.reviewerOneDecision ||
        oldWidget.record.reviewerTwoDecision != widget.record.reviewerTwoDecision ||
        oldWidget.record.reviewerOneNote != widget.record.reviewerOneNote ||
        oldWidget.record.reviewerTwoNote != widget.record.reviewerTwoNote) {
      _syncDecisionFieldsFromRecord();
    }
  }

  void _syncDecisionFieldsFromRecord() {
    _reviewerOneDecision = widget.record.reviewerOneDecision;
    _reviewerTwoDecision = widget.record.reviewerTwoDecision;
    _reviewerOneNoteController.text = widget.record.reviewerOneNote;
    _reviewerTwoNoteController.text = widget.record.reviewerTwoNote;
  }

  @override
  void dispose() {
    _reviewerOneNoteController.dispose();
    _reviewerTwoNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      title: const Text('قرار المراجعين'),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _DecisionBox(
              title: 'المراجع الأول',
              selectedDecision: _reviewerOneDecision,
              noteController: _reviewerOneNoteController,
              onDecisionChanged: (decision) => setState(() => _reviewerOneDecision = decision),
              onSubmit: () => widget.onSubmitDecision(
                recordId: widget.record.id,
                reviewerIndex: 1,
                decision: _reviewerOneDecision,
                note: _reviewerOneNoteController.text,
              ),
            ),
            _DecisionBox(
              title: 'المراجع الثاني',
              selectedDecision: _reviewerTwoDecision,
              noteController: _reviewerTwoNoteController,
              onDecisionChanged: (decision) => setState(() => _reviewerTwoDecision = decision),
              onSubmit: () => widget.onSubmitDecision(
                recordId: widget.record.id,
                reviewerIndex: 2,
                decision: _reviewerTwoDecision,
                note: _reviewerTwoNoteController.text,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DecisionBox extends StatelessWidget {
  const _DecisionBox({
    required this.title,
    required this.selectedDecision,
    required this.noteController,
    required this.onDecisionChanged,
    required this.onSubmit,
  });

  final String title;
  final PwfReviewDecision selectedDecision;
  final TextEditingController noteController;
  final ValueChanged<PwfReviewDecision> onDecisionChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              DropdownButtonFormField<PwfReviewDecision>(
                value: selectedDecision,
                decoration: const InputDecoration(
                  labelText: 'القرار',
                  border: OutlineInputBorder(),
                ),
                items: PwfReviewDecision.values
                    .map(
                      (decision) => DropdownMenuItem(
                        value: decision,
                        child: Text(decision.labelAr),
                      ),
                    )
                    .toList(),
                onChanged: (value) => onDecisionChanged(value ?? PwfReviewDecision.none),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة القرار',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('تسجيل القرار محليًا'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextBox extends StatelessWidget {
  const _TextBox({
    required this.controller,
    required this.label,
    required this.width,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final double width;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}
