import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class YnotTheme {
  static const bg = Color(0xFF050812);
  static const bg2 = Color(0xFF070B18);
  static const surface = Color(0xFF0F172A);
  static const surface2 = Color(0xFF141B2D);
  static const primary = Color(0xFFFF5DB8);
  static const primaryDark = Color(0xFFA93A7D);
  static const purple = Color(0xFF8B5CF6);
  static const mint = Color(0xFF63E6BE);
  static const text = Color(0xFFF8FAFC);
  static const mutedText = Color(0xFFB8AFC4);
  static const border = Color(0x14FFFFFF);

  static ThemeData get dark {
    final base = ThemeData.dark();
    final bodyTheme = GoogleFonts.nunitoSansTextTheme(base.textTheme).apply(
      bodyColor: text,
      displayColor: text,
    );
    final displayTheme = GoogleFonts.fredokaTextTheme(base.textTheme).apply(
      bodyColor: text,
      displayColor: text,
    );

    final textTheme = bodyTheme.copyWith(
      headlineLarge: displayTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineMedium: displayTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineSmall: displayTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: displayTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      titleMedium: bodyTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleSmall: bodyTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      bodyLarge: bodyTheme.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: bodyTheme.bodyMedium?.copyWith(height: 1.45),
      bodySmall: bodyTheme.bodySmall?.copyWith(height: 1.35),
      labelLarge: bodyTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: surface,
    ).copyWith(
      primary: primary,
      secondary: purple,
      tertiary: mint,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: mutedText,
      outline: border,
      outlineVariant: border,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withValues(alpha: 0.9),
        indicatorColor: primary.withValues(alpha: 0.22),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.nunitoSans(
            color: text,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2.withValues(alpha: 0.98),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
        hintStyle: const TextStyle(color: mutedText),
        labelStyle: const TextStyle(color: mutedText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface2.withValues(alpha: 0.92),
        selectedColor: primary.withValues(alpha: 0.22),
        labelStyle: const TextStyle(color: text),
        secondaryLabelStyle: const TextStyle(color: text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: const BorderSide(color: border),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(color: border),
    );
  }

  static ThemeData get light => dark;
}
