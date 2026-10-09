class LokasiModel {
  final int idLokasi;
  final String namaLokasi;
  final String jenisLokasi; // 'Sekolah' atau 'Dapur/SPPG'
  final String alamat;
  final String kontak;

  LokasiModel({
    required this.idLokasi,
    required this.namaLokasi,
    required this.jenisLokasi,
    required this.alamat,
    required this.kontak,
  });

  factory LokasiModel.fromJson(Map<String, dynamic> json) {
    return LokasiModel(
      idLokasi: int.parse(json['id_lokasi'].toString()),
      namaLokasi: json['nama_lokasi'] ?? '',
      jenisLokasi: json['jenis_lokasi'] ?? '',
      alamat: json['alamat'] ?? '',
      kontak: json['kontak'] ?? '',
    );
  }
}
