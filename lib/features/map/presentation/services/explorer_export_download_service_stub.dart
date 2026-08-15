class ExplorerExportDownloadService {
  const ExplorerExportDownloadService._();

  static bool get isDownloadSupported => false;

  static Future<bool> downloadTextFile({
    required String fileName,
    required String content,
    String mimeType = 'text/plain;charset=utf-8',
  }) async {
    return false;
  }
}
