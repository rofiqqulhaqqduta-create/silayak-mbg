class KategoriModel {
  final int idKategori;
  final String namaKategori;
  final String deskripsi;

  KategoriModel({
    required this.idKategori,
    required this.namaKategori,
    required this.deskripsi,
  });

  factory KategoriModel.fromJson(Map<String, dynamic> json) {
    return KategoriModel(
      idKategori: int.parse(json['id_kategori'].toString()),
      namaKategori: json['nama_kategori'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
    );
  }
}
