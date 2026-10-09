import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

/// Daftar akun Petugas Sekolah (termasuk yang mendaftar mandiri lewat
/// layar Registrasi) supaya Admin bisa menyetujui atau menolaknya.
/// Akun berstatus "Menunggu" ditampilkan paling atas dan punya tombol aksi;
/// akun yang sudah "Aktif"/"Ditolak" hanya ditampilkan sebagai riwayat.
class AkunPetugasScreen extends StatefulWidget {
  final VoidCallback? onStatusChanged;
  const AkunPetugasScreen({super.key, this.onStatusChanged});

  @override
  State<AkunPetugasScreen> createState() => AkunPetugasScreenState();
}

class AkunPetugasScreenState extends State<AkunPetugasScreen> {
  List<UserModel> _daftar = [];
  bool _loading = true;
  String? _error;
  int? _idDiproses;

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
      final data = await ApiService.getPetugasAccountList();
      setState(() => _daftar = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _validasi(UserModel akun, String statusBaru) async {
    final aksi = statusBaru == 'Aktif' ? 'menyetujui' : 'menolak';
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(statusBaru == 'Aktif' ? 'Setujui Akun' : 'Tolak Akun'),
        content: Text('Yakin ingin $aksi akun "${akun.namaLengkap}" (${akun.username})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(statusBaru == 'Aktif' ? 'Setujui' : 'Tolak')),
        ],
      ),
    );
    if (konfirmasi != true) return;

    setState(() => _idDiproses = akun.idUser);
    try {
      await ApiService.verifikasiAkunPetugas(idUser: akun.idUser, statusAkun: statusBaru);
      await muatData();
      widget.onStatusChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _idDiproses = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
              : _daftar.isEmpty
                  ? const EmptyState(
                      icon: Icons.badge_outlined,
                      title: 'Belum ada akun Petugas',
                      subtitle: 'Akun yang mendaftar lewat halaman login akan muncul di sini.',
                    )
                  : RefreshIndicator(
                      onRefresh: muatData,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: _daftar.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final akun = _daftar[index];
                          final menunggu = akun.statusAkun == 'Menunggu';
                          final diproses = _idDiproses == akun.idUser;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.primaryLight,
                                        child: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(akun.namaLengkap, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                            Text('@${akun.username} · ${akun.namaLokasi ?? '-'}',
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                      ),
                                      StatusBadge(status: akun.statusAkun),
                                    ],
                                  ),
                                  if (menunggu) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: diproses ? null : () => _validasi(akun, 'Ditolak'),
                                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: const BorderSide(color: AppColors.accent)),
                                            child: const Text('Tolak'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: diproses ? null : () => _validasi(akun, 'Aktif'),
                                            child: diproses
                                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                                : const Text('Setujui'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
