// lib/features/map/presentation/widgets/toolbox/tool_sections/import_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/constants/colors.dart';
import 'package:kimi/features/map/presentation/providers/toolbox_providers.dart';

final importFilesProvider = StateProvider<List<ImportFile>>((ref) => []);

class ImportFile {
  final String name;
  final String type;
  final double size;
  final DateTime uploadedAt;
  final ImportStatus status;

  ImportFile({
    required this.name,
    required this.type,
    required this.size,
    required this.uploadedAt,
    this.status = ImportStatus.pending,
  });
}

enum ImportStatus { pending, processing, success, error }

class ImportSection extends ConsumerWidget {
  const ImportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(importFilesProvider);
    final audience = ref.watch(mapToolAudienceProvider);
    final canImport = audience.canUseManagerTools;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                ref.read(activeToolSectionProvider.notifier).state = null;
              },
            ),
            const Text(
              'استيراد البيانات',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!canImport) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'يتطلب الاستيراد صلاحيات خاصة. يرجى التواصل مع المسؤول.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canImport ? () => _pickFiles(ref) : null,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 64,
                    color: canImport ? PwfColors.royalRed : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'اسحب الملفات هنا أو اضغط للاستيراد',
                    style: TextStyle(
                      color: canImport ? Colors.black87 : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'KML, KMZ, Shapefile (Zip), Excel, CSV',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'الصيغ المدعومة:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFormatChip('KML', Icons.location_on),
            _buildFormatChip('KMZ', Icons.location_on_outlined),
            _buildFormatChip('Shapefile (Zip)', Icons.folder_zip),
            _buildFormatChip('Excel', Icons.table_chart),
            _buildFormatChip('CSV', Icons.text_snippet),
          ],
        ),
        const SizedBox(height: 24),
        if (files.isNotEmpty) ...[
          const Text(
            'عمليات الاستيراد الأخيرة:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...files.map((file) => _buildFileTile(file)),
        ],
      ],
    );
  }

  Widget _buildFormatChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: PwfColors.primaryBlue),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: PwfColors.primaryBlue.withValues(alpha: 0.1),
      side: BorderSide.none,
    );
  }

  Widget _buildFileTile(ImportFile file) {
    IconData statusIcon;
    Color statusColor;

    switch (file.status) {
      case ImportStatus.pending:
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.orange;
        break;
      case ImportStatus.processing:
        statusIcon = Icons.sync;
        statusColor = Colors.blue;
        break;
      case ImportStatus.success:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case ImportStatus.error:
        statusIcon = Icons.error;
        statusColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.insert_drive_file, color: PwfColors.primaryBlue),
        title: Text(file.name, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          '${file.type} • ${(file.size / 1024).toStringAsFixed(1)} KB',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: Icon(statusIcon, color: statusColor, size: 20),
        dense: true,
      ),
    );
  }

  void _pickFiles(WidgetRef ref) async {
    final newFile = ImportFile(
      name: 'waqf_data_${DateTime.now().millisecondsSinceEpoch}.kml',
      type: 'KML',
      size: 1024 * 1024 * 2.5,
      uploadedAt: DateTime.now(),
    );

    ref.read(importFilesProvider.notifier).state = [
      newFile,
      ...ref.read(importFilesProvider),
    ];
  }
}
