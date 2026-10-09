import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notifikasi_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotifikasiProvider>().tandaiSemuaSudahDibaca();
    });
  }

  String _waktu(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final notif = context.watch<NotifikasiProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: notif.isLoading && notif.daftar.isEmpty
          ? const LoadingIndicator()
          : notif.daftar.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'Belum ada notifikasi',
                  subtitle: 'Notifikasi laporan baru akan tampil di sini.',
                )
              : RefreshIndicator(
                  onRefresh: notif.ambilNotifikasi,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notif.daftar.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final n = notif.daftar[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: n.belumDibaca ? AppColors.accentLight : AppColors.background,
                            child: Icon(
                              Icons.notifications_outlined,
                              color: n.belumDibaca ? AppColors.accent : AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                          title: Text(n.pesan, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(_waktu(n.createdAt), style: const TextStyle(fontSize: 11)),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
