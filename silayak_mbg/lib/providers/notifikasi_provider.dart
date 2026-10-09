import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notifikasi_model.dart';
import '../services/api_service.dart';

/// Notifikasi diimplementasikan dengan pendekatan polling berkala
/// (bukan push notification server-native/FCM) karena FCM memerlukan
/// proyek Firebase milik sendiri. Provider ini mengecek notifikasi baru
/// setiap beberapa detik selama aplikasi terbuka, lalu memicu badge
/// jumlah belum dibaca secara realtime di UI.
///
/// Jika ke depannya ingin push notification asli walau aplikasi tertutup,
/// tinggal tambahkan Firebase Cloud Messaging di titik ini.
class NotifikasiProvider extends ChangeNotifier {
  final int idUser;
  Timer? _timer;

  List<NotifikasiModel> _daftar = [];
  int _belumDibaca = 0;
  bool _isLoading = false;

  NotifikasiProvider({required this.idUser});

  List<NotifikasiModel> get daftar => _daftar;
  int get belumDibaca => _belumDibaca;
  bool get isLoading => _isLoading;

  void mulaiPolling() {
    ambilNotifikasi();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => ambilNotifikasi());
  }

  Future<void> ambilNotifikasi() async {
    try {
      _isLoading = true;
      final hasil = await ApiService.getNotifikasi(idUser);
      _daftar = hasil['notifikasi'];
      _belumDibaca = hasil['belum_dibaca'];
    } catch (_) {
      // Diamkan error polling supaya tidak mengganggu UI, akan dicoba lagi
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> tandaiSemuaSudahDibaca() async {
    await ApiService.markNotifikasiRead(idUser);
    await ambilNotifikasi();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
