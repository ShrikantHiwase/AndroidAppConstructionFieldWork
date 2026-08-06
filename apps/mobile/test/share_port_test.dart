import 'package:flutter_test/flutter_test.dart';

import 'package:construction_field_app/core/share/field_pdf_export.dart';
import 'package:construction_field_app/core/share/share_port.dart';
import 'package:construction_field_app/features/client_progress/domain/weekly_progress_models.dart';
import 'package:construction_field_app/features/dpr/domain/dpr_models.dart';
import 'package:construction_field_app/features/digests/domain/digest_models.dart';
import 'package:construction_field_app/features/pilot/domain/pilot_models.dart';

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

  test('DPR, digest, and weekly share text stay WhatsApp-friendly', () {
    final dprText = _sampleDpr().toShareText(projectName: 'Pune Tower');
    expect(dprText, contains('DAILY PROGRESS REPORT'));
    expect(dprText, contains('Pune Tower'));

    final digestText = _sampleDigest().toShareText(projectName: 'Pune Tower');
    expect(digestText, contains('PM DIGEST'));
    expect(digestText, contains('Crack'));

    final weeklyText = _sampleWeekly().toShareText(projectName: 'Pune Tower');
    expect(weeklyText, contains('WEEKLY PROGRESS'));
    expect(weeklyText, contains('Slab pour'));
  });

  test('FieldPdfExport builds non-empty DPR, digest, pilot, weekly PDFs',
      () async {
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

    final pilotBytes = await FieldPdfExport.pilot(
      snapshot: _samplePilot(),
      projectName: 'Pune Tower',
    );
    expect(pilotBytes.length, greaterThan(200));
    expect(String.fromCharCodes(pilotBytes.take(4)), '%PDF');

    final weeklyBytes = await FieldPdfExport.weekly(
      pack: _sampleWeekly(),
      projectName: 'Pune Tower',
    );
    expect(weeklyBytes.length, greaterThan(200));
    expect(String.fromCharCodes(weeklyBytes.take(4)), '%PDF');

    final port = RecordingSharePort();
    await port.shareFile(
      bytes: weeklyBytes,
      filename: 'weekly_progress_2026-08-03.pdf',
      subject: 'Weekly',
    );
    expect(port.sharedFiles.single.filename, 'weekly_progress_2026-08-03.pdf');
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
      DprActivity(id: 'a1', description: 'Pour', hasPhoto: true),
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

PilotMetricsSnapshot _samplePilot() {
  return PilotMetricsSnapshot(
    generatedAt: DateTime.utc(2026, 8, 6, 17),
    projectId: 'p',
    dprSubmittedDaysThisWeek: 3,
    openIssueCount: 2,
    pendingSyncCount: 0,
    syncLogCount: 10,
    syncErrorCount: 0,
    checklistCompleted: 4,
    checklistTotal: 12,
    issueCreateSampleCount: 3,
    issueCreateMedianMs: 55000,
    dprSubmitSampleCount: 3,
    dprSubmitMedianMs: 100000,
  );
}

WeeklyProgressSnapshot _sampleWeekly() {
  return WeeklyProgressSnapshot(
    generatedAt: DateTime.utc(2026, 8, 6, 17),
    weekStart: DateTime(2026, 8, 3),
    weekEndExclusive: DateTime(2026, 8, 10),
    submittedDprDays: 1,
    days: [
      WeeklyProgressDayLine(
        reportDate: DateTime(2026, 8, 4),
        weather: 'Clear',
        manpowerSummary: '40',
        activitySummaries: const ['Slab pour @ L3'],
        blockers: 'Crane delay',
      ),
    ],
    openIssueCount: 1,
    openIssueTitles: const ['Crack (Open)'],
    weekBlockers: const ['2026-08-04: Crane delay'],
  );
}
