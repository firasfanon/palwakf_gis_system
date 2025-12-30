
import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';
import '../widgets/header_nav.dart';
import '../widgets/web_footer.dart';

class PageScaffold extends StatelessWidget {
  final Widget child;
  final VoidCallback? onToggleTheme;
  const PageScaffold({super.key, required this.child, this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TopBar(onToggleTheme: onToggleTheme),
      const HeaderNav(),
      Expanded(child: child),
      const WebFooter(),
    ]);
  }
}
