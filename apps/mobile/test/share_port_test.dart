import 'package:flutter_test/flutter_test.dart';

import 'package:construction_field_app/core/share/field_pdf_export.dart';
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

  test('RecordingSharePort records PDF file shares', () async {
    final port = RecordingSharePort();
    final bytes = await FieldPdfExport.dpr(
      report: _sampleDpr(),
      projectName: 'Pune Tower',
    );
    final outcome = await port.shareFile(
      bytes: bytes,
      filename: 'dpr_2026-08-06.pdf',
      subject: 'DPR',
      fallbackText: 'fallback',
    );
    expect(outcome.delivery, ShareDelivery.system);
    expect(port.sharedFiles, hasLength(1));
    expect(port.sharedFiles.single.filename, 'dpr_2026-08-06.pdf');
    expect(port.sharedFiles.single.byteLength, greaterThan(100));
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
    final dprText = _sampleDpr().toShareText(projectName: 'Pune Tower');
    expect(dprText, contains('DAILY PROGRESS REPORT'));
    expect(dprText, contains('Pune Tower'));

    final digestText = _sampleDigest().toShareText(projectName: 'Pune Tower');
    expect(digestText, contains('PM DIGEST'));
    expect(digestText, contains('Crack'));
  });

  test('FieldPdfExport builds non-empty DPR and digest PDFs', () async {
    final dprBytes = await FieldPdfExport.dpr(
      report: _sampleDpr(),
      projectName: 'Pune Tower',
    );
    expect(dprBytes.length, greaterThan(200));
    // PDF magic header
    expect(String.fromCharCodes(dprBytes.take(4)), '%PDF');

    final digestBytes = await FieldPdfExport.digest(
      digest: _sampleDigest(),
      projectName: 'Pune Tower',
    );
    expect(digestBytes.length, greaterThan(200));
    expect(String.fromCharCodes(digestBytes.take(4)), '%PDF');
  });
}

DailyProgressReport _sampleDpr() {
  return DailyProgressReport(
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
}

PmDigestSnapshot _sampleDigest() {
  return PmDigestSnapshot(
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
}
