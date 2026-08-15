import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/constants/colors.dart';
import '../../../../domain/models/gis_layer_model.dart';
import '../../../providers/map_provider.dart';
import '../../../providers/map_ui_providers.dart';

class CompareToolPanel extends ConsumerWidget {
  const CompareToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapNotifierProvider);
    final enabled = ref.watch(compareEnabledProvider);
    final swipe = ref.watch(compareSwipePositionProvider);
    final left = ref.watch(compareLeftSourceProvider);
    final right = ref.watch(compareRightSourceProvider);

    final options = _compareOptions(mapState.gisLayers);
    final optionKeys = options.map((e) => e.key).toSet();
    final safeLeft =
        optionKeys.contains(left) ? left : options.firstOrNull?.key;
    final safeRight = optionKeys.contains(right)
        ? right
        : (options.length > 1 ? options[1].key : options.firstOrNull?.key);

    if (safeLeft != left && safeLeft != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(compareLeftSourceProvider.notifier).state = safeLeft;
      });
    }
    if (safeRight != right && safeRight != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(compareRightSourceProvider.notifier).state = safeRight;
      });
    }

    final leftLabel = options
            .where((e) => e.key == safeLeft)
            .map((e) => e.label)
            .firstOrNull ??
        '—';
    final rightLabel = options
            .where((e) => e.key == safeRight)
            .map((e) => e.label)
            .firstOrNull ??
        '—';

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _Header(onClose: onClose),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PwfColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر مصدرين مناسبين للمقارنة البصرية. تظهر هنا فقط الطبقات النشطة والعامة القابلة للمقارنة من نوع Raster مع الخرائط الأساسية.',
                style: TextStyle(
                  color: PwfColors.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SourceDropdown(
                      label: 'الجهة اليسرى',
                      value: safeLeft,
                      options: options,
                      onChanged: (v) {
                        if (v == null) return;
                        ref.read(compareLeftSourceProvider.notifier).state = v;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SourceDropdown(
                      label: 'الجهة اليمنى',
                      value: safeRight,
                      options: options,
                      onChanged: (v) {
                        if (v == null) return;
                        ref.read(compareRightSourceProvider.notifier).state = v;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PwfColors.outline),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _MiniChip(
                            label: leftLabel, color: PwfColors.primaryBlue),
                        const Spacer(),
                        _MiniChip(label: rightLabel, color: PwfColors.royalRed),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 132,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final dividerLeft = (constraints.maxWidth * swipe)
                                .clamp(16.0, constraints.maxWidth - 16.0);
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex:
                                            (swipe * 100).round().clamp(1, 99),
                                        child: Container(
                                          color: PwfColors.primaryBlue
                                              .withValues(alpha: 0.14),
                                          alignment: Alignment.center,
                                          child: Text(
                                            leftLabel,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: PwfColors.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: (100 - (swipe * 100).round())
                                            .clamp(1, 99),
                                        child: Container(
                                          color: PwfColors.royalRed
                                              .withValues(alpha: 0.10),
                                          alignment: Alignment.center,
                                          child: Text(
                                            rightLabel,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: PwfColors.royalRed,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  bottom: 0,
                                  left: dividerLeft,
                                  child:
                                      Container(width: 3, color: Colors.white),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'السحب ${(swipe * 100).round()}%',
                          style: const TextStyle(
                            color: PwfColors.royalRed,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          enabled ? 'وضع المقارنة نشط' : 'وضع المقارنة غير نشط',
                          style: TextStyle(
                            color: enabled
                                ? PwfColors.primaryBlue
                                : PwfColors.onSurface.withValues(alpha: 0.56),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: swipe,
                      onChanged: enabled
                          ? (v) => ref
                              .read(compareSwipePositionProvider.notifier)
                              .state = v.clamp(0.1, 0.9)
                          : null,
                      activeColor: PwfColors.royalRed,
                      inactiveColor: PwfColors.royalRed.withValues(alpha: 0.20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: enabled
                          ? () {
                              ref.read(compareEnabledProvider.notifier).state =
                                  false;
                            }
                          : null,
                      icon: const Icon(Icons.layers_clear),
                      label: const Text('إيقاف المقارنة'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (safeLeft == null ||
                              safeRight == null ||
                              safeLeft == safeRight)
                          ? null
                          : () {
                              ref
                                  .read(compareLeftSourceProvider.notifier)
                                  .state = safeLeft;
                              ref
                                  .read(compareRightSourceProvider.notifier)
                                  .state = safeRight;
                              ref.read(compareEnabledProvider.notifier).state =
                                  true;
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PwfColors.royalRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.compare_arrows),
                      label: const Text('تفعيل المقارنة',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

List<_CompareOption> _compareOptions(List<GisLayerModel> layers) {
  final options = <_CompareOption>[
    const _CompareOption(key: 'base:standard', label: 'خريطة قياسية'),
    const _CompareOption(key: 'base:dark', label: 'خريطة داكنة'),
    const _CompareOption(key: 'base:satellite', label: 'صورة فضائية'),
  ];

  final seen = options.map((e) => e.key).toSet();
  for (final layer in layers) {
    if (!layer.isActive || !layer.isPublic || !layer.compareEnabled) continue;
    if (seen.add(layer.key)) {
      options.add(_CompareOption(key: layer.key, label: layer.nameAr));
    }
  }
  return options;
}

class _CompareOption {
  final String key;
  final String label;
  const _CompareOption({required this.key, required this.label});
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: PwfColors.royalRed,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'المقارنة البصرية',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white)),
        ],
      ),
    );
  }
}

class _SourceDropdown extends StatelessWidget {
  const _SourceDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<_CompareOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: PwfColors.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PwfColors.outline),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: options
                  .map((e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.label, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
