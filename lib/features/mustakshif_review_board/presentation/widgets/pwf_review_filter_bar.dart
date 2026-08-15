import 'package:flutter/material.dart';

import '../../domain/pwf_review_enums.dart';
import '../pwf_review_board_providers.dart';

class PwfReviewFilterBar extends StatelessWidget {
  const PwfReviewFilterBar({
    super.key,
    required this.state,
    required this.onQueryChanged,
    required this.onQueueChanged,
    required this.onStatusChanged,
    required this.onGateChanged,
    required this.onSortChanged,
    required this.onLocalDraftsOnlyChanged,
    required this.onClearFilters,
  });

  final PwfReviewBoardState state;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onQueueChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onGateChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<bool> onLocalDraftsOnlyChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 210,
                  child: TextField(
                    onChanged: onQueryChanged,
                    decoration: const InputDecoration(
                      labelText: 'بحث في السجلات',
                      hintText: 'اسم تاريخي، مرشح، فترة، هندسة، أو رقم سجل',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: state.selectedQueueCode,
                    decoration: const InputDecoration(
                      labelText: 'مسار المراجعة',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'all', child: _dropdownText('كل المسارات')),
                      ...PwfReviewQueue.values.map(
                        (queue) => DropdownMenuItem(
                          value: queue.code,
                          child: _dropdownText(queue.labelAr),
                        ),
                      ),
                    ],
                    onChanged: (value) => onQueueChanged(value ?? 'all'),
                  ),
                ),
                SizedBox(
                  width: 270,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: state.selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'حالة المراجعة',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: state.availableStatuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: _dropdownText(status == 'all' ? 'كل الحالات' : status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => onStatusChanged(value ?? 'all'),
                  ),
                ),
                SizedBox(
                  width: 270,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: state.selectedGateCode,
                    decoration: const InputDecoration(
                      labelText: 'بوابة التشغيل',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: state.availableGateCodes
                        .map(
                          (gate) => DropdownMenuItem(
                            value: gate,
                            child: _dropdownText(gate == 'all' ? 'كل البوابات' : _gateLabel(gate)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => onGateChanged(value ?? 'all'),
                  ),
                ),
                SizedBox(
                  width: 270,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: state.selectedSortCode,
                    decoration: const InputDecoration(
                      labelText: 'الترتيب',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'risk_desc', child: _dropdownText('الأعلى خطورة أولًا')),
                      DropdownMenuItem(value: 'confidence_desc', child: _dropdownText('الثقة الأعلى')),
                      DropdownMenuItem(value: 'confidence_asc', child: _dropdownText('الثقة الأقل')),
                      DropdownMenuItem(value: 'distance_asc', child: _dropdownText('المسافة الأقرب')),
                      DropdownMenuItem(value: 'distance_desc', child: _dropdownText('المسافة الأبعد')),
                      DropdownMenuItem(value: 'queue_asc', child: _dropdownText('حسب مسار F')),
                      DropdownMenuItem(value: 'updated_desc', child: _dropdownText('آخر تعديل محلي')),
                    ],
                    onChanged: (value) => onSortChanged(value ?? 'risk_desc'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  selected: state.showLocalDraftsOnly,
                  onSelected: onLocalDraftsOnlyChanged,
                  avatar: const Icon(Icons.save_outlined, size: 18),
                  label: Text('المسودات المحلية فقط (${state.localDraftCount})'),
                ),
                OutlinedButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('مسح الفلاتر'),
                ),
                Text(
                  'المعروض: ${state.filteredRecords.length} من ${state.records.length}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _gateLabel(String gate) {
    return switch (gate) {
      'blocked_source_locator_required' => 'محجوب: مصدر مطلوب',
      'blocked_dual_signoff_required' => 'محجوب: توقيعان مطلوبان',
      'blocked_reviewer_disagreement' => 'محجوب: تعارض مراجعين',
      'not_exportable_negative_or_pending_decision' => 'غير قابل للتصدير',
      'internal_decision_package_ready' => 'جاهز داخليًا',
      _ => gate,
    };
  }
}


Widget _dropdownText(String value) {
  return Text(
    value,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    softWrap: false,
  );
}

