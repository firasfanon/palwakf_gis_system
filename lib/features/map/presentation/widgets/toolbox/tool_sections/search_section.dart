// lib/features/map/presentation/widgets/toolbox/tool_sections/search_section.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kimi/core/constants/colors.dart';
import 'package:kimi/features/map/data/repositories/gis_repository.dart';
import 'package:kimi/features/map/domain/models/gis_feature_model.dart';
import 'package:kimi/features/map/domain/models/lookup_item.dart';
import 'package:kimi/features/map/presentation/providers/lookup_providers.dart';
import 'package:kimi/features/map/presentation/providers/map_provider.dart';
import 'package:kimi/features/map/presentation/providers/toolbox_providers.dart';

enum _SearchSource {
  naturalBasins,
  estimatedBasins,
  settlement,
}

extension on _SearchSource {
  String get labelAr {
    switch (this) {
      case _SearchSource.naturalBasins:
        return 'الأحواض الطبيعية';
      case _SearchSource.estimatedBasins:
        return 'أحواض التخمين';
      case _SearchSource.settlement:
        return 'التسوية';
    }
  }

  IconData get icon {
    switch (this) {
      case _SearchSource.naturalBasins:
        return Icons.grid_view_rounded;
      case _SearchSource.estimatedBasins:
        return Icons.alt_route_rounded;
      case _SearchSource.settlement:
        return Icons.fact_check_outlined;
    }
  }

  bool get isImplemented => true;

  bool get isOperational => true;
}

final _naturalGovernoratesProvider = FutureProvider<List<LookupItem>>((ref) async {
  return ref.watch(gisRepositoryProvider).fetchNaturalGovernorates();
});

final _naturalCommunitiesProvider =
    FutureProvider.family<List<LookupItem>, String?>((ref, governorateNo) async {
  if (governorateNo == null || governorateNo.trim().isEmpty) {
    return const <LookupItem>[];
  }
  return ref
      .watch(gisRepositoryProvider)
      .fetchNaturalCommunitiesByGovernorate(governorateNo: governorateNo);
});

final _locationsByLguProvider =
    FutureProvider.family<List<LookupItem>, String?>((ref, lguCode) async {
  if (lguCode == null || lguCode.trim().isEmpty) {
    return const <LookupItem>[];
  }
  return ref
      .watch(gisRepositoryProvider)
      .fetchLocationLookupsByLgu(lguCode: lguCode);
});

class SearchSection extends ConsumerStatefulWidget {
  const SearchSection({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends ConsumerState<SearchSection> {
  _SearchSource? _selectedSource;

  final _pwfController = TextEditingController();
  final _basinController = TextEditingController();
  final _parcelController = TextEditingController();
  LookupItem? _selectedGovernorate;
  LookupItem? _selectedLgu;
  LookupItem? _selectedCommunity;

  LookupItem? _selectedNaturalGovernorate;
  LookupItem? _selectedNaturalCommunity;
  List<LookupItem> _naturalBlockNumbers = const [];
  LookupItem? _selectedNaturalBlockNumber;
  List<LookupItem> _naturalSites = const [];
  LookupItem? _selectedNaturalSite;

  bool _naturalLoading = false;
  String? _naturalError;
  List<GisFeatureModel> _naturalResults = const [];

  LookupItem? _selectedOperationalGovernorate;
  LookupItem? _selectedOperationalLgu;
  LookupItem? _selectedOperationalLocation;
  final _operationalBlockController = TextEditingController();
  final _operationalQuarterController = TextEditingController();
  final _operationalParcelController = TextEditingController();
  bool _operationalLoading = false;
  String? _lastNavigationMessage;
  List<String> _activeLayersAtSearchSourceStart = const <String>[];

  String _activeLayerFingerprint(Iterable<String> keys) {
    return keys
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .join('|');
  }

  LatLng? _extractCoordinates(dynamic geometry) {
    if (geometry is! Map<String, dynamic>) return null;
    final type = geometry['type']?.toString();
    final coords = geometry['coordinates'];
    if (type == 'Point' && coords is List && coords.length >= 2) {
      return LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble());
    }
    final bounds = _boundsFromGeometry(geometry);
    if (bounds == null) return null;
    return LatLng(
      (bounds.south + bounds.north) / 2,
      (bounds.west + bounds.east) / 2,
    );
  }

  LatLngBounds? _boundsFromGeometry(Map<String, dynamic>? geometry) {
    if (geometry == null) return null;
    final points = <LatLng>[];

    void collect(dynamic value) {
      if (value is List && value.length >= 2 && value[0] is num && value[1] is num) {
        points.add(LatLng((value[1] as num).toDouble(), (value[0] as num).toDouble()));
        return;
      }
      if (value is List) {
        for (final item in value) {
          collect(item);
        }
      }
    }

    collect(geometry['coordinates']);
    if (points.isEmpty) return null;
    var south = points.first.latitude;
    var north = points.first.latitude;
    var west = points.first.longitude;
    var east = points.first.longitude;
    for (final point in points.skip(1)) {
      if (point.latitude < south) south = point.latitude;
      if (point.latitude > north) north = point.latitude;
      if (point.longitude < west) west = point.longitude;
      if (point.longitude > east) east = point.longitude;
    }
    return LatLngBounds(LatLng(south, west), LatLng(north, east));
  }

  void _navigateToFeature(GisFeatureModel? feature, {double minZoom = 0}) {
    if (feature == null) return;
    final controller = ref.read(mapControllerProvider);
    final bounds = _boundsFromGeometry(feature.geom);
    if (bounds != null) {
      controller.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(34),
        ),
      );
      _recordNavigation('تم تحريك الخريطة إلى: ${feature.displayTitle}');
      return;
    }
    final point = _extractCoordinates(feature.centroid ?? feature.geom);
    if (point == null) return;
    final currentZoom = ref.read(mapNotifierProvider).zoom;
    controller.move(point, currentZoom < minZoom ? minZoom : currentZoom);
    _recordNavigation('تم تركيز الخريطة على: ${feature.displayTitle}');
  }

