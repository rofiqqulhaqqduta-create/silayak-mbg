import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/lokasi_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Layar untuk mencetak/mengekspor laporan ke PDF atau CSV (Excel),
/// sesuai kebutuhan fungsional no.11 pada proposal.
///
/// Karena aplikasi ini mode lokal/offline, PDF & CSV dibuat langsung dari
/// data di database lokal (bukan dari server), lalu dibagikan/disimpan
/// lewat fitur share bawaan HP.
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String? _statusVerifikasi; // null = semua
  int? _idLokasi; // null = semua
  List<LokasiModel> _lokasiList = [];
  bool _memproses = false;

  @override
  void initState() {
    super.initState();
    _muatLokasi();
  }

  Future<void> _muatLokasi() async {
    try {
      final data = await ApiService.getLokasiList();
      setState(() => _lokasiList = data);
    } catch (_) {
      // Diamkan — filter lokasi opsional, tidak menghalangi export
    }
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<void> _exportCsv() async {
    setState(() => _memproses = true);
    try {
      final daftar = await ApiService.getLaporanList(
        statusVerifikasi: _statusVerifikasi,
        idLokasi: _idLokasi,
      );

      final buffer = StringBuffer();
      final headerCsv = ['No', 'Tanggal Lapor', 'Lokasi', 'Menu', 'Petugas', 'Status Kelayakan', 'Kategori Masalah', 'Status Verifikasi', 'Catatan']
          .map(_csvEscape)
          .join(',');
      buffer.writeln('\uFEFF$headerCsv');

      for (var i = 0; i < daftar.length; i++) {
        final l = daftar[i];
        buffer.writeln([
          '${i + 1}',
          l.tanggalLapor,
          l.namaLokasi,
          l.namaMenu,
          l.namaPetugas,
          l.statusKelayakan,
          l.kategoriMasalah ?? '-',
          l.statusVerifikasi,
          l.catatan,
        ].map(_csvEscape).join(','));
      }

      final dir = await getTemporaryDirectory();
      final namaFile = 'laporan_silayak_mbg_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(p.join(dir.path, namaFile));
      await file.writeAsString(buffer.toString());

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Laporan SI-LAYAK MBG (CSV)'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _memproses = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _memproses = true);
    try {
      final daftar = await ApiService.getLaporanList(
        statusVerifikasi: _statusVerifikasi,
        idLokasi: _idLokasi,
      );

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Laporan Kelayakan Makanan - SI-LAYAK MBG',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['No', 'Tanggal', 'Lokasi', 'Menu', 'Petugas', 'Kelayakan', 'Verifikasi', 'Kategori Masalah'],
              data: List.generate(daftar.length, (i) {
                final l = daftar[i];
                return [
                  '${i + 1}',
                  l.tanggalLapor,
                  l.namaLokasi,
                  l.namaMenu,
                  l.namaPetugas,
                  l.statusKelayakan,
                  l.statusVerifikasi,
                  l.kategoriMasalah ?? '-',
                ];
              }),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1F7A5C)),
            ),
          ],
        ),
      );

      if (!mounted) return;
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _memproses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cetak / Export Laporan')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Filter (opsional)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _statusVerifikasi,
              decoration: const InputDecoration(labelText: 'Status Verifikasi'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua Status')),
                DropdownMenuItem(value: 'Menunggu', child: Text('Menunggu')),
                DropdownMenuItem(value: 'Disetujui', child: Text('Disetujui')),
                DropdownMenuItem(value: 'Ditolak', child: Text('Ditolak')),
              ],
              onChanged: (v) => setState(() => _statusVerifikasi = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _idLokasi,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Lokasi'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua Lokasi')),
                ..._lokasiList.map((l) => DropdownMenuItem(value: l.idLokasi, child: Text(l.namaLokasi, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) => setState(() => _idLokasi = v),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _memproses ? null : _exportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: _memproses
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Export / Cetak PDF'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _memproses ? null : _exportCsv,
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('Export CSV (Excel)'),
            ),
            const SizedBox(height: 20),
            const Text(
              'PDF akan terbuka di pratinjau cetak (bisa disimpan atau dibagikan). '
              'CSV akan dibuat lalu dibuka lewat menu bagikan/simpan bawaan HP.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
