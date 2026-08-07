import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/device/device_providers.dart';
import '../../../core/device/document_file_policy.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/document_models.dart';
import 'documents_providers.dart';

class UploadDocumentPage extends ConsumerStatefulWidget {
  const UploadDocumentPage({super.key, required this.folderId});

  final String folderId;

  @override
  ConsumerState<UploadDocumentPage> createState() => _UploadDocumentPageState();
}

class _UploadDocumentPageState extends ConsumerState<UploadDocumentPage> {
  final _name = TextEditingController(text: 'site_note.txt');
  final _body = TextEditingController(
    text: 'Uploaded from field.\nDemo content — Storage syncs on flush.',
  );
  var _type = DocContentType.txt;
  var _saving = false;
  String? _error;
  String? _localPath;
  int? _byteSizeBytes;
  List<String> _pdfPages = const [];

  @override
  void dispose() {
    _name.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await ref.read(documentFilePickerProvider).pick(
          preferredType: _type,
        );
    if (picked == null || !mounted) return;
    setState(() {
      _name.text = picked.fileName;
      _type = picked.kind;
      _localPath = picked.localPath;
      _byteSizeBytes = picked.byteSizeBytes;
      _pdfPages = picked.pdfPages;
      if (picked.textContent != null) {
        _body.text = picked.textContent!;
      } else if (picked.pdfPages.isNotEmpty) {
        _body.text = picked.pdfPages.first;
      }
      _error = null;
    });
  }

  Future<void> _save() async {
    final session = ref.read(authSessionProvider);
    if (session == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final contentType = switch (_type) {
        DocContentType.pdf => 'application/pdf',
        DocContentType.csv => 'text/csv',
        DocContentType.txt => 'text/plain',
        DocContentType.other => 'application/octet-stream',
      };
      final path = _localPath;
      await ref.read(documentsRepositoryProvider).uploadDocument(
            session: session,
            input: UploadDocumentInput(
              folderId: widget.folderId,
              name: _name.text,
              contentType: contentType,
              textContent: _type == DocContentType.pdf ? null : _body.text,
              pdfPages: _type == DocContentType.pdf
                  ? (_pdfPages.isNotEmpty
                      ? _pdfPages
                      : [
                          _body.text,
                          'Page 2 — continuation of ${_name.text}',
                        ])
                  : const [],
              localFilePath: path,
              sizeBytes: _byteSizeBytes,
            ),
          );
      if (!ref.read(isOfflineProvider)) {
        await ref.read(syncEngineProvider).flushNow(
              isOnline: true,
              projectId: session.activeProjectId,
            );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final native = ref.watch(usingNativeSensorsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.uploadDocument)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _name,
            decoration: InputDecoration(
              labelText: l10n.fileNameLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownMenu<DocContentType>(
            initialSelection: _type,
            label: Text(l10n.typeLabel),
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: DocContentType.txt, label: 'TXT'),
              DropdownMenuEntry(value: DocContentType.csv, label: 'CSV'),
              DropdownMenuEntry(value: DocContentType.pdf, label: 'PDF'),
            ],
            onSelected: (v) {
              if (v != null) setState(() => _type = v);
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _saving ? null : _pick,
            icon: const Icon(Icons.attach_file),
            label: Text(native ? l10n.pickFile : l10n.pickDemoFile),
          ),
          if (_localPath != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.pickedFileMeta(
                _localPath!.startsWith('local://')
                    ? l10n.demoStubLabel
                    : l10n.fileNoun,
                DocumentFilePolicy.formatBytes(
                  _byteSizeBytes ?? _body.text.length,
                ),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _body,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: _type == DocContentType.pdf
                  ? l10n.previewNotesLabel
                  : l10n.contentPreviewLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.uploadAction),
          ),
          const SizedBox(height: 8),
          Text(
            native ? l10n.uploadHintNative : l10n.uploadHintDemo,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
