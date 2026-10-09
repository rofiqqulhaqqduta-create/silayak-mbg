import 'package:flutter/material.dart';
import '../models/laporan_model.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class LaporanCard extends StatelessWidget {
  final LaporanModel laporan;
  final VoidCallback onTap;
  final bool tampilkanNamaPetugas;

  const LaporanCard({
    super.key,
    required this.laporan,
    required this.onTap,
    this.tampilkanNamaPetugas = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: laporan.isLayak ? AppColors.primaryLight : AppColors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  laporan.isLayak ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                  color: laporan.isLayak ? AppColors.primary : AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      laporan.namaLokasi,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      laporan.namaMenu,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tampilkanNamaPetugas) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Pelapor: ${laporan.namaPetugas}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusBadge(status: laporan.statusKelayakan),
                        StatusBadge(status: laporan.statusVerifikasi),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
