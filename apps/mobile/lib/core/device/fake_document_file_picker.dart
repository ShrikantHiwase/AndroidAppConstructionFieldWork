import '../../features/documents/domain/document_models.dart';
import '../../features/documents/domain/pdf_open_source.dart';
import 'document_file_picker.dart';
import 'document_file_policy.dart';

class FakeDocumentFilePicker implements DocumentFilePicker {
  FakeDocumentFilePicker({int startIndex = 0}) : _index = startIndex;

  int _index;

  @override
  Future<PickedDocument?> pick({
    DocContentType preferredType = DocContentType.txt,
  }) async {
    _index += 1;
    switch (preferredType) {
      case DocContentType.csv:
        return PickedDocument(
          localPath: 'local://demo/documents/field_log_$_index.csv',
          fileName: 'field_log_$_index.csv',
          contentType: 'text/csv',
          byteSizeBytes: DocumentFilePolicy.demoCsvBytes,
          textContent:
              'tag,level,size_mm\nCT-01,L2,300\nCT-02,L2,450\n',
        );
      case DocContentType.pdf:
        return PickedDocument(
          localPath: DemoDocumentAssets.gaPlanAssetUri,
          fileName: 'site_note_$_index.pdf',
          contentType: 'application/pdf',
          byteSizeBytes: DocumentFilePolicy.demoPdfBytes,
          pdfPages: const [
            'Fallback text if pdfrx cannot open the demo asset.',
          ],
        );
      case DocContentType.other:
      case DocContentType.txt:
        return PickedDocument(
          localPath: 'local://demo/documents/site_note_$_index.txt',
          fileName: 'site_note_$_index.txt',
          contentType: 'text/plain',
          byteSizeBytes: DocumentFilePolicy.demoTxtBytes,
          textContent:
              'Uploaded from field.\nDemo content — Storage syncs on flush.',
        );
    }
  }
}
