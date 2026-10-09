class LaporanModel {
  final int idLaporan;
  final String tanggalLapor;
  final String statusKelayakan; // 'Layak' / 'Tidak Layak'
  final String? fotoBukti;
  final String catatan;
  final String statusVerifikasi; // 'Menunggu' / 'Disetujui' / 'Ditolak'
  final String namaPetugas;
  final String namaMenu;
  final String? tanggalSajian;
  final int idLokasi;
  final String namaLokasi;
  final String? kategoriMasalah; // string gabungan, dipisah koma

  LaporanModel({
    required this.idLaporan,
    required this.tanggalLapor,
    required this.statusKelayakan,
    this.fotoBukti,
    required this.catatan,
    required this.statusVerifikasi,
    required this.namaPetugas,
    required this.namaMenu,
    this.tanggalSajian,
    required this.idLokasi,
    required this.namaLokasi,
    this.kategoriMasalah,
  });

  bool get isLayak => statusKelayakan == 'Layak';
  bool get isMenunggu => statusVerifikasi == 'Menunggu';

  factory LaporanModel.fromJson(Map<String, dynamic> json) {
    return LaporanModel(
      idLaporan: int.parse(json['id_laporan'].toString()),
      tanggalLapor: json['tanggal_lapor'] ?? '',
      statusKelayakan: json['status_kelayakan'] ?? '',
      fotoBukti: json['foto_bukti'],
      catatan: json['catatan'] ?? '',
      statusVerifikasi: json['status_verifikasi'] ?? 'Menunggu',
      namaPetugas: json['nama_petugas'] ?? '',
      namaMenu: json['nama_menu'] ?? '',
      tanggalSajian: json['tanggal_sajian'],
      idLokasi: int.tryParse(json['id_lokasi']?.toString() ?? '') ?? 0,
      namaLokasi: json['nama_lokasi'] ?? '',
      kategoriMasalah: json['kategori_masalah'],
    );
  }
}
