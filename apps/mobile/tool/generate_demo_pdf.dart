import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Regenerates [assets/demo/ga_plan_level_02.pdf] for the seeded Documents viewer.
Future<void> main() async {
  final doc = pw.Document(
    title: 'GA Plan Level 02',
    author: 'Construction Field App',
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Text(
          'GA PLAN - LEVEL 02',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Grid A-F · Scale 1:100'),
        pw.Text('North arrow toward site gate.'),
        pw.Text('Opening schedules referenced on sheet S-201.'),
        pw.SizedBox(height: 24),
        pw.Container(
          height: 280,
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          alignment: pw.Alignment.center,
          child: pw.Text('Plan sheet preview (demo)'),
        ),
      ],
    ),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Text(
          'SECTION A-A',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Beam B2: 300x600'),
        pw.Text('Slab thickness 150mm'),
        pw.Text('Note: hold pour until QA sign-off.'),
      ],
    ),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Text(
          'REVISION LOG',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Rev A - IFC issued'),
        pw.Text('Rev B - beam depth updated'),
        pw.Text('Search tip: look for B2 or QA in viewer search.'),
      ],
    ),
  );

  final out = File('assets/demo/ga_plan_level_02.pdf');
  await out.parent.create(recursive: true);
  final bytes = await doc.save();
  await out.writeAsBytes(bytes);
  // ignore: avoid_print
  print('Wrote ${out.path} (${bytes.length} bytes)');
}
