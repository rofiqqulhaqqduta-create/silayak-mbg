import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/laporan_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/laporan_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import 'laporan_detail_screen.dart';

/// Riwayat laporan milik Petugas Pelapor yang sedang login.
class RiwayatLaporanTab extends StatefulWidget {
  const RiwayatLaporanTab({super.key});

  @override
  State<RiwayatLaporanTab> createState() => RiwayatLaporanTabState();
}

class RiwayatLaporanTabState extends State<RiwayatLaporanTab> {
  List<LaporanModel> _daftar = [];
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
      final data = await ApiService.getLaporanList(idUser: idUser);
      setState(() => _daftar = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingIndicator(message: 'Memuat riwayat...');
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)));
    }
    if (_daftar.isEmpty) {
      return const EmptyState(
        icon: Icons.history_outlined,
        title: 'Belum ada riwayat',
        subtitle: 'Laporan yang Anda buat akan muncul di sini.',
      );
    }

    return RefreshIndicator(
      onRefresh: muatData,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _daftar.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final laporan = _daftar[index];
          return LaporanCard(
            laporan: laporan,
            tampilkanNamaPetugas: false,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => LaporanDetailScreen(idLaporan: laporan.idLaporan)),
            ),
          );
        },
      ),
    );
  }
}
