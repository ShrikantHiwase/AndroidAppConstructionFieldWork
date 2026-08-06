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
      hasPhoto: true,
    );
    expect(obs.hasPhoto, isTrue);
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
        ),
      ],
    );
    expect(ok.hasFailures, isTrue);
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
}
