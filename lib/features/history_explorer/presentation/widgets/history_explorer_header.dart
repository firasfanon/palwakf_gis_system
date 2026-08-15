import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../application/state/history_explorer_state.dart';
import '../../domain/enums/history_explorer_mode.dart';

class HistoryExplorerHeader extends StatefulWidget {
  const HistoryExplorerHeader({
    super.key,
    required this.state,
    required this.onModeChanged,
    required this.onPeriodChanged,
    required this.onLevelChanged,
    required this.onSearchChanged,
    required this.onToggleModernContext,
    required this.onToggleWaqfAssets,
    required this.onToggleParcels,
    required this.onToggleLineage,
    required this.onToggleLabels,
    required this.onToggleBoundariesOnly,
  });

  final HistoryExplorerState state;
  final ValueChanged<HistoryExplorerMode> onModeChanged;
  final ValueChanged<int?> onPeriodChanged;
  final ValueChanged<String?> onLevelChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleModernContext;
  final VoidCallback onToggleWaqfAssets;
  final VoidCallback onToggleParcels;
  final VoidCallback onToggleLineage;
  final VoidCallback onToggleLabels;
  final VoidCallback onToggleBoundariesOnly;

  @override
  State<HistoryExplorerHeader> createState() => _HistoryExplorerHeaderState();
}

