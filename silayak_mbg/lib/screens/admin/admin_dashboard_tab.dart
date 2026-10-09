import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/loading_indicator.dart';
import 'export_screen.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  Map<String, dynamic>? _rekap;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getRekapDashboard();
      setState(() => _rekap = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingIndicator(message: 'Memuat rekap...');
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _muatData, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    final ringkasan = _rekap!['ringkasan'] as Map<String, dynamic>;
    final perLokasi = _rekap!['per_lokasi'] as List;
    final perHari = _rekap!['per_hari'] as List;

    int v(String key) => int.tryParse(ringkasan[key]?.toString() ?? '0') ?? 0;

    return RefreshIndicator(
      onRefresh: _muatData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              StatCard(label: 'Total Laporan', value: '${v('total_laporan')}', icon: Icons.description_outlined, color: AppColors.primary),
              StatCard(label: 'Menunggu Verifikasi', value: '${v('total_menunggu')}', icon: Icons.hourglass_top_rounded, color: AppColors.pending),
              StatCard(label: 'Makanan Layak', value: '${v('total_layak')}', icon: Icons.check_circle_outline, color: AppColors.primary),
              StatCard(label: 'Tidak Layak', value: '${v('total_tidak_layak')}', icon: Icons.warning_amber_rounded, color: AppColors.accent),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Tren 7 Hari Terakhir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _TrenMingguan(data: perHari),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Rekap per Lokasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          if (perLokasi.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Belum ada data laporan.', style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            ...perLokasi.map((l) => _RekapLokasiItem(data: l)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExportScreen()),
            ),
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Cetak / Export Laporan'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _TrenMingguan extends StatelessWidget {
  final List data;
  const _TrenMingguan({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Belum ada laporan minggu ini.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    int maxVal = 1;
    for (final d in data) {
      final layak = int.tryParse(d['layak']?.toString() ?? '0') ?? 0;
      final tidakLayak = int.tryParse(d['tidak_layak']?.toString() ?? '0') ?? 0;
      final total = layak + tidakLayak;
      if (total > maxVal) maxVal = total;
    }

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((d) {
          final layak = int.tryParse(d['layak']?.toString() ?? '0') ?? 0;
          final tidakLayak = int.tryParse(d['tidak_layak']?.toString() ?? '0') ?? 0;
          final tanggal = (d['tanggal'] ?? '').toString();
          final label = tanggal.length >= 10 ? '${tanggal.substring(8, 10)}/${tanggal.substring(5, 7)}' : '-';

          final tinggiLayak = 90 * (layak / maxVal);
          final tinggiTidakLayak = 90 * (tidakLayak / maxVal);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('${layak + tidakLayak}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: tinggiLayak < 4 ? 4 : tinggiLayak,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 8,
                    height: tinggiTidakLayak < 4 ? 4 : tinggiTidakLayak,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _RekapLokasiItem extends StatelessWidget {
  final dynamic data;
  const _RekapLokasiItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final layak = int.tryParse(data['layak']?.toString() ?? '0') ?? 0;
    final tidakLayak = int.tryParse(data['tidak_layak']?.toString() ?? '0') ?? 0;
    final total = layak + tidakLayak == 0 ? 1 : layak + tidakLayak;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['nama_lokasi'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Expanded(flex: layak, child: Container(color: AppColors.primary)),
                    Expanded(flex: tidakLayak, child: Container(color: AppColors.accent)),
                    if (layak + tidakLayak == 0) Expanded(flex: total, child: Container(color: AppColors.background)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('Layak: $layak · Tidak Layak: $tidakLayak', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
