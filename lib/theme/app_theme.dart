import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF07140D);
  static const Color surface = Color(0xFF0E2117);
  static const Color surfaceElevated = Color(0xFF143321);
  static const Color primary = Color(0xFF4ADE80);
  static const Color primaryDark = Color(0xFF16A34A);
  static const Color primaryDeep = Color(0xFF052E16);
  static const Color accent = Color(0xFFA7F3D0);
  static const Color accentLight = Color(0xFFBBF7D0);
  static const Color textPrimary = Color(0xFFF0FDF4);
  static const Color textSecondary = Color(0xFFA7F3D0);
  static const Color textMuted = Color(0xFF7BA88E);
  static const Color border = Color(0xFF1F4D32);
  static const Color borderBright = Color(0xFF2F7B4F);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);
  static const Color info = Color(0xFF38BDF8);

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: danger,
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: const TextStyle(
          color: textPrimary,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        headlineMedium: const TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: const TextStyle(color: textPrimary, fontSize: 14),
        bodySmall: const TextStyle(color: textSecondary, fontSize: 12),
        labelSmall: const TextStyle(
          color: accentLight,
          fontSize: 11,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: textSecondary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderBright, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderBright, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
        prefixIconColor: textMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF052E16),
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentTextStyle: const TextStyle(color: textPrimary),
      ),
    );
  }
}
