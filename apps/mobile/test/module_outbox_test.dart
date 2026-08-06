import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/documents/data/local_documents_repository.dart';
import 'package:construction_field_app/features/documents/domain/document_models.dart';
import 'package:construction_field_app/features/dpr/data/local_dpr_repository.dart';
import 'package:construction_field_app/features/dpr/domain/dpr_models.dart';
import 'package:construction_field_app/features/issues/data/local_field_records_repository.dart';
import 'package:construction_field_app/features/site_ops/data/local_site_ops_repository.dart';
import 'package:construction_field_app/features/site_ops/domain/site_ops_models.dart';
import 'package:construction_field_app/features/voice_notes/domain/voice_note_models.dart';
import 'package:construction_field_app/sync/local_sync_engine.dart';
import 'package:construction_field_app/sync/outbox/outbox_entry.dart';
import 'package:construction_field_app/sync/remote/module_remote_pull.dart';
import 'package:construction_field_app/sync/remote/outbox_remote_sink.dart';

class _RecordingSink implements OutboxRemoteSink {
  final applied = <OutboxEntry>[];

  @override
  Future<void> apply(OutboxEntry entry) async {
    applied.add(entry);
  }
}

class _StubModulePull implements ModuleRemotePull {
  _StubModulePull({this.dprs = const []});

  final List<DailyProgressReport> dprs;

  @override
  Future<List<DailyProgressReport>> pullDprs(String projectId) async =>
      dprs.where((d) => d.projectId == projectId).toList();

  @override
  Future<List<SafetyRecord>> pullSafety(String projectId) async => const [];

  @override
  Future<List<QaInspection>> pullInspections(String projectId) async =>
      const [];

  @override
  Future<List<LabourMuster>> pullMuster(String projectId) async => const [];

  @override
  Future<List<MaterialLog>> pullMaterials(String projectId) async => const [];

  @override
  Future<List<DocFolder>> pullFolders(String projectId) async => const [];

  @override
  Future<List<ProjectDocument>> pullDocuments(String projectId) async =>
      const [];

  @override
  Future<List<DrawingPin>> pullPins(String projectId) async => const [];

  @override
  Future<List<VoiceNote>> pullVoiceNotes(String projectId) async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DPR create enqueues outbox and flush marks synced', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sink = _RecordingSink();
    final dprRepo = LocalDprRepository(prefs, remoteSink: sink);
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    final dpr = await dprRepo.createOrUpdateToday(
      session: session,
      input: const CreateDprInput(
        weather: 'Clear',
        manpowerSummary: '12',
        activities: [
          DprActivity(id: 'a1', description: 'Formwork', hasPhoto: true),
        ],
        blockers: '',
      ),
    );
    expect(dpr.synced, isFalse);
    expect(await dprRepo.watchPendingSyncCount().first, 1);

    await dprRepo.flushOutbox(isOnline: true);
    expect(sink.applied, hasLength(1));
    expect(sink.applied.first.collection, 'dprs');
    expect(await dprRepo.watchPendingSyncCount().first, 0);
    final after = await dprRepo.todayDpr(session.activeProjectId, DateTime.now());
    expect(after!.synced, isTrue);
  });

  test('site ops + documents flush through sync engine', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sink = _RecordingSink();
    final field = LocalFieldRecordsRepository(prefs, remoteSink: sink);
    final dpr = LocalDprRepository(prefs, remoteSink: sink);
    final pins = LocalDrawingPinsRepository(prefs, remoteSink: sink);
    final ops = LocalSiteOpsRepository(prefs, remoteSink: sink);
    final docs = LocalDocumentsRepository(prefs, remoteSink: sink);
    final engine = LocalSyncEngine(
      prefs: prefs,
      fieldRecords: field,
      moduleStores: [dpr, pins, ops, docs],
    );
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    await ops.addSafety(
      session: session,
      kind: SafetyKind.toolboxTalk,
      title: 'Morning TBT',
      notes: 'PPE check',
    );
    await docs.ensureSeedData(session);
    final folders = await docs.watchFolders(session.activeProjectId).first;
    await docs.uploadDocument(
      session: session,
      input: UploadDocumentInput(
        folderId: folders.first.id,
        name: 'site-note.txt',
        contentType: 'text/plain',
        textContent: 'hello',
      ),
    );

    expect(await engine.totalPending(), greaterThanOrEqualTo(2));
    final flushed = await engine.flushNow(
      isOnline: true,
      projectId: session.activeProjectId,
    );
    expect(flushed, greaterThanOrEqualTo(2));
    expect(await engine.totalPending(), 0);
    expect(
      sink.applied.map((e) => e.collection),
      containsAll(['safety_records', 'documents']),
    );
  });

  test('DPR pullRemote merges newer remote report', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.utc(2026, 8, 6);
    final remote = DailyProgressReport(
      id: 'dpr_remote_1',
      orgId: 'org_demo',
      projectId: 'proj_pune_tower',
      reportDate: now,
      weather: 'Rain',
      manpowerSummary: '8',
      activities: const [],
      blockers: 'Access',
      createdBy: 'u_x',
      createdByName: 'Cloud',
      createdAt: now,
      updatedAt: now,
      submitted: true,
      synced: true,
    );
    final dprRepo = LocalDprRepository(
      prefs,
      remotePull: _StubModulePull(dprs: [remote]),
    );
    final pulled = await dprRepo.pullRemote(projectId: 'proj_pune_tower');
    expect(pulled, 1);
    final list = await dprRepo.watchDprs('proj_pune_tower').first;
    expect(list.any((d) => d.id == 'dpr_remote_1'), isTrue);
  });
}