  void _recordNavigation(String message) {
    if (!mounted) return;
    setState(() => _lastNavigationMessage = message);
  }

  void _focusSearchResult(GisFeatureModel feature, {double minZoom = 12.0}) {
    ref.read(mapNotifierProvider.notifier).selectGisFeature(feature);
    _navigateToFeature(feature, minZoom: minZoom);
  }

  Future<void> _navigateToGovernorate(LookupItem value) async {
    final repo = ref.read(gisRepositoryProvider);
    final features = await repo.fetchModernExplorerGovernorateBoundaryFeatures(
      governorateNo: value.code,
    );
    if (!mounted || features.isEmpty) return;
    _navigateToFeature(features.first, minZoom: 9.0);
  }

  Future<void> _navigateToLgu(
    LookupItem value, {
    String? governorateNo,
  }) async {
    final repo = ref.read(gisRepositoryProvider);
    final features = await repo.fetchModernExplorerLguBoundaryFeatures(
      governorateNo: governorateNo ?? _selectedOperationalGovernorate?.code,
      lguCode: value.code,
    );
    if (!mounted || features.isEmpty) return;
    _navigateToFeature(features.first, minZoom: 12.0);
  }

  Future<void> _setOperationalScopeFromLgu(LookupItem? value) async {
    // This is a loading/filtering scope only. It does not toggle layers, does
    // not mutate activeLayers, and does not draw a new layer from the dropdown.
    await ref.read(mapNotifierProvider.notifier).setSettlementScope(
          lguCode: value?.code,
          lguName: value?.bestLabel,
        );
  }

  Future<void> _navigateToLocation(LookupItem value) async {
    final repo = ref.read(gisRepositoryProvider);
    final feature = await repo.fetchLocationBoundaryFeature(
      locationCode: value.code,
      locationName: value.bestLabel,
      lguCode: _selectedOperationalLgu?.code,
    );
    if (!mounted) return;
    _navigateToFeature(feature, minZoom: 13.0);
  }

  Future<void> _navigateToCommunity(LookupItem value) async {
    final repo = ref.read(gisRepositoryProvider);
    final feature = await repo.fetchCommunityBoundaryFeature(
      communityCode: value.code,
      communityName: value.bestLabel,
      layerKey: 'communities_boundary',
    );
    if (!mounted) return;
    _navigateToFeature(feature, minZoom: 10.0);
  }

  Future<void> _navigateToNaturalBlock({
    String? blockNo,
    String? siteName,
  }) async {
    final repo = ref.read(gisRepositoryProvider);
    final feature = await repo.fetchNaturalBlockFeature(
      governorateNo: _selectedNaturalGovernorate?.code,
      communityNo: _selectedNaturalCommunity?.code,
      blockNo: blockNo,
      siteName: siteName,
    );
    if (!mounted) return;
    _navigateToFeature(feature, minZoom: 11.5);
  }

  String? _operationalError;
  List<GisFeatureModel> _operationalResults = const [];

