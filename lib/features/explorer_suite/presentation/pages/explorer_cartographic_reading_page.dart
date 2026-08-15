import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../mustakshif/domain/enums/mustakshif_map_layer_semantics.dart';
import '../../../mustakshif/domain/models/mustakshif_layer_cartography.dart';
import '../../../mustakshif/presentation/widgets/pwf_dynamic_map_legend.dart';
import '../../../mustakshif/presentation/widgets/pwf_map_quality_badge.dart';
import '../../../mustakshif/presentation/widgets/pwf_map_reading_panel.dart';

class ExplorerCartographicReadingPage extends StatelessWidget {
  const ExplorerCartographicReadingPage({
    super.key,
    this.embeddedInAdmin = false,
    this.runtimeContext = const <String, String>{},
  });

  final bool embeddedInAdmin;
  final Map<String, String> runtimeContext;

  static const List<MustakshifLayerCartography> _demoLayers = [
    MustakshifLayerCartography(
      layerKey: 'westbank_gaza',
      layerNameAr: 'الحدود التاريخية / الضفة وغزة',
      layerNameEn: 'West Bank and Gaza boundary',
      purpose: MustakshifMapLayerPurpose.reference,
      geometryType: 'polygon',
      scaleProfile: 'overview',
      sourceName: 'GIS reference boundary',
      accuracyLevel: MustakshifLayerAccuracyLevel.medium,
      legalWeight: MustakshifLayerLegalWeight.reference,
      displayOrder: 10,
      zoomMin: 7.0,
      zoomMax: 22.0,
      isReferenceLayer: true,
      notes: 'طبقة سياقية للفتح والقراءة العامة وليست أداة إثبات حدود نهائية.',
    ),
    MustakshifLayerCartography(
      layerKey: 'governorates_boundary',
      layerNameAr: 'المحافظات',
      layerNameEn: 'Governorates',
      purpose: MustakshifMapLayerPurpose.reference,
      geometryType: 'polygon',
      scaleProfile: 'regional',
      sourceName: 'GIS administrative boundary',
      accuracyLevel: MustakshifLayerAccuracyLevel.medium,
      legalWeight: MustakshifLayerLegalWeight.reference,
      displayOrder: 20,
      zoomMin: 8.0,
      zoomMax: 22.0,
      isReferenceLayer: true,
    ),
    MustakshifLayerCartography(
      layerKey: 'lgus_boundary',
      layerNameAr: 'الهيئات المحلية',
      layerNameEn: 'Local government units',
      purpose: MustakshifMapLayerPurpose.reference,
      geometryType: 'polygon',
      scaleProfile: 'local',
      sourceName: 'GIS local boundary',
      accuracyLevel: MustakshifLayerAccuracyLevel.medium,
      legalWeight: MustakshifLayerLegalWeight.reference,
      displayOrder: 40,
      zoomMin: 11.0,
      zoomMax: 22.0,
      isReferenceLayer: true,
    ),
    MustakshifLayerCartography(
      layerKey: 'parcels_registered_v1',
      layerNameAr: 'قطع التسوية',
      layerNameEn: 'Registered parcels',
      purpose: MustakshifMapLayerPurpose.cadastral,
      geometryType: 'polygon',
      scaleProfile: 'parcel',
      sourceName: 'Settlement/cadastral GIS import',
      accuracyLevel: MustakshifLayerAccuracyLevel.high,
      legalWeight: MustakshifLayerLegalWeight.official,
      displayOrder: 80,
      zoomMin: 14.5,
      zoomMax: 22.0,
      isOperationalLayer: true,
      warningAr: 'تحتاج المطابقة مع السجل والوثيقة الرسمية قبل أي اعتماد قانوني.',
    ),
    MustakshifLayerCartography(
      layerKey: 'mosque_wb',
      layerNameAr: 'نقاط المساجد',
      layerNameEn: 'Mosques points',
      purpose: MustakshifMapLayerPurpose.operational,
      geometryType: 'point',
      scaleProfile: 'asset-point',
      sourceName: 'Operational GIS point layer',
      accuracyLevel: MustakshifLayerAccuracyLevel.medium,
      legalWeight: MustakshifLayerLegalWeight.operational,
      displayOrder: 100,
      zoomMin: 12.0,
      zoomMax: 22.0,
      isOperationalLayer: true,
      notes: 'النقطة تقرأ مع أقرب قطعة/حوض ولا تكفي وحدها لاستخراج مخطط مساحة.',
    ),
  ];

  double get _runtimeZoom {
    final raw = runtimeContext['zoom'];
    return double.tryParse(raw ?? '') ?? 12.50;
  }