class _HistoryExplorerHeaderState extends State<HistoryExplorerHeader> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchQuery);
    _searchFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant HistoryExplorerHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.state.searchQuery;
    if (_searchController.text == incoming) return;
    final keepFocus = _searchFocusNode.hasFocus;
    _searchController.value = TextEditingValue(
      text: incoming,
      selection: TextSelection.collapsed(offset: incoming.length),
      composing: TextRange.empty,
    );
    if (keepFocus && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final modeColor = _modeColor(state.mode);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PwfColors.outline),
        boxShadow: [
          BoxShadow(
            color: modeColor.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _HeroBanner(
            mode: state.mode,
            selectedPeriodLabel: state.selectedPeriod?.titleAr,
            selectedLevelLabel: state.selectedLevelLabel,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              _ModePill(
                selected: state.mode == HistoryExplorerMode.historical,
                onTap: () => widget.onModeChanged(HistoryExplorerMode.historical),
                label: 'من التاريخ',
                icon: Icons.history_edu_outlined,
                color: PwfColors.primaryBlue,
              ),
              _ModePill(
                selected: state.mode == HistoryExplorerMode.modern,
                onTap: () => widget.onModeChanged(HistoryExplorerMode.modern),
                label: 'من الحديث',
                icon: Icons.account_tree_outlined,
                color: PwfColors.warning,
              ),
              _ModePill(
                selected: state.mode == HistoryExplorerMode.waqf,
                onTap: () => widget.onModeChanged(HistoryExplorerMode.waqf),
                label: 'من الوقف',
                icon: Icons.domain_outlined,
                color: PwfColors.royalRed,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PwfColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PwfColors.outline),
            ),
            child: Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 250,
                      child: DropdownButtonFormField<int>(
                        value: state.selectedPeriodNo,
                        isExpanded: true,
                        style: const TextStyle(
                          color: PwfColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        iconEnabledColor: PwfColors.primaryBlue,
                        dropdownColor: Colors.white,
                        decoration: _fieldDecoration(
                          label: 'الفترة',
                          icon: Icons.timeline_outlined,
                        ),
                        items: state.periods
                            .map(
                              (period) => DropdownMenuItem<int>(
                                value: period.periodNo,
                                child: Text(
                                  '${period.periodNo} — ${period.titleAr}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: PwfColors.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: widget.onPeriodChanged,
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        value: state.selectedLevelKey,
                        isExpanded: true,
                        style: TextStyle(
                          color: state.canDrawOverlay ? PwfColors.onSurface : PwfColors.onSurface.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w700,
                        ),
                        iconEnabledColor: state.canDrawOverlay ? PwfColors.primaryBlue : PwfColors.onSurface.withValues(alpha: 0.48),
                        dropdownColor: Colors.white,
                        decoration: _fieldDecoration(
                          label: 'المستوى الإداري',
                          icon: Icons.layers_outlined,
                          enabled: state.canDrawOverlay,
                        ),
                        disabledHint: Text(
                          state.selectedLevelLabel ?? 'يتاح فقط للفترات التشغيلية',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: PwfColors.onSurface.withValues(alpha: 0.58),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        items: state.levels
                            .map(
                              (level) => DropdownMenuItem<String>(
                                value: level.levelKey,
                                child: Text(
                                  level.displayLabel,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: PwfColors.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: state.canDrawOverlay ? widget.onLevelChanged : null,
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: widget.onSearchChanged,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          color: PwfColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: _fieldDecoration(
                          label: _searchLabelForMode(state.mode),
                          icon: Icons.search,
                          hint: _searchHintForMode(state.mode),
                        ).copyWith(
                          suffixIcon: _searchController.text.trim().isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    widget.onSearchChanged('');
                                    _searchFocusNode.requestFocus();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close, color: PwfColors.onSurface),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'ابدأ بالفترة والمستوى، ثم استخدم البحث لتضييق النتائج قبل فتح الخيارات المتقدمة.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PwfColors.onSurface.withValues(alpha: 0.62),
                          height: 1.5,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                'خيارات العرض المتقدمة',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: PwfColors.primaryBlue,
                    ),
              ),
              subtitle: Text(
                'أظهر المرجع الحديث أو الأصول الوقفية أو التسميات عند الحاجة فقط.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PwfColors.onSurface.withValues(alpha: 0.64),
                    ),
              ),
              children: [
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _CompactToggleChip(
                      selected: state.showModernContext,
                      onTap: widget.onToggleModernContext,
                      label: 'المرجع الحديث',
                      icon: Icons.polyline_outlined,
                      color: PwfColors.warning,
                    ),
                    _CompactToggleChip(
                      selected: state.showWaqfAssets,
                      onTap: widget.onToggleWaqfAssets,
                      label: 'الأصول الوقفية',
                      icon: Icons.real_estate_agent_outlined,
                      color: PwfColors.royalRed,
                    ),
                    _CompactToggleChip(
                      selected: state.showParcels,
                      onTap: widget.onToggleParcels,
                      label: 'القطع المرتبطة',
                      icon: Icons.crop_square_outlined,
                      color: PwfColors.warning,
                    ),
                    _CompactToggleChip(
                      selected: state.showLineage,
                      onTap: widget.onToggleLineage,
                      label: 'السلالة',
                      icon: Icons.account_tree_outlined,
                      color: PwfColors.success,
                    ),
                    _CompactToggleChip(
                      selected: state.showLabels,
                      onTap: widget.onToggleLabels,
                      label: 'التسميات',
                      icon: Icons.label_outline,
                      color: PwfColors.primaryBlue,
                    ),
                    _CompactToggleChip(
                      selected: state.boundariesOnly,
                      onTap: widget.onToggleBoundariesOnly,
                      label: 'الحدود فقط',
                      icon: Icons.crop_square_outlined,
                      color: PwfColors.onSurface,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
    bool enabled = true,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: enabled ? const Color(0xFFCBD5E1) : const Color(0xFFD6DCE5),
      ),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: enabled ? Colors.white : const Color(0xFFF5F7FB),
      prefixIcon: Icon(
        icon,
        color: enabled ? PwfColors.primaryBlue : PwfColors.onSurface.withValues(alpha: 0.48),
      ),
      labelStyle: TextStyle(
        color: enabled ? PwfColors.onSurface.withValues(alpha: 0.82) : PwfColors.onSurface.withValues(alpha: 0.66),
        fontWeight: FontWeight.w700,
      ),
      hintStyle: TextStyle(
        color: PwfColors.onSurface.withValues(alpha: 0.62),
        fontWeight: FontWeight.w600,
      ),
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: PwfColors.primaryBlue, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Color _modeColor(HistoryExplorerMode mode) {
    switch (mode) {
      case HistoryExplorerMode.historical:
        return PwfColors.primaryBlue;
      case HistoryExplorerMode.modern:
        return PwfColors.warning;
      case HistoryExplorerMode.waqf:
        return PwfColors.royalRed;
    }
  }

  String _searchLabelForMode(HistoryExplorerMode mode) {
    switch (mode) {
      case HistoryExplorerMode.historical:
        return 'ابحث عن كيان تاريخي';
      case HistoryExplorerMode.modern:
        return 'ابحث عن مرجع حديث';
      case HistoryExplorerMode.waqf:
        return 'ابحث عن وقف أو PWF';
    }
  }

  String _searchHintForMode(HistoryExplorerMode mode) {
    switch (mode) {
      case HistoryExplorerMode.historical:
        return 'سنجق القدس أو قضاء الخليل';
      case HistoryExplorerMode.modern:
        return 'بيت لحم أو بيت جالا';
      case HistoryExplorerMode.waqf:
        return 'اسم الأصل أو المفتاح';
    }
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.mode,
    required this.selectedPeriodLabel,
    required this.selectedLevelLabel,
  });

  final HistoryExplorerMode mode;
  final String? selectedPeriodLabel;
  final String? selectedLevelLabel;

  @override
  Widget build(BuildContext context) {
    Color color;
    String subtitle;
    switch (mode) {
      case HistoryExplorerMode.historical:
        color = PwfColors.primaryBlue;
        subtitle = 'ابدأ من فترة تاريخية ثم انزل تدريجيًا إلى المرجع الحديث والأصل الوقفي.';
        break;
      case HistoryExplorerMode.modern:
        color = PwfColors.warning;
        subtitle = 'ابدأ من تجمع أو مرجع حديث ثم تتبّع الجذر التاريخي الذي ينتمي إليه.';
        break;
      case HistoryExplorerMode.waqf:
        color = PwfColors.royalRed;
        subtitle = 'ابدأ من الوقف الحديث أو المفتاح الوقفي ثم تتبّع امتداده الإداري والتاريخي.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0B1220),
            color.withValues(alpha: 0.96),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بوابة التاريخ الوقفي',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.7,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                _HeroBadge(label: _modeLabel(mode), color: color),
                if ((selectedPeriodLabel ?? '').trim().isNotEmpty)
                  _HeroBadge(label: selectedPeriodLabel!, color: Colors.white),
                if ((selectedLevelLabel ?? '').trim().isNotEmpty)
                  _HeroBadge(label: 'المستوى: $selectedLevelLabel', color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _modeLabel(HistoryExplorerMode mode) {
    switch (mode) {
      case HistoryExplorerMode.historical:
        return 'من التاريخ';
      case HistoryExplorerMode.modern:
        return 'من الحديث';
      case HistoryExplorerMode.waqf:
        return 'من الوقف';
    }
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color == Colors.white ? Colors.white.withValues(alpha: 0.92) : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color == Colors.white ? const Color(0xFF102049) : Colors.white,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.selected,
    required this.onTap,
    required this.label,
    required this.icon,
    required this.color,
  });

  final bool selected;
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color : PwfColors.outline),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? color : PwfColors.onSurface.withValues(alpha: 0.72)),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: selected ? color : PwfColors.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactToggleChip extends StatelessWidget {
  const _CompactToggleChip({
    required this.selected,
    required this.onTap,
    required this.label,
    required this.icon,
    required this.color,
  });

  final bool selected;
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : PwfColors.surfaceVariant,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color : PwfColors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? color : PwfColors.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected ? color : PwfColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
