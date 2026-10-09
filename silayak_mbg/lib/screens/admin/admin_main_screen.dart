import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifikasi_provider.dart';
import '../../theme/app_theme.dart';
import 'admin_dashboard_tab.dart';
import 'verifikasi_list_tab.dart';
import 'master_data_tab.dart';
import 'notifikasi_screen.dart';
import '../login_screen.dart';

/// Shell utama untuk role Admin: bottom navigation dengan 3 tab
/// (Dashboard, Verifikasi Laporan, Data Master) + akses notifikasi
/// & logout lewat AppBar.
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;
  late NotifikasiProvider _notifProvider;

  final List<String> _judul = const ['Dashboard', 'Verifikasi Laporan', 'Data Master'];

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
          title: Text(_judul[_currentIndex]),
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
            IconButton(icon: const Icon(Icons.logout), tooltip: 'Keluar (ganti akun)', onPressed: _logout),
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
                        child: Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(height: 10),
                      Text(user.namaLengkap,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      const Text('Admin / Koordinator SPPG', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
          children: const [
            AdminDashboardTab(),
            VerifikasiListTab(),
            MasterDataTab(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), activeIcon: Icon(Icons.fact_check), label: 'Verifikasi'),
            BottomNavigationBarItem(icon: Icon(Icons.storage_outlined), activeIcon: Icon(Icons.storage), label: 'Data Master'),
          ],
        ),
      ),
    );
  }
}
