import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum StatusType { success, warning, danger, info, neutral }

/// Badge kecil buat status ("Aktif", "Selesai", "Menunggu", dst).
/// Dipakai bareng di HomeScreen, ScheduleCard, riwayat presensi, dll --
/// biar warna & bentuknya konsisten, nggak beda-beda tiap screen.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.type = StatusType.neutral,
    this.icon,
  });

  final String label;
  final StatusType type;
  final IconData? icon;

  ({Color fg, Color bg}) get _colors {
    switch (type) {
      case StatusType.success:
        return (fg: AppColors.success, bg: AppColors.successBg);
      case StatusType.warning:
        return (fg: AppColors.warning, bg: AppColors.warningBg);
      case StatusType.danger:
        return (fg: AppColors.danger, bg: AppColors.dangerBg);
      case StatusType.info:
        return (fg: AppColors.info, bg: AppColors.infoBg);
      case StatusType.neutral:
        return (fg: AppColors.textSecondary, bg: AppColors.background);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: colors.fg),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: colors.fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}