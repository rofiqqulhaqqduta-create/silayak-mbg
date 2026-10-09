import 'package:flutter/material.dart';
import '../../models/kategori_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';

class KategoriManagementScreen extends StatefulWidget {
  const KategoriManagementScreen({super.key});

  @override
  State<KategoriManagementScreen> createState() => _KategoriManagementScreenState();
}

class _KategoriManagementScreenState extends State<KategoriManagementScreen> {
  List<KategoriModel> _daftar = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getKategoriList();
      setState(() => _daftar = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _bukaForm({KategoriModel? kategori}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormKategori(kategori: kategori, onSaved: _muatData),
    );
  }

  Future<void> _hapus(KategoriModel kategori) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Hapus kategori "${kategori.namaKategori}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (konfirmasi != true) return;
    try {
      await ApiService.deleteKategori(kategori.idKategori);
      _muatData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _bukaForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
              : _daftar.isEmpty
                  ? const EmptyState(
                      icon: Icons.report_gmailerrorred_outlined,
                      title: 'Belum ada kategori',
                      subtitle: 'Tambahkan kategori masalah, misalnya "Basi".',
                    )
                  : RefreshIndicator(
                      onRefresh: _muatData,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: _daftar.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final k = _daftar[index];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.accentLight,
                                child: Icon(Icons.warning_amber_rounded, color: AppColors.accent, size: 20),
                              ),
                              title: Text(k.namaKategori, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              subtitle: Text(k.deskripsi, style: const TextStyle(fontSize: 12)),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) => v == 'edit' ? _bukaForm(kategori: k) : _hapus(k),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Ubah')),
                                  PopupMenuItem(value: 'hapus', child: Text('Hapus')),
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

class _FormKategori extends StatefulWidget {
  final KategoriModel? kategori;
  final VoidCallback onSaved;
  const _FormKategori({this.kategori, required this.onSaved});

  @override
  State<_FormKategori> createState() => _FormKategoriState();
}

class _FormKategoriState extends State<_FormKategori> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nama;
  late TextEditingController _deskripsi;
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.kategori?.namaKategori ?? '');
    _deskripsi = TextEditingController(text: widget.kategori?.deskripsi ?? '');
  }

  @override
  void dispose() {
    _nama.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);
    try {
      if (widget.kategori == null) {
        await ApiService.createKategori(nama: _nama.text.trim(), deskripsi: _deskripsi.text.trim());
      } else {
        await ApiService.updateKategori(
          idKategori: widget.kategori!.idKategori,
          nama: _nama.text.trim(),
          deskripsi: _deskripsi.text.trim(),
        );
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text(widget.kategori == null ? 'Tambah Kategori Masalah' : 'Ubah Kategori Masalah',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Nama Kategori',
                  controller: _nama,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(label: 'Deskripsi', controller: _deskripsi, maxLines: 3),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _menyimpan ? null : _simpan,
                  child: _menyimpan
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
