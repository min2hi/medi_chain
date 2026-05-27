import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── App-wide theme notifier ───────────────────────────────────────────────────
// Singleton ValueNotifier — main.dart dùng ValueListenableBuilder để listen.
// Không cần ThemeBloc phức tạp — ValueNotifier là đủ cho thành phần đơn giản này.
class AppThemeNotifier {
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier(ThemeMode.light);

  /// Gọi trong main() để đọc setting đã lưu
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    mode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Toggle và persist sang SharedPreferences
  static Future<void> toggle() async {
    final nowDark = mode.value == ThemeMode.dark;
    mode.value = nowDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', !nowDark);
  }

  static bool get isDark => mode.value == ThemeMode.dark;
}

class AppTheme {
  // ─── Core Brand ─────────────────────────────────────────────────────────────
  static const Color kPrimary      = Color(0xFF14B8A6);
  static const Color kPrimaryDark  = Color(0xFF0D9488);
  static const Color kPrimaryLight = Color(0xFFCCFBF1); // teal tint surface

  // ─── Backgrounds & Surfaces ──────────────────────────────────────────────────
  static const Color kBg      = Color(0xFFF8FAFC);
  static const Color kSurface = Color(0xFFFFFFFF);

  // ─── Text ────────────────────────────────────────────────────────────────────
  static const Color kTextPrimary   = Color(0xFF0F172A);
  static const Color kTextSecondary = Color(0xFF475569);
  static const Color kTextMuted     = Color(0xFF94A3B8);

  // ─── Border ──────────────────────────────────────────────────────────────────
  static const Color kBorder = Color(0xFFE2E8F0);

  // ─── Semantic Colors (chỉ dùng với đúng semantic, không random) ──────────────
  static const Color kSuccess = Color(0xFF10B981); // Active, healthy, done
  static const Color kWarning = Color(0xFFF59E0B); // Expiring soon, caution
  static const Color kDanger  = Color(0xFFEF4444); // Expired, critical, error
  static const Color kError   = Color(0xFFEF4444); // Alias of kDanger
  static const Color kInfo    = Color(0xFF3B82F6); // Info, links
  static const Color kAccent  = Color(0xFF3B82F6);

  // ─── Semantic Surface Tints (cho background của badges/alerts) ───────────────
  static const Color kSuccessSurface = Color(0xFFF0FDF4);
  static const Color kWarningSurface = Color(0xFFFFFBEB);
  static const Color kDangerSurface  = Color(0xFFFEF2F2);
  static const Color kInfoSurface    = Color(0xFFEFF6FF);


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

  // ─── Dark Theme — legible, premium dark palette ────────────────────────────────
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );
    // ── Dark palette — được calibrate cho mắt người Việt/OLED screens
    // Rule: mỗi layer phải có đủ contrast để mắt phân biệt — không quá tối, không quá sáng
    const darkBg       = Color(0xFF0D1520); // background chính — deep navy, không pure black
    const darkSurface  = Color(0xFF182030); // card surface — rõ hơn bg +7% lightness
    const darkSurface2 = Color(0xFF1E2C3D); // elevated card (nested) — thêm 1 layer nữa
    const darkBorder   = Color(0xFF2A3A50); // border rõ hơn — tăng từ 334155 → 2A3A50
    const darkText     = Color(0xFFECF0F6); // primary text — slightly off-white, dễ mắt hơn pure white
    const darkTextSub  = Color(0xFF8A9BB5); // secondary text — rõ hơn mà vẫn hierarchy
    const darkMuted    = Color(0xFF4E6280); // muted/placeholder — tối hơn, rõ phân cấp

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: baseTextTheme.copyWith(
        bodyLarge:  baseTextTheme.bodyLarge?.copyWith(color: darkText),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: darkText),
        bodySmall:  baseTextTheme.bodySmall?.copyWith(color: darkTextSub),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: darkText, fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: darkText, fontWeight: FontWeight.w600,
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimary,
        brightness: Brightness.dark,
        primary:   kPrimary,
        secondary: kAccent,
        surface:   darkBg,
        error:     kError,
        onSurface: darkText,
      ),
      scaffoldBackgroundColor: darkBg,
      cardColor: darkSurface,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      dividerColor: darkBorder,
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: darkText,
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
        fillColor: darkSurface2, // input fields dùng elevated layer — nổi rõ hơn
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kError),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: darkMuted),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSpacing — Consistent spatial scale (8-point grid)
// ─────────────────────────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppRadius — Border radius scale
// ─────────────────────────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 24.0;
  static const double full = 999.0; // pill shape
}

// ─────────────────────────────────────────────────────────────────────────────
// AppShadow — Elevation system (3 levels)
// ─────────────────────────────────────────────────────────────────────────────
class AppShadow {
  AppShadow._();

  /// Subtle card shadow — default for all surface cards
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Medium shadow — FAB, bottom sheets, modals
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Teal glow — primary CTA buttons, active states
  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color(0x3314B8A6),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminColors — Design tokens cho Admin Portal
// Dùng thay cho hardcode hex trong mọi admin screen & widget.
// Inspired by: Linear, Vercel Dashboard, Datadog dark theme.
// ─────────────────────────────────────────────────────────────────────────────
class AdminColors {
  AdminColors._();

  // ── Background Layers (deep → shallow) ───────────────────────────────────
  static const Color bg       = Color(0xFF080E1A); // Body background
  static const Color surface  = Color(0xFF0F1829); // Card / tile
  static const Color elevated = Color(0xFF162237); // Pressed / hover state
  static const Color overlay  = Color(0xFF1A2A42); // Dialog / modal

  // ── Borders ──────────────────────────────────────────────────────────────
  static const Color border      = Color(0xFF1E2D42);
  static const Color borderFocus = Color(0xFF2E4A6A);
  // Shimmer highlight — skeleton loading animation mid-color
  static const Color shimmer     = Color(0xFF1E2D42);

  // ── Legacy dark aliases (backward compat for keywords_screen) ────────────
  static const Color darkSurface = surface;
  static const Color darkBg      = bg;
  static const Color darkBorder  = border;

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFEFF3FF);
  static const Color textSecondary = Color(0xFF7A90B0);
  static const Color textMuted     = Color(0xFF445566);

  // ── Semantic Colors ───────────────────────────────────────────────────────
  static const Color aiPrimary = Color(0xFF6366F1); // Indigo — AI/actions
  static const Color success   = Color(0xFF10B981); // Emerald — approved
  static const Color warning   = Color(0xFFF59E0B); // Amber — pending
  static const Color danger    = Color(0xFFEF4444); // Red — error/blocked
  static const Color info      = Color(0xFF3B82F6); // Blue — review/info
  static const Color purple    = Color(0xFF8B5CF6); // Purple — system/ops

  // ── Role Colors ───────────────────────────────────────────────────────────
  static const Color roleAdmin   = Color(0xFFEC4899);
  static const Color roleDoctor  = Color(0xFF3B82F6);
  static const Color rolePatient = Color(0xFF10B981);

  // ── Dashboard Header Gradient (Linear-style) ──────────────────────────────
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF080E1A), Color(0xFF12103A)],
  );
}
