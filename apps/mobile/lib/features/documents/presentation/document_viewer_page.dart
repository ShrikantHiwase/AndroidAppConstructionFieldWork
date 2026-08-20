import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/share/share_port.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/document_models.dart';
import '../domain/pdf_open_source.dart';
import 'documents_providers.dart';

class DocumentViewerPage extends ConsumerStatefulWidget {
  const DocumentViewerPage({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends ConsumerState<DocumentViewerPage> {
  final _search = TextEditingController();
  ProjectDocument? _doc;
  var _loading = true;
  var _pageIndex = 0;
  var _query = '';
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final doc = await ref
        .read(documentsRepositoryProvider)
        .getDocument(widget.documentId);
    if (!mounted) return;
    setState(() {
      _doc = doc;
      _loading = false;
      _pageIndex = 0;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final doc = _doc;
    if (doc == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.documentNoun)),
        body: Center(child: Text(l10n.documentNotFound)),
      );
    }

    final pdfSource =
        doc.kind == DocContentType.pdf ? resolvePdfOpenSource(doc) : null;
    final usePdfrx = pdfSource?.usesPdfrx ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.name),
        actions: [
          if (!doc.downloaded)
            IconButton(
              tooltip: l10n.downloadTooltip,
              onPressed: () async {
                final updated = await ref
                    .read(documentsRepositoryProvider)
                    .markDownloaded(doc.id);
                if (mounted) setState(() => _doc = updated);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.savedOnDevice)),
                  );
                }
              },
              icon: const Icon(Icons.download_outlined),
            ),
          IconButton(
            tooltip: l10n.shareDocumentSummaryTooltip,
            onPressed: () async {
              final doc = _doc;
              if (doc == null) return;
              final text = StringBuffer()
                ..writeln(doc.name)
                ..writeln(l10n.documentShareType(doc.contentType))
                ..writeln(
                  doc.remoteUrl == null
                      ? (doc.localFilePath ?? l10n.documentShareOnDevice)
                      : l10n.documentShareUrl(doc.remoteUrl!),
                );
              final outcome = await ref.read(sharePortProvider).shareText(
                    text: text.toString(),
                    subject: doc.name,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      shareSnackMessage(
                        outcome,
                        kind: l10n.shareKindDocumentSummary,
                        l10n: l10n,
                      ),
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!usePdfrx)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  labelText: l10n.searchLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () =>
                        setState(() => _query = _search.text.trim()),
                  ),
                ),
                onSubmitted: (v) => setState(() => _query = v.trim()),
              ),
            ),
          if (doc.kind == DocContentType.pdf && usePdfrx) ...[
            Expanded(child: _buildPdfrxViewer(pdfSource!)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.pdfrxViewerHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ] else if (doc.kind == DocContentType.pdf) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _pageIndex == 0
                        ? null
                        : () => setState(() => _pageIndex -= 1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    l10n.pageOfTotal(
                      _pageIndex + 1,
                      doc.pdfPages.isEmpty ? 1 : doc.pdfPages.length,
                    ),
                  ),
                  IconButton(
                    onPressed: doc.pdfPages.isEmpty ||
                            _pageIndex >= doc.pdfPages.length - 1
                        ? null
                        : () => setState(() => _pageIndex += 1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(
                      () => _scale = (_scale - 0.2).clamp(0.8, 2.5),
                    ),
                    icon: const Icon(Icons.zoom_out),
                  ),
                  IconButton(
                    onPressed: () => setState(
                      () => _scale = (_scale + 0.2).clamp(0.8, 2.5),
                    ),
                    icon: const Icon(Icons.zoom_in),
                  ),
                ],
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3,
                child: Transform.scale(
                  scale: _scale,
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: _highlightedText(
                      context,
                      doc.pdfPages.isEmpty
                          ? l10n.noPdfPreview
                          : doc.pdfPages[_pageIndex],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.textPdfPreviewHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ] else ...[
            Expanded(
              child: InteractiveViewer(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _highlightedText(
                    context,
                    doc.textContent ?? l10n.noPreviewForFileType,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPdfrxViewer(PdfOpenSource source) {
    switch (source.backend) {
      case PdfViewerBackend.pdfrxAsset:
        return PdfViewer.asset(source.assetPath!);
      case PdfViewerBackend.pdfrxFile:
        return PdfViewer.file(source.filePath!);
      case PdfViewerBackend.syntheticPages:
        return const SizedBox.shrink();
    }
  }

  Widget _highlightedText(BuildContext context, String body) {
    if (_query.isEmpty) {
      return SelectableText(body, style: Theme.of(context).textTheme.bodyLarge);
    }
    final lower = body.toLowerCase();
    final q = _query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final index = lower.indexOf(q, start);
      if (index < 0) {
        spans.add(TextSpan(text: body.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: body.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: body.substring(index, index + q.length),
          style: TextStyle(
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = index + q.length;
    }
    return SelectableText.rich(
      TextSpan(style: Theme.of(context).textTheme.bodyLarge, children: spans),
    );
  }
}
