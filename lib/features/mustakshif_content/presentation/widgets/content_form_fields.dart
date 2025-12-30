import 'package:flutter/material.dart';

import '../../domain/enums/mustakshif_content_type.dart';
import '../../domain/enums/mustakshif_publish_status.dart';
import 'historical_period_filter.dart';

class ContentFormFields extends StatelessWidget {
  const ContentFormFields({
    super.key,
    required this.type,
    required this.titleController,
    required this.contentController,
    required this.excerptController,
    this.historicalPeriodId,
    required this.onChangedHistoricalPeriodId,
    required this.status,
    required this.onChangedStatus,
    required this.publishDate,
    required this.onPickPublishDate,
    // announcements
    required this.isPinned,
    required this.onChangedPinned,
    required this.priorityController,
    required this.expireAt,
    required this.onPickExpireAt,
  });

  final MustakshifContentType type;

  final TextEditingController titleController;
  final TextEditingController contentController;
  final TextEditingController excerptController;
  final int? historicalPeriodId;
  final ValueChanged<int?> onChangedHistoricalPeriodId;

  final MustakshifPublishStatus status;
  final ValueChanged<MustakshifPublishStatus> onChangedStatus;

  final DateTime? publishDate;
  final VoidCallback onPickPublishDate;

  final bool isPinned;
  final ValueChanged<bool> onChangedPinned;
  final TextEditingController priorityController;

  final DateTime? expireAt;
  final VoidCallback onPickExpireAt;

  @override
  Widget build(BuildContext context) {
    final isAnnouncement = type == MustakshifContentType.announcements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: titleController,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            labelText: 'العنوان',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: excerptController,
          textDirection: TextDirection.rtl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'ملخص (اختياري)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        HistoricalPeriodFilter(
          value: historicalPeriodId,
          onChanged: onChangedHistoricalPeriodId,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: contentController,
          textDirection: TextDirection.rtl,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'المحتوى',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<MustakshifPublishStatus>(
                value: status,
                items: MustakshifPublishStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.labelAr, textDirection: TextDirection.rtl),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChangedStatus(v);
                },
                decoration: const InputDecoration(
                  labelText: 'الحالة',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickPublishDate,
                icon: const Icon(Icons.event),
                label: Text(
                  publishDate == null ? 'تاريخ النشر' : _fmt(publishDate!),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ],
        ),
        if (isAnnouncement) ...[
          const SizedBox(height: 16),
          SwitchListTile(
            value: isPinned,
            onChanged: onChangedPinned,
            title: const Text('تثبيت الإعلان', textDirection: TextDirection.rtl),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: priorityController,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              labelText: 'الأولوية (0 - 100)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPickExpireAt,
            icon: const Icon(Icons.timer_off),
            label: Text(
              expireAt == null ? 'تاريخ انتهاء الإعلان (اختياري)' : 'ينتهي: ${_fmt(expireAt!)}',
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ],
    );
  }

  static String _fmt(DateTime dt) {
    final d = dt.toLocal();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
