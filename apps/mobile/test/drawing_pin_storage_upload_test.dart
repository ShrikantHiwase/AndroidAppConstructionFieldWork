import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/auth/domain/auth_models.dart';
import 'package:construction_field_app/features/dpr/data/local_dpr_repository.dart';
import 'package:construction_field_app/features/dpr/domain/dpr_models.dart';
import 'package:construction_field_app/features/issues/data/local_field_records_repository.dart';
import 'package:construction_field_app/features/issues/domain/issue_models.dart';
import 'package:construction_field_app/sync/outbox/outbox_entry.dart';
import 'package:construction_field_app/sync/remote/outbox_remote_sink.dart';
import 'package:construction_field_app/sync/remote/storage_uploader.dart';

class _RecordingSink implements OutboxRemoteSink {
  final applied = <OutboxEntry>[];

  @override
  Future<void> apply(OutboxEntry entry) async {
    applied.add(entry);
  }
}

class _RecordingUploader implements StorageUploader {
  final uploads = <StorageUploadRequest>[];

  @override
  Future<String> upload(StorageUploadRequest request) async {
    uploads.add(request);
    return 'https://example.test/${request.storagePath}';
  }
}

class _FailingUploader implements StorageUploader {
  @override
  Future<String> upload(StorageUploadRequest request) async {
    throw StateError('storage down');
  }
}

class _PinCtx {
  _PinCtx({
    required this.session,
    required this.repo,
    required this.issue,
  });

  final AuthSession session;
  final LocalDrawingPinsRepository repo;
  final Issue issue;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_PinCtx> seed({
    OutboxRemoteSink? sink,
    StorageUploader? uploader,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    final issues = LocalFieldRecordsRepository(prefs);
    final issue = await issues.createIssue(
      session: session,
      input: const CreateIssueInput(title: 'Crack at grid B', description: ''),
    );
    final repo = LocalDrawingPinsRepository(
      prefs,
      remoteSink: sink,
      storageUploader: uploader,
    );
    await repo.ensureSeedDrawings(session);
    return _PinCtx(session: session, repo: repo, issue: issue);
  }

  test('pin photo enqueues upload then create; flush sets remoteUrl', () async {
    final sink = _RecordingSink();
    final uploader = _RecordingUploader();
    final ctx = await seed(sink: sink, uploader: uploader);
    final sheet =
        (await ctx.repo.watchDrawings(ctx.session.activeProjectId).first)
            .single;

    final pin = await ctx.repo.addPin(
      session: ctx.session,
      input: CreatePinInput(
        drawingId: sheet.id,
        page: 1,
        x: 0.4,
        y: 0.5,
        issueId: ctx.issue.id,
        issueTitle: ctx.issue.title,
        photoLocalPath: 'local://demo/pin.jpg',
        photoByteSizeBytes: 150 * 1024,
      ),
    );
    expect(pin.pendingPhotoUpload, isTrue);
    expect(pin.hasPhoto, isTrue);
    expect(await ctx.repo.watchPendingSyncCount().first, 2);

    await ctx.repo.flushOutbox(isOnline: true);
    expect(uploader.uploads, hasLength(1));
    expect(
      uploader.uploads.first.storagePath,
      contains('drawing_pins/${pin.id}/'),
    );
    expect(sink.applied, hasLength(1));
    expect(sink.applied.first.operation, OutboxOperation.create);
    expect(sink.applied.first.payload['photoRemoteUrl'], contains('https://'));
    expect(sink.applied.first.payload['pendingPhotoUpload'], isFalse);

    final saved = (await ctx.repo.watchPins(sheet.id).first)
        .firstWhere((p) => p.id == pin.id);
    expect(saved.photoRemoteUrl, startsWith('https://'));
    expect(saved.pendingPhotoUpload, isFalse);
    expect(await ctx.repo.watchPendingSyncCount().first, 0);
  });

  test('failed pin upload keeps create in outbox', () async {
    final sink = _RecordingSink();
    final ctx = await seed(sink: sink, uploader: _FailingUploader());
    final sheet =
        (await ctx.repo.watchDrawings(ctx.session.activeProjectId).first)
            .single;

    await ctx.repo.addPin(
      session: ctx.session,
      input: CreatePinInput(
        drawingId: sheet.id,
        page: 1,
        x: 0.2,
        y: 0.3,
        issueId: ctx.issue.id,
        issueTitle: ctx.issue.title,
        photoLocalPath: 'local://demo/pin_fail.jpg',
      ),
    );
    await ctx.repo.flushOutbox(isOnline: true);
    expect(sink.applied, isEmpty);
    expect(await ctx.repo.watchPendingSyncCount().first, greaterThan(0));
  });

  test('pin without photo enqueues create only', () async {
    final sink = _RecordingSink();
    final uploader = _RecordingUploader();
    final ctx = await seed(sink: sink, uploader: uploader);
    final sheet =
        (await ctx.repo.watchDrawings(ctx.session.activeProjectId).first)
            .single;

    final pin = await ctx.repo.addPin(
      session: ctx.session,
      input: CreatePinInput(
        drawingId: sheet.id,
        page: 1,
        x: 0.1,
        y: 0.1,
        issueId: ctx.issue.id,
        issueTitle: ctx.issue.title,
      ),
    );
    expect(pin.hasPhoto, isFalse);
    expect(await ctx.repo.watchPendingSyncCount().first, 1);

    await ctx.repo.flushOutbox(isOnline: true);
    expect(uploader.uploads, isEmpty);
    expect(sink.applied.single.operation, OutboxOperation.create);
  });
}
