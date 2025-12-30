// ignore_for_file: unused_element
/// No-op SEO helpers for non-web platforms.
class SeoController {
  static void setTitle(String title) {}
  static void setDescription(String description) {}
  static void setOpenGraph({
    required String title,
    String? description,
    String? url,
  }) {}
}
