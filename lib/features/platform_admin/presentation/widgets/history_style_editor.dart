import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/colors.dart';

class HistoryStyleColorOption {
  final String labelAr;
  final String hex;

  const HistoryStyleColorOption({
    required this.labelAr,
    required this.hex,
  });
}

class HistoryStylePreset {
  final String key;
  final String labelAr;
  final String descriptionAr;
  final Map<String, dynamic> styleJson;

  const HistoryStylePreset({
    required this.key,
    required this.labelAr,
    required this.descriptionAr,
    required this.styleJson,
  });
}

class HistoryDashPreset {
  final String labelAr;
  final String value;

  const HistoryDashPreset(this.labelAr, this.value);
}

const List<HistoryStyleColorOption> kHistoryStyleColors = [
  HistoryStyleColorOption(labelAr: 'أزرق ملكي', hex: '#1E3A8A'),
  HistoryStyleColorOption(labelAr: 'أزرق داكن', hex: '#0F172A'),
  HistoryStyleColorOption(labelAr: 'أزرق فاتح', hex: '#3B82F6'),
  HistoryStyleColorOption(labelAr: 'سماوي', hex: '#60A5FA'),
  HistoryStyleColorOption(labelAr: 'ذهبي', hex: '#D4AF37'),
  HistoryStyleColorOption(labelAr: 'ذهبي داكن', hex: '#8B6B11'),
  HistoryStyleColorOption(labelAr: 'أحمر ملكي', hex: '#B22222'),
  HistoryStyleColorOption(labelAr: 'أحمر فاتح', hex: '#EF4444'),
  HistoryStyleColorOption(labelAr: 'أخضر', hex: '#16A34A'),
  HistoryStyleColorOption(labelAr: 'بنفسجي', hex: '#7C3AED'),
  HistoryStyleColorOption(labelAr: 'أبيض', hex: '#FFFFFF'),
  HistoryStyleColorOption(labelAr: 'رمادي فاتح', hex: '#CBD5E1'),
  HistoryStyleColorOption(labelAr: 'رمادي داكن', hex: '#475569'),
  HistoryStyleColorOption(labelAr: 'أسود', hex: '#111827'),
];

const List<HistoryStylePreset> kHistoryStylePresets = [
  HistoryStylePreset(
    key: 'ottoman_base',
    labelAr: 'عثماني أساسي',
    descriptionAr: 'مناسب للطبقة التاريخية الأصلية مع إبراز واضح للحدود والتسميات.',
    styleJson: {
      'fillColor': '#D4AF37',
      'fillOpacity': 0.22,
      'strokeColor': '#8B6B11',
      'strokeWidth': 2.0,
      'strokeOpacity': 0.95,
      'showLabel': true,
      'labelColor': '#F8FAFC',
      'labelSize': 13,
      'labelWeight': '700',
      'labelHaloColor': '#0B1220',
      'labelHaloWidth': 2,
      'states': {
        'hover': {'strokeColor': '#F59E0B', 'strokeWidth': 2.8},
        'selected': {'strokeColor': '#B22222', 'strokeWidth': 3.2},
      },
    },
  ),
  HistoryStylePreset(
    key: 'modern_reference',
    labelAr: 'مرجع حديث',
    descriptionAr: 'للإشارات الحديثة التفسيرية مع حدود متقطعة وحضور أخف من الطبقة التاريخية.',
    styleJson: {
      'fillColor': '#60A5FA',
      'fillOpacity': 0.06,
      'strokeColor': '#3B82F6',
      'strokeWidth': 1.6,
      'strokeOpacity': 0.85,
      'dashArray': '8,6',
      'showLabel': true,
      'labelColor': '#DBEAFE',
      'labelSize': 11,
      'labelWeight': '600',
      'labelHaloColor': '#0B1220',
      'labelHaloWidth': 1,
      'states': {
        'hover': {'strokeColor': '#93C5FD', 'strokeWidth': 2.0},
        'selected': {'strokeColor': '#1D4ED8', 'strokeWidth': 2.6},
      },
    },
  ),
  HistoryStylePreset(
    key: 'waqf_asset',
    labelAr: 'أصل وقفي',
    descriptionAr: 'للتمييز الوقفي المباشر مع أحمر ملكي واضح وحدود أعلى حضورًا.',
    styleJson: {
      'fillColor': '#B22222',
      'fillOpacity': 0.14,
      'strokeColor': '#7F1D1D',
      'strokeWidth': 2.4,
      'strokeOpacity': 0.96,
      'showLabel': true,
      'labelColor': '#FEE2E2',
      'labelSize': 12,
      'labelWeight': '700',
      'labelHaloColor': '#111827',
      'labelHaloWidth': 2,
      'states': {
        'hover': {'strokeColor': '#EF4444', 'strokeWidth': 2.9},
        'selected': {'strokeColor': '#FCA5A5', 'strokeWidth': 3.4},
      },
    },
  ),
  HistoryStylePreset(
    key: 'print_friendly',
    labelAr: 'ملائم للطباعة',
    descriptionAr: 'ألوان حيادية وتباين مرتفع للطباعة والتصدير الورقي.',
    styleJson: {
      'fillColor': '#CBD5E1',
      'fillOpacity': 0.10,
      'strokeColor': '#0F172A',
      'strokeWidth': 2.2,
      'strokeOpacity': 1.0,
      'showLabel': true,
      'labelColor': '#0F172A',
      'labelSize': 12,
      'labelWeight': '700',
      'labelHaloColor': '#FFFFFF',
      'labelHaloWidth': 3,
    },
  ),
];

