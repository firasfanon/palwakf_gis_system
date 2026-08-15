class ExplorerBookmarkStorage {
  const ExplorerBookmarkStorage._();

  static bool get isPersistenceSupported => false;

  static Future<List<Map<String, dynamic>>> loadBookmarks() async {
    return const <Map<String, dynamic>>[];
  }

  static Future<bool> saveBookmarks(List<Map<String, dynamic>> bookmarks) async {
    return false;
  }

  static Future<bool> clearBookmarks() async {
    return false;
  }
}
