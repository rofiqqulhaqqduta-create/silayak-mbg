import 'package:flutter/material.dart';
import '../models/lokasi_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_indicator.dart';

/// Registrasi mandiri untuk Petugas Sekolah baru.
///
/// Akun yang didaftarkan lewat sini TIDAK langsung bisa dipakai login —
/// statusnya "Menunggu" sampai divalidasi (disetujui/ditolak) oleh Admin
/// lewat menu "Akun Petugas" pada Data Master.
class RegistrasiScreen extends StatefulWidget {
  const RegistrasiScreen({super.key});

  @override
  State<RegistrasiScreen> createState() => _RegistrasiScreenState();
}

class _RegistrasiScreenState extends State<RegistrasiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _konfirmasi = TextEditingController();
  bool _obscure = true;

  List<LokasiModel> _daftarSekolah = [];
  int? _idLokasi;
  bool _memuatLokasi = true;
  bool _mendaftar = false;

  @override
  void initState() {
    super.initState();
    _muatSekolah();
  }

  @override
  void dispose() {
    _nama.dispose();
    _username.dispose();
    _password.dispose();
    _konfirmasi.dispose();
    super.dispose();
  }

  Future<void> _muatSekolah() async {
    try {
      final semua = await ApiService.getLokasiList();
      setState(() => _daftarSekolah = semua.where((l) => l.jenisLokasi == 'Sekolah').toList());
    } catch (_) {
      // Biarkan daftar kosong; validator dropdown akan menahan submit.
    } finally {
      if (mounted) setState(() => _memuatLokasi = false);
    }
  }

  Future<void> _daftar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idLokasi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih sekolah tempat bertugas terlebih dahulu')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _mendaftar = true);
    try {
      await ApiService.registerPetugas(
        namaLengkap: _nama.text.trim(),
        username: _username.text.trim(),
        password: _password.text,
        idLokasi: _idLokasi!,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Registrasi Berhasil'),
          content: const Text(
            'Akun Anda sudah tersimpan dan sedang menunggu verifikasi dari Admin/Koordinator SPPG. '
            'Anda akan bisa login setelah akun disetujui.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti')),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _mendaftar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Daftar Akun Petugas')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Untuk Guru Piket / Petugas Sekolah yang belum punya akun. '
                  'Akun baru perlu divalidasi Admin dulu sebelum bisa dipakai login.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'Nama Lengkap',
                  controller: _nama,
                  icon: Icons.badge_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Username',
                  controller: _username,
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Username wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                _memuatLokasi
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LoadingIndicator(message: 'Memuat daftar sekolah...'),
                      )
                    : DropdownButtonFormField<int>(
                        initialValue: _idLokasi,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Sekolah Tempat Bertugas'),
                        items: _daftarSekolah
                            .map((l) => DropdownMenuItem(value: l.idLokasi, child: Text(l.namaLokasi, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (v) => setState(() => _idLokasi = v),
                        validator: (v) => v == null ? 'Pilih sekolah terlebih dahulu' : null,
                      ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Password',
                  controller: _password,
                  obscureText: _obscure,
                  icon: Icons.lock_outline,
                  validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Konfirmasi Password',
                  controller: _konfirmasi,
                  obscureText: _obscure,
                  icon: Icons.lock_outline,
                  validator: (v) => (v != _password.text) ? 'Konfirmasi password tidak sama' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                    label: Text(_obscure ? 'Tampilkan' : 'Sembunyikan'),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _mendaftar ? null : _daftar,
                  child: _mendaftar
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Daftar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
