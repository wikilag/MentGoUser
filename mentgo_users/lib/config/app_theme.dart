import 'package:flutter/material.dart';

/// Colores y estilos inspirados directamente en el logo oficial de Mental Go.
class MentalGoTheme {
  // Verde turquesa / esmeralda ("Go" y pin del cerebro)
  static const Color primaryTeal = Color(0xFF11AC8E);

  // Azul marino profundo ("Mental" y "APP")
  static const Color darkNavy = Color(0xFF08253A);

  // Tonos suaves y neutros del logo
  static const Color softMint = Color(0xFFE7F7F4);
  static const Color subtitleGray = Color(0xFF4A5559);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Ruta del logo en assets
  static const String logoAsset = 'assets/images/mental_go_logo.jpg';

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryTeal,
      primary: primaryTeal,
      onPrimary: Colors.white,
      secondary: darkNavy,
      onSecondary: Colors.white,
      primaryContainer: softMint,
      onPrimaryContainer: darkNavy,
      surface: pureWhite,
      onSurface: darkNavy,
      onSurfaceVariant: subtitleGray,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: pureWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: pureWhite,
        foregroundColor: darkNavy,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7FBFA),
        labelStyle: const TextStyle(color: subtitleGray),
        prefixIconColor: primaryTeal,
        suffixIconColor: subtitleGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD0EAE4), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryTeal,
        ),
      ),
    );
  }
}
