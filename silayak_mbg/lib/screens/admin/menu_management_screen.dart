import 'package:flutter/material.dart';
import '../../models/menu_model.dart';
import '../../models/lokasi_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  List<MenuModel> _daftar = [];
  List<LokasiModel> _lokasiList = [];
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
      final results = await Future.wait([
        ApiService.getMenuList(),
        ApiService.getLokasiList(),
      ]);
      setState(() {
        _daftar = results[0] as List<MenuModel>;
        _lokasiList = results[1] as List<LokasiModel>;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _bukaForm({MenuModel? menu}) {
    if (_lokasiList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan data Lokasi terlebih dahulu sebelum membuat menu.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormMenu(menu: menu, lokasiList: _lokasiList, onSaved: _muatData),
    );
  }

  Future<void> _hapus(MenuModel menu) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Menu'),
        content: Text('Hapus menu "${menu.namaMenu}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (konfirmasi != true) return;

    try {
      await ApiService.deleteMenu(menu.idMenu);
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
                      icon: Icons.restaurant_menu_outlined,
                      title: 'Belum ada menu',
                      subtitle: 'Jadwalkan menu makanan untuk tiap lokasi.',
                    )
                  : RefreshIndicator(
                      onRefresh: _muatData,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: _daftar.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final m = _daftar[index];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Icon(Icons.restaurant_menu, color: AppColors.primary, size: 20),
                              ),
                              title: Text(m.namaMenu, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              subtitle: Text('${m.namaLokasi ?? '-'}\n${m.tanggalSajian}', style: const TextStyle(fontSize: 12)),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) => v == 'edit' ? _bukaForm(menu: m) : _hapus(m),
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

class _FormMenu extends StatefulWidget {
  final MenuModel? menu;
  final List<LokasiModel> lokasiList;
  final VoidCallback onSaved;
  const _FormMenu({this.menu, required this.lokasiList, required this.onSaved});

  @override
  State<_FormMenu> createState() => _FormMenuState();
}

class _FormMenuState extends State<_FormMenu> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nama;
  DateTime _tanggal = DateTime.now();
  int? _idLokasi;
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.menu?.namaMenu ?? '');
    _idLokasi = widget.menu?.idLokasi ?? widget.lokasiList.first.idLokasi;
    if (widget.menu != null) {
      _tanggal = DateTime.tryParse(widget.menu!.tanggalSajian) ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  String get _tanggalFormatted =>
      '${_tanggal.year.toString().padLeft(4, '0')}-${_tanggal.month.toString().padLeft(2, '0')}-${_tanggal.day.toString().padLeft(2, '0')}';

  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (hasil != null) setState(() => _tanggal = hasil);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate() || _idLokasi == null) return;
    setState(() => _menyimpan = true);
    try {
      if (widget.menu == null) {
        await ApiService.createMenu(namaMenu: _nama.text.trim(), tanggalSajian: _tanggalFormatted, idLokasi: _idLokasi!);
      } else {
        await ApiService.updateMenu(
          idMenu: widget.menu!.idMenu,
          namaMenu: _nama.text.trim(),
          tanggalSajian: _tanggalFormatted,
          idLokasi: _idLokasi!,
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
                Text(widget.menu == null ? 'Tambah Menu' : 'Ubah Menu', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Nama Menu',
                  controller: _nama,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _idLokasi,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Lokasi'),
                  items: widget.lokasiList
                      .map((l) => DropdownMenuItem(value: l.idLokasi, child: Text(l.namaLokasi, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _idLokasi = v),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pilihTanggal,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tanggal Sajian', prefixIcon: Icon(Icons.calendar_today_outlined)),
                    child: Text(_tanggalFormatted),
                  ),
                ),
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
