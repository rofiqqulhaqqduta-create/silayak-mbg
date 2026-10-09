import 'package:flutter/material.dart';
import '../../models/lokasi_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';

class LokasiManagementScreen extends StatefulWidget {
  const LokasiManagementScreen({super.key});

  @override
  State<LokasiManagementScreen> createState() => _LokasiManagementScreenState();
}

class _LokasiManagementScreenState extends State<LokasiManagementScreen> {
  List<LokasiModel> _daftar = [];
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
      final data = await ApiService.getLokasiList();
      setState(() => _daftar = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _bukaForm({LokasiModel? lokasi}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormLokasi(lokasi: lokasi, onSaved: _muatData),
    );
  }

  Future<void> _hapus(LokasiModel lokasi) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Lokasi'),
        content: Text('Hapus "${lokasi.namaLokasi}"? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (konfirmasi != true) return;

    try {
      await ApiService.deleteLokasi(lokasi.idLokasi);
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
                      icon: Icons.location_on_outlined,
                      title: 'Belum ada lokasi',
                      subtitle: 'Tambahkan data sekolah atau dapur SPPG.',
                    )
                  : RefreshIndicator(
                      onRefresh: _muatData,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: _daftar.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final l = _daftar[index];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Icon(
                                  l.jenisLokasi == 'Sekolah' ? Icons.school_outlined : Icons.restaurant_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(l.namaLokasi, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              subtitle: Text('${l.jenisLokasi}\n${l.alamat}', style: const TextStyle(fontSize: 12)),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) => v == 'edit' ? _bukaForm(lokasi: l) : _hapus(l),
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

class _FormLokasi extends StatefulWidget {
  final LokasiModel? lokasi;
  final VoidCallback onSaved;
  const _FormLokasi({this.lokasi, required this.onSaved});

  @override
  State<_FormLokasi> createState() => _FormLokasiState();
}

class _FormLokasiState extends State<_FormLokasi> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nama;
  late TextEditingController _alamat;
  late TextEditingController _kontak;
  String _jenis = 'Sekolah';
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.lokasi?.namaLokasi ?? '');
    _alamat = TextEditingController(text: widget.lokasi?.alamat ?? '');
    _kontak = TextEditingController(text: widget.lokasi?.kontak ?? '');
    _jenis = widget.lokasi?.jenisLokasi ?? 'Sekolah';
  }

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
    _kontak.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);
    try {
      if (widget.lokasi == null) {
        await ApiService.createLokasi(
          namaLokasi: _nama.text.trim(),
          jenisLokasi: _jenis,
          alamat: _alamat.text.trim(),
          kontak: _kontak.text.trim(),
        );
      } else {
        await ApiService.updateLokasi(
          idLokasi: widget.lokasi!.idLokasi,
          namaLokasi: _nama.text.trim(),
          jenisLokasi: _jenis,
          alamat: _alamat.text.trim(),
          kontak: _kontak.text.trim(),
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
                Text(widget.lokasi == null ? 'Tambah Lokasi' : 'Ubah Lokasi',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Nama Lokasi',
                  controller: _nama,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _jenis,
                  decoration: const InputDecoration(labelText: 'Jenis Lokasi'),
                  items: const [
                    DropdownMenuItem(value: 'Sekolah', child: Text('Sekolah')),
                    DropdownMenuItem(value: 'Dapur/SPPG', child: Text('Dapur/SPPG')),
                  ],
                  onChanged: (v) => setState(() => _jenis = v ?? 'Sekolah'),
                ),
                const SizedBox(height: 12),
                CustomTextField(label: 'Alamat', controller: _alamat, maxLines: 2),
                const SizedBox(height: 12),
                CustomTextField(label: 'Kontak', controller: _kontak, keyboardType: TextInputType.phone),
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
