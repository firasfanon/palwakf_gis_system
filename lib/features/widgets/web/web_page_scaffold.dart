import 'package:flutter/material.dart';

import 'web_app_bar.dart';
import 'web_footer.dart';

/// غلاف موحّد لصفحات الويب: Header + Footer + محتوى.
///
/// ملاحظة:
/// - افتراضيًا [scrollable]=false حتى لا يحدث تعارض مع ListView/Expanded داخل الصفحات.
/// - الصفحات هي المسؤولة عن التمرير داخليًا (ListView / SingleChildScrollView).
class WebPageScaffold extends StatelessWidget {
  const WebPageScaffold({
    super.key,
    required this.child,
    this.scrollable = false,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    return Scaffold(
      appBar: WebAppBar(),
      body: scrollable
          ? LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Expanded(child: content),
                          const WebFooter(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          : Column(
              children: [
                Expanded(child: content),
                const WebFooter(),
              ],
            ),
    );
  }
}
