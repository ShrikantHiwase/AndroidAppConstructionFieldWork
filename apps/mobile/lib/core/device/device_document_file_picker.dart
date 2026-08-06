import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../../features/documents/domain/document_models.dart';
import 'document_file_picker.dart';
import 'fake_document_file_picker.dart';

/// On-device file pick via `file_picker`; falls back to Fake on errors.
class DeviceDocumentFilePicker implements DocumentFilePicker {
  DeviceDocumentFilePicker({DocumentFilePicker? fallback})
      : _fallback = fallback ?? FakeDocumentFilePicker();

  final DocumentFilePicker _fallback;

  @override
  Future<PickedDocument?> pick({
    DocContentType preferredType = DocContentType.txt,
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: switch (preferredType) {
          DocContentType.pdf => const ['pdf'],
          DocContentType.csv => const ['csv'],
          DocContentType.txt => const ['txt', 'text', 'md'],
          DocContentType.other => const ['txt', 'csv', 'pdf'],
        },
        withData: false,
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.single;
      final path = file.path;
      if (path == null || path.isEmpty) {
        return _fallback.pick(preferredType: preferredType);
      }

      String? textContent;
      var pdfPages = const <String>[];
      final name = file.name;
      final mime = _mimeFor(name, preferredType);
      final kind = DocContentTypeX.fromMimeOrName(mime, name);

      if (kind == DocContentType.txt || kind == DocContentType.csv) {
        try {
          final raw = await File(path).readAsString();
          textContent = raw.length > 20000 ? raw.substring(0, 20000) : raw;
        } catch (_) {
          textContent = 'File on device — open externally if needed.';
        }
      } else if (kind == DocContentType.pdf) {
        pdfPages = [
          'PDF on device: $name',
          'Full PDF viewer (pdfrx) still deferred — metadata synced on flush.',
        ];
      }

      return PickedDocument(
        localPath: path,
        fileName: name,
        contentType: mime,
        byteSizeBytes: file.size > 0 ? file.size : null,
        textContent: textContent,
        pdfPages: pdfPages,
      );
    } catch (_) {
      return _fallback.pick(preferredType: preferredType);
    }
  }

  String _mimeFor(String name, DocContentType preferred) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.csv')) return 'text/csv';
    if (lower.endsWith('.txt') || lower.endsWith('.md')) return 'text/plain';
    return switch (preferred) {
      DocContentType.pdf => 'application/pdf',
      DocContentType.csv => 'text/csv',
      DocContentType.txt || DocContentType.other => 'text/plain',
    };
  }
}
