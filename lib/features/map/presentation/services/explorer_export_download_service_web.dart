import 'dart:html' as html;

class ExplorerExportDownloadService {
  const ExplorerExportDownloadService._();

  static bool get isDownloadSupported => true;

  static Future<bool> downloadTextFile({
    required String fileName,
    required String content,
    String mimeType = 'text/plain;charset=utf-8',
  }) async {
    final blob = html.Blob(<String>[content], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    try {
      final anchor = html.AnchorElement(href: url)
        ..download = fileName
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      return true;
    } finally {
      html.Url.revokeObjectUrl(url);
    }
  }
}
