import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_indicator.dart';

/// Detail laporan untuk Petugas Pelapor — hanya menampilkan informasi,
/// tanpa aksi verifikasi (aksi tersebut khusus Admin).
class LaporanDetailScreen extends StatefulWidget {
  final int idLaporan;
  const LaporanDetailScreen({super.key, required this.idLaporan});

  @override
  State<LaporanDetailScreen> createState() => _LaporanDetailScreenState();
}

class _LaporanDetailScreenState extends State<LaporanDetailScreen> {
  Map<String, dynamic>? _laporan;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muatDetail();
  }

  Future<void> _muatDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getLaporanDetail(widget.idLaporan);
      setState(() => _laporan = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Laporan')),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final lp = _laporan!;
    final fotoPath = lp['foto_bukti'] as String?;
    final kategoriList = (lp['daftar_kategori_masalah'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fotoPath != null && fotoPath.isNotEmpty && File(fotoPath).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(
                  File(fotoPath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: AppColors.primaryLight,
                    child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 40)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              StatusBadge(status: lp['status_kelayakan'] ?? '-'),
              StatusBadge(status: lp['status_verifikasi'] ?? '-'),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _baris('Lokasi', lp['nama_lokasi'] ?? '-'),
                  _baris('Menu', lp['nama_menu'] ?? '-'),
                  _baris('Tanggal Sajian', lp['tanggal_sajian'] ?? '-'),
                  _baris('Waktu Lapor', lp['tanggal_lapor'] ?? '-'),
                ],
              ),
            ),
          ),
          if (kategoriList.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Kategori Masalah', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kategoriList
                  .map((k) => Chip(
                        label: Text(k['nama_kategori'] ?? '-'),
                        backgroundColor: AppColors.accentLight,
                        labelStyle: const TextStyle(color: AppColors.accent, fontSize: 12),
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
          ],
          if ((lp['catatan'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Catatan Anda', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(lp['catatan'], style: const TextStyle(color: AppColors.textSecondary)),
          ],
          if (lp['status_verifikasi'] == 'Menunggu') ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.pendingLight, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, color: AppColors.pending, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Laporan sedang menunggu verifikasi Admin.', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _baris(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
