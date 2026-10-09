import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/user_model.dart';
import '../models/lokasi_model.dart';
import '../models/menu_model.dart';
import '../models/kategori_model.dart';
import '../models/laporan_model.dart';
import '../models/notifikasi_model.dart';

/// Exception khusus supaya UI bisa menampilkan pesan error dalam
/// Bahasa Indonesia ke pengguna.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// -----------------------------------------------------------------------
/// CATATAN ARSITEKTUR (mode lokal/offline untuk demo 1 HP):
/// Nama kelas ini tetap "ApiService" (bukan diganti) supaya semua layar
/// yang sudah memanggil ApiService.xxx() tidak perlu diubah sama sekali.
/// Tapi isinya sekarang murni membaca/menulis ke database SQLite lokal
/// lewat DatabaseHelper — TIDAK ADA panggilan jaringan/HTTP sama sekali.
/// -----------------------------------------------------------------------
class ApiService {
  static const String _baseUrl =
    'http://10.0.2.2:8000/api';

  static Future<Database> get _db async => DatabaseHelper.instance.database;

  // ---------------- AUTH ----------------
 static Future<UserModel> login(String username, String password) async {
  if (username.trim().isEmpty || password.isEmpty) {
    throw ApiException('Username dan password wajib diisi');
  }

  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'username': username.trim(),
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return UserModel.fromJson(
        Map<String, dynamic>.from(data['data']),
      );
    }

    throw ApiException(
      data['message'] ?? 'Username atau password salah',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}
  /// Registrasi mandiri untuk Petugas Sekolah baru. Akun langsung tersimpan
  /// tapi berstatus "Menunggu" — belum bisa dipakai login sampai divalidasi
  /// (disetujui/ditolak) oleh Admin lewat menu "Akun Petugas".
 static Future<void> registerPetugas({
  required String namaLengkap,
  required String username,
  required String password,
  required int idLokasi,
}) async {
  if (namaLengkap.trim().isEmpty ||
      username.trim().isEmpty ||
      password.isEmpty) {
    throw ApiException('Semua kolom wajib diisi');
  }

  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'namaLengkap': namaLengkap.trim(),
        'username': username.trim(),
        'password': password,
        'idLokasi': idLokasi,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['success'] == true) {
      return;
    }

    throw ApiException(
      data['message'] ?? 'Registrasi gagal',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}
  /// Daftar akun Petugas (untuk menu Admin "Akun Petugas"). Bisa difilter
  /// per status ('Menunggu'/'Aktif'/'Ditolak') atau semua kalau null.
  static Future<List<UserModel>> getPetugasAccountList({
  String? statusAkun,
}) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/petugas'),
      headers: {
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final List<dynamic> listData = data['data'] ?? [];

      final users = listData
          .map((item) => UserModel.fromJson(item))
          .where((user) {
            if (statusAkun == null) {
              return true;
            }

            return user.statusAkun == statusAkun;
          })
          .toList();

      return users;
    }

