import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/document_models.dart';
import 'document_viewer_page.dart';
import 'documents_providers.dart';
import 'upload_document_page.dart';

class DocumentsBrowserPage extends ConsumerStatefulWidget {
  const DocumentsBrowserPage({super.key});

  @override
  ConsumerState<DocumentsBrowserPage> createState() =>
      _DocumentsBrowserPageState();
}

class _DocumentsBrowserPageState extends ConsumerState<DocumentsBrowserPage> {
  final _stack = <DocFolder?>[null];

  DocFolder? get _current => _stack.last;

  void _openFolder(DocFolder folder) {
    setState(() => _stack.add(folder));
  }

  void _pop() {
    if (_stack.length <= 1) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _stack.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final foldersAsync = ref.watch(foldersProvider);
    final docsAsync = ref.watch(documentsInFolderProvider(_current?.id));
    final session = ref.watch(authSessionProvider);
    final canUpload =
        session != null && canUploadDocuments(session.activeRole);

    final title = _current?.name ?? l10n.documents;
    final crumb = _stack
        .whereType<DocFolder>()
        .map((f) => f.name)
        .join(' / ');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _pop,
        ),
        title: Text(title),
        actions: [
          if (canUpload && _current?.kind == FolderKind.documentType)
            IconButton(
              tooltip: l10n.uploadTooltip,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => UploadDocumentPage(folderId: _current!.id),
                  ),
                );
              },
              icon: const Icon(Icons.upload_file),
            ),
        ],
      ),
      body: foldersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (allFolders) {
          final children = allFolders
              .where((f) => f.parentId == _current?.id)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          return docsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (docs) {
              if (children.isEmpty && docs.isEmpty) {
                return Center(
                  child: Text(
                    _current == null
                        ? l10n.noDocumentFoldersYet
                        : l10n.emptyFolderUploadHint,
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (crumb.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        crumb,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ...children.map(
                    (folder) => ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      leading: Icon(
                        folder.kind == FolderKind.discipline
                            ? Icons.account_tree_outlined
                            : Icons.folder_outlined,
                      ),
                      title: Text(folder.name),
                      subtitle: Text(
                        folder.kind == FolderKind.discipline
                            ? l10n.disciplineFolderKind
                            : l10n.documentTypeFolderKind,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openFolder(folder),
                    ),
                  ),
                  if (children.isNotEmpty && docs.isNotEmpty)
                    const SizedBox(height: 12),
                  ...docs.map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        leading: Icon(_iconFor(doc.kind)),
                        title: Text(doc.name),
                        subtitle: Text(
                          '${doc.kind.label}'
                          '${doc.downloaded ? l10n.onDevicePart : l10n.cloudPart}'
                          '${doc.synced ? '' : l10n.pendingSyncPart}',
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  DocumentViewerPage(documentId: doc.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(DocContentType kind) => switch (kind) {
        DocContentType.pdf => Icons.picture_as_pdf_outlined,
        DocContentType.csv => Icons.table_chart_outlined,
        DocContentType.txt => Icons.article_outlined,
        DocContentType.other => Icons.insert_drive_file_outlined,
      };
}
