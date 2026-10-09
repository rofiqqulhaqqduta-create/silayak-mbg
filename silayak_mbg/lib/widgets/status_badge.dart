import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Badge kecil untuk menampilkan status kelayakan / status verifikasi
/// dengan warna semantik yang konsisten di seluruh aplikasi.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  _StatusStyle _resolve(String status) {
    switch (status) {
      case 'Layak':
      case 'Disetujui':
      case 'Aktif':
        return _StatusStyle(AppColors.primary, AppColors.primaryLight);
      case 'Tidak Layak':
      case 'Ditolak':
        return _StatusStyle(AppColors.accent, AppColors.accentLight);
      case 'Menunggu':
      default:
        return _StatusStyle(AppColors.pending, AppColors.pendingLight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: style.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusStyle {
  final Color foreground;
  final Color background;
  _StatusStyle(this.foreground, this.background);
}
