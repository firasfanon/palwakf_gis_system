// lib/presentation/widgets/web/web_container.dart
import 'package:flutter/material.dart';

/// حاوية قياسية لمحتوى صفحات الويب (maxWidth + padding)
class WebContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const WebContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
