import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;

import '../../../../../../core/constants/colors.dart';
import '../../../providers/map_provider.dart';
import '../../../providers/map_ui_providers.dart';

class CoordinatesToolPanel extends ConsumerStatefulWidget {
  const CoordinatesToolPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<CoordinatesToolPanel> createState() =>
      _CoordinatesToolPanelState();
}

enum _CoordinateInputMode { palestineGrid, decimal }

class _CoordinatesToolPanelState extends ConsumerState<CoordinatesToolPanel> {
  static const String _palestineGridDef =
      '+proj=cass +lat_0=31.7340969444444 +lon_0=35.2120805555556 '
      '+x_0=170251.555 +y_0=126867.909 +a=6378300.789 +b=6356566.435 '
      '+towgs84=-275.7224,94.7824,340.8944,-8.001,-4.42,-11.821,1 '
      '+units=m +no_defs +type=crs';

  final _x = TextEditingController();
  final _y = TextEditingController();

  _CoordinateInputMode _mode = _CoordinateInputMode.palestineGrid;
  _CoordinateResult? _result;

  @override
  void dispose() {
    _x.dispose();
    _y.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gotoMarker = ref.watch(gotoMarkerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _Header(title: 'الذهاب إلى الإحداثيات', onClose: widget.onClose),
        const SizedBox(height: 12),
        _PrimaryPill(
          label: 'نظام فلسطين Grid (EPSG:28191)',
          icon: Icons.grid_on,
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle('إدخال الإحداثيات'),
              const SizedBox(height: 10),
              _ModeChips(
                value: _mode,
                onChanged: (next) {
                  setState(() {
                    _mode = next;
                    _result = null;
                    _x.clear();
                    _y.clear();
                  });
                },
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _x,
                label: _mode == _CoordinateInputMode.palestineGrid
                    ? 'Easting (شرق)'
                    : 'Longitude',
                hint: _mode == _CoordinateInputMode.palestineGrid
                    ? 'مثال: 174762'
                    : 'مثال: 35.2345',
              ),
              const SizedBox(height: 10),
              _Field(
                controller: _y,
                label: _mode == _CoordinateInputMode.palestineGrid
                    ? 'Northing (شمال)'
                    : 'Latitude',
                hint: _mode == _CoordinateInputMode.palestineGrid
                    ? 'مثال: 180836'
                    : 'مثال: 31.7767',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SmallActionChip(
                    icon: Icons.center_focus_strong,
                    label: 'استخدام مركز الخريطة',
                    onTap: _fillFromMapCenter,
                  ),
                  _SmallActionChip(
                    icon: Icons.touch_app,
                    label: 'استخدام آخر نقرة',
                    onTap: _fillFromLastTap,
                  ),
                  _SmallActionChip(
                    icon: Icons.copy_all,
                    label: 'نسخ المدخلات',
                    onTap: _copyInputs,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoBox(
                title: _mode == _CoordinateInputMode.palestineGrid
                    ? 'الوضع الافتراضي: Palestine Grid'
                    : 'الوضع الثانوي: Decimal Lat/Lng',
                lines: _mode == _CoordinateInputMode.palestineGrid
                    ? const [
                        'أدخل Easting / Northing بنظام فلسطين 1923.',
                        'الإسقاط: Cassini-Soldner.',
                        'الوحدة: متر.',
                      ]
                    : const [
                        'هذا الوضع مخصص للإحداثيات العشرية القياسية.',
                        'يبقى الوضع الافتراضي داخل الأداة هو Palestine Grid.',
                      ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _Btn(
                      label: 'انتقال',
                      icon: Icons.send,
                      primary: true,
                      onTap: _go,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Btn(
                      label: 'مسح',
                      icon: Icons.delete_outline,
                      primary: false,
                      onTap: _clear,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _Btn(
                label: gotoMarker == null
                    ? 'لا توجد علامة لإزالتها'
                    : 'إزالة العلامة',
                icon: Icons.delete_forever,
                danger: true,
                onTap: gotoMarker == null ? null : _removeMarker,
              ),
            ],
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 12),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle('الموقع الناتج'),
                const SizedBox(height: 10),
                _InfoRow(
                    label: 'Palestine Grid',
                    value:
                        'E ${_fmt0(_result!.easting)} • N ${_fmt0(_result!.northing)}'),
                const SizedBox(height: 8),
                _InfoRow(
                    label: 'WGS84',
                    value:
                        'Lat ${_result!.latLng.latitude.toStringAsFixed(6)} • Lng ${_result!.latLng.longitude.toStringAsFixed(6)}'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Btn(
                        label: 'تمركز',
                        icon: Icons.center_focus_strong,
                        primary: false,
                        onTap: _recenterOnResult,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Btn(
                        label: 'نسخ WGS84',
                        icon: Icons.copy,
                        primary: false,
                        onTap: _copyWgs84,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  proj4.Projection _wgs84Projection() => proj4.Projection.get('EPSG:4326')!;

  proj4.Projection _palestineGridProjection() {
    return proj4.Projection.get('EPSG:28191') ??
        proj4.Projection.add('EPSG:28191', _palestineGridDef);
  }

  double? _parseCoord(String input) {
    final normalized = input.trim().replaceAll(',', '').replaceAll('٫', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  LatLng? _palestineGridToLatLng(double easting, double northing) {
    try {
      final source = _palestineGridProjection();
      final target = _wgs84Projection();
      final point =
          source.transform(target, proj4.Point(x: easting, y: northing));
      return LatLng(point.y, point.x);
    } catch (_) {
      return null;
    }
  }

  ({double easting, double northing})? _latLngToPalestineGrid(LatLng latLng) {
    try {
      final source = _wgs84Projection();
      final target = _palestineGridProjection();
      final point = source.transform(
          target, proj4.Point(x: latLng.longitude, y: latLng.latitude));
      return (easting: point.x, northing: point.y);
    } catch (_) {
      return null;
    }
  }

  void _fillFromMapCenter() {
    final center = ref.read(mapControllerProvider).camera.center;
    final grid = _latLngToPalestineGrid(center);
    if (grid == null) return;

    setState(() {
      if (_mode == _CoordinateInputMode.palestineGrid) {
        _x.text = _fmt0(grid.easting);
        _y.text = _fmt0(grid.northing);
      } else {
        _x.text = center.longitude.toStringAsFixed(6);
        _y.text = center.latitude.toStringAsFixed(6);
      }
    });
  }

  void _fillFromLastTap() {
    final point = ref.read(lastTapLatLngProvider);
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد نقرة سابقة على الخريطة')),
      );
      return;
    }
    final grid = _latLngToPalestineGrid(point);
    if (grid == null) return;

    setState(() {
      if (_mode == _CoordinateInputMode.palestineGrid) {
        _x.text = _fmt0(grid.easting);
        _y.text = _fmt0(grid.northing);
      } else {
        _x.text = point.longitude.toStringAsFixed(6);
        _y.text = point.latitude.toStringAsFixed(6);
      }
    });
  }

  void _go() {
    final x = _parseCoord(_x.text);
    final y = _parseCoord(_y.text);
    if (x == null || y == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل قيم إحداثيات صحيحة أولًا')),
      );
      return;
    }

    LatLng? target;
    double easting;
    double northing;

    if (_mode == _CoordinateInputMode.palestineGrid) {
      target = _palestineGridToLatLng(x, y);
      easting = x;
      northing = y;
      if (target == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تعذر تحويل Palestine Grid إلى موقع على الخريطة')),
        );
        return;
      }
    } else {
      if (y < -90 || y > 90 || x < -180 || x > 180) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('قيم Latitude/Longitude خارج النطاق الصحيح')),
        );
        return;
      }
      target = LatLng(y, x);
      final grid = _latLngToPalestineGrid(target);
      if (grid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('تعذر تحويل الإحداثيات العشرية إلى Palestine Grid')),
        );
        return;
      }
      easting = grid.easting;
      northing = grid.northing;
    }

    final mapController = ref.read(mapControllerProvider);

    ref.read(drawEditingProvider.notifier).state = false;
    ref.read(measureEditingProvider.notifier).state = false;
    ref.read(directionsPickTargetProvider.notifier).state = null;
    ref.read(gotoMarkerProvider.notifier).state = target;
    ref.read(lastTapLatLngProvider.notifier).state = target;

    setState(() {
      _result = _CoordinateResult(
        easting: easting,
        northing: northing,
        latLng: target!,
      );
    });

    final nextZoom =
        mapController.camera.zoom < 15 ? 15.0 : mapController.camera.zoom;
    mapController.move(target, nextZoom);
  }

  void _clear() {
    setState(() {
      _x.clear();
      _y.clear();
      _result = null;
    });
  }

  void _removeMarker() {
    ref.read(gotoMarkerProvider.notifier).state = null;
    setState(() => _result = null);
  }

  void _recenterOnResult() {
    final result = _result;
    if (result == null) return;
    final mapController = ref.read(mapControllerProvider);
    mapController.move(result.latLng,
        mapController.camera.zoom < 15 ? 15.0 : mapController.camera.zoom);
  }

  void _copyInputs() {
    final x = _x.text.trim();
    final y = _y.text.trim();
    if (x.isEmpty || y.isEmpty) return;
    Clipboard.setData(ClipboardData(text: 'X=$x, Y=$y'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ قيم الإدخال')),
    );
  }

  void _copyWgs84() {
    final result = _result;
    if (result == null) return;
    Clipboard.setData(
      ClipboardData(
        text:
            '${result.latLng.latitude.toStringAsFixed(6)}, ${result.latLng.longitude.toStringAsFixed(6)}',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ إحداثيات WGS84')),
    );
  }

  String _fmt0(double value) => value.toStringAsFixed(0);
}

class _CoordinateResult {
  const _CoordinateResult({
    required this.easting,
    required this.northing,
    required this.latLng,
  });

  final double easting;
  final double northing;
  final LatLng latLng;
}

/* -------------------------- Small UI primitives -------------------------- */

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose});
  final String title;
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
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900))),
          IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white)),
        ],
      ),
    );
  }
}

