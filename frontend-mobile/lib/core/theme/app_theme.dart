import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Design tokens — đồng nhất với web globals.css ─────────────────────────
  static const Color kPrimary     = Color(0xFF14B8A6); // --primary
  static const Color kPrimaryDark = Color(0xFF0D9488); // --primary-hover
  static const Color kBg          = Color(0xFFF8FAFC); // --background
  static const Color kSurface     = Color(0xFFFFFFFF); // --surface
  static const Color kTextPrimary = Color(0xFF0F172A); // --text-primary
  static const Color kTextSecondary = Color(0xFF475569); // --text-secondary
  static const Color kTextMuted   = Color(0xFF94A3B8); // --text-muted
  static const Color kBorder      = Color(0xFFE2E8F0); // --border
  static const Color kError       = Color(0xFFEF4444);
  static const Color kAccent      = Color(0xFF3B82F6);

  static ThemeData get lightTheme {
    // Inter font — đồng nhất với web (Inter from Google Fonts)
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: baseTextTheme.copyWith(
        bodyLarge:  baseTextTheme.bodyLarge?.copyWith(color: kTextPrimary),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: kTextPrimary),
        bodySmall:  baseTextTheme.bodySmall?.copyWith(color: kTextSecondary),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: kTextPrimary, fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: kTextPrimary, fontWeight: FontWeight.w600,
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimary,
        primary:   kPrimary,
        secondary: kAccent,
        surface:   kBg,
        error:     kError,
        onSurface: kTextPrimary,
      ),
      scaffoldBackgroundColor: kBg,
      cardTheme: CardThemeData(
        color: kSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: kSurface,
        foregroundColor: kTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: kTextPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kError),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: kTextMuted),
      ),
    );
  }
}
