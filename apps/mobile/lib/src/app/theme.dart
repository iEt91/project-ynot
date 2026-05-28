import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class YnotTheme {
  static const _bg = Color(0xFF070B14);
  static const _surface = Color(0xFF111827);
  static const _surface2 = Color(0xFF172033);
  static const _accent = Color(0xFFFF77B7);
  static const _accent2 = Color(0xFF7C5CFF);
  static const _text = Color(0xFFF3F4F6);
  static const _muted = Color(0xFF9CA3AF);

  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
    );
    final textTheme = GoogleFonts.nunitoSansTextTheme(base.textTheme).apply(
      bodyColor: _text,
      displayColor: _text,
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.dark,
      surface: _surface,
    ).copyWith(
      primary: _accent,
      secondary: _accent2,
      surface: _surface,
      onSurface: _text,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: _bg,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _text,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surface,
        indicatorColor: _accent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.nunitoSans(
            color: _text,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _text,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: _muted),
        labelStyle: const TextStyle(color: _muted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surface2,
        selectedColor: _accent.withValues(alpha: 0.22),
        labelStyle: const TextStyle(color: _text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: _surface2.withValues(alpha: 0.5)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get light {
    return dark;
  }
}
