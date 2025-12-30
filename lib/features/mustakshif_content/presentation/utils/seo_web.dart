import 'dart:html' as html;

class SeoController {
  static void setTitle(String title) {
    html.document.title = title;
  }

  static void setDescription(String description) {
    _setMeta(name: 'description', content: description);
  }

  static void setOpenGraph({
    required String title,
    String? description,
    String? url,
  }) {
    setTitle(title);
    if (description != null && description.trim().isNotEmpty) {
      setDescription(description.trim());
    }
    _setMeta(property: 'og:title', content: title);
    if (description != null && description.trim().isNotEmpty) {
      _setMeta(property: 'og:description', content: description.trim());
    }
    if (url != null && url.trim().isNotEmpty) {
      _setMeta(property: 'og:url', content: url.trim());
    }
  }

  static void _setMeta({String? name, String? property, required String content}) {
    final head = html.document.head;
    if (head == null) return;

    html.MetaElement? meta;
    for (final el in head.querySelectorAll('meta')) {
      if (el is! html.MetaElement) continue;
      if (name != null && el.name == name) {
        meta = el;
        break;
      }
      if (property != null && el.getAttribute('property') == property) {
        meta = el;
        break;
      }
    }

    meta ??= html.MetaElement();
    if (name != null) meta.name = name;
    if (property != null) meta.setAttribute('property', property);
    meta.content = content;

    if (meta.parent == null) {
      head.append(meta);
    }
  }
}