    throw ApiException(
      data['message'] ?? 'Gagal mengambil data petugas',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

 static Future<int> countAkunPetugasMenunggu() async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/petugas'),
      headers: {
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final List<dynamic> listData = data['data'] ?? [];

      return listData.where((item) {
        return item['status_akun'] == 'Menunggu';
      }).length;
    }

    throw ApiException(
      data['message'] ?? 'Gagal menghitung akun petugas menunggu',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

  /// Admin menyetujui ('Aktif') atau menolak ('Ditolak') akun Petugas baru.
  static Future<void> verifikasiAkunPetugas({
  required int idUser,
  required String statusAkun,
}) async {
  try {
    String endpoint;

    if (statusAkun == 'Aktif') {
      endpoint = 'approve';
    } else if (statusAkun == 'Ditolak') {
      endpoint = 'reject';
    } else {
      throw ApiException('Status verifikasi tidak valid.');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/petugas/$idUser/$endpoint'),
      headers: {
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    throw ApiException(
      data['message'] ?? 'Gagal memperbarui status akun petugas.',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

  // ---------------- LOKASI ----------------
  static Future<List<LokasiModel>> getLokasiList() async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/lokasi'),
      headers: {
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final List<dynamic> listData = data['data'] ?? [];

      return listData
          .map((item) => LokasiModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    throw ApiException(
      data['message'] ?? 'Gagal mengambil data lokasi',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

  static Future<void> createLokasi({
  required String namaLokasi,
  required String jenisLokasi,
  required String alamat,
  required String kontak,
}) async {
  if (namaLokasi.trim().isEmpty) {
    throw ApiException('Nama lokasi wajib diisi');
  }

  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/lokasi'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'nama_lokasi': namaLokasi.trim(),
        'jenis_lokasi': jenisLokasi.trim(),
        'alamat': alamat.trim(),
        'kontak': kontak.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['success'] == true) {
      return;
    }

    throw ApiException(
      data['message'] ?? 'Gagal menambahkan lokasi',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

 static Future<void> updateLokasi({
  required int idLokasi,
  required String namaLokasi,
  required String jenisLokasi,
  required String alamat,
  required String kontak,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$_baseUrl/lokasi/$idLokasi'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'nama_lokasi': namaLokasi.trim(),
        'jenis_lokasi': jenisLokasi.trim(),
        'alamat': alamat.trim(),
        'kontak': kontak.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    throw ApiException(
      data['message'] ?? 'Gagal memperbarui lokasi',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

 static Future<void> deleteLokasi(int idLokasi) async {
  try {
    final response = await http.delete(
      Uri.parse('$_baseUrl/lokasi/$idLokasi'),
      headers: {
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    throw ApiException(
      data['message'] ?? 'Gagal menghapus lokasi',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

  // ---------------- MENU ----------------
 static Future<List<MenuModel>> getMenuList({int? idLokasi}) async {
  try {
    String url = '$_baseUrl/menu';

    if (idLokasi != null) {
      url += '?id_lokasi=$idLokasi';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final List<dynamic> listData = data['data'] ?? [];

      return listData
          .map((item) => MenuModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    throw ApiException(
      data['message'] ?? 'Gagal mengambil data menu',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

 static Future<void> createMenu({
  required String namaMenu,
  required String tanggalSajian,
  required int idLokasi,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/menu'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'nama_menu': namaMenu.trim(),
        'tanggal_sajian': tanggalSajian,
        'id_lokasi': idLokasi,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['success'] == true) {
      return;
    }

    throw ApiException(
      data['message'] ?? 'Gagal menambahkan menu',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

 static Future<void> updateMenu({
  required int idMenu,
  required String namaMenu,
  required String tanggalSajian,
  required int idLokasi,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$_baseUrl/menu/$idMenu'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'nama_menu': namaMenu.trim(),
        'tanggal_sajian': tanggalSajian,
        'id_lokasi': idLokasi,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    throw ApiException(
      data['message'] ?? 'Gagal memperbarui menu',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

 static Future<void> deleteMenu(int idMenu) async {
  try {
    final response = await http.delete(
      Uri.parse('$_baseUrl/menu/$idMenu'),
      headers: {
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    throw ApiException(
      data['message'] ?? 'Gagal menghapus menu',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

  // ---------------- KATEGORI MASALAH ----------------
 static Future<List<KategoriModel>> getKategoriList() async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/kategori-masalah'),
      headers: {
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final List<dynamic> listData = data['data'] ?? [];

      return listData
          .map((item) => KategoriModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    throw ApiException(
      data['message'] ?? 'Gagal mengambil data kategori masalah',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

  static Future<void> createKategori({
  required String nama,
  required String deskripsi,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/kategori-masalah'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'nama_kategori': nama.trim(),
        'deskripsi': deskripsi.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['success'] == true) {
      return;
    }

    throw ApiException(
      data['message'] ?? 'Gagal menambahkan kategori masalah',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

 static Future<void> updateKategori({
  required int idKategori,
  required String nama,
  required String deskripsi,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$_baseUrl/kategori-masalah/$idKategori'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'nama_kategori': nama.trim(),
        'deskripsi': deskripsi.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    throw ApiException(
      data['message'] ?? 'Gagal memperbarui kategori masalah',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

static Future<void> deleteKategori(int idKategori) async {
  try {
    final response = await http.delete(
      Uri.parse('$_baseUrl/kategori-masalah/$idKategori'),
      headers: {
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    throw ApiException(
      data['message'] ?? 'Gagal menghapus kategori masalah',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

  // ---------------- LAPORAN ----------------
  static const String _selectLaporanDasar = '''
    SELECT lp.id_laporan, lp.tanggal_lapor, lp.status_kelayakan, lp.foto_bukti,
           lp.catatan, lp.status_verifikasi,
           u.nama_lengkap AS nama_petugas,
           mn.nama_menu, mn.tanggal_sajian,
           lok.id_lokasi, lok.nama_lokasi,
           (SELECT GROUP_CONCAT(k.nama_kategori, ', ')
              FROM tb_detail_masalah dm
              JOIN tb_kategori_masalah k ON dm.id_kategori = k.id_kategori
             WHERE dm.id_laporan = lp.id_laporan) AS kategori_masalah
    FROM tb_laporan lp
    JOIN tb_user u ON lp.id_user = u.id_user
    JOIN tb_menu mn ON lp.id_menu = mn.id_menu
    JOIN tb_lokasi lok ON mn.id_lokasi = lok.id_lokasi
  ''';

 static Future<List<LaporanModel>> getLaporanList({
  int? idUser,
  String? statusVerifikasi,
  int? idLokasi,
}) async {
  try {
    String url = '$_baseUrl/laporan';

    final params = <String, String>{};

    if (idUser != null) {
      params['id_user'] = idUser.toString();
    }

    if (statusVerifikasi != null) {
      params['status_verifikasi'] = statusVerifikasi;
    }

    if (idLokasi != null) {
      params['id_lokasi'] = idLokasi.toString();
    }

    if (params.isNotEmpty) {
      url += '?' + Uri(queryParameters: params).query;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final List<dynamic> listData = data['data'] ?? [];

      return listData
          .map(
            (item) => LaporanModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    throw ApiException(
      data['message'] ?? 'Gagal mengambil data laporan',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

  static Future<Map<String, dynamic>> getLaporanDetail(int idLaporan) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/laporan/$idLaporan'),
      headers: {
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']);
    }

    if (response.statusCode == 404) {
      throw ApiException('Laporan tidak ditemukan');
    }

    throw ApiException(
      data['message'] ?? 'Gagal mengambil detail laporan',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}
  /// Menyalin foto yang diambil dari kamera/galeri ke folder dokumen
  /// aplikasi supaya tidak hilang walau file asal (cache kamera) dihapus.
  static Future<String> _simpanFotoLokal(File foto) async {
    final dir = await getApplicationDocumentsDirectory();
    final fotoDir = Directory(p.join(dir.path, 'foto_bukti_silayak'));
    if (!await fotoDir.exists()) {
      await fotoDir.create(recursive: true);
    }
    final ekstensi = p.extension(foto.path);
    final namaBaru = 'bukti_${DateTime.now().millisecondsSinceEpoch}$ekstensi';
    final tujuan = p.join(fotoDir.path, namaBaru);
    final hasil = await foto.copy(tujuan);
    return hasil.path;
  }

  static Future<void> createLaporan({
  required int idUser,
  required int idMenu,
  required String statusKelayakan,
  required String catatan,
  required List<int> kategoriMasalah,
  required File foto,
}) async {
  if (statusKelayakan == 'Tidak Layak' && kategoriMasalah.isEmpty) {
    throw ApiException(
      'Kategori masalah wajib dipilih jika makanan tidak layak',
    );
  }

  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/laporan'),
    );

    request.headers['Accept'] = 'application/json';

    request.fields['id_user'] = idUser.toString();
    request.fields['id_menu'] = idMenu.toString();
    request.fields['status_kelayakan'] = statusKelayakan;
    request.fields['catatan'] = catatan;

    for (int i = 0; i < kategoriMasalah.length; i++) {
  request.fields['kategori_masalah[$i]'] =
      kategoriMasalah[i].toString();
}

    request.files.add(
      await http.MultipartFile.fromPath(
        'foto_bukti',
        foto.path,
      ),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['success'] == true) {
      return;
    }

    throw ApiException(
      data['message'] ?? 'Gagal membuat laporan',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

 static Future<void> verifikasiLaporan({
  required int idLaporan,
  required String statusVerifikasi,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$_baseUrl/laporan/$idLaporan/verifikasi'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'status_verifikasi': statusVerifikasi,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    throw ApiException(
      data['message'] ?? 'Gagal memverifikasi laporan',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}

  // ---------------- DASHBOARD ----------------
 static Future<Map<String, dynamic>> getRekapDashboard({
  int? idUser,
}) async {
  try {
    String url = '$_baseUrl/dashboard';

    if (idUser != null) {
      url += '?id_user=$idUser';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']);
    }

    throw ApiException(
      data['message'] ?? 'Gagal mengambil data dashboard',
    );
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}
  // ---------------- NOTIFIKASI ----------------
 static Future<Map<String, dynamic>> getNotifikasi(int idUser) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/notifikasi?id_user_tujuan=$idUser'),
      headers: {
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(
        data['message'] ?? 'Gagal mengambil notifikasi',
      );
    }

    final List<dynamic> listData = data['data'] ?? [];

    final notifikasi = listData
        .map(
          (item) => NotifikasiModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    final countResponse = await http.get(
      Uri.parse(
        '$_baseUrl/notifikasi/count?id_user_tujuan=$idUser',
      ),
      headers: {
        'Accept': 'application/json',
      },
    );

    final countData = jsonDecode(countResponse.body);

    final belumDibaca =
        countResponse.statusCode == 200 &&
                countData['success'] == true
            ? int.tryParse(
                  countData['jumlah'].toString(),
                ) ??
                0
            : 0;

    return {
      'notifikasi': notifikasi,
      'belum_dibaca': belumDibaca,
    };
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}
  static Future<void> markNotifikasiRead(
  int idUser, {
  int? idNotifikasi,
}) async {
  try {
    // Jika hanya satu notifikasi yang dipilih
    if (idNotifikasi != null) {
      final response = await http.put(
        Uri.parse(
          '$_baseUrl/notifikasi/$idNotifikasi/dibaca',
        ),
        headers: {
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return;
      }

      throw ApiException(
        data['message'] ?? 'Gagal menandai notifikasi',
      );
    }

    // Jika tidak ada ID, tandai semua notifikasi milik user
    final hasil = await getNotifikasi(idUser);

    final List<NotifikasiModel> daftar =
        List<NotifikasiModel>.from(hasil['notifikasi']);

    for (final notifikasi in daftar) {
      if (notifikasi.belumDibaca) {
        final response = await http.put(
          Uri.parse(
            '$_baseUrl/notifikasi/${notifikasi.idNotifikasi}/dibaca',
          ),
          headers: {
            'Accept': 'application/json',
          },
        );

        final data = jsonDecode(response.body);

        if (response.statusCode != 200 || data['success'] != true) {
          throw ApiException(
            data['message'] ?? 'Gagal menandai notifikasi',
          );
        }
      }
    }
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException(
      'Tidak dapat terhubung ke server Laravel.',
    );
  }
}
}
