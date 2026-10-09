import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifikasi_provider.dart';
import '../../theme/app_theme.dart';
import 'petugas_dashboard_tab.dart';
import 'riwayat_laporan_tab.dart';
import 'input_laporan_screen.dart';
import '../admin/notifikasi_screen.dart';
import '../login_screen.dart';

/// Shell utama untuk role Petugas Pelapor: bottom navigation dengan
/// 2 tab (Beranda, Riwayat Laporan) + tombol mengambang untuk membuat
/// laporan baru — alur inti dari use case "Input Laporan Kelayakan Makanan".
class PetugasMainScreen extends StatefulWidget {
  const PetugasMainScreen({super.key});

  @override
  State<PetugasMainScreen> createState() => _PetugasMainScreenState();
}

class _PetugasMainScreenState extends State<PetugasMainScreen> {
  int _currentIndex = 0;
  final GlobalKey<RiwayatLaporanTabState> _riwayatKey = GlobalKey<RiwayatLaporanTabState>();
  final GlobalKey<PetugasDashboardTabState> _dashboardKey = GlobalKey<PetugasDashboardTabState>();
  late NotifikasiProvider _notifProvider;

  @override
  void initState() {
    super.initState();
    final idUser = context.read<AuthProvider>().user!.idUser;
    _notifProvider = NotifikasiProvider(idUser: idUser);
    _notifProvider.mulaiPolling();
  }

  @override
  void dispose() {
    _notifProvider.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (konfirmasi == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _bukaFormLaporan() async {
    final berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const InputLaporanScreen()),
    );
    if (berhasil == true) {
      _riwayatKey.currentState?.muatData();
      _dashboardKey.currentState?.muatData();
      setState(() => _currentIndex = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    // Sesaat setelah logout, AuthProvider.user jadi null tapi layar ini
    // mungkin masih sempat rebuild sebelum navigasi ke LoginScreen selesai.
    // Tampilkan layar kosong sementara daripada crash null-check.
    if (user == null) return const SizedBox.shrink();

    return ChangeNotifierProvider.value(
      value: _notifProvider,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentIndex == 0 ? 'Beranda' : 'Riwayat Laporan'),
          actions: [
            Consumer<NotifikasiProvider>(
              builder: (context, notif, _) => Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: _notifProvider,
                          child: const NotifikasiScreen(),
                        ),
                      ),
                    ),
                  ),
                  if (notif.belumDibaca > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          notif.belumDibaca > 9 ? '9+' : '${notif.belumDibaca}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Keluar (ganti akun)',
              onPressed: _logout,
            ),
            const SizedBox(width: 4),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: AppColors.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.badge_outlined, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(height: 10),
                      Text(user.namaLengkap,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('Petugas Pelapor · ${user.namaLokasi ?? '-'}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.accent),
                  title: const Text('Keluar'),
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  },
                ),
              ],
            ),
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            PetugasDashboardTab(key: _dashboardKey, onTambahLaporan: _bukaFormLaporan),
            RiwayatLaporanTab(key: _riwayatKey),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _bukaFormLaporan,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
          label: const Text('Buat Laporan', style: TextStyle(color: Colors.white)),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Riwayat'),
          ],
        ),
      ),
    );
  }
}
