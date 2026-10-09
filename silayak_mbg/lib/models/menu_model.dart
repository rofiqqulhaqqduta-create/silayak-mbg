class MenuModel {
  final int idMenu;
  final String namaMenu;
  final String tanggalSajian; // format YYYY-MM-DD
  final int idLokasi;
  final String? namaLokasi;

  MenuModel({
    required this.idMenu,
    required this.namaMenu,
    required this.tanggalSajian,
    required this.idLokasi,
    this.namaLokasi,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      idMenu: int.parse(json['id_menu'].toString()),
      namaMenu: json['nama_menu'] ?? '',
      tanggalSajian: json['tanggal_sajian'] ?? '',
      idLokasi: int.parse(json['id_lokasi'].toString()),
      namaLokasi: json['nama_lokasi'],
    );
  }
}
