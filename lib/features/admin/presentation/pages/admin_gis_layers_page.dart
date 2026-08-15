import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/colors.dart';
import '../../../map/data/repositories/gis_repository.dart';
import '../../../map/domain/models/gis_layer_model.dart';
import '../providers/admin_gis_layers_provider.dart';
import '../widgets/admin_scaffold.dart';

class AdminGisLayersPage extends ConsumerWidget {
  const AdminGisLayersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLayers = ref.watch(adminGisLayersProvider);
    final repo = ref.watch(gisRepositoryProvider);

    return AdminScaffold(
      title: 'إدارة طبقات GIS',
      activeRoute: '/admin/gis-layers',
      child: asyncLayers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBox(error: e.toString()),
        data: (layers) {
          if (layers.isEmpty) {
            return const _InfoBox(
              title: 'لا توجد طبقات متاحة',
              message:
                  'إذا كنت تتوقع طبقات غير public/active ولا تظهر هنا، فالسبب غالبًا سياسات RLS على gis.gis_layers.\n\nتأكد أيضًا من: Supabase → Settings → API → Exposed schemas تحتوي gis.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'تحكم في ظهور الطبقات في الصفحة العامة (Public) وتشغيلها (Active).',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(adminGisLayersProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('تحديث'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: layers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final l = layers[i];
                    return _LayerTile(
                      layer: l,
                      onToggleActive: (v) async {
                        try {
                          await repo.updateLayerFlags(
                              layerId: l.id,
                              unitId: l.unitId,
                              key: l.key,
                              isActive: v);
                          ref.invalidate(adminGisLayersProvider);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'تعذر تحديث الطبقة: ${e.toString()}')),
                            );
                          }
                        }
                      },
                      onTogglePublic: (v) async {
                        try {
                          await repo.updateLayerFlags(
                              layerId: l.id,
                              unitId: l.unitId,
                              key: l.key,
                              isPublic: v);
                          ref.invalidate(adminGisLayersProvider);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'تعذر تحديث الطبقة: ${e.toString()}')),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LayerTile extends StatelessWidget {
  final GisLayerModel layer;
  final ValueChanged<bool> onToggleActive;
  final ValueChanged<bool> onTogglePublic;

  const _LayerTile({
    required this.layer,
    required this.onToggleActive,
    required this.onTogglePublic,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor =
        layer.isActive ? const Color(0xFF16A34A) : PwfColors.royalRed;
    final badgeText = layer.isActive ? 'مُفعل' : 'غير مُفعل';

    final pubColor =
        layer.isPublic ? const Color(0xFF2563EB) : const Color(0xFF6B7280);
    final pubText = layer.isPublic ? 'عام' : 'داخلي';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(layer.nameAr,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(layer.key,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              _Badge(color: badgeColor, text: badgeText),
              const SizedBox(width: 8),
              _Badge(color: pubColor, text: pubText),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SwitchRow(
                  label: 'تشغيل الطبقة',
                  value: layer.isActive,
                  onChanged: onToggleActive,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SwitchRow(
                  label: 'إظهار للعامة',
                  value: layer.isPublic,
                  onChanged: onTogglePublic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: PwfColors.primaryBlue,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final String text;
  const _Badge({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String message;
  const _InfoBox({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(color: Colors.white70, height: 1.5)),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;
  const _ErrorBox({required this.error});

  @override
  Widget build(BuildContext context) {
    final msg = error.toLowerCase().contains('schema')
        ? 'Supabase لا يسمح بالوصول إلى schema "gis" عبر API.\n\nاذهب إلى Supabase → Settings → API → Exposed schemas وأضف: gis'
        : error;

    return _InfoBox(title: 'خطأ', message: msg);
  }
}
