import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/pwf_card.dart';
import '../../../waqf/application/providers/waqf_reference_providers.dart';
import '../../domain/models/history_waqf_asset_link.dart';

class WaqfReferencePreviewCard extends ConsumerWidget {
  const WaqfReferencePreviewCard({
    super.key,
    required this.asset,
    this.title = 'مرجع الوقف داخل المستكشف',
    this.compact = false,
  });

  final HistoryWaqfAssetLink asset;
  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookupKey = asset.pwfKey.trim().isNotEmpty ? asset.pwfKey.trim() : asset.id.trim();
    final bundleAsync = ref.watch(waqfReferenceBundleProvider(lookupKey));

    return PwfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              _TinyBadge(
                label: bundleAsync.isLoading ? 'جارٍ التحميل' : 'ربط وقفي',
                color: PwfColors.royalRed,
              ),
            ],
          ),
          const SizedBox(height: 12),
          bundleAsync.when(
            loading: () => const _InlineMessage(
              icon: Icons.hourglass_top_rounded,
              message: 'جارٍ تحميل المرجع الوقفي التفصيلي وربطه ببطاقة المستكشف.',
            ),
            error: (error, _) => _FallbackAssetSummary(
              asset: asset,
              helper: 'تعذر تحميل المرجع الوقفي التفصيلي حاليًا، لذلك نعرض البيانات المتوفرة داخل المستكشف فقط.',
            ),
            data: (bundle) {
              if (bundle == null || !bundle.hasData) {
                return _FallbackAssetSummary(
                  asset: asset,
                  helper: 'لم نجد سجلًا وقفيًا تفصيليًا لهذا الأصل داخل الجداول المرجعية، لذلك نعرض البيانات الحالية فقط.',
                );
              }

              final endowment = bundle.endowment;
              final endower = bundle.endower;
              final chips = <Widget>[
                _TinyBadge(label: endowment?.nationalId ?? asset.pwfKey, color: PwfColors.royalRed),
                if ((endowment?.type ?? asset.typeLabel ?? '').trim().isNotEmpty)
                  _TinyBadge(label: endowment?.type ?? asset.typeLabel!, color: PwfColors.primaryBlue),
                if ((endowment?.status ?? asset.statusLabel ?? '').trim().isNotEmpty)
                  _TinyBadge(label: endowment?.status ?? asset.statusLabel!, color: PwfColors.warning),
                if (bundle.isFallback)
                  const _TinyBadge(label: 'مرجع مرحلي', color: PwfColors.warning)
                else
                  const _TinyBadge(label: 'مرجع سيادي', color: PwfColors.success),
              ];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    endowment?.displayName ?? asset.displayLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: chips),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'الواقف', value: endower?.displayName ?? endowment?.endowerName ?? asset.endowerName ?? '—'),
                  _InfoRow(label: 'الموقع', value: endowment?.locationLabel ?? _locationFromAsset(asset)),
                  if (!compact) ...[
                    _InfoRow(label: 'الفئة', value: endowment?.category ?? asset.categoryLabel ?? '—'),
                    _InfoRow(label: 'النوع الفرعي', value: endowment?.subType ?? asset.typeLabel ?? '—'),
                    if ((endowment?.purpose ?? asset.purpose ?? '').trim().isNotEmpty)
                      _InfoRow(label: 'الغرض', value: endowment?.purpose ?? asset.purpose ?? '—'),
                    if (asset.area != null || endowment?.totalArea != null)
                      _InfoRow(label: 'المساحة', value: ((endowment?.totalArea ?? asset.area)!).toStringAsFixed(2)),
                  ],
                  if ((bundle.note ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      bundle.note!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PwfColors.onSurface.withValues(alpha: 0.76),
                            height: 1.6,
                          ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.go('/waqf/${asset.pwfKey.isNotEmpty ? asset.pwfKey : asset.id}'),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('فتح صفحة الوقف'),
                        ),
                        TextButton.icon(
                          onPressed: () => context.go('/history'),
                          icon: const Icon(Icons.travel_explore),
                          label: const Text('العودة إلى المستكشف'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _locationFromAsset(HistoryWaqfAssetLink item) {
    final parts = [item.community, item.municipality, item.governorate]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    return parts.isEmpty ? '—' : parts.join(' / ');
  }
}

class _FallbackAssetSummary extends StatelessWidget {
  const _FallbackAssetSummary({required this.asset, required this.helper});

  final HistoryWaqfAssetLink asset;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          asset.displayLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TinyBadge(label: asset.pwfKey, color: PwfColors.royalRed),
            if ((asset.typeLabel ?? '').trim().isNotEmpty)
              _TinyBadge(label: asset.typeLabel!, color: PwfColors.primaryBlue),
            if ((asset.statusLabel ?? '').trim().isNotEmpty)
              _TinyBadge(label: asset.statusLabel!, color: PwfColors.warning),
          ],
        ),
        const SizedBox(height: 12),
        _InfoRow(label: 'الواقف', value: asset.endowerName ?? '—'),
        _InfoRow(label: 'الموقع', value: [asset.community, asset.municipality, asset.governorate].whereType<String>().where((e) => e.trim().isNotEmpty).join(' / ').isEmpty ? '—' : [asset.community, asset.municipality, asset.governorate].whereType<String>().where((e) => e.trim().isNotEmpty).join(' / ')),
        if ((asset.purpose ?? '').trim().isNotEmpty) _InfoRow(label: 'الغرض', value: asset.purpose!),
        const SizedBox(height: 10),
        Text(
          helper,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PwfColors.onSurface.withValues(alpha: 0.76),
                height: 1.6,
              ),
        ),
      ],
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: PwfColors.primaryBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
          ),
        ),
      ],
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PwfColors.onSurface.withValues(alpha: 0.64),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
