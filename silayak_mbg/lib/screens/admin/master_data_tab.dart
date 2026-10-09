import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'lokasi_management_screen.dart';
import 'menu_management_screen.dart';
import 'kategori_management_screen.dart';
import 'akun_petugas_screen.dart';

/// Tab "Data Master" berisi 4 sub-tab: Lokasi, Menu, Kategori Masalah,
/// dan Akun Petugas — sesuai kebutuhan fungsional no.2, 3, 4 pada proposal
/// ditambah validasi registrasi mandiri Petugas Sekolah.
class MasterDataTab extends StatefulWidget {
  const MasterDataTab({super.key});

  @override
  State<MasterDataTab> createState() => _MasterDataTabState();
}

class _MasterDataTabState extends State<MasterDataTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<AkunPetugasScreenState> _akunKey = GlobalKey<AkunPetugasScreenState>();
  int _jumlahMenunggu = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _muatJumlahMenunggu();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _muatJumlahMenunggu() async {
    try {
      final jumlah = await ApiService.countAkunPetugasMenunggu();
      if (mounted) setState(() => _jumlahMenunggu = jumlah);
    } catch (_) {
      // Badge opsional; abaikan kalau gagal dihitung.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              const Tab(text: 'Lokasi'),
              const Tab(text: 'Menu'),
              const Tab(text: 'Kategori'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Akun Petugas'),
                    if (_jumlahMenunggu > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          _jumlahMenunggu > 9 ? '9+' : '$_jumlahMenunggu',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const LokasiManagementScreen(),
              const MenuManagementScreen(),
              const KategoriManagementScreen(),
              AkunPetugasScreen(key: _akunKey, onStatusChanged: _muatJumlahMenunggu),
            ],
          ),
        ),
      ],
    );
  }
}
