import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// Splash screen SmartLock Campus.
///
/// Catatan desain: referensi asli pakai radial glow di belakang icon.
/// MD (UI_Implementation_Guidelines) eksplisit minta hindari "gradient
/// baru", jadi glow itu sengaja TIDAK dipakai di sini -- diganti solid
/// navy flat + satu entrance animation kecil (scale + fade) sebagai
/// feedback, bukan dekorasi. Setelah delay singkat, screen ini nyerahin
/// keputusan rute ke redirect logic di app_router (bukan hardcode ke
/// '/home' atau '/login').
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    // Redirect logic di app_router yang menentukan tujuan akhir (login
    // atau langsung home/lecturer-home kalau token masih valid).
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.navyLight,
                            borderRadius: AppRadius.mediumAll,
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: const Center(
                            child: Icon(Icons.lock_outline_rounded, color: Colors.white, size: 36),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const Text(
                          'SmartLock Campus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'SISTEM PRESENSI & AKSES KAMPUS',
                          style: TextStyle(
                            color: AppColors.textOnNavyMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_outlined, color: AppColors.textOnNavyMuted, size: 14),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Dsolve Studio',
                    style: TextStyle(
                      color: AppColors.textOnNavyMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}