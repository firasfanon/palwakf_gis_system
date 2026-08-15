import 'dart:convert';
import 'dart:html' as html;

class ExplorerBookmarkStorage {
  const ExplorerBookmarkStorage._();

  static const String _storageKey = 'palwakf.mustakshif.explorer.bookmarks.v1';

  static bool get isPersistenceSupported => true;

  static Future<List<Map<String, dynamic>>> loadBookmarks() async {
    final raw = html.window.localStorage[_storageKey];
    if (raw == null || raw.trim().isEmpty) return const <Map<String, dynamic>>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <Map<String, dynamic>>[];
    return decoded
        .whereType<Map>()
        .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
        .toList(growable: false);
  }

  static Future<bool> saveBookmarks(List<Map<String, dynamic>> bookmarks) async {
    html.window.localStorage[_storageKey] = jsonEncode(bookmarks);
    return true;
  }

  static Future<bool> clearBookmarks() async {
    html.window.localStorage.remove(_storageKey);
    return true;
  }
}
