import 'dart:io';

import '../domain/document_models.dart';

/// Bundled demo PDF used by seed data and Fake PDF picks.
abstract final class DemoDocumentAssets {
  static const gaPlanAsset = 'assets/demo/ga_plan_level_02.pdf';
  static const assetUriPrefix = 'asset://';

  /// Stored on [ProjectDocument.localFilePath] for in-app pdfrx viewing.
  static const gaPlanAssetUri = '$assetUriPrefix$gaPlanAsset';

  static bool isAssetUri(String? path) =>
      path != null && path.startsWith(assetUriPrefix);

  static String? assetPathFromUri(String path) {
    if (!isAssetUri(path)) return null;
    return path.substring(assetUriPrefix.length);
  }
}

enum PdfViewerBackend { pdfrxAsset, pdfrxFile, syntheticPages }

/// Resolves how the Documents viewer should open a PDF.
class PdfOpenSource {
  const PdfOpenSource._({
    required this.backend,
    this.assetPath,
    this.filePath,
  });

  final PdfViewerBackend backend;
  final String? assetPath;
  final String? filePath;

  bool get usesPdfrx =>
      backend == PdfViewerBackend.pdfrxAsset ||
      backend == PdfViewerBackend.pdfrxFile;

  factory PdfOpenSource.asset(String assetPath) => PdfOpenSource._(
        backend: PdfViewerBackend.pdfrxAsset,
        assetPath: assetPath,
      );

  factory PdfOpenSource.file(String filePath) => PdfOpenSource._(
        backend: PdfViewerBackend.pdfrxFile,
        filePath: filePath,
      );

  factory PdfOpenSource.synthetic() => const PdfOpenSource._(
        backend: PdfViewerBackend.syntheticPages,
      );
}

/// Prefers real PDF bytes (asset or on-device file); falls back to [pdfPages].
PdfOpenSource resolvePdfOpenSource(
  ProjectDocument doc, {
  bool Function(String path)? fileExists,
}) {
  if (doc.kind != DocContentType.pdf) {
    return PdfOpenSource.synthetic();
  }

  final path = doc.localFilePath;
  if (path == null || path.isEmpty) {
    return PdfOpenSource.synthetic();
  }

  final asset = DemoDocumentAssets.assetPathFromUri(path);
  if (asset != null && asset.isNotEmpty) {
    return PdfOpenSource.asset(asset);
  }

  if (path.startsWith('local://') || path.startsWith('demo://')) {
    return PdfOpenSource.synthetic();
  }

  final exists = fileExists ?? (p) => File(p).existsSync();
  if (exists(path)) {
    return PdfOpenSource.file(path);
  }

  return PdfOpenSource.synthetic();
}
