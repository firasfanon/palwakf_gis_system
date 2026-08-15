import 'dart:convert';
import 'dart:html' as html;

class PwfExportResult {
  const PwfExportResult({
    required this.success,
    required this.message,
    required this.filename,
    required this.bytesLength,
    required this.rowCount,
    required this.checksum,
    required this.adapterCode,
  });

  final bool success;
  final String message;
  final String filename;
  final int bytesLength;
  final int rowCount;
  final String checksum;
  final String adapterCode;

  bool get hasRows => rowCount > 0;

  String get qualityLabelAr {
    if (!success) return 'فشل التصدير';
    if (!hasRows) return 'تصدير فارغ يحتاج مراجعة';
    if (bytesLength <= 3) return 'payload غير كافٍ';
    return 'payload جاهز قبل التنزيل';
  }

  String get verificationLine {
    return 'adapter=$adapterCode; file=$filename; bytes=$bytesLength; rows=$rowCount; checksum=$checksum; quality=$qualityLabelAr';
  }

  String get manifestText {
    return [
      'Mustakshif Export QA Result',
      'filename=$filename',
      'success=$success',
      'adapter=$adapterCode',
      'bytes=$bytesLength',
      'rows=$rowCount',
      'checksum=$checksum',
      'quality=$qualityLabelAr',
      'browser_disk_write_verification=false',
      'payload_pre_download_verification=true',
    ].join('\n');
  }
}

class PwfExportFileAdapter {
  const PwfExportFileAdapter();

  Future<PwfExportResult> downloadCsv({
    required String filename,
    required String csvContent,
  }) async {
    final bytes = utf8.encode('\ufeff$csvContent');
    final checksum = _fnv1a32(bytes);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..setAttribute('data-pwf-checksum', checksum)
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    return PwfExportResult(
      success: true,
      filename: filename,
      bytesLength: bytes.length,
      rowCount: _countCsvRows(csvContent),
      checksum: checksum,
      adapterCode: 'web_anchor_download',
      message: 'تم تجهيز payload وإطلاق تنزيل CSV: $filename — checksum=$checksum',
    );
  }

  static int _countCsvRows(String csvContent) {
    final lines = csvContent.split('\n').where((line) => line.trim().isNotEmpty).length;
    return lines == 0 ? 0 : lines - 1;
  }

  static String _fnv1a32(List<int> bytes) {
    var hash = 0x811c9dc5;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