  @override
  void dispose() {
    _pwfController.dispose();
    _basinController.dispose();
    _parcelController.dispose();
    _operationalBlockController.dispose();
    _operationalQuarterController.dispose();
    _operationalParcelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapNotifierProvider);
    final currentActiveLayerFingerprint =
        _activeLayerFingerprint(mapState.activeLayers);
    final searchStartActiveLayerFingerprint =
        _activeLayerFingerprint(_activeLayersAtSearchSourceStart);
    final activeLayersStableSinceSourceStart = _selectedSource == null ||
        currentActiveLayerFingerprint == searchStartActiveLayerFingerprint;
    final governoratesAsync = ref.watch(governoratesLookupProvider);
    final lgusAsync = ref.watch(lgusLookupProvider(_selectedGovernorate?.code));
    final communitiesAsync =
        ref.watch(communitiesLookupProvider(_selectedLgu?.code));
    final operationalLgusAsync =
        ref.watch(lgusLookupProvider(_selectedOperationalGovernorate?.code));
    final operationalLocationsAsync =
        ref.watch(_locationsByLguProvider(_selectedOperationalLgu?.code));
    final naturalGovernoratesAsync = ref.watch(_naturalGovernoratesProvider);
    final naturalCommunitiesAsync = ref.watch(
      _naturalCommunitiesProvider(_selectedNaturalGovernorate?.code),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        if (!widget.embedded) ...[
          _Header(
            onBack: () => ref.read(activeToolSectionProvider.notifier).state = null,
          ),
          const SizedBox(height: 12),
        ],
        _SourceSelector(
          selectedSource: _selectedSource,
          onChanged: (value) => unawaited(_onSourceChanged(value)),
        ),
        const SizedBox(height: 12),
        _SourceHint(source: _selectedSource),
        if (_selectedSource != null) ...[
          const SizedBox(height: 12),
          _SearchRuntimeStatus(
            sourceLabel: _selectedSource!.labelAr,
            temporaryLayerLabel: mapState.temporarySearchReferenceLayerLabel,
            settlementScope: mapState.settlementScopeLguName,
            activeLayersCount: mapState.activeLayers.length,
            activeLayersStableSinceSourceStart:
                activeLayersStableSinceSourceStart,
            lastNavigationMessage: _lastNavigationMessage,
            onEndSession: () => unawaited(_endSearchSession()),
          ),
        ],
        const SizedBox(height: 12),
        if (_selectedSource == null)
          const _InfoNotice(
            icon: Icons.info_outline,
            text: 'اختر مصدر البيانات أولًا لعرض نموذج البحث المناسب.',
          )
        else if (_selectedSource == _SearchSource.naturalBasins)
          _buildNaturalCard(
            context,
            naturalGovernoratesAsync,
            naturalCommunitiesAsync,
          )
        else
          _buildOperationalCard(
            context,
            _selectedSource!,
            governoratesAsync,
            operationalLgusAsync,
            operationalLocationsAsync,
          ),
      ],
    );
  }

  Future<void> _onSourceChanged(_SearchSource? value) async {
    _clearNaturalForm(silent: true, clearSearchReferenceLayer: false);
    _clearOperationalForm(silent: true, clearSearchReferenceLayer: false);
    if (!mounted) return;
    final activeLayerSnapshot = List<String>.unmodifiable(
      ref.read(mapNotifierProvider).activeLayers.map((key) => key.trim()),
    );
    setState(() {
      _selectedSource = value;
      _activeLayersAtSearchSourceStart = activeLayerSnapshot;
    });

    final notifier = ref.read(mapNotifierProvider.notifier);
    switch (value) {
      case _SearchSource.naturalBasins:
        await notifier.setTemporarySearchReferenceLayer(
          layerKey: 'natural_blocks_full',
          labelAr: 'الأحواض الطبيعية — مرجع بحث مؤقت',
        );
        break;
      case _SearchSource.estimatedBasins:
        await notifier.setTemporarySearchReferenceLayer(
          layerKey: 'guessing_blocks',
          labelAr: 'أحواض التخمين — مرجع بحث مؤقت',
        );
        break;
      case _SearchSource.settlement:
      case null:
        await notifier.clearTemporarySearchReferenceLayer();
        break;
    }
  }


  Future<void> _ensureTemporaryReferenceForCurrentSource() async {
    final notifier = ref.read(mapNotifierProvider.notifier);
    switch (_selectedSource) {
      case _SearchSource.naturalBasins:
        await notifier.setTemporarySearchReferenceLayer(
          layerKey: 'natural_blocks_full',
          labelAr: 'الأحواض الطبيعية — مرجع بحث مؤقت',
        );
        break;
      case _SearchSource.estimatedBasins:
        await notifier.setTemporarySearchReferenceLayer(
          layerKey: 'guessing_blocks',
          labelAr: 'أحواض التخمين — مرجع بحث مؤقت',
        );
        break;
      case _SearchSource.settlement:
      case null:
        break;
    }
  }

  Widget _buildWaqfCard(
    BuildContext context,
    MapState mapState,
    AsyncValue<List<LookupItem>> governoratesAsync,
    AsyncValue<List<LookupItem>> lgusAsync,
    AsyncValue<List<LookupItem>> communitiesAsync,
  ) {
    return Column(
      children: [
        _Panel(
          title: 'البحث العقاري الوقفي',
          child: Column(
            children: [
              _DropdownLookup(
                label: 'المحافظة',
                value: _selectedGovernorate,
                itemsAsync: governoratesAsync,
                onChanged: (value) async {
                  setState(() {
                    _selectedGovernorate = value;
                    _selectedLgu = null;
                    _selectedCommunity = null;
                  });
                  if (value != null) await _navigateToGovernorate(value);
                },
              ),
              const SizedBox(height: 10),
              _DropdownLookup(
                label: 'البلدية / الهيئة',
                value: _selectedLgu,
                itemsAsync: lgusAsync,
                onChanged: (value) async {
                  setState(() {
                    _selectedLgu = value;
                    _selectedCommunity = null;
                  });
                  if (value != null) {
                    await _navigateToLgu(
                      value,
                      governorateNo: _selectedGovernorate?.code,
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              _DropdownLookup(
                label: 'القرية / المدينة / التجمع',
                value: _selectedCommunity,
                itemsAsync: communitiesAsync,
                onChanged: (value) async {
                  setState(() => _selectedCommunity = value);
                  if (value != null) await _navigateToCommunity(value);
                },
              ),
              const SizedBox(height: 10),
              _Input(label: 'PWF / مفتاح الوقف', controller: _pwfController),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Input(
                      label: 'الحوض',
                      controller: _basinController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Input(
                      label: 'القطعة',
                      controller: _parcelController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PrimaryBtn(
                      label: 'بحث',
                      icon: Icons.search,
                      onTap: _searchWaqf,
                      color: PwfColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _SecondaryBtn(
                label: 'مسح',
                icon: Icons.clear,
                onTap: _clearWaqfForm,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (mapState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        if (mapState.error != null && !mapState.isLoading)
          _InfoNotice(
            icon: Icons.error_outline,
            text: mapState.error!,
            danger: true,
          ),
        if (!mapState.isLoading && mapState.waqfResults.isNotEmpty)
          _Panel(
            title: 'النتائج (${mapState.waqfResults.length})',
            child: Column(
              children: mapState.waqfResults.take(12).map((waqf) {
                return _ResultCard(
                  title: waqf.name ?? waqf.pwfKey,
                  subtitle: [
                    if ((waqf.governorate ?? '').isNotEmpty) waqf.governorate,
                    if ((waqf.municipality ?? '').isNotEmpty)
                      waqf.municipality,
                    if ((waqf.community ?? '').isNotEmpty) waqf.community,
                    if ((waqf.basin ?? '').isNotEmpty) 'حوض ${waqf.basin}',
                    if ((waqf.parcel ?? '').isNotEmpty) 'قطعة ${waqf.parcel}',
                  ].whereType<String>().join(' • '),
                  tag: waqf.pwfKey,
                  onTap: () => ref.read(mapNotifierProvider.notifier).selectWaqf(waqf),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildNaturalCard(
    BuildContext context,
    AsyncValue<List<LookupItem>> governoratesAsync,
    AsyncValue<List<LookupItem>> communitiesAsync,
  ) {
    return Column(
      children: [
        _Panel(
          title: 'الأحواض الطبيعية',
          child: Column(
            children: [
              _DropdownLookup(
                label: 'المحافظة',
                value: _selectedNaturalGovernorate,
                itemsAsync: governoratesAsync,
                onChanged: (value) async {
                  setState(() {
                    _selectedNaturalGovernorate = value;
                    _selectedNaturalCommunity = null;
                    _naturalBlockNumbers = const [];
                    _selectedNaturalBlockNumber = null;
                    _naturalSites = const [];
                    _selectedNaturalSite = null;
                    _naturalResults = const [];
                    _naturalError = null;
                  });

                  if (value == null) {
                    ref.read(mapNotifierProvider.notifier).clearSelection();
                    return;
                  }

                  await _ensureTemporaryReferenceForCurrentSource();
                  await _navigateToGovernorate(value);
                },
              ),
              const SizedBox(height: 10),
              _DropdownLookup(
                label: 'القرية / المدينة / التجمع',
                value: _selectedNaturalCommunity,
                itemsAsync: communitiesAsync,
                onChanged: (value) async {
                  setState(() {
                    _selectedNaturalCommunity = value;
                    _naturalBlockNumbers = const [];
                    _selectedNaturalBlockNumber = null;
                    _naturalSites = const [];
                    _selectedNaturalSite = null;
                    _naturalResults = const [];
                    _naturalError = null;
                  });

                  if (value == null) {
                    return;
                  }

                  await _ensureTemporaryReferenceForCurrentSource();
                  await _navigateToCommunity(value);
                  await _loadNaturalBlockNumbers();
                },
              ),
              const SizedBox(height: 10),
              _DropdownLookupItems(
                label: 'رقم الحوض',
                value: _selectedNaturalBlockNumber,
                items: _naturalBlockNumbers,
                itemLabelBuilder: (item) {
                  final blockNo = item.code.trim();
                  final blockName = item.labelAr.trim();
                  if (blockName.isEmpty) return 'الحوض $blockNo';
                  return 'الحوض $blockNo — $blockName';
                },
                onChanged: (value) async {
                  setState(() {
                    _selectedNaturalBlockNumber = value;
                    _naturalSites = const [];
                    _selectedNaturalSite = null;
                    _naturalResults = const [];
                    _naturalError = null;
                  });
                  if (value == null) return;
                  await _ensureTemporaryReferenceForCurrentSource();
                  await _navigateToNaturalBlock(blockNo: value.code);
                  await _loadNaturalSites();
                },
              ),
              const SizedBox(height: 10),
              _DropdownLookupItems(
                label: 'اسم الحوض',
                value: _selectedNaturalSite,
                items: _naturalSites,
                onChanged: (value) async {
                  setState(() {
                    _selectedNaturalSite = value;
                    _naturalResults = const [];
                    _naturalError = null;
                  });
                  if (value == null) return;
                  await _ensureTemporaryReferenceForCurrentSource();
                  await _navigateToNaturalBlock(
                    blockNo: _selectedNaturalBlockNumber?.code,
                    siteName: value.bestLabel,
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PrimaryBtn(
                      label: 'بحث',
                      icon: Icons.search,
                      onTap: _searchNatural,
                      color: PwfColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _SecondaryBtn(
                label: 'مسح',
                icon: Icons.clear,
                onTap: _clearNaturalForm,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_naturalLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        if (_naturalError != null && !_naturalLoading)
          _InfoNotice(
            icon: Icons.error_outline,
            text: _naturalError!,
            danger: true,
          ),
        if (!_naturalLoading && _naturalResults.isNotEmpty)
          _Panel(
            title: 'النتائج (${_naturalResults.length})',
            child: Column(
              children: _naturalResults.take(12).map((feature) {
                final title = feature.props['blockname_']?.toString() ??
                    feature.props['sitename_a']?.toString() ??
                    feature.titleAr ??
                    feature.titleEn ??
                    feature.layerKey;
                final number = feature.props['block_no']?.toString() ??
                    feature.props['basin_no']?.toString() ??
                    feature.props['basin_number']?.toString() ??
                    feature.props['no']?.toString() ??
                    '';
                final locality = feature.props['communityn']?.toString() ??
                    feature.props['community_name_ar']?.toString() ??
                    feature.props['locality_name_ar']?.toString() ??
                    feature.props['locality_name']?.toString() ??
                    feature.props['lgu_name_ar']?.toString() ??
                    '';
                return _ResultCard(
                  title: title,
                  subtitle: [
                    if (locality.isNotEmpty) locality,
                    if (number.isNotEmpty) 'رقم الحوض $number',
                  ].join(' • '),
                  tag: feature.layerKey,
                  onTap: () => _focusSearchResult(feature, minZoom: 11.5),
                );
              }).toList(),
            ),
          ),
        if (!_naturalLoading &&
            _naturalResults.isEmpty &&
            _naturalError == null)
          const _InfoNotice(
            icon: Icons.search_off,
            text: 'اختيار مصدر الأحواض الطبيعية يفتح طبقة مرجعية مؤقتة ضمن مستوى التجمعات. اختيار المحافظة/التجمع/رقم الحوض/اسم الحوض/الموقع يعمل زوم فقط.',
          ),
      ],
    );
  }


  Widget _buildOperationalCard(
    BuildContext context,
    _SearchSource source,
    AsyncValue<List<LookupItem>> governoratesAsync,
    AsyncValue<List<LookupItem>> lgusAsync,
    AsyncValue<List<LookupItem>> locationsAsync,
  ) {
    final isSettlement = source == _SearchSource.settlement;
    final title = isSettlement ? 'قطع أراضي التسوية' : 'أحواض التخمين';
    final hint = isSettlement
        ? 'اختر المحافظة أو الهيئة أو اسم الموقع للانتقال فقط، ثم استخدم حوض التسوية/الحي/رقم القطعة للزوم أو تضييق النتائج. طبقة المواقع تظهر بالزوم فوق الهيئة المحلية، والتسوية والقطع تظهر حسب الزوم ولا تُفتح كطبقة بحث مؤقتة.'
        : 'اختيار مصدر أحواض التخمين يفتح طبقة مرجعية مؤقتة ضمن مستوى الهيئات المحلية. اختيار المحافظة/الهيئة/اسم الموقع/اسم الحوض/رقم القطعة بعد ذلك ينفذ زوم فقط ولا يعيد الرسم.';

    return Column(
      children: [
        _Panel(
          title: title,
          child: Column(
            children: [
              _InfoNotice(
                icon: Icons.rule_folder_outlined,
                text: hint,
              ),
              const SizedBox(height: 10),
              _DropdownLookup(
                label: 'المحافظة',
                value: _selectedOperationalGovernorate,
                itemsAsync: governoratesAsync,
                onChanged: (value) async {
                  setState(() {
                    _selectedOperationalGovernorate = value;
                    _selectedOperationalLgu = null;
                    _selectedOperationalLocation = null;
                    _operationalResults = const [];
                    _operationalError = null;
                  });
                  await _setOperationalScopeFromLgu(null);
                  if (value == null) {
                    ref.read(mapNotifierProvider.notifier).clearModernExplorerBoundaryOverlays();
                    return;
                  }
                  await _ensureTemporaryReferenceForCurrentSource();
                  await _navigateToGovernorate(value);
                },
              ),
              const SizedBox(height: 10),
              _DropdownLookup(
                label: 'الهيئة المحلية / التجمع',
                value: _selectedOperationalLgu,
                itemsAsync: lgusAsync,
                onChanged: (value) async {
                  setState(() {
                    _selectedOperationalLgu = value;
                    _selectedOperationalLocation = null;
                    _operationalResults = const [];
                    _operationalError = null;
                  });
                  if (value == null) {
                    await _setOperationalScopeFromLgu(null);
                    final governorate = _selectedOperationalGovernorate;
                    if (governorate != null) await _navigateToGovernorate(governorate);
                    return;
                  }
                  await _setOperationalScopeFromLgu(value);
                  await _ensureTemporaryReferenceForCurrentSource();
                  await _navigateToLgu(value);
                },
              ),
              if (_selectedOperationalLgu != null) ...[
                const SizedBox(height: 10),
                _DropdownLookup(
                  label: 'اسم الموقع',
                  value: _selectedOperationalLocation,
                  itemsAsync: locationsAsync,
                  onChanged: (value) async {
                    setState(() {
                      _selectedOperationalLocation = value;
                      _operationalResults = const [];
                      _operationalError = null;
                    });
                    if (value != null) await _navigateToLocation(value);
                  },
                ),
              ],
              const SizedBox(height: 10),
              _Input(
                label: isSettlement ? 'رقم الحوض' : 'رقم حوض التخمين',
                controller: _operationalBlockController,
              ),
              if (isSettlement) ...[
                const SizedBox(height: 10),
                _Input(
                  label: 'اسم الحي',
                  controller: _operationalQuarterController,
                ),
                const SizedBox(height: 10),
                _Input(
                  label: 'رقم القطعة',
                  controller: _operationalParcelController,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PrimaryBtn(
                      label: 'بحث',
                      icon: Icons.search,
                      onTap: () => _searchOperational(source),
                      color: PwfColors.royalRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _SecondaryBtn(
                label: 'مسح',
                icon: Icons.clear,
                onTap: _clearOperationalForm,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_operationalLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        if (_operationalError != null && !_operationalLoading)
          _InfoNotice(
            icon: Icons.error_outline,
            text: _operationalError!,
            danger: true,
          ),
        if (!_operationalLoading && _operationalResults.isNotEmpty)
          _Panel(
            title: 'النتائج (${_operationalResults.length})',
            child: Column(
              children: _operationalResults.take(20).map((feature) {
                final p = feature.props;
                final titleText = p['display_title']?.toString() ??
                    feature.titleAr ??
                    feature.titleEn ??
                    title;
                final subtitle = isSettlement
                    ? [
                        if ((p['lgu_name_ar'] ?? '').toString().trim().isNotEmpty)
                          p['lgu_name_ar'].toString(),
                        if ((p['block_display_no'] ?? p['block_no'] ?? '').toString().trim().isNotEmpty)
                          'حوض ${p['block_display_no'] ?? p['block_no']}',
                        if ((p['parcel_display_no'] ?? '').toString().trim().isNotEmpty)
                          'قطعة ${p['parcel_display_no']}',
                        if ((p['registrati'] ?? '').toString().trim().isNotEmpty)
                          p['registrati'].toString(),
                      ].join(' • ')
                    : [
                        if ((p['lgu_name_ar'] ?? '').toString().trim().isNotEmpty)
                          p['lgu_name_ar'].toString(),
                        if ((p['block_no'] ?? '').toString().trim().isNotEmpty)
                          'حوض ${p['block_no']}',
                        if ((p['notes'] ?? '').toString().trim().isNotEmpty)
                          p['notes'].toString(),
                      ].join(' • ');
                return _ResultCard(
                  title: titleText,
                  subtitle: subtitle,
                  tag: feature.layerKey,
                  onTap: () => _focusSearchResult(feature, minZoom: isSettlement ? 15.0 : 14.0),
                );
              }).toList(),
            ),
          ),
        if (!_operationalLoading &&
            _operationalResults.isEmpty &&
            _operationalError == null)
          _InfoNotice(
            icon: Icons.map_outlined,
            text: isSettlement
                ? 'اختيار المحافظة/الهيئة/اسم الموقع/حوض التسوية/الحي/رقم القطعة ينقل الكاميرا فقط. المواقع والتسوية وأرقام القطع تظهر بالزوم الطبيعي.'
                : 'طبقة أحواض التخمين المرجعية تُفتح مؤقتًا من مصدر البيانات، وباقي الاختيارات بما فيها اسم الموقع تعمل زوم فقط.',
          ),
      ],
    );
  }



  Future<void> _loadNaturalBlockNumbers() async {
    final governorateNo = _selectedNaturalGovernorate?.code;
    final communityNo = _selectedNaturalCommunity?.code;
    if ((governorateNo ?? '').trim().isEmpty ||
        (communityNo ?? '').trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _naturalBlockNumbers = const [];
        _selectedNaturalBlockNumber = null;
        _naturalSites = const [];
        _selectedNaturalSite = null;
      });
      return;
    }

    try {
      final repo = ref.read(gisRepositoryProvider);
      final items = await repo.fetchNaturalBlockNumbers(
        governorateNo: governorateNo!,
        communityNo: communityNo!,
      );
      if (!mounted) return;
      setState(() {
        _naturalBlockNumbers = items;
        if (_selectedNaturalBlockNumber != null &&
            !_naturalBlockNumbers.any((item) => item.code == _selectedNaturalBlockNumber!.code)) {
          _selectedNaturalBlockNumber = null;
        }
        _naturalSites = const [];
        _selectedNaturalSite = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _naturalBlockNumbers = const [];
        _selectedNaturalBlockNumber = null;
        _naturalSites = const [];
        _selectedNaturalSite = null;
      });
    }
  }

  Future<void> _loadNaturalSites() async {
    final governorateNo = _selectedNaturalGovernorate?.code;
    final communityNo = _selectedNaturalCommunity?.code;
    final blockNo = _selectedNaturalBlockNumber?.code;
    if ((governorateNo ?? '').trim().isEmpty ||
        (communityNo ?? '').trim().isEmpty ||
        (blockNo ?? '').trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _naturalSites = const [];
        _selectedNaturalSite = null;
      });
      return;
    }

    try {
      final repo = ref.read(gisRepositoryProvider);
      final items = await repo.fetchNaturalSiteNames(
        governorateNo: governorateNo!,
        communityNo: communityNo!,
        blockNo: blockNo!,
      );
      if (!mounted) return;
      setState(() {
        _naturalSites = items;
        if (_selectedNaturalSite != null &&
            !_naturalSites.any((item) => item.code == _selectedNaturalSite!.code)) {
          _selectedNaturalSite = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _naturalSites = const [];
        _selectedNaturalSite = null;
      });
    }
  }

  Future<void> _searchNatural() async {
    final governorateNo = _selectedNaturalGovernorate?.code;
    final communityNo = _selectedNaturalCommunity?.code;
    final blockNo = _selectedNaturalBlockNumber?.code;
    final siteName = _selectedNaturalSite?.bestLabel;

    if ((governorateNo ?? '').trim().isEmpty) {
      setState(() {
        _naturalError = 'اختر المحافظة أولًا.';
        _naturalResults = const [];
      });
      return;
    }
    if ((communityNo ?? '').trim().isEmpty) {
      setState(() {
        _naturalError = 'اختر التجمع أولًا.';
        _naturalResults = const [];
      });
      return;
    }
    if ((blockNo ?? '').trim().isEmpty) {
      setState(() {
        _naturalError = 'اختر رقم الحوض أولًا.';
        _naturalResults = const [];
      });
      return;
    }
    if (_naturalSites.isNotEmpty && (siteName ?? '').trim().isEmpty) {
      setState(() {
        _naturalError = 'اختر اسم الموقع من الحوض أولًا.';
        _naturalResults = const [];
      });
      return;
    }

    setState(() {
      _naturalLoading = true;
      _naturalError = null;
      _naturalResults = const [];
    });
    try {
      final repo = ref.read(gisRepositoryProvider);
      final results = await repo.searchNaturalBlocks(
        governorateNo: governorateNo,
        communityNo: communityNo,
        blockNo: (blockNo ?? '').trim().isEmpty ? null : blockNo,
        siteName: (siteName ?? '').trim().isEmpty ? null : siteName,
      );
      if (!mounted) return;
      setState(() {
        _naturalLoading = false;
        _naturalResults = results;
        if (results.isEmpty) {
          _naturalError = 'لا توجد نتائج مطابقة للتسلسل المختار.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _naturalLoading = false;
        _naturalError = error.toString();
      });
    }
  }

  Future<void> _searchOperational(_SearchSource source) async {
    final lguCode = _selectedOperationalLgu?.code.trim() ?? '';
    final lguNo = int.tryParse(lguCode);
    if (lguNo == null) {
      setState(() {
        _operationalError = 'اختر الهيئة المحلية أولًا.';
        _operationalResults = const [];
      });
      return;
    }

    setState(() {
      _operationalLoading = true;
      _operationalError = null;
      _operationalResults = const [];
    });

    await _setOperationalScopeFromLgu(_selectedOperationalLgu);

    try {
      final repo = ref.read(gisRepositoryProvider);
      final results = source == _SearchSource.settlement
          ? await repo.searchParcels(
              lguNo: lguNo,
              blockNo: _operationalBlockController.text,
              quarterName: _operationalQuarterController.text,
              parcelNo: _operationalParcelController.text,
            )
          : await repo.searchGuessingBlocks(
              lguNo: lguNo,
              blockNo: _operationalBlockController.text,
            );

      if (!mounted) return;
      setState(() {
        _operationalLoading = false;
        _operationalResults = results;
        if (results.isEmpty) {
          _operationalError = 'لا توجد نتائج مطابقة للمدخلات الحالية.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _operationalLoading = false;
        _operationalError = error.toString();
      });
    }
  }


  Future<void> _searchWaqf() async {
    await ref.read(mapNotifierProvider.notifier).searchWaqf(
          pwfKey: _pwfController.text.trim().isEmpty
              ? null
              : _pwfController.text.trim(),
          governorate: _selectedGovernorate?.labelAr,
          municipality: _selectedLgu?.labelAr,
          community: _selectedCommunity?.labelAr,
          basin: _basinController.text.trim().isEmpty
              ? null
              : _basinController.text.trim(),
          parcel: _parcelController.text.trim().isEmpty
              ? null
              : _parcelController.text.trim(),
        );
  }

  void _clearWaqfForm() {
    setState(() {
      _selectedGovernorate = null;
      _selectedLgu = null;
      _selectedCommunity = null;
    });
    _pwfController.clear();
    _basinController.clear();
    _parcelController.clear();
  }

  Future<void> _endSearchSession() async {
    _clearNaturalForm(silent: true, clearSearchReferenceLayer: false);
    _clearOperationalForm(silent: true, clearSearchReferenceLayer: false);
    await ref.read(mapNotifierProvider.notifier).clearTemporarySearchReferenceLayer();
    ref.read(mapNotifierProvider.notifier).clearModernExplorerBoundaryOverlays();
    if (!mounted) return;
    setState(() {
      _selectedSource = null;
      _activeLayersAtSearchSourceStart = const <String>[];
      _lastNavigationMessage = 'تم إنهاء سياق البحث وإغلاق الطبقة المرجعية المؤقتة.';
    });
  }

  void _clearOperationalForm({
    bool silent = false,
    bool clearSearchReferenceLayer = true,
  }) {
    ref.read(mapNotifierProvider.notifier).clearModernExplorerBoundaryOverlays();
    unawaited(_setOperationalScopeFromLgu(null));
    if (clearSearchReferenceLayer) {
      unawaited(ref
          .read(mapNotifierProvider.notifier)
          .clearTemporarySearchReferenceLayer());
    }
    if (!mounted) return;
    setState(() {
      _selectedOperationalGovernorate = null;
      _selectedOperationalLgu = null;
      _selectedOperationalLocation = null;
      _operationalResults = const [];
      _operationalError = null;
      _operationalLoading = false;
      if (!silent) _lastNavigationMessage = null;
    });
    _operationalBlockController.clear();
    _operationalQuarterController.clear();
    _operationalParcelController.clear();
  }


  void _clearNaturalForm({
    bool silent = false,
    bool clearSearchReferenceLayer = true,
  }) {
    ref.read(mapNotifierProvider.notifier).clearSelection();
    if (clearSearchReferenceLayer) {
      unawaited(ref
          .read(mapNotifierProvider.notifier)
          .clearTemporarySearchReferenceLayer());
    }
    if (!mounted) return;
    setState(() {
      _selectedNaturalGovernorate = null;
      _selectedNaturalCommunity = null;
      _naturalBlockNumbers = const [];
      _selectedNaturalBlockNumber = null;
      _naturalSites = const [];
      _selectedNaturalSite = null;
      _naturalResults = const [];
      _naturalError = null;
      _naturalLoading = false;
      if (!silent) _lastNavigationMessage = null;
    });
  }
}


class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, color: PwfColors.onSurface),
        ),
        const Spacer(),
        const Text(
          'البحث',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ],
    );
  }
}

class _SourceSelector extends StatelessWidget {
  const _SourceSelector({
    required this.selectedSource,
    required this.onChanged,
  });

  final _SearchSource? selectedSource;
  final ValueChanged<_SearchSource?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مصدر البيانات',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: PwfColors.royalRed,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<_SearchSource>(
            value: selectedSource,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down_rounded),
            hint: const Text('الرجاء الاختيار'),
            decoration: _decoration('المصدر'),
            items: _SearchSource.values.map((source) {
              return DropdownMenuItem<_SearchSource>(
                value: source,
                child: Row(
                  children: [
                    Icon(source.icon, size: 18, color: PwfColors.primaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        source.labelAr,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SourceHint extends StatelessWidget {
  const _SourceHint({required this.source});

  final _SearchSource? source;

  @override
  Widget build(BuildContext context) {
    if (source == null) {
      return const SizedBox.shrink();
    }

    final implemented = source!.isImplemented;
    return _InfoNotice(
      icon: implemented ? Icons.verified_outlined : Icons.pending_outlined,
      text: implemented
          ? 'تم اختيار: ${source!.labelAr}. مصدر البيانات يحدد سياق البحث فقط؛ الاختيارات التفصيلية تنفذ زوم/تركيز، والطبقات المرجعية المؤقتة تُغلق عند تغيير المصدر أو مسح البحث.'
          : 'تم تجهيز اختيار المصدر: ${source!.labelAr}. الربط التشغيلي لهذا المصدر سيُستكمل لاحقًا دون كسر الواجهة الحالية.',
      danger: false,
    );
  }
}


class _SearchRuntimeStatus extends StatelessWidget {
  const _SearchRuntimeStatus({
    required this.sourceLabel,
    required this.temporaryLayerLabel,
    required this.settlementScope,
    required this.activeLayersCount,
    required this.activeLayersStableSinceSourceStart,
    required this.lastNavigationMessage,
    required this.onEndSession,
  });

  final String sourceLabel;
  final String? temporaryLayerLabel;
  final String? settlementScope;
  final int activeLayersCount;
  final bool activeLayersStableSinceSourceStart;
  final String? lastNavigationMessage;
  final VoidCallback onEndSession;

  @override
  Widget build(BuildContext context) {
    final temporaryLayer = (temporaryLayerLabel ?? '').trim();
    final scope = (settlementScope ?? '').trim();
    final last = (lastNavigationMessage ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RuntimeChip(
                icon: Icons.source_outlined,
                label: 'المصدر: $sourceLabel',
              ),
              _RuntimeChip(
                icon: Icons.layers_clear_outlined,
                label: temporaryLayer.isEmpty
                    ? 'لا توجد طبقة مرجعية مؤقتة'
                    : temporaryLayer,
              ),
              _RuntimeChip(
                icon: Icons.navigation_outlined,
                label: 'القوائم: زوم/انتقال فقط',
              ),
              _RuntimeChip(
                icon: activeLayersStableSinceSourceStart
                    ? Icons.verified_outlined
                    : Icons.info_outline,
                label: activeLayersStableSinceSourceStart
                    ? 'activeLayers ثابتة من البحث ($activeLayersCount)'
                    : 'activeLayers تغيرت خارجيًا ($activeLayersCount)',
              ),
              if (scope.isNotEmpty)
                _RuntimeChip(
                  icon: Icons.filter_alt_outlined,
                  label: 'نطاق تشغيلي: $scope',
                ),
            ],
          ),
          if (last.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              last,
              style: TextStyle(
                color: PwfColors.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: OutlinedButton.icon(
              onPressed: onEndSession,
              icon: const Icon(Icons.close_rounded, size: 17),
              label: const Text('إنهاء سياق البحث'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PwfColors.royalRed,
                side: BorderSide(
                  color: PwfColors.royalRed.withValues(alpha: 0.35),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuntimeChip extends StatelessWidget {
  const _RuntimeChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: PwfColors.primaryBlue),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: PwfColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingSourceCard extends StatelessWidget {
  const _PendingSourceCard({required this.source});

  final _SearchSource source;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: source.labelAr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _InfoNotice(
            icon: Icons.build_circle_outlined,
            text: 'تم تجهيز مصدر البيانات داخل صندوق الأدوات، لكن ربط البحث التشغيلي لهذا المصدر لم يُفعّل بعد في هذه النسخة.',
          ),
          SizedBox(height: 10),
          _InfoNotice(
            icon: Icons.rule_folder_outlined,
            text: 'المصدر العامل حاليًا هو: الأحواض الطبيعية، وسيُربط مصدرَا أحواض التخمين والتسوية لاحقًا.',
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: PwfColors.royalRed,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: PwfColors.outline.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: _decoration(label),
    );
  }
}

class _DropdownLookup extends StatelessWidget {
  const _DropdownLookup({
    required this.label,
    required this.value,
    required this.itemsAsync,
    required this.onChanged,
  });

  final String label;
  final LookupItem? value;
  final AsyncValue<List<LookupItem>> itemsAsync;
  final ValueChanged<LookupItem?> onChanged;

  @override
  Widget build(BuildContext context) {
    return itemsAsync.when(
      data: (items) {
        LookupItem? resolvedValue;
        if (value != null) {
          for (final item in items) {
            if (item.code == value!.code) {
              resolvedValue = item;
              break;
            }
          }
        }

        return DropdownButtonFormField<LookupItem>(
          value: resolvedValue,
          isExpanded: true,
          hint: Text(items.isEmpty ? 'لا توجد بيانات متاحة' : 'الرجاء الاختيار'),
          items: items
              .map(
                (item) => DropdownMenuItem<LookupItem>(
                  value: item,
                  child: Text(
                    item.bestLabel,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: _decoration(label),
        );
      },
      loading: () => TextField(
        enabled: false,
        decoration: _decoration(label),
      ),
      error: (_, __) => TextField(
        enabled: false,
        decoration: _decoration(label).copyWith(errorText: 'تعذر التحميل'),
      ),
    );
  }
}


class _DropdownLookupItems extends StatelessWidget {
  const _DropdownLookupItems({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabelBuilder,
  });

  final String label;
  final LookupItem? value;
  final List<LookupItem> items;
  final ValueChanged<LookupItem?> onChanged;
  final String Function(LookupItem item)? itemLabelBuilder;

  @override
  Widget build(BuildContext context) {
    LookupItem? resolvedValue;
    if (value != null) {
      for (final item in items) {
        if (item.code == value!.code) {
          resolvedValue = item;
          break;
        }
      }
    }

    return DropdownButtonFormField<LookupItem>(
      value: resolvedValue,
      isExpanded: true,
      decoration: _decoration(label),
      hint: Text(items.isEmpty ? 'لا توجد بيانات متاحة' : 'الرجاء الاختيار'),
      items: items.map((item) {
        final text = (itemLabelBuilder?.call(item) ?? item.bestLabel).trim();
        return DropdownMenuItem<LookupItem>(
          value: item,
          child: Text(
            text.isEmpty ? item.code : text,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: items.isEmpty ? null : onChanged,
    );
  }
}

class _DropdownText extends StatelessWidget {
  const _DropdownText({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      isExpanded: true,
      hint: Text(items.isEmpty ? 'لا توجد بيانات متاحة' : 'الرجاء الاختيار'),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: _decoration(label),
    );
  }
}

InputDecoration _decoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    hintStyle: TextStyle(
      color: PwfColors.onSurface.withValues(alpha: 0.55),
      fontWeight: FontWeight.w600,
    ),
    labelStyle: TextStyle(
      color: PwfColors.onSurface.withValues(alpha: 0.72),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: PwfColors.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: PwfColors.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: PwfColors.primaryBlue,
        width: 1.4,
      ),
    ),
  );
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  const _SecondaryBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: PwfColors.primaryBlue,
          side: BorderSide(
            color: PwfColors.primaryBlue.withValues(alpha: 0.55),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PwfColors.outline),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: PwfColors.royalRed.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.place_outlined,
            color: PwfColors.royalRed,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                style: TextStyle(
                  color: PwfColors.onSurface.withValues(alpha: 0.70),
                ),
              ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: PwfColors.primaryGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: PwfColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoNotice extends StatelessWidget {
  const _InfoNotice({
    required this.icon,
    required this.text,
    this.danger = false,
  });

  final IconData icon;
  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? PwfColors.error : PwfColors.primaryBlue;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
