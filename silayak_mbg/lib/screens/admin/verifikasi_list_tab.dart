import 'package:flutter/material.dart';
import '../../models/laporan_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/laporan_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import 'verifikasi_detail_screen.dart';

class VerifikasiListTab extends StatefulWidget {
  const VerifikasiListTab({super.key});

  @override
  State<VerifikasiListTab> createState() => _VerifikasiListTabState();
}

class _VerifikasiListTabState extends State<VerifikasiListTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String?> _statusPerTab = [null, 'Menunggu', 'Disetujui', 'Ditolak'];
  final List<String> _labelTab = const ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];

  List<LaporanModel> _semuaLaporan = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _labelTab.length, vsync: this);
    _muatData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _muatData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getLaporanList();
      setState(() => _semuaLaporan = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  List<LaporanModel> _filter(String? status) {
    if (status == null) return _semuaLaporan;
    return _semuaLaporan.where((l) => l.statusVerifikasi == status).toList();
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
            tabs: _labelTab.map((t) => Tab(text: t)).toList(),
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingIndicator(message: 'Memuat laporan...')
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
                  : TabBarView(
                      controller: _tabController,
                      children: _statusPerTab.map((status) {
                        final daftar = _filter(status);
                        if (daftar.isEmpty) {
                          return const EmptyState(
                            icon: Icons.fact_check_outlined,
                            title: 'Belum ada laporan',
                            subtitle: 'Laporan dari petugas akan muncul di sini.',
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: _muatData,
                          color: AppColors.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: daftar.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final laporan = daftar[index];
                              return LaporanCard(
                                laporan: laporan,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => VerifikasiDetailScreen(idLaporan: laporan.idLaporan),
                                    ),
                                  );
                                  _muatData();
                                },
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
        ),
      ],
    );
  }
}
