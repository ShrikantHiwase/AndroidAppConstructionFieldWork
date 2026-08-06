import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/connectivity_provider.dart';
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

  @override
  void dispose() {
    _name.dispose();
    _body.dispose();
    super.dispose();
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
      await ref.read(documentsRepositoryProvider).uploadDocument(
            session: session,
            input: UploadDocumentInput(
              folderId: widget.folderId,
              name: _name.text,
              contentType: contentType,
              textContent: _type == DocContentType.pdf ? null : _body.text,
              pdfPages: _type == DocContentType.pdf
                  ? [
                      _body.text,
                      'Page 2 — continuation of ${_name.text}',
                    ]
                  : const [],
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
    return Scaffold(
      appBar: AppBar(title: const Text('Upload document')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'File name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownMenu<DocContentType>(
            initialSelection: _type,
            label: const Text('Type'),
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
          TextFormField(
            controller: _body,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Content (demo)',
              border: OutlineInputBorder(),
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
                : const Text('Upload'),
          ),
          const SizedBox(height: 8),
          Text(
            'Saves offline immediately. On flush, demo paths use demo:// Storage '
            'URLs; real file paths upload to Firebase Storage when configured.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
