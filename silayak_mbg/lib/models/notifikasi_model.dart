class NotifikasiModel {
  final int idNotifikasi;
  final int idLaporan;
  final String pesan;
  final String statusBaca; // 'Belum Dibaca' / 'Sudah Dibaca'
  final String createdAt;
  final String? namaLokasi;

  NotifikasiModel({
    required this.idNotifikasi,
    required this.idLaporan,
    required this.pesan,
    required this.statusBaca,
    required this.createdAt,
    this.namaLokasi,
  });

  bool get belumDibaca => statusBaca == 'Belum Dibaca';

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      idNotifikasi: int.parse(json['id_notifikasi'].toString()),
      idLaporan: int.parse(json['id_laporan'].toString()),
      pesan: json['pesan'] ?? '',
      statusBaca: json['status_baca'] ?? 'Belum Dibaca',
      createdAt: json['created_at'] ?? '',
      namaLokasi: json['nama_lokasi'],
    );
  }
}
