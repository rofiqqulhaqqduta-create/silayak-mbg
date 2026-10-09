import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_indicator.dart';

class VerifikasiDetailScreen extends StatefulWidget {
  final int idLaporan;
  const VerifikasiDetailScreen({super.key, required this.idLaporan});

  @override
  State<VerifikasiDetailScreen> createState() => _VerifikasiDetailScreenState();
}

class _VerifikasiDetailScreenState extends State<VerifikasiDetailScreen> {
  Map<String, dynamic>? _laporan;
  bool _loading = true;
  bool _memproses = false;
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

  Future<void> _verifikasi(String status) async {
    final label = status == 'Disetujui' ? 'menyetujui' : 'menolak';
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'Disetujui' ? 'Setujui Laporan?' : 'Tolak Laporan?'),
        content: Text('Anda yakin ingin $label laporan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Lanjutkan')),
        ],
      ),
    );
    if (konfirmasi != true) return;

    setState(() => _memproses = true);
    try {
      await ApiService.verifikasiLaporan(idLaporan: widget.idLaporan, statusVerifikasi: status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Laporan berhasil ${status == 'Disetujui' ? 'disetujui' : 'ditolak'}')),
      );
      await _muatDetail();
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
                  _baris('Jenis Lokasi', lp['jenis_lokasi'] ?? '-'),
                  _baris('Menu', lp['nama_menu'] ?? '-'),
                  _baris('Tanggal Sajian', lp['tanggal_sajian'] ?? '-'),
                  _baris('Petugas Pelapor', lp['nama_petugas'] ?? '-'),
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
            const Text('Catatan Petugas', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(lp['catatan'], style: const TextStyle(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 28),
          if (lp['status_verifikasi'] == 'Menunggu') ...[
            const Text('Tindakan Verifikasi', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _memproses ? null : () => _verifikasi('Ditolak'),
                    icon: const Icon(Icons.close, color: AppColors.accent),
                    label: const Text('Tolak', style: TextStyle(color: AppColors.accent)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accent)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _memproses ? null : () => _verifikasi('Disetujui'),
                    icon: const Icon(Icons.check),
                    label: const Text('Setujui'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
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
