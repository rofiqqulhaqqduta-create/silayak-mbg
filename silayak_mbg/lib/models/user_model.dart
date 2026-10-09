class UserModel {
  final int idUser;
  final String namaLengkap;
  final String username;
  final String role; // 'Admin' atau 'Petugas'
  final int? idLokasi;
  final String? namaLokasi;
  final String statusAkun; // 'Menunggu', 'Aktif', atau 'Ditolak'

  UserModel({
    required this.idUser,
    required this.namaLengkap,
    required this.username,
    required this.role,
    this.idLokasi,
    this.namaLokasi,
    this.statusAkun = 'Aktif',
  });

  bool get isAdmin => role == 'Admin';
  bool get isPetugas => role == 'Petugas';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUser: int.parse(json['id_user'].toString()),
      namaLengkap: json['nama_lengkap'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      idLokasi: json['id_lokasi'] != null ? int.tryParse(json['id_lokasi'].toString()) : null,
      namaLokasi: json['nama_lokasi'],
      statusAkun: json['status_akun'] ?? 'Aktif',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'nama_lengkap': namaLengkap,
      'username': username,
      'role': role,
      'id_lokasi': idLokasi,
      'nama_lokasi': namaLokasi,
      'status_akun': statusAkun,
    };
  }
}
