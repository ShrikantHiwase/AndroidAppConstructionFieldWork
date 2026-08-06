import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/share/share_port.dart';
import '../domain/document_models.dart';
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final doc = _doc;
    if (doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document')),
        body: const Center(child: Text('Document not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.name),
        actions: [
          if (!doc.downloaded)
            IconButton(
              tooltip: 'Download',
              onPressed: () async {
                final updated = await ref
                    .read(documentsRepositoryProvider)
                    .markDownloaded(doc.id);
                if (mounted) setState(() => _doc = updated);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved on device')),
                  );
                }
              },
              icon: const Icon(Icons.download_outlined),
            ),
          IconButton(
            tooltip: 'Share document summary',
            onPressed: () async {
              final doc = _doc;
              if (doc == null) return;
              final text = StringBuffer()
                ..writeln(doc.name)
                ..writeln('Type: ${doc.contentType}')
                ..writeln(
                  doc.remoteUrl == null
                      ? (doc.localFilePath ?? 'On device / demo local path')
                      : 'URL: ${doc.remoteUrl}',
                );
              final outcome = await ref.read(sharePortProvider).shareText(
                    text: text.toString(),
                    subject: doc.name,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      shareSnackMessage(outcome, kind: 'Document summary'),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                labelText: 'Search',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _query = _search.text.trim()),
                ),
              ),
              onSubmitted: (v) => setState(() => _query = v.trim()),
            ),
          ),
          if (doc.kind == DocContentType.pdf) ...[
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
                  Text('Page ${_pageIndex + 1} / ${doc.pdfPages.length}'),
                  IconButton(
                    onPressed: _pageIndex >= doc.pdfPages.length - 1
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
                          ? 'Empty PDF'
                          : doc.pdfPages[_pageIndex],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Demo PDF pages — replace with pdfrx when Storage is live.',
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
                    doc.textContent ??
                        'No preview available for this file type.',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
