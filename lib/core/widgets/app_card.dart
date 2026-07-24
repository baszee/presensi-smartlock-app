import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bungkus standar buat semua card putih (hero card, stat card, schedule
/// card, dst). Border tipis + shadow ringan sesuai MD (hindari shadow
/// tebal). Pakai ini alih-alih Container manual biar radius & padding
/// konsisten di semua screen.
///
/// `filled` -- kalau true, background navy (dipakai buat hero/summary
/// card gelap seperti "84% Attendance This Week" di referensi desain).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.filled = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: filled ? AppColors.navy : AppColors.surface,
        borderRadius: AppRadius.mediumAll,
        border: filled ? null : Border.all(color: AppColors.border, width: 1),
        boxShadow: filled
            ? null
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.mediumAll,
        onTap: onTap,
        child: content,
      ),
    );
  }
}