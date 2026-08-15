class PwfSourceLocator {
  const PwfSourceLocator({
    required this.sourceTitle,
    required this.sourceType,
    required this.locatorText,
    required this.evidenceNote,
    this.page,
    this.tableName,
    this.rowReference,
  });

  factory PwfSourceLocator.fromJson(Map<String, dynamic> json) {
    return PwfSourceLocator(
      sourceTitle: '${json['source_title'] ?? ''}',
      sourceType: '${json['source_type'] ?? ''}',
      locatorText: '${json['locator_text'] ?? ''}',
      evidenceNote: '${json['evidence_note'] ?? ''}',
      page: _nullableText(json['page']),
      tableName: _nullableText(json['table_name']),
      rowReference: _nullableText(json['row_reference']),
    );
  }

  final String sourceTitle;
  final String sourceType;
  final String locatorText;
  final String evidenceNote;
  final String? page;
  final String? tableName;
  final String? rowReference;

  bool get isComplete {
    return sourceTitle.trim().isNotEmpty &&
        sourceType.trim().isNotEmpty &&
        locatorText.trim().isNotEmpty &&
        evidenceNote.trim().isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'source_title': sourceTitle,
      'source_type': sourceType,
      'locator_text': locatorText,
      'evidence_note': evidenceNote,
      'page': page,
      'table_name': tableName,
      'row_reference': rowReference,
    };
  }

  PwfSourceLocator copyWith({
    String? sourceTitle,
    String? sourceType,
    String? locatorText,
    String? evidenceNote,
    String? page,
    String? tableName,
    String? rowReference,
  }) {
    return PwfSourceLocator(
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceType: sourceType ?? this.sourceType,
      locatorText: locatorText ?? this.locatorText,
      evidenceNote: evidenceNote ?? this.evidenceNote,
      page: page ?? this.page,
      tableName: tableName ?? this.tableName,
      rowReference: rowReference ?? this.rowReference,
    );
  }

  static String? _nullableText(dynamic value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }
}