class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PwfColors.royalRed,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900))),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PwfColors.outline),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.gps_fixed, color: PwfColors.royalRed, size: 18),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: PwfColors.royalRed)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(
      {required this.controller, required this.label, required this.hint});
  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: true),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PwfColors.outline)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PwfColors.outline)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: PwfColors.royalRed.withValues(alpha: 0.8))),
          ),
        ),
      ],
    );
  }
}

class _ModeChips extends StatelessWidget {
  const _ModeChips({required this.value, required this.onChanged});

  final _CoordinateInputMode value;
  final ValueChanged<_CoordinateInputMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip({
      required String label,
      required _CoordinateInputMode mode,
      required IconData icon,
    }) {
      final selected = value == mode;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onChanged(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? PwfColors.royalRed.withValues(alpha: 0.10)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? PwfColors.royalRed : PwfColors.outline,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16,
                    color: selected ? PwfColors.royalRed : PwfColors.onSurface),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color:
                          selected ? PwfColors.royalRed : PwfColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(
            label: 'Palestine Grid',
            mode: _CoordinateInputMode.palestineGrid,
            icon: Icons.grid_on),
        const SizedBox(width: 10),
        chip(
            label: 'Lat / Lng',
            mode: _CoordinateInputMode.decimal,
            icon: Icons.public),
      ],
    );
  }
}

class _SmallActionChip extends StatelessWidget {
  const _SmallActionChip(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: PwfColors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: PwfColors.primaryBlue),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: PwfColors.primaryBlue)),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child:
                        Icon(Icons.circle, size: 6, color: PwfColors.royalRed),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(line, style: const TextStyle(height: 1.35))),
                ],
              ),
            ),
        ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: PwfColors.primaryBlue),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w700))),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.primary = false,
      this.danger = false});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bg = danger
        ? PwfColors.royalRed
        : (primary ? PwfColors.royalRed : const Color(0xFFE2E8F0));
    final fg = danger || primary ? Colors.white : PwfColors.onSurface;

    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          disabledForegroundColor: Colors.black38,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}
