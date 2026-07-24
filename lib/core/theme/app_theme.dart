import 'package:flutter/material.dart';

/// Token pusat untuk visual identity SmartLock Campus.
///
/// Filosofi (lihat UI_Implementation_Guidelines_SmartLock.md): navy sebagai
/// warna utama, putih sebagai surface, abu-abu terang sebagai background,
/// gaya enterprise yang bersih -- bukan playful/dashboard penuh dekorasi.
/// File ini BELUM dipakai di screen manapun selain lewat `Theme.of(context)`
/// di main.dart. Migrasi warna hardcoded di screen lain dilakukan bertahap,
/// nggak sekaligus.
class AppColors {
  AppColors._();

  // Primary -- Navy. `navy` = warna utama (button, app bar dark section),
  // `navyDark` untuk elemen yang butuh kontras lebih tinggi (mis. status
  // bar area / hero gelap), `navyLight` untuk state hover/pressed tipis.
  static const Color navy = Color(0xFF0B1F3A);
  static const Color navyDark = Color(0xFF071527);
  static const Color navyLight = Color(0xFF16305A);

  // Surface & background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF4F6F9);
  static const Color border = Color(0xFFE2E8F0);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textOnNavy = Color(0xFFFFFFFF);
  static const Color textOnNavyMuted = Color(0xFFB6C2D9);

  // Status -- dipakai secukupnya (StatusChip, dsb), bukan buat dekorasi.
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFE8F6ED);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFDF2E3);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFCEAEA);
  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFE8F0FE);
}

/// Sistem spacing: 4, 8, 12, 16, 24, 32, 48, 64.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;
}

/// Sistem radius: 12, 20, 24.
class AppRadius {
  AppRadius._();

  static const double small = 12;
  static const double medium = 20;
  static const double large = 24;

  static BorderRadius get smallAll => BorderRadius.circular(small);
  static BorderRadius get mediumAll => BorderRadius.circular(medium);
  static BorderRadius get largeAll => BorderRadius.circular(large);
}

/// Type scale terbatas: Display, Heading, Title, Body, Caption.
/// Sengaja tidak menambah dependency font baru (google_fonts dll) dulu --
/// pakai font sistem, cukup didisiplinkan lewat scale & weight yang jelas.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.navy,
      onPrimary: AppColors.textOnNavy,
      secondary: AppColors.navyLight,
      onSecondary: AppColors.textOnNavy,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      onError: AppColors.textOnNavy,
    );

    final textTheme = TextTheme(
      // Display -- headline paling besar (mis. judul splash/hero utama)
      displayMedium: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
      ),
      // Heading -- judul screen/section
      headlineSmall: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
      ),
      // Title -- judul card/list item
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      // Body -- teks utama
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      bodySmall: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
      // Caption -- label kecil, metadata
      labelSmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.3,
        letterSpacing: 0.2,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,

      // Border tipis + shadow ringan, bukan shadow tebal (lihat MD).
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mediumAll,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.textOnNavy,
          disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.4),
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smallAll),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smallAll),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallAll,
          borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}