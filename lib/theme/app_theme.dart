import 'package:flutter/material.dart';

class AppColors {
  static const Color midnight = Color(0xFF08111F);
  static const Color navy = Color(0xFF10203A);
  static const Color cyan = Color(0xFF55D6FF);
  static const Color gold = Color(0xFFFFC96B);
  static const Color coral = Color(0xFFFF7A73);
  static const Color mint = Color(0xFF98F7C0);
  static const Color textPrimary = Color(0xFFF7F8FB);
  static const Color textMuted = Color(0xFFA9B6C8);
  static const Color stroke = Color(0x33FFFFFF);
}

class AppTheme {
  static ThemeData get theme {
    final scheme =
        ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: AppColors.cyan,
        ).copyWith(
          primary: AppColors.cyan,
          secondary: AppColors.gold,
          error: AppColors.coral,
          surface: AppColors.navy,
          onPrimary: AppColors.midnight,
          onSecondary: AppColors.midnight,
          onSurface: AppColors.textPrimary,
        );

    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          height: 1.02,
          letterSpacing: -1.8,
        ),
        headlineMedium: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -0.8,
        ),
        titleLarge: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: const TextStyle(color: AppColors.textPrimary, height: 1.5),
        bodyMedium: const TextStyle(color: AppColors.textMuted, height: 1.45),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xDD13243B),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF13233B),
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        side: const BorderSide(color: AppColors.stroke),
      ),
      dividerColor: Colors.white12,
    );
  }
}
