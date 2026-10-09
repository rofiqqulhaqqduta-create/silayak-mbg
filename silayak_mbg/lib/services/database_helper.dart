import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Lapisan database lokal (SQLite) untuk mode DEMO 1 HP.
///
/// Tidak ada server/API sama sekali — semua data (Admin, Petugas, Lokasi,
/// Menu, Kategori Masalah, Laporan, Notifikasi) tersimpan di file database
/// SQLite di dalam penyimpanan aplikasi pada HP itu sendiri.
///
/// KETERBATASAN (sengaja, sesuai permintaan untuk mode demo):
/// Karena datanya lokal per-HP, kalau aplikasi ini di-install di 2 HP
/// berbeda, data TIDAK akan sinkron antara HP Admin dan HP Petugas.
/// Untuk demo, login Admin dan Petugas dilakukan bergantian di 1 HP yang
/// sama (makanya ada tombol logout yang jelas di kedua peran).
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'silayak_mbg_lokal.db');
    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tb_lokasi (
        id_lokasi INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_lokasi TEXT NOT NULL,
        jenis_lokasi TEXT NOT NULL,
        alamat TEXT,
        kontak TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tb_user (
        id_user INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_lengkap TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        id_lokasi INTEGER,
        status_akun TEXT NOT NULL DEFAULT 'Aktif',
        FOREIGN KEY (id_lokasi) REFERENCES tb_lokasi(id_lokasi)
      )
    ''');

    await db.execute('''
      CREATE TABLE tb_menu (
        id_menu INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_menu TEXT NOT NULL,
        tanggal_sajian TEXT NOT NULL,
        id_lokasi INTEGER NOT NULL,
        FOREIGN KEY (id_lokasi) REFERENCES tb_lokasi(id_lokasi)
      )
    ''');

    await db.execute('''
      CREATE TABLE tb_kategori_masalah (
        id_kategori INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_kategori TEXT NOT NULL,
        deskripsi TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tb_laporan (
        id_laporan INTEGER PRIMARY KEY AUTOINCREMENT,
        id_user INTEGER NOT NULL,
        id_menu INTEGER NOT NULL,
        tanggal_lapor TEXT NOT NULL,
        status_kelayakan TEXT NOT NULL,
        foto_bukti TEXT,
        catatan TEXT,
        status_verifikasi TEXT NOT NULL DEFAULT 'Menunggu',
        FOREIGN KEY (id_user) REFERENCES tb_user(id_user),
        FOREIGN KEY (id_menu) REFERENCES tb_menu(id_menu)
      )
    ''');

    await db.execute('''
      CREATE TABLE tb_detail_masalah (
        id_detail INTEGER PRIMARY KEY AUTOINCREMENT,
        id_laporan INTEGER NOT NULL,
        id_kategori INTEGER NOT NULL,
        FOREIGN KEY (id_laporan) REFERENCES tb_laporan(id_laporan) ON DELETE CASCADE,
        FOREIGN KEY (id_kategori) REFERENCES tb_kategori_masalah(id_kategori)
      )
    ''');

    await db.execute('''
      CREATE TABLE tb_notifikasi (
        id_notifikasi INTEGER PRIMARY KEY AUTOINCREMENT,
        id_laporan INTEGER NOT NULL,
        id_user_tujuan INTEGER NOT NULL,
        pesan TEXT NOT NULL,
        status_baca TEXT NOT NULL DEFAULT 'Belum Dibaca',
        created_at TEXT NOT NULL,
        FOREIGN KEY (id_laporan) REFERENCES tb_laporan(id_laporan) ON DELETE CASCADE,
        FOREIGN KEY (id_user_tujuan) REFERENCES tb_user(id_user)
      )
    ''');

    await _seedData(db);
  }

  /// Migrasi untuk pengguna yang sudah pernah install versi lama
  /// (sebelum ada fitur registrasi mandiri Petugas + validasi Admin).
  /// Akun yang sudah ada otomatis dianggap "Aktif" (tidak perlu verifikasi
  /// ulang), supaya login yang sudah berjalan tidak terganggu.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE tb_user ADD COLUMN status_akun TEXT NOT NULL DEFAULT 'Aktif'");
    }
  }

  Future<void> _seedData(Database db) async {
    final idLokasi1 = await db.insert('tb_lokasi', {
      'nama_lokasi': 'SD Negeri 01 Medan',
      'jenis_lokasi': 'Sekolah',
      'alamat': 'Jl. Merdeka No. 1, Medan',
      'kontak': '0811111111',
    });
    await db.insert('tb_lokasi', {
      'nama_lokasi': 'Dapur SPPG Medan Kota',
      'jenis_lokasi': 'Dapur/SPPG',
      'alamat': 'Jl. Gatot Subroto No. 10, Medan',
      'kontak': '0822222222',
    });

    await db.insert('tb_user', {
      'nama_lengkap': 'Koordinator SPPG',
      'username': 'admin',
      'password': hashPassword('admin123'),
      'role': 'Admin',
      'id_lokasi': null,
      'status_akun': 'Aktif',
    });
    await db.insert('tb_user', {
      'nama_lengkap': 'Guru Piket - SDN 01',
      'username': 'petugas1',
      'password': hashPassword('petugas123'),
      'role': 'Petugas',
      'id_lokasi': idLokasi1,
      'status_akun': 'Aktif',
    });

    const kategoriAwal = [
      {'nama_kategori': 'Basi', 'deskripsi': 'Makanan sudah basi/berbau tidak sedap'},
      {'nama_kategori': 'Kurang Matang', 'deskripsi': 'Makanan belum matang sempurna'},
      {'nama_kategori': 'Benda Asing', 'deskripsi': 'Ditemukan benda asing pada makanan'},
      {'nama_kategori': 'Kemasan Rusak', 'deskripsi': 'Kemasan makanan rusak/bocor'},
    ];
    for (final k in kategoriAwal) {
      await db.insert('tb_kategori_masalah', k);
    }

    // Menu contoh untuk hari ini supaya Petugas langsung bisa coba lapor
    final now = DateTime.now();
    final tanggalHariIni =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await db.insert('tb_menu', {
      'nama_menu': 'Nasi, Ayam Goreng, Sayur Bayam',
      'tanggal_sajian': tanggalHariIni,
      'id_lokasi': idLokasi1,
    });
  }

  /// Hash sederhana (SHA-256) untuk password yang disimpan lokal.
  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}
