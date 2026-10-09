# Aplikasi SI-LAYAK MBG — Mode Lokal (Demo 1 HP)

## Penting: Ini Versi Lokal/Offline
Aplikasi ini TIDAK memakai server/API/XAMPP sama sekali. Semua data (akun,
lokasi, menu, kategori masalah, laporan, notifikasi) disimpan di **database
SQLite di dalam HP itu sendiri**. Cocok untuk demo/presentasi tugas tanpa
perlu laptop+XAMPP menyala.

**Konsekuensi yang perlu dipahami:** karena datanya lokal per-HP, Admin dan
Petugas harus login **bergantian di HP yang sama**. Kalau aplikasi ini
diinstall di 2 HP berbeda, data laporan di HP Petugas TIDAK akan muncul di
HP Admin (tidak ada tempat bersama untuk saling kirim data). Untuk keperluan
selain demo (dipakai sungguhan oleh sekolah & admin di lokasi berbeda),
versi ini perlu diganti kembali ke versi berbasis server.

## 1. Persiapan Proyek
```bash
flutter create silayak_mbg
cd silayak_mbg
# Timpa folder lib/ dan pubspec.yaml bawaan dengan yang ada di paket ini
flutter pub get
```

## 2. Konfigurasi Android (lebih sederhana dari versi API)
Ikuti `android_config/AndroidManifest_petunjuk.md`:
1. Tambahkan permission CAMERA & READ_MEDIA_IMAGES.
2. Set `minSdk = 26` di `android/app/build.gradle`.

Tidak perlu izin internet atau konfigurasi jaringan apa pun.

## 3. Menjalankan di HP Fisik
```bash
flutter devices
flutter run
```
Tidak perlu WiFi/koneksi apa pun — aplikasi berjalan penuh offline.

## 4. Cara Demo Bergantian Admin ↔ Petugas
1. Buka aplikasi, login sebagai **Petugas** (`petugas1` / `petugas123`).
2. Buat laporan (foto + pilih menu + status kelayakan).
3. Tekan ikon **logout** di pojok kanan atas (ada di kedua peran), lalu
   login sebagai **Admin** (`admin` / `admin123`).
4. Buka tab **Verifikasi**, cek laporan yang baru dibuat, setujui/tolak.
5. Logout lagi, login sebagai Petugas untuk melihat notifikasi hasil
   verifikasi — begitu seterusnya, bolak-balik di 1 HP yang sama.

## 5. Struktur Folder `lib/`
```
lib/
├── main.dart
├── theme/app_theme.dart          # Tema & 3 warna dominan
├── models/                       # Model data
├── services/
│   ├── database_helper.dart      # Setup & skema database SQLite lokal
│   └── api_service.dart          # Semua operasi data (CRUD lokal, TANPA jaringan)
├── providers/                    # State management (auth & notifikasi)
├── screens/
│   ├── login_screen.dart / splash_screen.dart
│   ├── admin/                    # Semua layar khusus Admin
│   └── petugas/                  # Semua layar khusus Petugas Pelapor
└── widgets/
```

> Catatan: nama kelas `ApiService` sengaja dipertahankan (bukan diganti jadi
> "LocalService" atau semacamnya) supaya konsisten dan gampang ditelusuri.
> Isinya sudah murni database lokal, bukan panggilan jaringan.

## 6. Akun Login (dibuat otomatis saat aplikasi pertama kali dibuka)
| Role | Username | Password |
|---|---|---|
| Admin | `admin` | `admin123` |
| Petugas | `petugas1` | `petugas123` |

Data contoh (2 lokasi, 4 kategori masalah, 1 menu hari ini) juga otomatis
dibuat saat pertama kali aplikasi dijalankan (lihat `_seedData` di
`database_helper.dart`).

## 7. Tentang Fitur yang Menyesuaikan Mode Lokal
- **Foto bukti**: disalin ke folder dokumen aplikasi di HP (bukan diunggah
  ke server), path filenya disimpan di database lokal.
- **Notifikasi**: tetap dicek berkala (polling) tiap 20 detik, tapi sumbernya
  sekarang database lokal, bukan server — jadi selalu instan/realtime
  selama aplikasi terbuka, tanpa delay jaringan.
- **Export CSV**: dibuat sebagai file lokal lalu dibagikan lewat menu
  share/simpan bawaan HP (sebelumnya lewat link browser).
- **Export PDF**: tetap sama seperti sebelumnya — dibuat langsung di HP
  dan dibuka di pratinjau cetak/bagikan.
- **Reset data**: untuk mulai dari awal (hapus semua data lokal), uninstall
  lalu install ulang aplikasinya — atau hapus data aplikasi lewat
  Pengaturan > Aplikasi > SI-LAYAK MBG > Hapus Data/Storage di Android.

## 8. Catatan Desain (3 Warna Dominan) — tidak berubah
- **Hijau (`#1F7A5C`)** — warna utama/brand.
- **Merah (`#E15554`)** — aksen peringatan/status "Tidak Layak"/"Ditolak".
- **Putih/Krem (`#F5F6F4` & `#FFFFFF`)** — latar dan kartu.

## 9. Kalau Nanti Mau Kembali ke Versi Server (2 HP Terpisah)
Semua layar (UI) di folder `screens/` dan `widgets/` tetap sama persis dan
TIDAK perlu diubah. Yang perlu diganti hanya isi `services/api_service.dart`
(kembalikan ke versi yang memanggil HTTP ke backend PHP) — sudah pernah
dibuatkan sebelumnya kalau masih disimpan, atau bisa diminta dibuatkan lagi.
