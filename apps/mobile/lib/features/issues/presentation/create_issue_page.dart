import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/connectivity_provider.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/issue_models.dart';
import 'field_records_providers.dart';

class CreateIssuePage extends ConsumerStatefulWidget {
  const CreateIssuePage({super.key});

  @override
  ConsumerState<CreateIssuePage> createState() => _CreateIssuePageState();
}

class _CreateIssuePageState extends ConsumerState<CreateIssuePage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  GeoLocation? _location;
  final _attachments = <MediaAttachment>[];
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final session = ref.read(authSessionProvider);
    if (session == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(fieldRecordsRepositoryProvider).createIssue(
            session: session,
            input: CreateIssueInput(
              title: _title.text,
              description: _description.text,
              location: _location,
              attachments: List.of(_attachments),
            ),
          );
      final offline = ref.read(isOfflineProvider);
      if (!offline) {
        await ref
            .read(fieldRecordsRepositoryProvider)
            .flushOutbox(isOnline: true);
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
      appBar: AppBar(title: const Text('New Issue')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Evidence', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _location = const GeoLocation(
                      latitude: 18.5912,
                      longitude: 73.7389,
                      accuracyMeters: 8,
                      label: 'Demo GPS · Hinjewadi',
                    );
                  });
                },
                icon: const Icon(Icons.my_location),
                label: Text(_location == null ? 'Add demo GPS' : 'Refresh GPS'),
              ),
              if (_location != null)
                TextButton(
                  onPressed: () => setState(() => _location = null),
                  child: const Text('Clear GPS'),
                ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _attachments.add(
                      MediaAttachment(
                        id: 'media_${_attachments.length + 1}',
                        fileName:
                            'site_photo_${_attachments.length + 1}.jpg',
                        contentType: 'image/jpeg',
                        localPath:
                            'local://demo/site_photo_${_attachments.length + 1}.jpg',
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Add demo photo'),
              ),
            ],
          ),
          if (_location != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_location!.label ?? 'GPS'}: '
              '${_location!.latitude.toStringAsFixed(5)}, '
              '${_location!.longitude.toStringAsFixed(5)}',
            ),
          ],
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._attachments.map(
              (a) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.image_outlined),
                title: Text(a.fileName),
                subtitle:
                    Text(a.pendingUpload ? 'Queued for upload' : 'Uploaded'),
              ),
            ),
          ],
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
                : const Text('Save issue'),
          ),
          const SizedBox(height: 8),
          Text(
            'Saves offline immediately; syncs when online.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
