import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/core/device/evidence_image_policy.dart';
import 'package:construction_field_app/core/device/local_media_cache.dart';
import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/issues/data/local_field_records_repository.dart';
import 'package:construction_field_app/features/issues/domain/issue_models.dart';
import 'package:construction_field_app/features/site_ops/data/local_site_ops_repository.dart';
import 'package:construction_field_app/features/site_ops/domain/site_ops_models.dart';
import 'package:construction_field_app/sync/local_sync_engine.dart';
import 'package:construction_field_app/sync/remote/storage_uploader.dart';
import 'package:construction_field_app/sync/sync_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalCacheEstimates', () {
    test('demo paths use policy demo size when byte size missing', () {
      expect(
        LocalCacheEstimates.bytesFor(localPath: 'local://x.jpg'),
        EvidenceImagePolicy.demoByteSize,
      );
      expect(
        LocalCacheEstimates.bytesFor(
          localPath: 'local://x.jpg',
          byteSizeBytes: 42,
        ),
        42,
      );
      expect(LocalCacheEstimates.bytesFor(localPath: null), 0);
    });

    test('only uploaded local:// stubs are reclaimable', () {
      expect(
        LocalCacheEstimates.isReclaimableLocalStub(
          localPath: 'local://a.jpg',
          remoteUrl: 'demo://storage/a.jpg',
        ),
        isTrue,
      );
      expect(
        LocalCacheEstimates.isReclaimableLocalStub(
          localPath: 'local://a.jpg',
          remoteUrl: null,
        ),
        isFalse,
      );
      expect(
        LocalCacheEstimates.isReclaimableLocalStub(
          localPath: '/tmp/a.jpg',
          remoteUrl: 'https://cdn/a.jpg',
        ),
        isFalse,
      );
    });

    test('snapshot usage ratio clamps against soft cap', () {
      final snap = LocalCacheSnapshot(
        slices: const [
          LocalCacheSlice(label: 'issues', estimatedBytes: 12 * 1024 * 1024),
        ],
        capBytes: SyncCleanupPolicy.softLocalBytesCap,
      );
      expect(snap.estimatedBytes, 12 * 1024 * 1024);
      expect(snap.usageRatio, 1.5);
      expect(snap.reclaimableBytes, 0);
    });
  });

  test('cleanup reclaims uploaded issue + site-ops local stubs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final field = LocalFieldRecordsRepository(prefs);
    final siteOps = LocalSiteOpsRepository(
      prefs,
      storageUploader: const NoOpStorageUploader(),
    );
    final engine = LocalSyncEngine(
      prefs: prefs,
      fieldRecords: field,
      moduleStores: [siteOps],
      mediaCaches: [field, siteOps],
    );
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    await field.createIssue(
      session: session,
      input: CreateIssueInput(
        title: 'Uploaded photo',
        description: '',
        attachments: [
          MediaAttachment(
            id: 'att1',
            fileName: 'pour.jpg',
            contentType: 'image/jpeg',
            localPath: 'local://demo/pour.jpg',
            remoteUrl: 'demo://storage/pour.jpg',
            pendingUpload: false,
            byteSizeBytes: 150 * 1024,
          ),
          MediaAttachment(
            id: 'att2',
            fileName: 'pending.jpg',
            contentType: 'image/jpeg',
            localPath: 'local://demo/pending.jpg',
            pendingUpload: true,
            byteSizeBytes: 100 * 1024,
          ),
        ],
      ),
    );

    await siteOps.addSafety(
      session: session,
      kind: SafetyKind.observation,
      title: 'Open edge',
      notes: '',
      photoLocalPath: 'local://demo/safety.jpg',
      photoByteSizeBytes: 120 * 1024,
    );
    await siteOps.flushOutbox(isOnline: true);

    final before = engine.estimateLocalCache();
    expect(before.estimatedBytes, greaterThan(0));
    expect(before.reclaimableBytes, greaterThan(0));
    expect(before.slices.map((s) => s.label), containsAll(['issues', 'site-ops']));

    final result = await engine.runStorageCleanup();
    expect(result.reclaimedMediaPaths, greaterThanOrEqualTo(2));
    expect(result.cacheBytesAfter, lessThan(result.cacheBytesBefore));

    final after = engine.estimateLocalCache();
    // Pending (not-yet-uploaded) issue stub remains; uploaded stubs cleared.
    expect(after.estimatedBytes, 100 * 1024);
    expect(after.reclaimableBytes, 0);

    final issue = (await field.watchIssues(session.activeProjectId).first).first;
    expect(
      issue.attachments.firstWhere((a) => a.id == 'att1').localPath,
      isNull,
    );
    expect(
      issue.attachments.firstWhere((a) => a.id == 'att2').localPath,
      'local://demo/pending.jpg',
    );

    final safety =
        (await siteOps.watchSafety(session.activeProjectId).first).first;
    expect(safety.photoRemoteUrl, startsWith('demo://'));
    expect(safety.photoLocalPath, isNull);
  });
}
