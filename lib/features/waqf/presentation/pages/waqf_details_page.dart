
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/pwf_card.dart';

import '../../application/providers/waqf_reference_providers.dart';
import '../widgets/waqf_reference_summary_cards.dart';

class WaqfDetailsPage extends ConsumerWidget {
  final String waqfId;

  const WaqfDetailsPage({super.key, required this.waqfId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundleAsync = ref.watch(waqfReferenceBundleProvider(waqfId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الوقف'),
        actions: [
          TextButton.icon(
            onPressed: () {
              final params = <String, String>{'mode': 'waqf'};
              if (waqfId.trim().isNotEmpty) {
                params['waqfId'] = waqfId.trim();
                params['waqfKey'] = waqfId.trim();
                params['q'] = waqfId.trim();
              }
              context.go(Uri(path: '/history', queryParameters: params).toString());
            },
            icon: const Icon(Icons.travel_explore),
            label: const Text('العودة إلى المستكشف'),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: bundleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('تعذر تحميل بيانات الوقف: $error')),
          data: (bundle) {
            if (bundle == null || !bundle.hasData) {
              final repository = ref.read(waqfReferenceRepositoryProvider);
              return FutureBuilder(
                future: repository.searchEndowments(query: waqfId, limit: 12),
                builder: (context, snapshot) {
                  final fallback = snapshot.data;
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (fallback != null && fallback.isNotEmpty) {
                    final endowment = fallback.first;
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        PwfCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('مرجع وقفي إداري مشتق', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: PwfColors.warning.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text('مرجع وقفي إداري مشتق', style: TextStyle(color: PwfColors.warning, fontWeight: FontWeight.w800)),
                                  ),
                                  if (endowment.nationalId.trim().isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: PwfColors.primaryBlue.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(endowment.nationalId, style: const TextStyle(color: PwfColors.primaryBlue, fontWeight: FontWeight.w800)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text('لم يُعثر على سجل وقفي تفصيلي كامل، لكن تم العثور على مرجع وقفي مشتق من الفهرس الإداري الحديث ويمكن استخدامه داخل المستكشف والسلالة.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        WaqfReferenceSummaryCard(endowment: endowment),
                      ],
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PWF / ID: $waqfId', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const Text('لم يُعثر على سجل وقفي تفصيلي في الجداول المرجعية الحالية، ولم يتوفر أيضًا مرجع إداري مشتق لهذا المعرف. جرّب فتح الصفحة عبر PWF أو الكود الإداري من داخل نتائج الوقف.'),
                      ],
                    ),
                  );
                },
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PwfCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ملخص الربط داخل المستكشف', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (bundle.isFallback ? PwfColors.warning : PwfColors.success).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              bundle.isFallback ? 'مرجع وقفي مرحلي' : 'مرجع وقفي سيادي',
                              style: TextStyle(
                                color: bundle.isFallback ? PwfColors.warning : PwfColors.success,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if ((bundle.sourceLabel).trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: PwfColors.primaryBlue.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(bundle.sourceLabel, style: const TextStyle(color: PwfColors.primaryBlue, fontWeight: FontWeight.w800)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('تُستخدم هذه الصفحة كمرجع تفصيلي مكمل لوضع «من الوقف» داخل المستكشف التاريخي، وتعرض الوقف والواقف إن توفرت بياناتهما المرجعية.'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (bundle.endowment != null) WaqfReferenceSummaryCard(endowment: bundle.endowment!),
                if (bundle.endower != null) ...[
                  const SizedBox(height: 16),
                  EndowerSummaryCard(endower: bundle.endower!),
                ],
                if ((bundle.note ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(bundle.note!),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
