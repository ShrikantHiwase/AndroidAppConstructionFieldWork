import '../../features/documents/domain/document_models.dart';

/// Result of a document file pick (Fake stub or on-device path).
class PickedDocument {
  const PickedDocument({
    required this.localPath,
    required this.fileName,
    required this.contentType,
    this.byteSizeBytes,
    this.textContent,
    this.pdfPages = const [],
  });

  final String localPath;
  final String fileName;
  final String contentType;
  final int? byteSizeBytes;

  /// Inline body for TXT/CSV demo viewing (Fake / readable Device text).
  final String? textContent;

  /// Synthetic PDF pages until pdfrx is wired.
  final List<String> pdfPages;

  DocContentType get kind =>
      DocContentTypeX.fromMimeOrName(contentType, fileName);
}

/// Document file selection. Fake is default; Device behind sensors gate.
abstract class DocumentFilePicker {
  /// Picks one document. [preferredType] guides Fake stubs and Device filters.
  Future<PickedDocument?> pick({
    DocContentType preferredType = DocContentType.txt,
  });
}
