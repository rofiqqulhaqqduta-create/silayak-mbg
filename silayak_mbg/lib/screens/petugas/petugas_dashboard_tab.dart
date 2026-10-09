import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/loading_indicator.dart';

/// Beranda untuk Petugas Pelapor: ringkasan laporan miliknya sendiri
/// + akses cepat untuk membuat laporan baru.
class PetugasDashboardTab extends StatefulWidget {
  final VoidCallback onTambahLaporan;
  const PetugasDashboardTab({super.key, required this.onTambahLaporan});

  @override
  State<PetugasDashboardTab> createState() => PetugasDashboardTabState();
}

class PetugasDashboardTabState extends State<PetugasDashboardTab> {
  Map<String, dynamic>? _rekap;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    muatData();
  }

  Future<void> muatData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final idUser = context.read<AuthProvider>().user!.idUser;
      final data = await ApiService.getRekapDashboard(idUser: idUser);
      setState(() => _rekap = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    if (_loading) return const LoadingIndicator(message: 'Memuat data...');

    final ringkasan = _rekap?['ringkasan'] as Map<String, dynamic>?;
    int v(String key) => int.tryParse(ringkasan?[key]?.toString() ?? '0') ?? 0;

    return RefreshIndicator(
      onRefresh: muatData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.badge_outlined, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Halo, ${user.namaLengkap}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(user.namaLokasi ?? '-', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                StatCard(label: 'Laporan Saya', value: '${v('total_laporan')}', icon: Icons.description_outlined, color: AppColors.primary),
                StatCard(label: 'Menunggu Verifikasi', value: '${v('total_menunggu')}', icon: Icons.hourglass_top_rounded, color: AppColors.pending),
                StatCard(label: 'Disetujui', value: '${v('total_disetujui')}', icon: Icons.check_circle_outline, color: AppColors.primary),
                StatCard(label: 'Ditolak', value: '${v('total_ditolak')}', icon: Icons.cancel_outlined, color: AppColors.accent),
              ],
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onTambahLaporan,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Buat Laporan Kelayakan Makanan'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Laporkan kondisi makanan yang diterima/disajikan hari ini beserta foto bukti.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
