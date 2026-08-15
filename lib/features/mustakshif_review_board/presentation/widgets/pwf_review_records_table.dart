import 'package:flutter/material.dart';

import '../../domain/pwf_review_record.dart';
import 'pwf_status_chip.dart';

class PwfReviewRecordsTable extends StatelessWidget {
  const PwfReviewRecordsTable({
    super.key,
    required this.records,
    required this.selectedRecordId,
    required this.localDraftRecordIds,
    required this.onSelectRecord,
  });

  final List<PwfReviewRecord> records;
  final String? selectedRecordId;
  final Set<String> localDraftRecordIds;
  final ValueChanged<String> onSelectRecord;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('لا توجد سجلات مطابقة للفلاتر الحالية.')),
        ),
      );
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18,
          dataRowMinHeight: 42,
          dataRowMaxHeight: 48,
          headingRowHeight: 44,
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('السجل')),
            DataColumn(label: Text('المكان التاريخي')),
            DataColumn(label: Text('الفترة')),
            DataColumn(label: Text('المرشح الحالي')),
            DataColumn(label: Text('المسار')),
            DataColumn(label: Text('المسافة')),
            DataColumn(label: Text('مخاطر الخريطة')),
            DataColumn(label: Text('الثقة')),
            DataColumn(label: Text('المصدر')),
            DataColumn(label: Text('بوابة التشغيل')),
            DataColumn(label: Text('جاهزية الخريطة')),
          ],
          rows: records.map((record) {
            final selected = selectedRecordId == record.id;
            final isDraft = localDraftRecordIds.contains(record.id);
            return DataRow(
              selected: selected,
              onSelectChanged: (_) => onSelectRecord(record.id),
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(record.id),
                      if (isDraft) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.save_outlined, size: 16),
                      ],
                    ],
                  ),
                ),
                DataCell(SizedBox(width: 160, child: Text(record.placeNameAr, overflow: TextOverflow.ellipsis))),
                DataCell(SizedBox(width: 105, child: Text(record.periodLabelAr, overflow: TextOverflow.ellipsis))),
                DataCell(SizedBox(width: 150, child: Text(record.currentCandidateAr, overflow: TextOverflow.ellipsis))),
                DataCell(PwfStatusChip(label: record.queueCode, compact: true)),
                DataCell(Text(record.distanceLabel)),
                DataCell(PwfStatusChip(label: record.distanceRiskLabelAr, compact: true)),
                DataCell(Text('${record.confidenceScore}%')),
                DataCell(PwfStatusChip(label: record.locatorStatus.labelAr, compact: true)),
                DataCell(SizedBox(width: 190, child: Text(record.operationalGateStatus, overflow: TextOverflow.ellipsis))),
                DataCell(SizedBox(width: 150, child: Text(record.coordinateEvidenceStatusAr, overflow: TextOverflow.ellipsis))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
