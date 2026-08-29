import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/site_ops/data/local_site_ops_repository.dart';
import 'package:construction_field_app/features/site_ops/domain/site_ops_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalSiteOpsRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = LocalSiteOpsRepository(prefs);
  });

  test('safety observation requires photo; toolbox does not', () async {
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    expect(
      () => repo.addSafety(
        session: session,
        kind: SafetyKind.observation,
        title: 'Open edge',
        notes: 'Missing rail',
      ),
      throwsA(isA<SiteOpsException>()),
    );

    final talk = await repo.addSafety(
      session: session,
      kind: SafetyKind.toolboxTalk,
      title: 'Morning toolbox',
      notes: 'PPE check',
    );
    expect(talk.kind, SafetyKind.toolboxTalk);

    final obs = await repo.addSafety(
      session: session,
      kind: SafetyKind.observation,
      title: 'Open edge',
      notes: 'Missing rail',
      photoLocalPath: 'local://demo/safety_obs.jpg',
      photoByteSizeBytes: 150 * 1024,
    );
    expect(obs.hasPhoto, isTrue);
    expect(obs.photoLocalPath, startsWith('local://'));
    expect(obs.photoByteSizeBytes, 150 * 1024);
  });

  test('QA fail without photo is rejected', () async {
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    final qa = await auth.signInWithEmail(
      email: 'qa@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    expect(
      () => repo.addInspection(
        session: qa,
        title: 'WIR',
        items: const [
          InspectionItem(
            id: '1',
            label: 'Cover',
            result: InspectionResult.fail,
          ),
        ],
      ),
      throwsA(isA<SiteOpsException>()),
    );

    final ok = await repo.addInspection(
      session: qa,
      title: 'WIR',
      items: const [
        InspectionItem(
          id: '1',
          label: 'Cover',
          result: InspectionResult.fail,
          hasPhoto: true,
          photoLocalPath: 'local://demo/qa_fail.jpg',
          photoByteSizeBytes: 120 * 1024,
        ),
      ],
    );
    expect(ok.hasFailures, isTrue);
    expect(ok.items.single.photoByteSizeBytes, 120 * 1024);
  });

  test('labour muster and material inward', () async {
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'pm@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    final muster = await repo.addMuster(
      session: session,
      trade: 'Civil',
      subcontractor: 'ABC',
      headcount: 12,
    );
    expect(muster.geofenceOk, isTrue);

    final mat = await repo.addMaterial(
      session: session,
      kind: MaterialLogKind.consumption,
      material: 'Cement',
      quantity: 40,
      unit: 'bags',
      activityRef: 'Columns',
    );
    expect(mat.kind, MaterialLogKind.consumption);
  });

  test('client cannot mutate site ops', () async {
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    final client = await auth.signInWithEmail(
      email: 'client@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    expect(
      () => repo.addMuster(
        session: client,
        trade: 'x',
        subcontractor: 'y',
        headcount: 1,
      ),
      throwsA(isA<SiteOpsException>()),
    );
  });

  test('ensureSeedSiteOps fills Pune tabs without outbox', () async {
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    final engineer = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    await repo.ensureSeedSiteOps(engineer);

    final safety = await repo.watchSafety(engineer.activeProjectId).first;
    final inspections =
        await repo.watchInspections(engineer.activeProjectId).first;
    final muster = await repo.watchMuster(engineer.activeProjectId).first;
    final materials =
        await repo.watchMaterials(engineer.activeProjectId).first;

    expect(safety, hasLength(2));
    expect(
      safety.map((s) => s.id),
      containsAll(['safety_seed_observation', 'safety_seed_toolbox']),
    );
    final observation =
        safety.firstWhere((s) => s.id == 'safety_seed_observation');
    expect(observation.title, contains('edge protection'));
    expect(observation.hasPhoto, isTrue);
    expect(observation.photoRemoteUrl, 'demo://seed/safety-edge.jpg');
    expect(observation.synced, isTrue);
    final toolbox = safety.firstWhere((s) => s.id == 'safety_seed_toolbox');
    expect(toolbox.kind, SafetyKind.toolboxTalk);
    expect(toolbox.hasPhoto, isFalse);
    expect(toolbox.synced, isTrue);

    expect(inspections, hasLength(1));
    expect(inspections.single.id, 'insp_seed_slab');
    expect(inspections.single.title, contains('pre-pour'));
    expect(inspections.single.hasFailures, isTrue);
    final failItem =
        inspections.single.items.firstWhere((i) => i.id == 'insp_item_2');
    expect(failItem.hasPhoto, isTrue);
    expect(failItem.photoRemoteUrl, 'demo://seed/qa-formwork.jpg');
    expect(inspections.single.synced, isTrue);

    expect(muster, hasLength(1));
    expect(muster.single.id, 'muster_seed_bar');
    expect(muster.single.trade, 'Bar bending');
    expect(muster.single.headcount, 14);
    expect(muster.single.synced, isTrue);

    expect(materials, hasLength(1));
    expect(materials.single.id, 'mat_seed_cement');
    expect(materials.single.material, 'OPC 53');
    expect(materials.single.quantity, 200);
    expect(materials.single.synced, isTrue);

    expect(await repo.watchPendingSyncCount().first, 0);

    await repo.ensureSeedSiteOps(engineer);
    expect(await repo.watchSafety(engineer.activeProjectId).first, hasLength(2));
    expect(
      await repo.watchInspections(engineer.activeProjectId).first,
      hasLength(1),
    );
  });
}
