import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/servis_model.dart';
import '../../utils/report_data_helper.dart';

class ServiceReportPdf {
  static Future<void> preview({
    required ServisModel servis,
  }) async {
    final bytes = await generate(
      servis: servis,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'laporan-servis-${servis.id}.pdf',
    );
  }

  static Future<Uint8List> generate({
    required ServisModel servis,
  }) async {
    final pdf = pw.Document();

    final logoBytes = await _loadLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _header(
          logoBytes,
        ),
        footer: (context) => _footer(
          context,
        ),
        build: (context) {
          return [
            _serviceHeader(servis),

            pw.SizedBox(height: 20),

            _summary(servis),

            pw.SizedBox(height: 24),

            pw.Text(
              'DAFTAR UNIT AC',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 12),

            ...List.generate(
              servis.itemsData.length,
                  (index) {
                return _acItem(
                  index + 1,
                  servis.itemsData[index],
                );
              },
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List?> _loadLogo() async {
    try {
      final data = await rootBundle.load(
        'assets/logo.png',
      );

      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _header(
      Uint8List? logoBytes,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(
        bottom: 12,
      ),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey400,
          ),
        ),
      ),
      child: pw.Row(
        children: [
          if (logoBytes != null)
            pw.Image(
              pw.MemoryImage(logoBytes),
              width: 42,
              height: 42,
            ),

          if (logoBytes != null)
            pw.SizedBox(width: 12),

          pw.Column(
            crossAxisAlignment:
            pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RIDHO TEKNIK',
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Laporan Pekerjaan Servis AC',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(
      pw.Context context,
      ) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(
        top: 10,
      ),
      child: pw.Text(
        'Halaman ${context.pageNumber} dari '
            '${context.pagesCount}',
        style: const pw.TextStyle(
          fontSize: 8,
          color: PdfColors.grey600,
        ),
      ),
    );
  }

  static pw.Widget _serviceHeader(
      ServisModel servis,
      ) {
    return pw.Column(
      crossAxisAlignment:
      pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 16),

        pw.Text(
          'LAPORAN SERVIS AC',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),

        pw.SizedBox(height: 4),

        pw.Text(
          servis.lokasiNama,
          style: const pw.TextStyle(
            fontSize: 11,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  static pw.Widget _summary(
      ServisModel servis,
      ) {
    final address =
    ReportDataHelper.firstNonEmpty([
      servis.lokasiData?['address'],
      servis.lokasiData?['alamat'],
    ]);

    final totalUnits =
    servis.itemsData.isNotEmpty
        ? servis.itemsData.length
        : servis.jumlahAc;

    final visitDate =
        servis.tanggalBerkunjung ??
            servis.tanggalDitugaskan;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey300,
        ),
        borderRadius:
        pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          _row(
            'ID Servis',
            '#${servis.id}',
          ),

          _row(
            'Jenis',
            servis.jenisDisplay,
          ),

          _row(
            'Status',
            ReportDataHelper.effectiveStatus(
              servis,
            ),
          ),

          _row(
            'Lokasi',
            servis.lokasiNama,
          ),

          _row(
            'Alamat',
            address.isEmpty
                ? '-'
                : address,
          ),

          _row(
            'Tanggal Kunjungan',
            ReportDataHelper.formatDateTime(
              visitDate,
            ),
          ),

          _row(
            'Jumlah Unit',
            '$totalUnits unit',
          ),
        ],
      ),
    );
  }

  static pw.Widget _row(
      String label,
      String value,
      ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: pw.Row(
        crossAxisAlignment:
        pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 125,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ),

          pw.Text(
            ': ',
            style: const pw.TextStyle(
              fontSize: 9,
            ),
          ),

          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight:
                pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _acItem(
      int number,
      Map<String, dynamic> item,
      ) {
    final room =
    ReportDataHelper.extractRoom(item);

    final acName =
    ReportDataHelper.acName(item);

    final brand =
    ReportDataHelper.brand(item);

    final type =
    ReportDataHelper.type(item);

    final capacity =
    ReportDataHelper.capacity(item);

    final technician =
    ReportDataHelper.technician(item);

    final diagnosis =
    (item['diagnosa'] ?? '')
        .toString()
        .trim();

    final action =
    (item['tindakan'] ?? '')
        .toString()
        .trim();

    final start =
    ReportDataHelper.parseDate(
      item['tanggal_mulai'],
    );

    final finish =
    ReportDataHelper.parseDate(
      item['tanggal_selesai'],
    );

    return pw.Container(
      margin: const pw.EdgeInsets.only(
        bottom: 14,
      ),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey300,
        ),
        borderRadius:
        pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment:
        pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$number. '
                '${room.roomName.isEmpty ? acName : room.roomName}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          if (room.roomName.isNotEmpty)
            pw.Text(
              acName,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blue700,
              ),
            ),

          pw.SizedBox(height: 8),

          _row(
            'Lantai',
            room.floorName.isEmpty
                ? '-'
                : room.floorName,
          ),

          _row(
            'Merek',
            brand.isEmpty ? '-' : brand,
          ),

          _row(
            'Tipe',
            type.isEmpty ? '-' : type,
          ),

          _row(
            'Kapasitas',
            capacity.isEmpty
                ? '-'
                : capacity,
          ),

          _row(
            'Teknisi',
            technician,
          ),

          _row(
            'Mulai',
            ReportDataHelper.formatDateTime(
              start,
            ),
          ),

          _row(
            'Selesai',
            ReportDataHelper.formatDateTime(
              finish,
            ),
          ),

          if (diagnosis.isNotEmpty) ...[
            pw.SizedBox(height: 8),

            pw.Text(
              'Diagnosa',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 3),

            pw.Text(
              diagnosis,
              style: const pw.TextStyle(
                fontSize: 9,
              ),
            ),
          ],

          if (action.isNotEmpty) ...[
            pw.SizedBox(height: 8),

            pw.Text(
              'Tindakan',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 3),

            pw.Text(
              action,
              style: const pw.TextStyle(
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}