import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../waqf/application/providers/waqf_reference_providers.dart';
import '../../../waqf/domain/models/endowment_reference.dart';
import '../../../waqf/presentation/widgets/waqf_reference_summary_cards.dart';

class AdminWaqfReferencePage extends ConsumerStatefulWidget {
  const AdminWaqfReferencePage({super.key});

  @override
  ConsumerState<AdminWaqfReferencePage> createState() => _AdminWaqfReferencePageState();
}

class _AdminWaqfReferencePageState extends ConsumerState<AdminWaqfReferencePage> {
  late final TextEditingController _searchCtrl;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: ref.read(waqfAdminSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }


  EndowmentReference? _selectedListItem(List<EndowmentReference> items) {
    final id = _selectedId;
    if (id == null) return null;
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _openHistoryFromWaqf(BuildContext context, EndowmentReference? item) {
    if (item == null) {
      context.go('/history?mode=waqf');
      return;
    }
    final displayQuery = item.displayName.trim();
    final fallbackQuery = item.cityName?.trim().isNotEmpty == true ? item.cityName!.trim() : item.nationalId.trim();
    final query = displayQuery.isNotEmpty ? displayQuery : fallbackQuery;
    final params = <String, String>{
      'mode': 'waqf',
      if (query.isNotEmpty) 'q': query,
      if (item.id.trim().isNotEmpty) 'waqfId': item.id.trim(),
      if (item.nationalId.trim().isNotEmpty) 'waqfKey': item.nationalId.trim(),
    };
    context.go(Uri(path: '/history', queryParameters: params).toString());
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(waqfAdminSearchQueryProvider);
    final resultsAsync = ref.watch(waqfAdminSearchResultsProvider);
    final selectedBundleAsync = _selectedId == null ? null : ref.watch(waqfReferenceBundleProvider(_selectedId!));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مرجع الوقف داخل لوحة التحكم',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'هذه الصفحة تجعل مرحلة الوقف ظاهرة إداريًا: فهرسة الأوقاف المرجعية، مراجعة الربط، ثم الانتقال إلى المستكشف أو صفحة الوقف.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.6),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ActionButton(
                    label: 'فتح المستكشف من الوقف',
                    icon: Icons.travel_explore,
                    onTap: () => _openHistoryFromWaqf(context, _selectedListItem(resultsAsync.value ?? const [])),
                  ),
                  _ActionButton(
                    label: 'فتح صفحة الوقف المحدد',
                    icon: Icons.open_in_new,
                    enabled: _selectedId != null,
                    onTap: _selectedId == null
                        ? null
                        : () {
                            final selected = _selectedListItem(resultsAsync.value ?? const []);
                            final target = (selected?.nationalId.trim().isNotEmpty == true)
                                ? selected!.nationalId.trim()
                                : _selectedId!;
                            context.go('/waqf/$target');
                          },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن وقف أو PWF أو واقف أو موقع...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.46)),
                          prefixIcon: const Icon(Icons.search, color: PwfColors.primaryGold),
                          filled: true,
                          fillColor: const Color(0xFF0B1220),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                            borderSide: BorderSide(color: PwfColors.primaryGold),
                          ),
                        ),
                        onChanged: (value) => ref.read(waqfAdminSearchQueryProvider.notifier).state = value,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: PwfColors.primaryBlue.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.24)),
                      ),
                      child: Text(
                        query.trim().isEmpty ? 'بحث عام' : 'فلترة فعّالة',
                        style: const TextStyle(color: PwfColors.primaryGold, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: resultsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, _) => _PanelMessage(message: 'تعذر تحميل الفهرس الوقفي: $error'),
                          data: (items) {
                            if (items.isEmpty) {
                              return const _PanelMessage(message: 'لا توجد نتائج وقفية مطابقة للبحث الحالي.');
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.all(14),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final selected = item.id == _selectedId;
                                return _WaqfAdminListCard(
                                  item: item,
                                  selected: selected,
                                  onTap: () => setState(() => _selectedId = item.id),
                                  onOpenDetail: () => context.go('/waqf/${item.id}'),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: _selectedId == null
                            ? const _PanelMessage(message: 'اختر وقفًا من الفهرس لعرض بطاقته المرجعية وروابطه السريعة.')
                            : selectedBundleAsync!.when(
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (error, _) => _PanelMessage(message: 'تعذر تحميل بطاقة الوقف: $error'),
                                data: (bundle) {
                                  if (bundle == null || !bundle.hasData || bundle.endowment == null) {
                                    return const _PanelMessage(message: 'لم تُعثر بطاقة مرجعية تفصيلية لهذا الوقف.');
                                  }
                                  return ListView(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'بطاقة الوقف المرجعية',
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                            ),
                                          ),
                                          if (bundle.isFallback)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: PwfColors.warning.withValues(alpha: 0.16),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: const Text('مرجع مرحلي', style: TextStyle(color: PwfColors.warning, fontWeight: FontWeight.w800)),
                                            )
                                          else
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: PwfColors.success.withValues(alpha: 0.16),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: const Text('مرجع سيادي', style: TextStyle(color: PwfColors.success, fontWeight: FontWeight.w800)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      WaqfReferenceSummaryCard(endowment: bundle.endowment!),
                                      if (bundle.endower != null) ...[
                                        const SizedBox(height: 12),
                                        EndowerSummaryCard(endower: bundle.endower!),
                                      ],
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          _ActionButton(
                                            label: 'فتح صفحة الوقف',
                                            icon: Icons.open_in_new,
                                            onTap: () => context.go('/waqf/${bundle.endowment!.id}'),
                                          ),
                                          _ActionButton(
                                            label: 'فتح المستكشف',
                                            icon: Icons.travel_explore,
                                            onTap: () => _openHistoryFromWaqf(context, bundle.endowment),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaqfAdminListCard extends StatelessWidget {
  const _WaqfAdminListCard({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onOpenDetail,
  });

  final EndowmentReference item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? PwfColors.primaryBlue.withValues(alpha: 0.16) : const Color(0xFF0B1220),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? PwfColors.primaryGold : Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.displayName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                IconButton(
                  tooltip: 'فتح صفحة الوقف',
                  onPressed: onOpenDetail,
                  icon: const Icon(Icons.open_in_new, color: PwfColors.primaryGold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DarkChip(label: item.nationalId, color: PwfColors.royalRed),
                if ((item.type ?? '').trim().isNotEmpty) _DarkChip(label: item.type!, color: PwfColors.primaryBlue),
                if ((item.status ?? '').trim().isNotEmpty) _DarkChip(label: item.status!, color: PwfColors.warning),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              [item.locationLabel, item.endowerName, item.purpose]
                  .whereType<String>()
                  .where((e) => e.trim().isNotEmpty && e != '—')
                  .join(' • '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onTap, this.enabled = true});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF111827) : const Color(0xFF111827).withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: enabled ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: enabled ? PwfColors.primaryGold : Colors.white38, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: enabled ? Colors.white70 : Colors.white38, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _DarkChip extends StatelessWidget {
  const _DarkChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
    );
  }
}

class _PanelMessage extends StatelessWidget {
  const _PanelMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.7, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
