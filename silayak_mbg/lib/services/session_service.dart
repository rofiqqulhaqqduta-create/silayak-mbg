import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

/// Menyimpan sesi login pengguna secara aman di perangkat
/// (memenuhi kebutuhan non-fungsional "secure local storage").
class SessionService {
  static const _storage = FlutterSecureStorage();
  static const _keyUser = 'silayak_mbg_user_session';

  static Future<void> saveUser(UserModel user) async {
    await _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    final raw = await _storage.read(key: _keyUser);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    await _storage.delete(key: _keyUser);
  }
}
