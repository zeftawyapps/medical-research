import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Available Medical Research Color Palettes
enum AppThemePalette {
  medicalTeal,
  clinicalNavy,
  nordicSage,
  charcoalCyan,
  deepIndigo,
  graphiteRose,
  warmSand,
  oledDark,
}

/// Palette Metadata for UI & Rendering
class PaletteConfig {
  final String id;
  final String titleEn;
  final String titleAr;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color? lightPrimary;
  final Color? darkPrimary;
  final Color? lightSecondary;
  final Color? darkSecondary;
  final Color? lightAccent;
  final Color? darkAccent;
  final Color darkBg;
  final Color darkSurface;
  final Color darkCard;
  final Color darkBorder;
  final Color lightBg;
  final Color lightSurface;
  final Color lightCard;
  final Color lightBorder;
  final Color lightTextPrimary;
  final Color lightTextSecondary;
  final Color darkTextPrimary;
  final Color darkTextSecondary;

  const PaletteConfig({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.primary,
    required this.secondary,
    required this.accent,
    this.lightPrimary,
    this.darkPrimary,
    this.lightSecondary,
    this.darkSecondary,
    this.lightAccent,
    this.darkAccent,
    required this.darkBg,
    required this.darkSurface,
    required this.darkCard,
    required this.darkBorder,
    required this.lightBg,
    required this.lightSurface,
    required this.lightCard,
    required this.lightBorder,
    this.lightTextPrimary = const Color(0xFF0F172A),
    this.lightTextSecondary = const Color(0xFF475569), // Upgraded to Slate 600 (7:1 AAA contrast)
    this.darkTextPrimary = const Color(0xFFF8FAFC),
    this.darkTextSecondary = const Color(0xFF94A3B8), // Upgraded to Slate 400 (8.5:1 contrast)
  });

  /// Get mode-calibrated primary color (600-700 for light mode, 400-500 for dark mode)
  Color getPrimary(bool isDark) => isDark ? (darkPrimary ?? primary) : (lightPrimary ?? primary);

  /// Get mode-calibrated secondary color
  Color getSecondary(bool isDark) => isDark ? (darkSecondary ?? secondary) : (lightSecondary ?? secondary);

  /// Get mode-calibrated accent color
  Color getAccent(bool isDark) => isDark ? (darkAccent ?? accent) : (lightAccent ?? accent);
}

class AppTheme {
  // Alert & Utility Colors
  static const Color alertAmber = Color(0xFFFFB703);
  static const Color alertAmberDarkText = Color(0xFFB45309); // High-contrast amber for light backgrounds
  static const Color alertRed = Color(0xFFEF476F);
  static const Color alertGreen = Color(0xFF10B981);

  // Unified Ultra-Deep Obsidian Dark Mode Foundation across ALL palettes
  static const Color uniformDarkBg = Color(0xFF06080C); // Ultra-deep pitch dark
  static const Color uniformDarkSurface = Color(0xFF0D1117); // Deep obsidian surface
  static const Color uniformDarkCard = Color(0xFF141923); // Elevated dark card
  static const Color uniformDarkBorder = Color(0xFF222B3D); // Subtle crisp slate border
  static const Color uniformDarkTextPrimary = Color(0xFFF8FAFC);
  static const Color uniformDarkTextSecondary = Color(0xFF94A3B8);

  // Modern Clinical Light Mode Foundation (Sterile, anti-glare, pristine medical slate)
  static const Color uniformLightBg = Color(0xFFF8FAFC); // Clean Slate 50
  static const Color uniformLightSurface = Color(0xFFFFFFFF); // Clean pure white surface
  static const Color uniformLightCard = Color(0xFFFFFFFF); // Elevated crisp card
  static const Color uniformLightBorder = Color(0xFFE2E8F0); // Crisp border (Slate 200)
  static const Color uniformLightTextPrimary = Color(0xFF0F172A); // Deep Slate 900
  static const Color uniformLightTextSecondary = Color(0xFF475569); // Slate 600 (7:1 contrast)

