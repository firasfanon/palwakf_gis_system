import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Renders content safely as plain text.
/// - If it looks like HTML, it strips tags and normalizes line breaks.
/// - If it looks like markdown, it stays as plain text (no extra deps).
class SafeContentBody extends StatelessWidget {
  const SafeContentBody({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cleaned = _clean(text);

    final content = cleaned.trim().isEmpty ? 'لا يوجد نص.' : cleaned.trim();

    final textWidget = kIsWeb
        ? SelectableText(
            content,
            textDirection: TextDirection.rtl,
            style: theme.textTheme.bodyMedium,
          )
        : Text(
            content,
            textDirection: TextDirection.rtl,
            style: theme.textTheme.bodyMedium,
          );

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: textWidget,
      ),
    );
  }

  String _clean(String input) {
    final s = input.trim();
    if (s.isEmpty) return s;

    // crude HTML detection
    final looksLikeHtml = RegExp(r'<\s*\w+[^>]*>').hasMatch(s);
    if (!looksLikeHtml) return s;

    var out = s;

    // normalize common breaks
    out = out.replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n');
    out = out.replaceAll(RegExp(r'</\s*p\s*>', caseSensitive: false), '\n');
    out = out.replaceAll(RegExp(r'</\s*div\s*>', caseSensitive: false), '\n');

    // strip tags
    out = out.replaceAll(RegExp(r'<[^>]+>'), '');

    // decode a few entities
    out = out
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    // collapse multiple blank lines
    out = out.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');

    return out;
  }
}
