import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/client_progress/domain/weekly_progress_models.dart';
import '../../features/digests/domain/digest_models.dart';
import '../../features/dpr/domain/dpr_models.dart';
import '../../features/pilot/domain/pilot_models.dart';
import '../../l10n/app_localizations.dart';

/// Builds printable field PDFs for WhatsApp / email share (no Firebase).
///
/// Uses bundled Noto Sans (+ Devanagari fallback) so Hinglish ARB labels
/// render instead of Helvetica tofu boxes.
class FieldPdfExport {
  const FieldPdfExport._();

  static Future<pw.ThemeData>? _themeFuture;

  static Future<pw.ThemeData> _loadTheme() {
    return _themeFuture ??= () async {
      final regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
      );
      final bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
      );
      final devanagari = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf'),
      );
      return pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        fontFallback: [devanagari],
      );
    }();
  }

  /// Test-only: clear cached theme between cases if needed.
  static void debugResetTheme() {
    _themeFuture = null;
  }

  static Future<Uint8List> dpr({
    required DailyProgressReport report,
    required String projectName,
    required AppLocalizations l10n,
  }) async {
    final theme = await _loadTheme();
    final date = report.reportDate.toIso8601String().split('T').first;
    final doc = pw.Document(
      title: 'DPR $date — $projectName',
      author: report.createdByName,
      theme: theme,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              l10n.dprShareHeader,
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
            l10n.pdfPageOf(context.pageNumber, context.pagesCount),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          _kv(l10n.pdfDate, date),
          _kv(l10n.pdfBy, report.createdByName),
          _kv(
            l10n.pdfStatus,
            report.submitted ? l10n.submittedLabel : l10n.draftLabel,
          ),
          _kv(
            l10n.pdfWeather,
            report.weather.isEmpty ? '—' : report.weather,
          ),
          _kv(
            l10n.pdfManpower,
            report.manpowerSummary.isEmpty ? '—' : report.manpowerSummary,
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            l10n.pdfActivities,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (report.activities.isEmpty) pw.Text(l10n.pdfNoneRecorded),
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
                        '${a.location == null ? '' : l10n.dprShareLocationPart(a.location!)}'
                        '${a.photoCount == 0 ? '' : l10n.dprSharePhotoPart(a.photoCount)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          pw.SizedBox(height: 12),
          pw.Text(
            l10n.pdfBlockers,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(report.blockers.isEmpty ? l10n.noneLabel : report.blockers),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> digest({
    required PmDigestSnapshot digest,
    required String projectName,
    required AppLocalizations l10n,
  }) async {
    final theme = await _loadTheme();
    final generated = digest.generatedAt.toIso8601String();
    final doc = pw.Document(
      title: 'PM digest — $projectName',
      author: 'Construction Field App',
      theme: theme,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              l10n.pdfDigestTitle,
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
            l10n.pdfPageOf(context.pageNumber, context.pagesCount),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          _kv(l10n.pdfGenerated, generated),
          _kv(l10n.pdfOpenIssues, '${digest.openIssueCount}'),
          _kv(l10n.pdfOpenRfis, '${digest.openRfiCount}'),
          _kv(
            l10n.pdfTodayDpr,
            digest.missingTodayDpr
                ? l10n.pdfTodayDprMissing
                : l10n.pdfTodayDprOk,
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            l10n.pdfQueue,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (digest.items.isEmpty) pw.Text(l10n.queueIsClear),
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

  static Future<Uint8List> weekly({
    required WeeklyProgressSnapshot pack,
    required String projectName,
    required AppLocalizations l10n,
  }) async {
    final theme = await _loadTheme();
    final generated = pack.generatedAt.toIso8601String();
    final doc = pw.Document(
      title: 'Weekly progress — $projectName',
      author: 'Construction Field App',
      theme: theme,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              l10n.pdfWeeklyTitle,
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
            l10n.pdfPageOf(context.pageNumber, context.pagesCount),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          _kv(l10n.pdfWeek, pack.weekRangeLabel),
          _kv(l10n.pdfGenerated, generated),
          _kv(
            l10n.pdfSubmittedDprDays,
            l10n.pdfSubmittedDaysValue(pack.submittedDprDays),
          ),
          _kv(l10n.pdfOpenIssues, '${pack.openIssueCount}'),
          pw.SizedBox(height: 16),
          pw.Text(
            l10n.pdfDailyHighlights,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (pack.days.isEmpty) pw.Text(l10n.weeklyShareEmptyWeek),
          if (pack.days.isNotEmpty)
            ...pack.days.map(
              (day) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      day.dateLabel,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      l10n.pdfWeatherManpowerLine(
                        day.weather,
                        day.manpowerSummary,
                      ),
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                    ...day.activitySummaries.map(
                      (a) => pw.Text('- $a'),
                    ),
                    if (day.blockers != null)
                      pw.Text(
                        l10n.pdfBlockersLine(day.blockers!),
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.red700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (pack.openIssueTitles.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              l10n.openIssuesSection,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            ...pack.openIssueTitles.map((t) => pw.Text('- $t')),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> pilot({
    required PilotMetricsSnapshot snapshot,
    required String projectName,
    required AppLocalizations l10n,
  }) async {
    final theme = await _loadTheme();
    final generated = snapshot.generatedAt.toIso8601String();
    final rate = snapshot.syncFailureRate;
    final rateLabel = rate == null
        ? l10n.pdfNa
        : '${(rate * 100).toStringAsFixed(1)}%';
    final doc = pw.Document(
      title: 'Pilot snapshot — $projectName',
      author: 'Construction Field App',
      theme: theme,
    );

    String statusOkBelow(bool? met, {required int needSamples}) {
      return switch (met) {
        true => l10n.pilotStatusOk,
        false => l10n.pilotStatusBelow,
        null => l10n.pilotStatusNeedSamples(needSamples),
      };
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              l10n.pdfPilotTitle,
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
            l10n.pdfPageOf(context.pageNumber, context.pagesCount),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          _kv(l10n.pdfGenerated, generated),
          _kv(
            l10n.pdfDprDays,
            l10n.pdfDprDaysValue(
              snapshot.dprSubmittedDaysThisWeek,
              snapshot.dprTargetMet ? l10n.pilotStatusOk : l10n.pilotStatusBelow,
            ),
          ),
          _kv(
            l10n.pdfDprSubmit,
            l10n.pdfMedianValue(
              snapshot.dprSubmitMedianLabel,
              snapshot.dprSubmitSampleCount,
              '<3m',
              statusOkBelow(
                snapshot.dprSubmitTargetMet,
                needSamples: PilotMetricsSnapshot.dprSubmitMinSamples,
              ),
            ),
          ),
          _kv(
            l10n.pdfIssueCreate,
            l10n.pdfMedianValue(
              snapshot.issueCreateMedianLabel,
              snapshot.issueCreateSampleCount,
              '<90s',
              statusOkBelow(
                snapshot.issueCreateTargetMet,
                needSamples: PilotMetricsSnapshot.issueCreateMinSamples,
              ),
            ),
          ),
          _kv(l10n.pdfOpenIssues, '${snapshot.openIssueCount}'),
          _kv(l10n.pdfPendingSync, '${snapshot.pendingSyncCount}'),
          _kv(
            l10n.pdfSyncErrors,
            l10n.pdfSyncErrorsLine(
              snapshot.syncErrorCount,
              snapshot.syncLogCount,
              rateLabel,
              snapshot.syncTargetMet
                  ? l10n.pilotStatusOk
                  : l10n.pilotStatusWatch,
            ),
          ),
          _kv(
            l10n.pdfUatChecklist,
            l10n.pdfCountOfTotal(
              snapshot.checklistCompleted,
              snapshot.checklistTotal,
            ),
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