  List<MustakshifLayerCartography> get _runtimeLayers {
    final keys = _splitQueryList(runtimeContext['visible_layer_keys'], separator: ',');
    final names = _splitQueryList(runtimeContext['visible_layer_names'], separator: '||');
    if (keys.isEmpty) {
      return _demoLayers
          .where((layer) => layer.isVisibleForZoom(_runtimeZoom))
          .toList(growable: false);
    }

    return keys.asMap().entries.map((entry) {
      final index = entry.key;
      final key = entry.value;
      MustakshifLayerCartography? existing;
      for (final layer in _demoLayers) {
        if (layer.layerKey == key) {
          existing = layer;
          break;
        }
      }
      if (existing != null) return existing;
      final name = index < names.length && names[index].trim().isNotEmpty
          ? names[index].trim()
          : key;
      return MustakshifLayerCartography(
        layerKey: key,
        layerNameAr: name,
        purpose: MustakshifMapLayerPurpose.operational,
        geometryType: 'mixed',
        scaleProfile: 'runtime-visible',
        sourceName: 'Live map runtime context',
        accuracyLevel: MustakshifLayerAccuracyLevel.unknown,
        legalWeight: MustakshifLayerLegalWeight.operational,
        displayOrder: 100 + index,
        zoomMin: 0,
        zoomMax: 22,
        isOperationalLayer: true,
        warningAr: 'طبقة قادمة من سياق الخريطة الحي؛ تُستخدم للقراءة ولا تغيّر حالة الطبقات.',
      );
    }).toList(growable: false);
  }

  static List<String> _splitQueryList(String? raw, {required String separator}) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return const <String>[];
    return value
        .split(separator)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final runtimeZoom = _runtimeZoom;
    final runtimeLayers = _runtimeLayers;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: embeddedInAdmin ? const Color(0xFF0B1220) : PwfColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1120;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 20, wide ? 24 : 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _CartographicHero(),
                    const SizedBox(height: 16),
                    _ActionStrip(
                      onOpenReadingPanel: () => PwfMapReadingPanel.show(
                        context,
                        title: 'كيف أقرأ هذه الخريطة؟',
                        subtitle: 'نموذج قراءة كارتوجرافية داخل Mustakshif Explorer',
                        currentZoom: runtimeZoom,
                        visibleLayers: runtimeLayers,
                      ),
                    ),
                    if (runtimeContext.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _RuntimeContextPanel(
                        embeddedInAdmin: embeddedInAdmin,
                        runtimeContext: runtimeContext,
                        visibleLayerCount: runtimeLayers.length,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _SectionShell(
                      embeddedInAdmin: embeddedInAdmin,
                      title: 'Legend ديناميكي لعينة الطبقات',
                      subtitle:
                          runtimeContext.isEmpty
                              ? 'هذه عينة metadata لشرح القراءة؛ الربط النهائي مع الخريطة يجب أن يمرر الطبقات الظاهرة فعليًا فقط من viewport/zoom، لا كل الطبقات.'
                              : 'هذه قراءة مبنية على سياق الخريطة الحي: الطبقات المفعلة/الظاهرة والزوم وعدد العناصر؛ لا تغيّر حالة الطبقات.',
                      child: PwfDynamicMapLegend(layers: runtimeLayers),
                    ),
                    const SizedBox(height: 16),
                    _ReadingRulesGrid(embeddedInAdmin: embeddedInAdmin),
                    const SizedBox(height: 16),
                    _IntegrationStatusPanel(embeddedInAdmin: embeddedInAdmin),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CartographicHero extends StatelessWidget {
  const _CartographicHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1220), Color(0xFF1E3A8A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PwfColors.primaryGold.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PwfMapQualityBadge(label: 'Cartographic Knowledge'),
              PwfMapQualityBadge(label: 'Map Reading UX'),
              PwfMapQualityBadge(label: 'Layer Metadata'),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'نموذج قراءة الخريطة داخل المستكشف',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 28,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'هذه الصفحة تدمج الحزمة الكارتوجرافية داخل Explorer Suite: مفهوم الخريطة، metadata الطبقات، الوزن القانوني، مستوى الدقة، وتحذيرات المصدر. لا تشغل طبقات ولا توقفها ولا تعدل activeLayers.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontWeight: FontWeight.w600,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({required this.onOpenReadingPanel});

  final VoidCallback onOpenReadingPanel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: onOpenReadingPanel,
          icon: const Icon(Icons.menu_book_outlined),
          label: const Text('افتح لوحة قراءة الخريطة'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go('/admin/mustakshif/review-map?source=cartographic_reading'),
          icon: const Icon(Icons.map_outlined),
          label: const Text('افتح خريطة المراجعة'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go('/admin/explorer-suite/smart?source=cartographic_reading&action=map_reading_prompt'),
          icon: const Icon(Icons.psychology_alt_outlined),
          label: const Text('اربط مع المستكشف الذكي'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go('/admin/mustakshif/review-board?source=cartographic_reading'),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('لوحة المراجعة'),
        ),
      ],
    );
  }
}


class _RuntimeContextPanel extends StatelessWidget {
  const _RuntimeContextPanel({
    required this.embeddedInAdmin,
    required this.runtimeContext,
    required this.visibleLayerCount,
  });

  final bool embeddedInAdmin;
  final Map<String, String> runtimeContext;
  final int visibleLayerCount;

  @override
  Widget build(BuildContext context) {
    final rows = <_RuntimeRow>[
      _RuntimeRow('مصدر الفتح', runtimeContext['source'] ?? 'غير محدد'),
      _RuntimeRow('المكوّن', runtimeContext['from'] ?? 'غير محدد'),
      _RuntimeRow('الزوم', runtimeContext['zoom'] ?? 'غير محدد'),
      _RuntimeRow('الطبقات المفعّلة', runtimeContext['active_count'] ?? '0'),
      _RuntimeRow('الطبقات المقروءة', '$visibleLayerCount'),
      _RuntimeRow('العناصر الظاهرة/المحمّلة', runtimeContext['feature_count'] ?? '0'),
      if ((runtimeContext['temporary_reference_label'] ?? '').isNotEmpty)
        _RuntimeRow('طبقة مرجعية مؤقتة', runtimeContext['temporary_reference_label']!),
      if ((runtimeContext['settlement_scope_lgu_name'] ?? '').isNotEmpty)
        _RuntimeRow('نطاق التسوية', runtimeContext['settlement_scope_lgu_name']!),
    ];

    return _SectionShell(
      embeddedInAdmin: embeddedInAdmin,
      title: 'سياق الفتح التشغيلي من الخريطة',
      subtitle: 'هذا السياق يُقرأ من الخريطة للشرح فقط؛ لا يفعّل طبقات ولا يوقفها ولا يغيّر activeLayers.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: embeddedInAdmin ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PwfColors.primaryGold.withValues(alpha: 0.18)),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final row in rows)
              PwfMapQualityBadge(label: '${row.label}: ${row.value}', compact: true),
          ],
        ),
      ),
    );
  }
}