const List<HistoryDashPreset> kHistoryDashPresets = [
  HistoryDashPreset('متصل', ''),
  HistoryDashPreset('متقطع خفيف', '6,4'),
  HistoryDashPreset('متقطع واسع', '10,6'),
  HistoryDashPreset('منقط', '2,4'),
  HistoryDashPreset('طويل/قصير', '12,4,3,4'),
];

const List<String> kHistoryLabelWeights = ['400', '500', '600', '700', '800'];

class HistoryStyleEditor extends StatefulWidget {
  final Map<String, dynamic> initialValue;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final String title;

  const HistoryStyleEditor({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.title = 'محرر النمط',
  });

  @override
  State<HistoryStyleEditor> createState() => _HistoryStyleEditorState();
}

class _HistoryStyleEditorState extends State<HistoryStyleEditor> {
  late Map<String, dynamic> _style;
  late Map<String, dynamic> _baselineStyle;
  late TextEditingController _jsonController;
  String? _selectedPresetKey;

  @override
  void initState() {
    super.initState();
    _style = _clone(widget.initialValue);
    _baselineStyle = _clone(widget.initialValue);
    _jsonController = TextEditingController(text: _pretty(_style));
  }

  @override
  void didUpdateWidget(covariant HistoryStyleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = _pretty(oldWidget.initialValue);
    final after = _pretty(widget.initialValue);
    if (before != after) {
      _style = _clone(widget.initialValue);
      _baselineStyle = _clone(widget.initialValue);
      _jsonController.text = _pretty(_style);
    }
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _clone(Map<String, dynamic> input) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(input)) as Map);

  String _pretty(Map<String, dynamic> value) =>
      const JsonEncoder.withIndent('  ').convert(value);

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return Map<String, dynamic>.from(value.cast<String, dynamic>());
    return <String, dynamic>{};
  }

  void _emit() {
    _jsonController.text = _pretty(_style);
    widget.onChanged(_clone(_style));
  }

  void _setValue(String key, dynamic value) {
    setState(() {
      if (value == null || (value is String && value.trim().isEmpty)) {
        _style.remove(key);
      } else {
        _style[key] = value;
      }
      _emit();
    });
  }

  void _setStateValue(String stateKey, String childKey, dynamic value) {
    final states = _asMap(_style['states']);
    final current = _asMap(states[stateKey]);
    if (value == null || (value is String && value.trim().isEmpty)) {
      current.remove(childKey);
    } else {
      current[childKey] = value;
    }
    if (current.isEmpty) {
      states.remove(stateKey);
    } else {
      states[stateKey] = current;
    }
    _setValue('states', states);
  }

  double _readDouble(String key, double fallback) {
    final value = _style[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _readStateDouble(String stateKey, String childKey, double fallback) {
    final value = _asMap(_asMap(_style['states'])[stateKey])[childKey];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _readString(String key, [String fallback = '']) =>
      _style[key]?.toString() ?? fallback;

  String _readStateString(String stateKey, String childKey, [String fallback = '']) =>
      _asMap(_asMap(_style['states'])[stateKey])[childKey]?.toString() ?? fallback;

  bool _readBool(String key, bool fallback) {
    final value = _style[key];
    if (value is bool) return value;
    final raw = value?.toString().toLowerCase();
    if (raw == 'true') return true;
    if (raw == 'false') return false;
    return fallback;
  }

  bool get _isModified => _pretty(_style) != _pretty(_baselineStyle);

  Future<void> _copyJson() async {
    await Clipboard.setData(ClipboardData(text: _pretty(_style)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ JSON إلى الحافظة')),
    );
  }

  void _applyPreset([HistoryStylePreset? directPreset]) {
    HistoryStylePreset? preset = directPreset;
    if (preset == null && _selectedPresetKey != null) {
      for (final item in kHistoryStylePresets) {
        if (item.key == _selectedPresetKey) {
          preset = item;
          break;
        }
      }
    }
    if (preset == null) return;
    setState(() {
      _style = _clone(preset!.styleJson);
      _selectedPresetKey = preset.key;
      _emit();
    });
  }

  void _applyJson() {
    try {
      final decoded = jsonDecode(_jsonController.text.trim());
      if (decoded is! Map) {
        throw const FormatException('JSON object required');
      }
      setState(() {
        _style = Map<String, dynamic>.from(decoded.cast<String, dynamic>());
        _emit();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تطبيق JSON بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر قراءة JSON: $e')),
      );
    }
  }

  void _resetStyle() {
    setState(() {
      _style = <String, dynamic>{};
      _emit();
    });
  }

  void _restoreBaseline() {
    setState(() {
      _style = _clone(_baselineStyle);
      _emit();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = _colorFromHex(_readString('fillColor', '#1E3A8A'))
        .withValues(alpha: _readDouble('fillOpacity', 0.18));
    final strokeColor = _colorFromHex(_readString('strokeColor', '#D4AF37'));
    final labelColor = _colorFromHex(_readString('labelColor', '#F8FAFC'));
    final baselineFill = _colorFromHex(_baselineStyle['fillColor']?.toString())
        .withValues(alpha: _toDouble(_baselineStyle['fillOpacity']) ?? 0.18);
    final baselineStroke = _colorFromHex(_baselineStyle['strokeColor']?.toString());
    final baselineLabel = _colorFromHex(_baselineStyle['labelColor']?.toString());

    return DefaultTabController(
      length: 4,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'أولوية الوراثة: Override العنصر ← Override الفترة/المستوى ← افتراضي المستوى ← Profile.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isModified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: PwfColors.primaryGold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: PwfColors.primaryGold.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'تعديلات غير محفوظة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPresetKey,
                    decoration: _decoration('قالب جاهز مستلهم من أدوات GIS'),
                    items: kHistoryStylePresets
                        .map(
                          (preset) => DropdownMenuItem<String>(
                            value: preset.key,
                            child: Text(preset.labelAr),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedPresetKey = value),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _selectedPresetKey == null ? null : _applyPreset,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('تطبيق'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _restoreBaseline,
                  icon: const Icon(Icons.history),
                  label: const Text('استعادة الأصل'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _copyJson,
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('نسخ JSON'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PresetLibrary(
              selectedKey: _selectedPresetKey,
              onSelect: (preset) => setState(() => _selectedPresetKey = preset.key),
              onApply: _applyPreset,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          runSpacing: 8,
                          children: [
                            _InfoLine('التعبئة', '${_readString('fillColor', '—')} • ${_readDouble('fillOpacity', 0.18).toStringAsFixed(2)}'),
                            _InfoLine('الحدود', '${_readString('strokeColor', '—')} • ${_readDouble('strokeWidth', 1.8).toStringAsFixed(1)}'),
                            _InfoLine('التسمية', '${_readString('labelColor', '—')} • ${_readDouble('labelSize', 12).toStringAsFixed(0)}px'),
                            _InfoLine('النمط', _readString('dashArray', 'متصل')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _StylePreview(fillColor: fillColor, strokeColor: strokeColor, labelColor: labelColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PreviewComparisonCard(
                          title: 'الحالي',
                          fillColor: fillColor,
                          strokeColor: strokeColor,
                          labelColor: labelColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PreviewComparisonCard(
                          title: 'الأصل / الموروث',
                          fillColor: baselineFill,
                          strokeColor: baselineStroke,
                          labelColor: baselineLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const TabBar(
              isScrollable: true,
              labelColor: PwfColors.primaryGold,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'أساسي'),
                Tab(text: 'التسميات'),
                Tab(text: 'الحالات'),
                Tab(text: 'متقدم'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 380,
              child: TabBarView(
                children: [
                  _buildBasicTab(),
                  _buildLabelsTab(),
                  _buildStatesTab(),
                  _buildAdvancedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _colorPickerField(
                  'لون التعبئة',
                  _readString('fillColor'),
                  (v) => _setValue('fillColor', v),
                  includeNone: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _colorPickerField(
                  'لون الحدود',
                  _readString('strokeColor'),
                  (v) => _setValue('strokeColor', v),
                  includeNone: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sliderField('شفافية التعبئة', _readDouble('fillOpacity', 0.18), 0, 1,
              (v) => _setValue('fillOpacity', double.parse(v.toStringAsFixed(2)))),
          _sliderField('سماكة الحدود', _readDouble('strokeWidth', 1.8), 0.5, 8,
              (v) => _setValue('strokeWidth', double.parse(v.toStringAsFixed(1)))),
          _sliderField('شفافية الحدود', _readDouble('strokeOpacity', 0.95), 0, 1,
              (v) => _setValue('strokeOpacity', double.parse(v.toStringAsFixed(2)))),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _dashValue(),
                  decoration: _decoration('نمط الحدود'),
                  items: kHistoryDashPresets
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.value,
                          child: Text(item.labelAr),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => _setValue('dashArray', value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _textField(
                  'ترتيب الظهور',
                  _readString('zIndex'),
                  (v) => _setValue('zIndex', int.tryParse(v.trim()) ?? v.trim()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _QuickActionPanel(
            title: 'اختصارات سريعة',
            actions: [
              _QuickActionChip(label: 'حدود فقط', onTap: () {
                _setValue('fillOpacity', 0.0);
                _setValue('strokeWidth', 2.2);
              }),
              _QuickActionChip(label: 'إبراز قوي', onTap: () {
                _setValue('fillOpacity', 0.28);
                _setValue('strokeWidth', 2.8);
                _setValue('strokeOpacity', 1.0);
              }),
              _QuickActionChip(label: 'مظهر خفيف', onTap: () {
                _setValue('fillOpacity', 0.08);
                _setValue('strokeWidth', 1.2);
                _setValue('strokeOpacity', 0.72);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabelsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SwitchListTile(
            value: _readBool('showLabel', true),
            onChanged: (value) => _setValue('showLabel', value),
            title: const Text('إظهار التسميات', style: TextStyle(color: Colors.white)),
            contentPadding: EdgeInsets.zero,
          ),
          Row(
            children: [
              Expanded(
                child: _colorPickerField(
                  'لون النص',
                  _readString('labelColor'),
                  (v) => _setValue('labelColor', v),
                  includeNone: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _readString('labelWeight', '700'),
                  decoration: _decoration('وزن النص'),
                  items: kHistoryLabelWeights
                      .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) => _setValue('labelWeight', value ?? '700'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sliderField('حجم النص', _readDouble('labelSize', 12), 8, 24,
              (v) => _setValue('labelSize', double.parse(v.toStringAsFixed(0)))),
          Row(
            children: [
              Expanded(
                child: _colorPickerField(
                  'لون الهالة',
                  _readString('labelHaloColor'),
                  (v) => _setValue('labelHaloColor', v),
                  includeNone: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _sliderField('عرض الهالة', _readDouble('labelHaloWidth', 2), 0, 6,
                    (v) => _setValue('labelHaloWidth', double.parse(v.toStringAsFixed(1)))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _sliderField('أقل تكبير لظهور التسمية', _readDouble('labelMinZoom', 0), 0, 22,
                    (v) => _setValue('labelMinZoom', double.parse(v.toStringAsFixed(0)))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _sliderField('أعلى تكبير لظهور التسمية', _readDouble('labelMaxZoom', 22), 0, 22,
                    (v) => _setValue('labelMaxZoom', double.parse(v.toStringAsFixed(0)))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _QuickActionPanel(
            title: 'قوالب تسمية جاهزة',
            actions: [
              _QuickActionChip(label: 'واضحة للخريطة', onTap: () {
                _setValue('labelSize', 13);
                _setValue('labelWeight', '700');
                _setValue('labelHaloWidth', 2);
              }),
              _QuickActionChip(label: 'خفيفة', onTap: () {
                _setValue('labelSize', 10);
                _setValue('labelWeight', '500');
                _setValue('labelHaloWidth', 1);
              }),
              _QuickActionChip(label: 'للطباعة', onTap: () {
                _setValue('labelColor', '#0F172A');
                _setValue('labelHaloColor', '#FFFFFF');
                _setValue('labelHaloWidth', 3);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('عند المرور', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _colorPickerField(
                  'لون التعبئة عند المرور',
                  _readStateString('hover', 'fillColor'),
                  (v) => _setStateValue('hover', 'fillColor', v),
                  includeNone: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _colorPickerField(
                  'لون الحدود عند المرور',
                  _readStateString('hover', 'strokeColor'),
                  (v) => _setStateValue('hover', 'strokeColor', v),
                  includeNone: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _sliderField('سماكة الحدود عند المرور', _readStateDouble('hover', 'strokeWidth', 2.4), 0.5, 8,
              (v) => _setStateValue('hover', 'strokeWidth', double.parse(v.toStringAsFixed(1)))),
          const SizedBox(height: 16),
          const Text('عند التحديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _colorPickerField(
                  'لون التعبئة عند التحديد',
                  _readStateString('selected', 'fillColor'),
                  (v) => _setStateValue('selected', 'fillColor', v),
                  includeNone: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _colorPickerField(
                  'لون الحدود عند التحديد',
                  _readStateString('selected', 'strokeColor'),
                  (v) => _setStateValue('selected', 'strokeColor', v),
                  includeNone: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _sliderField('سماكة الحدود عند التحديد', _readStateDouble('selected', 'strokeWidth', 3.0), 0.5, 10,
              (v) => _setStateValue('selected', 'strokeWidth', double.parse(v.toStringAsFixed(1)))),
          const SizedBox(height: 12),
          _QuickActionPanel(
            title: 'قوالب سريعة للحالات',
            actions: [
              _QuickActionChip(label: 'تمييز ذهبي', onTap: () {
                _setStateValue('hover', 'strokeColor', '#D4AF37');
                _setStateValue('hover', 'strokeWidth', 2.6);
                _setStateValue('selected', 'strokeColor', '#B22222');
                _setStateValue('selected', 'strokeWidth', 3.2);
              }),
              _QuickActionChip(label: 'تمييز أزرق', onTap: () {
                _setStateValue('hover', 'strokeColor', '#60A5FA');
                _setStateValue('selected', 'strokeColor', '#1E3A8A');
              }),
              _QuickActionChip(label: 'مسح الحالات', onTap: () => _setValue('states', <String, dynamic>{})),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'للمستخدم الخبير: تحرير JSON الخام، استيراد/إعادة تطبيق، أو تفريغ النمط بالكامل.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _jsonController,
            minLines: 12,
            maxLines: 18,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            decoration: _decoration('style_json / override_style_json'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _applyJson,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('تطبيق JSON'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _copyJson,
                icon: const Icon(Icons.download_outlined),
                label: const Text('تصدير سريع'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _restoreBaseline,
                icon: const Icon(Icons.restore),
                label: const Text('إرجاع الأصل'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _resetStyle,
                icon: const Icon(Icons.restart_alt),
                label: const Text('تفريغ'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textField(String label, String value, ValueChanged<String> onChanged) {
    return TextFormField(
      key: ValueKey('$label:$value'),
      initialValue: value,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(label),
    );
  }

  Widget _colorPickerField(
    String label,
    String value,
    ValueChanged<String?> onChanged, {
    bool includeNone = false,
  }) {
    final normalized = value.trim().toUpperCase();
    final hasMatch = kHistoryStyleColors.any((item) => item.hex.toUpperCase() == normalized);
    final selectedValue = normalized.isEmpty
        ? (includeNone ? '__none__' : kHistoryStyleColors.first.hex)
        : (hasMatch ? normalized : (includeNone ? '__custom__' : kHistoryStyleColors.first.hex));

    final options = <DropdownMenuItem<String>>[];
    if (includeNone) {
      options.add(const DropdownMenuItem<String>(
        value: '__none__',
        child: Text('بدون تغيير'),
      ));
    }
    options.addAll(
      kHistoryStyleColors.map(
        (item) => DropdownMenuItem<String>(
          value: item.hex.toUpperCase(),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _colorFromHex(item.hex),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(item.labelAr, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
    if (!hasMatch && normalized.isNotEmpty) {
      options.add(
        DropdownMenuItem<String>(
          value: '__custom__',
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _colorFromHex(value),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('لون مخصص ($value)', overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: selectedValue,
          isExpanded: true,
          decoration: _decoration(label),
          items: options,
          onChanged: (selected) {
            if (selected == null) return;
            if (selected == '__none__') {
              onChanged(null);
              return;
            }
            if (selected == '__custom__') {
              onChanged(value.isEmpty ? null : value);
              return;
            }
            onChanged(selected);
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in kHistoryStyleColors)
              InkWell(
                onTap: () => onChanged(item.hex),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _colorFromHex(item.hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.hex.toUpperCase() == normalized
                          ? PwfColors.primaryGold
                          : Colors.white.withValues(alpha: 0.24),
                      width: item.hex.toUpperCase() == normalized ? 2.2 : 1,
                    ),
                  ),
                ),
              ),
            if (includeNone)
              InkWell(
                onTap: () => onChanged(null),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: normalized.isEmpty ? PwfColors.primaryGold : Colors.white.withValues(alpha: 0.24),
                      width: normalized.isEmpty ? 2.2 : 1,
                    ),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white70),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _sliderField(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    final safeValue = value.clamp(min, max);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              Text(
                safeValue.toStringAsFixed(max <= 1 ? 2 : 1),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
              ),
            ],
          ),
          Slider(value: safeValue, min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  String _dashValue() {
    final current = _readString('dashArray');
    for (final item in kHistoryDashPresets) {
      if (item.value == current) return item.value;
    }
    return '';
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Color _colorFromHex(String? input) {
    if (input == null || input.trim().isEmpty) return const Color(0xFF1E3A8A);
    var hex = input.trim().replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final intValue = int.tryParse(hex, radix: 16);
    if (intValue == null) return const Color(0xFF1E3A8A);
    return Color(intValue);
  }
}

class _PresetLibrary extends StatelessWidget {
  final String? selectedKey;
  final ValueChanged<HistoryStylePreset> onSelect;
  final ValueChanged<HistoryStylePreset> onApply;

  const _PresetLibrary({
    required this.selectedKey,
    required this.onSelect,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kHistoryStylePresets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final preset = kHistoryStylePresets[index];
          final selected = preset.key == selectedKey;
          final fillColor = _hexToColor(preset.styleJson['fillColor']?.toString()).withValues(
            alpha: _toDouble(preset.styleJson['fillOpacity']) ?? 0.18,
          );
          final strokeColor = _hexToColor(preset.styleJson['strokeColor']?.toString());
          return InkWell(
            onTap: () => onSelect(preset),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 240,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? PwfColors.primaryGold.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.08),
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preset.labelAr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle, color: PwfColors.primaryGold, size: 18),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      preset.descriptionAr,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TinyPreview(fillColor: fillColor, strokeColor: strokeColor),
                      ),
                      const SizedBox(width: 8),
                      TextButton(onPressed: () => onApply(preset), child: const Text('تطبيق')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static Color _hexToColor(String? input) {
    if (input == null || input.trim().isEmpty) return const Color(0xFF1E3A8A);
    var hex = input.trim().replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final intValue = int.tryParse(hex, radix: 16);
    if (intValue == null) return const Color(0xFF1E3A8A);
    return Color(intValue);
  }
}

class _QuickActionPanel extends StatelessWidget {
  final String title;
  final List<_QuickActionChip> actions;

  const _QuickActionPanel({required this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions,
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: Colors.white.withValues(alpha: 0.04),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      labelStyle: const TextStyle(color: Colors.white),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text('$label:', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
          ),
        ],
      ),
    );
  }
}

class _StylePreview extends StatelessWidget {
  final Color fillColor;
  final Color strokeColor;
  final Color labelColor;

  const _StylePreview({
    required this.fillColor,
    required this.strokeColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 116,
              height: 58,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: strokeColor, width: 2),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'اسم العنصر',
                style: TextStyle(
                  color: labelColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewComparisonCard extends StatelessWidget {
  final String title;
  final Color fillColor;
  final Color strokeColor;
  final Color labelColor;

  const _PreviewComparisonCard({
    required this.title,
    required this.fillColor,
    required this.strokeColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _TinyPreview(fillColor: fillColor, strokeColor: strokeColor, labelColor: labelColor),
        ],
      ),
    );
  }
}

class _TinyPreview extends StatelessWidget {
  final Color fillColor;
  final Color strokeColor;
  final Color? labelColor;

  const _TinyPreview({
    required this.fillColor,
    required this.strokeColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 76,
              height: 32,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: strokeColor, width: 2),
              ),
            ),
          ),
          if (labelColor != null)
            Center(
              child: Text(
                'عنصر',
                style: TextStyle(
                  color: labelColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
