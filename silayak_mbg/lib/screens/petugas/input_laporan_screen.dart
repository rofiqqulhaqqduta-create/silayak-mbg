import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/menu_model.dart';
import '../../models/kategori_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';

/// Form utama Petugas Pelapor: use case "Input Laporan Kelayakan Makanan"
/// yang `<<include>>` "Upload Foto Bukti".
class InputLaporanScreen extends StatefulWidget {
  const InputLaporanScreen({super.key});

  @override
  State<InputLaporanScreen> createState() => _InputLaporanScreenState();
}

class _InputLaporanScreenState extends State<InputLaporanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _catatanController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _loadingMenu = true;
  String? _errorMenu;
  List<MenuModel> _menuList = [];
  List<KategoriModel> _kategoriList = [];

  int? _idMenu;
  String _statusKelayakan = 'Layak';
  final Set<int> _kategoriTerpilih = {};
  File? _foto;
  bool _mengirim = false;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _muatData() async {
    setState(() {
      _loadingMenu = true;
      _errorMenu = null;
    });
    try {
      final idLokasi = context.read<AuthProvider>().user!.idLokasi;
      final hasil = await Future.wait([
        ApiService.getMenuList(idLokasi: idLokasi),
        ApiService.getKategoriList(),
      ]);
      setState(() {
        _menuList = hasil[0] as List<MenuModel>;
        _kategoriList = hasil[1] as List<KategoriModel>;
        if (_menuList.isNotEmpty) _idMenu = _menuList.first.idMenu;
      });
    } catch (e) {
      setState(() => _errorMenu = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      setState(() => _loadingMenu = false);
    }
  }

  Future<void> _pilihSumberFoto() async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('Ambil Foto (Kamera)'),
              onTap: () {
                Navigator.pop(ctx);
                _ambilFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _ambilFoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ambilFoto(ImageSource source) async {
    try {
      final XFile? hasil = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1600);
      if (hasil != null) {
        setState(() => _foto = File(hasil.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
  }

  Future<void> _kirim() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idMenu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu belum tersedia untuk lokasi Anda. Hubungi Admin.')),
      );
      return;
    }
    if (_foto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto bukti wajib diambil terlebih dahulu.')),
      );
      return;
    }
    if (_statusKelayakan == 'Tidak Layak' && _kategoriTerpilih.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu kategori masalah.')),
      );
      return;
    }

    setState(() => _mengirim = true);
    try {
      final idUser = context.read<AuthProvider>().user!.idUser;
      await ApiService.createLaporan(
        idUser: idUser,
        idMenu: _idMenu!,
        statusKelayakan: _statusKelayakan,
        catatan: _catatanController.text.trim(),
        kategoriMasalah: _kategoriTerpilih.toList(),
        foto: _foto!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dikirim, menunggu verifikasi Admin.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan')),
      body: _loadingMenu
          ? const LoadingIndicator(message: 'Memuat data menu...')
          : _errorMenu != null
              ? Center(child: Text(_errorMenu!, style: const TextStyle(color: AppColors.textSecondary)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Foto Bukti', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _pilihSumberFoto,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.1)),
                            ),
                            child: _foto == null
                                ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.textSecondary),
                                      SizedBox(height: 8),
                                      Text('Ketuk untuk mengambil foto', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  )
                                : Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.file(_foto!, fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                                          radius: 16,
                                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Menu yang Dilaporkan', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        if (_menuList.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppColors.pendingLight, borderRadius: BorderRadius.circular(12)),
                            child: const Text(
                              'Belum ada menu yang dijadwalkan untuk lokasi Anda. Hubungi Admin untuk menambahkan menu.',
                              style: TextStyle(fontSize: 12),
                            ),
                          )
                        else
                          DropdownButtonFormField<int>(
                            initialValue: _idMenu,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Menu'),
                            items: _menuList
                                .map((m) => DropdownMenuItem(
                                      value: m.idMenu,
                                      child: Text('${m.namaMenu} (${m.tanggalSajian})', overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _idMenu = v),
                          ),
                        const SizedBox(height: 20),
                        const Text('Status Kelayakan', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Layak', label: Text('Layak'), icon: Icon(Icons.check_circle_outline)),
                            ButtonSegment(value: 'Tidak Layak', label: Text('Tidak Layak'), icon: Icon(Icons.warning_amber_rounded)),
                          ],
                          selected: {_statusKelayakan},
                          onSelectionChanged: (v) => setState(() => _statusKelayakan = v.first),
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: _statusKelayakan == 'Layak' ? AppColors.primary : AppColors.accent,
                            selectedForegroundColor: Colors.white,
                          ),
                        ),
                        if (_statusKelayakan == 'Tidak Layak') ...[
                          const SizedBox(height: 20),
                          const Text('Kategori Masalah', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _kategoriList.map((k) {
                              final dipilih = _kategoriTerpilih.contains(k.idKategori);
                              return FilterChip(
                                label: Text(k.namaKategori),
                                selected: dipilih,
                                onSelected: (v) => setState(() {
                                  if (v) {
                                    _kategoriTerpilih.add(k.idKategori);
                                  } else {
                                    _kategoriTerpilih.remove(k.idKategori);
                                  }
                                }),
                                selectedColor: AppColors.accentLight,
                                checkmarkColor: AppColors.accent,
                                labelStyle: TextStyle(color: dipilih ? AppColors.accent : AppColors.textPrimary, fontSize: 12),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 20),
                        const Text('Catatan Tambahan (opsional)', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        CustomTextField(label: 'Catatan', controller: _catatanController, maxLines: 3),
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: _mengirim ? null : _kirim,
                          child: _mengirim
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text('Kirim Laporan'),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
    );
  }
}
