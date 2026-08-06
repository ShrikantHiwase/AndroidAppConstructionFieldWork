import 'package:flutter_test/flutter_test.dart';

import 'package:construction_field_app/features/documents/domain/document_models.dart';
import 'package:construction_field_app/features/documents/domain/pdf_open_source.dart';

void main() {
  ProjectDocument doc({
    String? localFilePath,
    List<String> pdfPages = const ['page'],
  }) {
    final now = DateTime.utc(2026, 8, 6);
    return ProjectDocument(
      id: 'd1',
      orgId: 'o',
      projectId: 'p',
      folderId: 'f',
      name: 'plan.pdf',
      contentType: 'application/pdf',
      kind: DocContentType.pdf,
      createdBy: 'u',
      createdByName: 'Asha',
      createdAt: now,
      updatedAt: now,
      localFilePath: localFilePath,
      pdfPages: pdfPages,
    );
  }

  test('seeded asset URI opens with pdfrx asset backend', () {
    final source = resolvePdfOpenSource(
      doc(localFilePath: DemoDocumentAssets.gaPlanAssetUri),
    );
    expect(source.usesPdfrx, isTrue);
    expect(source.backend, PdfViewerBackend.pdfrxAsset);
    expect(source.assetPath, DemoDocumentAssets.gaPlanAsset);
  });

  test('on-device file path opens with pdfrx file backend', () {
    final source = resolvePdfOpenSource(
      doc(localFilePath: '/tmp/plan.pdf'),
      fileExists: (_) => true,
    );
    expect(source.backend, PdfViewerBackend.pdfrxFile);
    expect(source.filePath, '/tmp/plan.pdf');
  });

  test('local:// stub falls back to synthetic pages', () {
    final source = resolvePdfOpenSource(
      doc(localFilePath: 'local://demo/documents/x.pdf'),
    );
    expect(source.usesPdfrx, isFalse);
    expect(source.backend, PdfViewerBackend.syntheticPages);
  });

  test('missing file falls back to synthetic pages', () {
    final source = resolvePdfOpenSource(
      doc(localFilePath: '/missing/plan.pdf'),
      fileExists: (_) => false,
    );
    expect(source.backend, PdfViewerBackend.syntheticPages);
  });
}
