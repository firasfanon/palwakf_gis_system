import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/pwf_button.dart';
import '../providers/map_provider.dart';

// lib/features/map/presentation/widgets/details_panel.dart
class DetailsPanel extends ConsumerWidget {
  const DetailsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waqf = ref.watch(mapNotifierProvider).selectedWaqf;
    if (waqf == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PwfColors.primaryBlue,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        waqf.pwfKey,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: waqf.status.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          waqf.status.arLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    ref.read(mapNotifierProvider.notifier).clearSelection();
                  },
                ),
              ],
            ),
          ),

          // Tabs
          DefaultTabController(
            length: 3,
            child: Expanded(
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'ملخص'),
                      Tab(text: 'الموقع'),
                      Tab(text: 'الوثائق'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Summary Tab
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('النوع', waqf.type.arLabel),
                              _buildDetailRow(
                                  'المحافظة', waqf.governorate ?? '-'),
                              _buildDetailRow('التجمع', waqf.community ?? '-'),
                              _buildDetailRow(
                                  'البلدية', waqf.municipality ?? '-'),
                              _buildDetailRow('الحوض', waqf.basin ?? '-'),
                              _buildDetailRow('القطعة', waqf.parcel ?? '-'),
                              _buildDetailRow('المساحة',
                                  waqf.area != null ? '${waqf.area} م²' : '-'),
                              const Divider(),
                              const Text(
                                'ملاحظات',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                waqf.isSensitive
                                    ? 'التفاصيل الحساسة متاحة للمخولين فقط'
                                    : 'لا توجد ملاحظات',
                                style: TextStyle(
                                  color: waqf.isSensitive
                                      ? PwfColors.royalRed
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Location Tab
                        const Center(child: Text('عرض الخريطة التفصيلي')),

                        // Documents Tab
                        const Center(child: Text('الوثائق المرتبطة')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                PwfButton(
                  label: 'إنشاء طلب استعلام استثماري',
                  isFullWidth: true,
                  onPressed: () {},
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.share),
                        label: const Text('مشاركة'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download),
                        label: const Text('تصدير'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
