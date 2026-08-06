import 'package:flutter_test/flutter_test.dart';

import 'package:construction_field_app/core/share/share_port.dart';
import 'package:construction_field_app/features/dpr/domain/dpr_models.dart';
import 'package:construction_field_app/features/digests/domain/digest_models.dart';

void main() {
  test('RecordingSharePort records text and subject', () async {
    final port = RecordingSharePort();
    final outcome = await port.shareText(
      text: 'hello',
      subject: 'subj',
    );
    expect(outcome.delivery, ShareDelivery.system);
    expect(port.shared, hasLength(1));
    expect(port.shared.single.text, 'hello');
    expect(port.shared.single.subject, 'subj');
  });

  test('shareSnackMessage distinguishes delivery', () {
    expect(
      shareSnackMessage(
        const ShareOutcome(delivery: ShareDelivery.system),
        kind: 'Digest',
      ),
      contains('share sheet'),
    );
    expect(
      shareSnackMessage(
        const ShareOutcome(delivery: ShareDelivery.clipboard),
        kind: 'DPR summary',
      ),
      contains('copied'),
    );
  });

  test('DPR and digest share text stay WhatsApp-friendly', () {
    final dpr = DailyProgressReport(
      id: 'd1',
      orgId: 'o',
      projectId: 'p',
      reportDate: DateTime.utc(2026, 8, 6),
      weather: 'Clear',
      manpowerSummary: '40',
      activities: const [
        DprActivity(id: 'a1', description: 'Pour', photoCount: 1),
      ],
      blockers: 'None',
      createdBy: 'u',
      createdByName: 'Asha',
      createdAt: DateTime.utc(2026, 8, 6),
      updatedAt: DateTime.utc(2026, 8, 6),
      submitted: true,
    );
    final dprText = dpr.toShareText(projectName: 'Pune Tower');
    expect(dprText, contains('DAILY PROGRESS REPORT'));
    expect(dprText, contains('Pune Tower'));

    final digest = PmDigestSnapshot(
      generatedAt: DateTime.utc(2026, 8, 6, 17),
      items: const [
        DigestItem(
          kind: DigestItemKind.openIssue,
          title: 'Crack',
          subtitle: 'Open',
        ),
      ],
      openIssueCount: 1,
      openRfiCount: 0,
      missingTodayDpr: false,
    );
    final digestText = digest.toShareText(projectName: 'Pune Tower');
    expect(digestText, contains('PM DIGEST'));
    expect(digestText, contains('Crack'));
  });
}
