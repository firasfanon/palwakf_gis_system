// lib/features/map/presentation/widgets/map_quick_search_bar.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/colors.dart';
import '../providers/map_provider.dart';
import '../../domain/models/gis_feature_model.dart';

class MapQuickSearchBar extends ConsumerStatefulWidget {
  const MapQuickSearchBar({super.key});

  @override
  ConsumerState<MapQuickSearchBar> createState() => _MapQuickSearchBarState();
}

class _MapQuickSearchBarState extends ConsumerState<MapQuickSearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  Timer? _debounce;
  String _q = '';
  List<_SearchHit> _hits = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v, List<GisFeatureModel> features,
      Map<String, String> layerNames) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 240), () {
      final q = v.trim();
      if (!mounted) return;

      setState(() {
        _q = q;
        _hits = _filterHits(q, features, layerNames);
      });
    });
  }

  List<_SearchHit> _filterHits(String q, List<GisFeatureModel> features,
      Map<String, String> layerNames) {
    final needle = q.trim().toLowerCase();
    if (needle.length < 2) return const [];

    final out = <_SearchHit>[];

    for (final f in features) {
      final title = _titleFor(f);
      if (title.isEmpty) continue;

      final layerName = layerNames[f.layerKey] ?? f.layerKey;

      final code = (f.props['code'] ?? f.props['id'] ?? '').toString();
      final pwf =
          (f.props['pwf_key'] ?? f.props['pwf'] ?? f.props['pwfKey'] ?? '')
              .toString();

      final hay =
          '${title.toLowerCase()} ${layerName.toLowerCase()} ${f.layerKey.toLowerCase()} ${code.toLowerCase()} ${pwf.toLowerCase()}';
      if (!hay.contains(needle)) continue;

      out.add(_SearchHit(
        feature: f,
        title: title,
        subtitle: layerName,
      ));

      if (out.length >= 12) break;
    }

    // Prefer exact code/pwf matches
    out.sort((a, b) {
      final aCode = (a.feature.props['code'] ?? '').toString();
      final bCode = (b.feature.props['code'] ?? '').toString();
      final aPwf = (a.feature.props['pwf_key'] ?? a.feature.props['pwf'] ?? '')
          .toString();
      final bPwf = (b.feature.props['pwf_key'] ?? b.feature.props['pwf'] ?? '')
          .toString();

      int score(String s) =>
          (s.trim().isNotEmpty && s.trim().toLowerCase() == needle) ? 0 : 1;

      final sa = (score(aPwf) + score(aCode));
      final sb = (score(bPwf) + score(bCode));
      if (sa != sb) return sa.compareTo(sb);

      return a.title.length.compareTo(b.title.length);
    });

    return out;
  }

  String _titleFor(GisFeatureModel f) {
    final t = (f.titleAr ?? '').trim();
    if (t.isNotEmpty) return t;

    String pick(List<String> keys) {
      for (final k in keys) {
        final v = f.props[k];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return '';
    }

    final pwf = pick(const ['pwf_key', 'pwf', 'pwfKey']);
    final name = pick(
        const ['name_ar', 'label_ar', 'name', 'label', 'title', 'code', 'key']);

    if (pwf.isNotEmpty && name.isNotEmpty) return '$pwf — $name';
    if (pwf.isNotEmpty) return pwf;
    if (name.isNotEmpty) return name;

    return f.id;
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapNotifierProvider);

    final features = mapState.gisFeatures;
    final layerNames = <String, String>{
      for (final l in mapState.gisLayers) l.key: l.nameAr,
    };

    final showDropdown = _focus.hasFocus && _q.trim().length >= 2;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1220).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white70, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        onChanged: (v) => _onChanged(v, features, layerNames),
                        onSubmitted: (v) {
                          final q = v.trim();
                          final looksLikeKey =
                              RegExp(r'[0-9]').hasMatch(q) && q.length >= 4;
                          if (looksLikeKey) {
                            ref
                                .read(mapNotifierProvider.notifier)
                                .searchWaqf(pwfKey: q);
                          }
                        },
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText:
                              'بحث ضمن نطاق الخريطة الحالي (اكتب حرفين أو أكثر)',
                          hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_controller.text.trim().isNotEmpty)
                      IconButton(
                        tooltip: 'مسح',
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _q = '';
                            _hits = const [];
                          });
                        },
                        icon: const Icon(Icons.close,
                            color: Colors.white70, size: 18),
                      ),
                  ],
                ),
              ),
              if (showDropdown) const SizedBox(height: 8),
              if (showDropdown)
                _SearchDropdown(
                  hits: _hits,
                  isLoading: mapState.gisLoading,
                  onSelect: (hit) {
                    ref
                        .read(mapNotifierProvider.notifier)
                        .selectGisFeature(hit.feature);
                    _focus.unfocus();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchDropdown extends StatelessWidget {
  final List<_SearchHit> hits;
  final bool isLoading;
  final ValueChanged<_SearchHit> onSelect;

  const _SearchDropdown({
    required this.hits,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && hits.isEmpty) {
      return _buildPanel(
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('جارٍ تحميل طبقات/ميزات…',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    if (hits.isEmpty) {
      return _buildPanel(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'لا توجد نتائج ضمن النطاق الحالي. حرّك الخريطة أو فعّل طبقات أكثر.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
          ),
        ),
      );
    }

    return _buildPanel(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: hits.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          itemBuilder: (context, i) {
            final h = hits[i];
            return ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -2),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: PwfColors.primaryGold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: PwfColors.primaryGold.withValues(alpha: 0.28)),
                ),
                child: const Icon(Icons.place, size: 18, color: Colors.white70),
              ),
              title: Text(
                h.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                h.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
              ),
              onTap: () => onSelect(h),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPanel({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SearchHit {
  final GisFeatureModel feature;
  final String title;
  final String subtitle;

  const _SearchHit({
    required this.feature,
    required this.title,
    required this.subtitle,
  });
}