class _RuntimeRow {
  const _RuntimeRow(this.label, this.value);

  final String label;
  final String value;
}

class _ReadingRulesGrid extends StatelessWidget {
  const _ReadingRulesGrid({required this.embeddedInAdmin});

  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _RuleItem(
        icon: Icons.visibility_outlined,
        title: 'الطبقات الظاهرة فقط',
        body: 'لوحة القراءة تستخدم الطبقات الظاهرة في الزوم/viewport الحالي، ولا تقرأ كل الطبقات دفعة واحدة.',
      ),
      _RuleItem(
        icon: Icons.verified_user_outlined,
        title: 'الوزن القانوني',
        body: 'كل طبقة تحمل وزنًا: رسمي، مرجعي، تشغيلي، تحليلي، أو غير محقق.',
      ),
      _RuleItem(
        icon: Icons.warning_amber_outlined,
        title: 'تحذير الدقة والمصدر',
        body: 'أي طبقة بلا مصدر أو بدقة غير محددة تظهر كطبقة تحتاج مراجعة.',
      ),
      _RuleItem(
        icon: Icons.layers_clear_outlined,
        title: 'لا تغيير activeLayers',
        body: 'القراءة الكارتوجرافية لا تشغل ولا توقف الطبقات؛ هي طبقة تفسير ومعرفة فقط.',
      ),
    ];

    return _SectionShell(
      embeddedInAdmin: embeddedInAdmin,
      title: 'قواعد القراءة الحاكمة',
      subtitle: 'هذه القواعد تحافظ على فصل القراءة والتحليل عن تشغيل الطبقات.',
      child: LayoutBuilder(
        builder: (context, c) {
          final columns = c.maxWidth >= 980 ? 4 : (c.maxWidth >= 620 ? 2 : 1);
          const gap = 12.0;
          final width = (c.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in items)
                SizedBox(
                  width: columns == 1 ? double.infinity : width,
                  child: _RuleCard(item: item, embeddedInAdmin: embeddedInAdmin),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _IntegrationStatusPanel extends StatelessWidget {
  const _IntegrationStatusPanel({required this.embeddedInAdmin});

  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      embeddedInAdmin: embeddedInAdmin,
      title: 'حالة الاندماج',
      subtitle: 'تم دمج الكود والوثائق داخل المستكشف، بينما بقي SQL داخل sandbox للمراجعة فقط.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: embeddedInAdmin ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.10)),
        ),
        child: const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PwfMapQualityBadge(label: 'Flutter widgets: مدمجة'),
            PwfMapQualityBadge(label: 'Explorer route: مدمج'),
            PwfMapQualityBadge(label: 'Smart prompts: موثقة'),
            PwfMapQualityBadge(label: 'SQL: sandbox فقط', warning: true),
          ],
        ),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.embeddedInAdmin,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final bool embeddedInAdmin;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: embeddedInAdmin ? Colors.white : PwfColors.primaryBlue,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: embeddedInAdmin ? Colors.white.withValues(alpha: 0.70) : const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _RuleItem {
  const _RuleItem({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.item, required this.embeddedInAdmin});

  final _RuleItem item;
  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 174,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: embeddedInAdmin ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PwfColors.primaryGold.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: PwfColors.primaryGold),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: TextStyle(
              color: embeddedInAdmin ? Colors.white : const Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              item.body,
              style: TextStyle(
                color: embeddedInAdmin ? Colors.white.withValues(alpha: 0.70) : const Color(0xFF475569),
                height: 1.45,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
