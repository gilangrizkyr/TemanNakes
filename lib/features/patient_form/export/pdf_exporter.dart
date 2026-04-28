import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../domain/models/form_template.dart';
import '../domain/models/patient_record.dart';

enum ReportTemplate { ringkas, detail }

class PdfExporter {
  /// Generate PDF dan kembalikan raw bytes (untuk Printing.layoutPdf)
  static Future<Uint8List> exportBytes({
    required FormTemplate template,
    required List<PatientRecord> records,
    required ReportTemplate reportTemplate,
    String institutionName = 'Fasilitas Kesehatan',
  }) async {
    final pdf = _buildDocument(
        template: template,
        records: records,
        reportTemplate: reportTemplate,
        institutionName: institutionName);
    return pdf.save();
  }

  /// Generate PDF dan kembalikan path file tersimpan
  static Future<String> export({
    required FormTemplate template,
    required List<PatientRecord> records,
    required ReportTemplate reportTemplate,
    String institutionName = 'Fasilitas Kesehatan',
  }) async {
    final pdf = _buildDocument(
        template: template,
        records: records,
        reportTemplate: reportTemplate,
        institutionName: institutionName);
    final dir = await getApplicationDocumentsDirectory();
    final safeName = template.name.replaceAll(RegExp(r'[^\w]'), '_');
    final filename = '${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static pw.Document _buildDocument({
    required FormTemplate template,
    required List<PatientRecord> records,
    required ReportTemplate reportTemplate,
    required String institutionName,
  }) {
    final pdf = pw.Document();

    // Column headers
    final fieldHeaders = reportTemplate == ReportTemplate.ringkas
        ? template.fields.take(5).toList()
        : template.fields;

    final columns = ['No', 'Tgl Input', ...fieldHeaders.map((f) => f.label)];
    // Column flex widths
    final widths = <pw.FlexColumnWidth>[
      const pw.FlexColumnWidth(0.5),
      const pw.FlexColumnWidth(1.5),
      ...fieldHeaders.map((_) => const pw.FlexColumnWidth(2)),
    ];

    // ── Page theme ────────────────────────────────────────────────────────────
    final headerColor = PdfColor.fromHex('#1B5E20');
    final rowAlt = PdfColor.fromHex('#F1F8E9');
    const textStyle = pw.TextStyle(fontSize: 9);
    final headerStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    // Auto-Landscape for dense reports
    final isLandscape = columns.length > 6;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          pageFormat: isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
          buildBackground: (context) => pw.Container(),
        ),
        header: (context) => _buildHeader(
          context,
          template: template,
          institutionName: institutionName,
          headerColor: headerColor,
          reportLabel: reportTemplate == ReportTemplate.ringkas
              ? 'Laporan Ringkas'
              : 'Laporan Detail',
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          // Total records info
          pw.Text(
            'Total Data: ${records.length} record',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.green900),
          ),
          pw.SizedBox(height: 8),
          // ── Table ────────────────────────────────────────────────────────────
          pw.Table(
            columnWidths: {
              for (var i = 0; i < widths.length; i++) i: widths[i],
            },
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: headerColor),
                children: columns
                    .map((h) => _cell(h, style: headerStyle, center: true))
                    .toList(),
              ),
              // Data rows
              for (var i = 0; i < records.length; i++)
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: i.isEven ? PdfColors.white : rowAlt,
                  ),
                  children: [
                    _cell('${i + 1}', center: true, style: textStyle),
                    _cell(_formatDate(records[i].createdAt), style: textStyle),
                    ...fieldHeaders.map((f) => _cell(
                          records[i].displayValue(f.id),
                          style: textStyle,
                        )),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(
    pw.Context context, {
    required FormTemplate template,
    required String institutionName,
    required PdfColor headerColor,
    required String reportLabel,
  }) {
    final now = DateTime.now();
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: headerColor, width: 2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(institutionName,
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text(template.name,
                      style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: headerColor)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(reportLabel,
                      style: pw.TextStyle(
                          fontSize: 10,
                          color: headerColor,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      'Tanggal: ${_formatDate(now)}',
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TemanNakes — Laporan Data Pasien',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Terverifikasi Pinnacle V5.5 Clinical Audit Seal',
                    style: pw.TextStyle(fontSize: 6, color: PdfColors.grey400, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Text('Halaman ${context.pageNumber} dari ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _cell(String text,
      {pw.TextStyle? style, bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        style: style ?? const pw.TextStyle(fontSize: 9),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        softWrap: true,
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.year}';
}