  /// Palettes Dictionary with Mode-Aware Colors for Maximum Contrast & Harmony
  static final Map<AppThemePalette, PaletteConfig> palettes = {
    AppThemePalette.medicalTeal: const PaletteConfig(
      id: 'medical_teal',
      titleEn: 'Medical Teal & Slate',
      titleAr: 'تركواز طبي وسليت',
      primary: Color(0xFF0D9488),
      secondary: Color(0xFF14B8A6),
      accent: Color(0xFF06B6D4),
      lightPrimary: Color(0xFF0F766E), // Teal 700 (5.3:1 contrast on white)
      darkPrimary: Color(0xFF0D9488), // Teal 600 (Darkened, rich)
      lightSecondary: Color(0xFF115E59), // Teal 800 (6.5:1 on white)
      darkSecondary: Color(0xFF0F766E), // Teal 700 (Darkened)
      lightAccent: Color(0xFF0284C7),
      darkAccent: Color(0xFF14B8A6),
      darkBg: uniformDarkBg,
      darkSurface: uniformDarkSurface,
      darkCard: uniformDarkCard,
      darkBorder: uniformDarkBorder,
      lightBg: uniformLightBg,
      lightSurface: uniformLightSurface,
      lightCard: uniformLightCard,
      lightBorder: uniformLightBorder,
    ),
    AppThemePalette.clinicalNavy: const PaletteConfig(
      id: 'clinical_navy',
      titleEn: 'Clinical Navy & Cobalt',
      titleAr: 'كحلي جراحي وكوبالت',
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF3B82F6),
      accent: Color(0xFF60A5FA),
      lightPrimary: Color(0xFF1D4ED8), // Blue 700 (5.5:1 contrast on white)
      darkPrimary: Color(0xFF2563EB), // Blue 600 (Darkened, 5.1:1 with white)
      lightSecondary: Color(0xFF1E40AF), // Blue 800
      darkSecondary: Color(0xFF1D4ED8), // Blue 700 (Darkened, 7.0:1 with white)
      lightAccent: Color(0xFF0284C7),
      darkAccent: Color(0xFF38BDF8),
      darkBg: uniformDarkBg,
      darkSurface: uniformDarkSurface,
      darkCard: uniformDarkCard,
      darkBorder: uniformDarkBorder,
      lightBg: uniformLightBg,
      lightSurface: uniformLightSurface,
      lightCard: uniformLightCard,
      lightBorder: uniformLightBorder,
    ),
    AppThemePalette.nordicSage: const PaletteConfig(
      id: 'nordic_sage',
      titleEn: 'Nordic Sage & Emerald',
      titleAr: 'أخضر مهدئ وزمردي',
      primary: Color(0xFF059669),
      secondary: Color(0xFF10B981),
      accent: Color(0xFF34D399),
      lightPrimary: Color(0xFF047857), // Emerald 700 (5.2:1 contrast on white)
      darkPrimary: Color(0xFF059669), // Emerald 600 (Darkened from 500)
      lightSecondary: Color(0xFF065F46), // Emerald 800
      darkSecondary: Color(0xFF047857), // Emerald 700 (Darkened from 400)
      lightAccent: Color(0xFF0F766E),
      darkAccent: Color(0xFF0D9488),
      darkBg: uniformDarkBg,
      darkSurface: uniformDarkSurface,
      darkCard: uniformDarkCard,
      darkBorder: uniformDarkBorder,
      lightBg: uniformLightBg,
      lightSurface: uniformLightSurface,
      lightCard: uniformLightCard,
      lightBorder: uniformLightBorder,
    ),
    AppThemePalette.charcoalCyan: const PaletteConfig(
      id: 'charcoal_cyan',
      titleEn: 'Charcoal & Sky Cyan',
      titleAr: 'فحمي وسماوي مشرق',
      primary: Color(0xFF0891B2),
      secondary: Color(0xFF06B6D4),
      accent: Color(0xFF38BDF8),
      lightPrimary: Color(0xFF0E7490), // Cyan 700 (4.9:1 contrast on white)
      darkPrimary: Color(0xFF0891B2), // Cyan 600 (Darkened from 500)
      lightSecondary: Color(0xFF155E75), // Cyan 800
      darkSecondary: Color(0xFF0E7490), // Cyan 700 (Darkened from 400)
      lightAccent: Color(0xFF0369A1),
      darkAccent: Color(0xFF0284C7),
      darkBg: uniformDarkBg,
      darkSurface: uniformDarkSurface,
      darkCard: uniformDarkCard,
      darkBorder: uniformDarkBorder,
      lightBg: uniformLightBg,
      lightSurface: uniformLightSurface,
      lightCard: uniformLightCard,
      lightBorder: uniformLightBorder,
    ),
    AppThemePalette.deepIndigo: const PaletteConfig(
      id: 'deep_indigo',
      titleEn: 'Deep Indigo & Amber',
      titleAr: 'نيلي عميق وعنبري',
      primary: Color(0xFF4F46E5),
      secondary: Color(0xFF6366F1),
      accent: Color(0xFFF59E0B),
      lightPrimary: Color(0xFF4338CA), // Indigo 700 (6.8:1 contrast on white)
      darkPrimary: Color(0xFF4F46E5), // Indigo 600 (Darkened, 5.25:1 with white)
      lightSecondary: Color(0xFF3730A3), // Indigo 800
      darkSecondary: Color(0xFF4338CA), // Indigo 700 (Darkened, 8.0:1 with white)
      lightAccent: Color(0xFFB45309),
      darkAccent: Color(0xFFD97706),
      darkBg: uniformDarkBg,
      darkSurface: uniformDarkSurface,
      darkCard: uniformDarkCard,
      darkBorder: uniformDarkBorder,
      lightBg: uniformLightBg,
      lightSurface: uniformLightSurface,
      lightCard: uniformLightCard,
      lightBorder: uniformLightBorder,
    ),
    AppThemePalette.graphiteRose: const PaletteConfig(
      id: 'graphite_rose',
      titleEn: 'Graphite & Rose Coral',
      titleAr: 'رمادي ومرجاني دافئ',
      primary: Color(0xFFE11D48),
      secondary: Color(0xFFF43F5E),
      accent: Color(0xFFFB7185),
      lightPrimary: Color(0xFFBE123C), // Rose 700 (5.6:1 contrast on white)
      darkPrimary: Color(0xFFE11D48), // Rose 600 (Darkened from 500, 5.8:1 with white)
      lightSecondary: Color(0xFF9F1239), // Rose 800
      darkSecondary: Color(0xFFBE123C), // Rose 700 (Darkened from 400, 6.1:1 with white)
      lightAccent: Color(0xFF881337),
      darkAccent: Color(0xFFFB7185),
      darkBg: uniformDarkBg,
      darkSurface: uniformDarkSurface,
      darkCard: uniformDarkCard,
      darkBorder: uniformDarkBorder,
      lightBg: uniformLightBg,
      lightSurface: uniformLightSurface,
      lightCard: uniformLightCard,
      lightBorder: uniformLightBorder,
    ),
    AppThemePalette.warmSand: const PaletteConfig(
      id: 'warm_sand',
      titleEn: 'Warm Sand & Bronze',
      titleAr: 'رملي مريح وبرونزي',
      primary: Color(0xFFD97706),
      secondary: Color(0xFFF59E0B),
      accent: Color(0xFFB45309),
      lightPrimary: Color(0xFFB45309), // Amber 700 (4.8:1 contrast on light)
      darkPrimary: Color(0xFFD97706), // Amber 600 (Darkened from 500)
      lightSecondary: Color(0xFF92400E), // Amber 800
      darkSecondary: Color(0xFFB45309), // Amber 700 (Darkened from 400)
      lightAccent: Color(0xFF78350F),
      darkAccent: Color(0xFFD97706),
      darkBg: uniformDarkBg,
      darkSurface: uniformDarkSurface,
      darkCard: uniformDarkCard,
      darkBorder: uniformDarkBorder,
      lightBg: Color(0xFFFAF7F2), // Subtle warm travertine (not muddy)
      lightSurface: Color(0xFFFFFFFF),
      lightCard: Color(0xFFFFFFFF),
      lightBorder: Color(0xFFE7E1D7),
    ),
    AppThemePalette.oledDark: const PaletteConfig(
      id: 'oled_dark',
      titleEn: 'OLED High-Contrast',
      titleAr: 'أسود مطلق عالي التباين',
      primary: Color(0xFF38BDF8),
      secondary: Color(0xFF4ADE80),
      accent: Color(0xFFFACC15),
      lightPrimary: Color(0xFF0284C7), // Sky 600 (4.7:1 contrast on white)
      darkPrimary: Color(0xFF0284C7), // Sky 600 (Darkened & crisp on pure black)
      lightSecondary: Color(0xFF047857), // Emerald 700
      darkSecondary: Color(0xFF059669), // Emerald 600 (Darkened)
      lightAccent: Color(0xFFCA8A04),
      darkAccent: Color(0xFFD97706),
      darkBg: Color(0xFF000000), // Pure Black for Samsung AMOLED
      darkSurface: Color(0xFF0C0C0C),
      darkCard: Color(0xFF141414),
      darkBorder: Color(0xFF262626),
      lightBg: uniformLightBg,
      lightSurface: uniformLightSurface,
      lightCard: uniformLightCard,
      lightBorder: uniformLightBorder,
    ),
  };

  // Legacy const colors for existing const widget trees
  static const Color primaryCyan = Color(0xFF0D9488);
  static const Color primaryTeal = Color(0xFF14B8A6);
  static const Color accentIndigo = Color(0xFF4361EE);
  static const Color accentPurple = Color(0xFF7209B7);
  static const Color darkBackground = uniformDarkBg;
  static const Color darkSurface = uniformDarkSurface;
  static const Color darkCard = uniformDarkCard;
  static const Color darkBorder = uniformDarkBorder;
  static const Color darkTextPrimary = uniformDarkTextPrimary;
  static const Color darkTextSecondary = uniformDarkTextSecondary;

  static const Color lightBackground = uniformLightBg;
  static const Color lightSurface = uniformLightSurface;
  static const Color lightCard = uniformLightCard;
  static const Color lightBorder = uniformLightBorder;
  static const Color lightTextPrimary = uniformLightTextPrimary;
  static const Color lightTextSecondary = uniformLightTextSecondary;

  // Linear Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF14B8A6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF4361EE), Color(0xFF7209B7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [uniformDarkSurface, uniformDarkCard],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme => getTheme(AppThemePalette.medicalTeal, true);
  static ThemeData get lightTheme => getTheme(AppThemePalette.medicalTeal, false);

  /// Computes optimal text color (deep dark slate or crisp white) for maximum WCAG contrast
  static Color getContrastTextColor(Color background) {
    final lumBg = background.computeLuminance();
    // Contrast with white: (1.0 + 0.05) / (lumBg + 0.05)
    final contrastWithWhite = 1.05 / (lumBg + 0.05);
    // Contrast with dark slate (#090D16, lum ~ 0.007): (lumBg + 0.05) / 0.057
    final contrastWithDark = (lumBg + 0.05) / 0.057;
    // Choose whichever text color yields superior WCAG contrast
    return contrastWithDark >= contrastWithWhite
        ? const Color(0xFF090D16) // Deep black-slate for light/pastel backgrounds (>= 5:1)
        : Colors.white; // Crisp pure white for dark backgrounds (>= 5:1)
  }

  /// Dynamically build complete ThemeData for any selected palette
  static ThemeData getTheme(AppThemePalette palette, bool isDark) {
    final cfg = palettes[palette] ?? palettes[AppThemePalette.medicalTeal]!;
    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

    final bg = isDark ? cfg.darkBg : cfg.lightBg;
    final surface = isDark ? cfg.darkSurface : cfg.lightSurface;
    final card = isDark ? cfg.darkCard : cfg.lightCard;
    final border = isDark ? cfg.darkBorder : cfg.lightBorder;
    final textPrimary = isDark ? cfg.darkTextPrimary : cfg.lightTextPrimary;
    final textSecondary = isDark ? cfg.darkTextSecondary : cfg.lightTextSecondary;

    final primary = cfg.getPrimary(isDark);
    final secondary = cfg.getSecondary(isDark);
    final accent = cfg.getAccent(isDark);

    // Dynamic contrast-aware text on primary/secondary/accent
    final onPrimary = getContrastTextColor(primary);
    final onSecondary = getContrastTextColor(secondary);
    final onTertiary = getContrastTextColor(accent);

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: primary,
            onPrimary: onPrimary,
            primaryContainer: primary.withValues(alpha: 0.22),
            onPrimaryContainer: const Color(0xFFF1F5F9),
            secondary: secondary,
            onSecondary: onSecondary,
            secondaryContainer: secondary.withValues(alpha: 0.18),
            onSecondaryContainer: const Color(0xFFF1F5F9),
            tertiary: accent,
            onTertiary: onTertiary,
            tertiaryContainer: accent.withValues(alpha: 0.18),
            onTertiaryContainer: const Color(0xFFF1F5F9),
            surface: surface,
            onSurface: textPrimary,
            onSurfaceVariant: textSecondary,
            outline: border,
            outlineVariant: border.withValues(alpha: 0.65),
            error: alertRed,
            onError: Colors.white,
            errorContainer: alertRed.withValues(alpha: 0.22),
            onErrorContainer: const Color(0xFFFFB4AB),
            surfaceContainerHighest: cfg.darkCard,
            surfaceContainerHigh: cfg.darkSurface,
            surfaceContainer: cfg.darkSurface,
            surfaceContainerLow: cfg.darkBg,
          )
        : ColorScheme.light(
            primary: primary,
            onPrimary: onPrimary,
            primaryContainer: primary.withValues(alpha: 0.10),
            onPrimaryContainer: primary,
            secondary: secondary,
            onSecondary: onSecondary,
            secondaryContainer: secondary.withValues(alpha: 0.10),
            onSecondaryContainer: secondary,
            tertiary: accent,
            onTertiary: onTertiary,
            tertiaryContainer: accent.withValues(alpha: 0.10),
            onTertiaryContainer: accent,
            surface: surface,
            onSurface: textPrimary,
            onSurfaceVariant: textSecondary,
            outline: border,
            outlineVariant: border.withValues(alpha: 0.65),
            error: alertRed,
            onError: Colors.white,
            errorContainer: alertRed.withValues(alpha: 0.10),
            onErrorContainer: const Color(0xFF90001D),
            surfaceContainerHighest: const Color(0xFFE2E8F0),
            surfaceContainerHigh: const Color(0xFFEDF2F7),
            surfaceContainer: cfg.lightSurface,
            surfaceContainerLow: cfg.lightBg,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w700),
        headlineSmall: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w400),
        bodySmall: GoogleFonts.inter(color: textSecondary, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600),
        labelMedium: GoogleFonts.inter(color: textSecondary, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.inter(color: textSecondary, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? (palette == AppThemePalette.oledDark ? const Color(0xFF101010) : cfg.darkSurface)
            : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: alertRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: alertRed, width: 2.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border.withValues(alpha: 0.5), width: 1.0),
        ),
        labelStyle: TextStyle(
          color: textSecondary,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: primary,
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
        ),
        hintStyle: TextStyle(
          color: textSecondary.withValues(alpha: 0.75),
          fontSize: 13,
        ),
        prefixIconColor: primary,
        suffixIconColor: textSecondary,
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.18),
        selectedIconTheme: IconThemeData(color: primary, size: 24),
        unselectedIconTheme: IconThemeData(color: textSecondary, size: 22),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 12,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return GoogleFonts.inter(
            color: textSecondary,
            fontSize: 12,
          );
        }),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? cfg.darkCard : const Color(0xFF0F172A),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: primary.withValues(alpha: isDark ? 0.25 : 0.15),
        disabledColor: border.withValues(alpha: 0.3),
        secondarySelectedColor: primary,
        labelStyle: TextStyle(color: textPrimary, fontSize: 12),
        secondaryLabelStyle: TextStyle(color: onPrimary, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border),
        ),
      ),
    );
  }

  // Sidebar styling helpers for AdaptiveAppShell
  static Color getSidebarBg(AppThemePalette palette, bool isDark) {
    final cfg = palettes[palette] ?? palettes[AppThemePalette.medicalTeal]!;
    return isDark ? uniformDarkBg : cfg.lightSurface;
  }

  static Color getSidebarSelectedColor(AppThemePalette palette, bool isDark) {
    final cfg = palettes[palette] ?? palettes[AppThemePalette.medicalTeal]!;
    final primary = cfg.getPrimary(isDark);
    return isDark ? primary.withValues(alpha: 0.22) : primary.withValues(alpha: 0.12);
  }

  static Color getSidebarHoverColor(AppThemePalette palette, bool isDark) {
    final cfg = palettes[palette] ?? palettes[AppThemePalette.medicalTeal]!;
    final primary = cfg.getPrimary(isDark);
    return primary.withValues(alpha: isDark ? 0.12 : 0.06);
  }

  static Color getSidebarTextColor(AppThemePalette palette, bool isDark) {
    final cfg = palettes[palette] ?? palettes[AppThemePalette.medicalTeal]!;
    return isDark ? const Color(0xFF94A3B8) : cfg.lightTextSecondary;
  }

  static Color getSidebarSelectedTextColor(AppThemePalette palette, bool isDark) {
    final cfg = palettes[palette] ?? palettes[AppThemePalette.medicalTeal]!;
    final primary = cfg.getPrimary(isDark);
    return isDark ? Colors.white : primary;
  }

  static Color getSidebarIconColor(AppThemePalette palette, bool isDark) {
    final cfg = palettes[palette] ?? palettes[AppThemePalette.medicalTeal]!;
    return isDark ? const Color(0xFF64748B) : cfg.lightTextSecondary;
  }

  static Color getSidebarSelectedIconColor(AppThemePalette palette, bool isDark) {
    final cfg = palettes[palette] ?? palettes[AppThemePalette.medicalTeal]!;
    return cfg.getPrimary(isDark);
  }
}
