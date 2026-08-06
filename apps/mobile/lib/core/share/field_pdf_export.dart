import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/digests/domain/digest_models.dart';
import '../../features/dpr/domain/dpr_models.dart';
import '../../features/pilot/domain/pilot_models.dart';

/// Builds printable field PDFs for WhatsApp / email share (no Firebase).
class FieldPdfExport {
  const FieldPdfExport._();

  static Future<Uint8List> dpr({
    required DailyProgressReport report,
    required String projectName,
  }) async {
    final date = report.reportDate.toIso8601String().split('T').first;
    final doc = pw.Document(
      title: 'DPR $date — $projectName',
      author: report.createdByName,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'DAILY PROGRESS REPORT',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              projectName,
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          _kv('Date', date),
          _kv('By', report.createdByName),
          _kv('Status', report.submitted ? 'Submitted' : 'Draft'),
          _kv('Weather', report.weather.isEmpty ? '—' : report.weather),
          _kv(
            'Manpower',
            report.manpowerSummary.isEmpty ? '—' : report.manpowerSummary,
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Activities',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (report.activities.isEmpty) pw.Text('None recorded.'),
          if (report.activities.isNotEmpty)
            ...report.activities.map(
              (a) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('-  '),
                    pw.Expanded(
                      child: pw.Text(
                        '${a.description}'
                        '${a.location == null ? '' : ' @ ${a.location}'}'
                        '${a.photoCount == 0 ? '' : ' (${a.photoCount} photo)'}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Blockers',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(report.blockers.isEmpty ? 'None' : report.blockers),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> digest({
    required PmDigestSnapshot digest,
    required String projectName,
  }) async {
    final generated = digest.generatedAt.toIso8601String();
    final doc = pw.Document(
      title: 'PM digest — $projectName',
      author: 'Construction Field App',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'PM DIGEST',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              projectName,
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          _kv('Generated', generated),
          _kv('Open issues', '${digest.openIssueCount}'),
          _kv('Open RFIs', '${digest.openRfiCount}'),
          _kv(
            'Today DPR',
            digest.missingTodayDpr ? 'missing / not submitted' : 'ok',
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Queue',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (digest.items.isEmpty) pw.Text('Queue is clear.'),
          if (digest.items.isNotEmpty)
            ...digest.items.map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.title,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      item.subtitle,
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> pilot({
    required PilotMetricsSnapshot snapshot,
    required String projectName,
  }) async {
    final generated = snapshot.generatedAt.toIso8601String();
    final rate = snapshot.syncFailureRate;
    final rateLabel = rate == null
        ? 'n/a'
        : '${(rate * 100).toStringAsFixed(1)}%';
    final doc = pw.Document(
      title: 'Pilot snapshot — $projectName',
      author: 'Construction Field App',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'PILOT / HYPERCARE',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              projectName,
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          _kv('Generated', generated),
          _kv(
            'DPR days',
            '${snapshot.dprSubmittedDaysThisWeek} (target >=4) '
            '${snapshot.dprTargetMet ? 'OK' : 'BELOW'}',
          ),
          _kv('Open issues', '${snapshot.openIssueCount}'),
          _kv('Pending sync', '${snapshot.pendingSyncCount}'),
          _kv(
            'Sync errors',
            '${snapshot.syncErrorCount} / ${snapshot.syncLogCount} '
            '($rateLabel, target <2%) '
            '${snapshot.syncTargetMet ? 'OK' : 'WATCH'}',
          ),
          _kv(
            'UAT checklist',
            '${snapshot.checklistCompleted} / ${snapshot.checklistTotal}',
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _kv(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }
}
