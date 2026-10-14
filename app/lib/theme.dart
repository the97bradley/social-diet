import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PulseTheme {
  static const ink = Color(0xFF121610);
  static const moss = Color(0xFF1C2318);
  static const leaf = Color(0xFF2A3424);
  static const lime = Color(0xFFD4F06E);
  static const clay = Color(0xFFE8A87C);
  static const cream = Color(0xFFF4F1E8);
  static const mist = Color(0xFFB7B3A6);

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(
        primary: lime,
        onPrimary: ink,
        secondary: clay,
        onSecondary: ink,
        surface: moss,
        onSurface: cream,
        error: Color(0xFFE57373),
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.sourceSans3TextTheme(base.textTheme).apply(
        bodyColor: cream,
        displayColor: cream,
      ).copyWith(
        displaySmall: GoogleFonts.fraunces(
          color: cream,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.6,
        ),
        headlineMedium: GoogleFonts.fraunces(
          color: cream,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        headlineSmall: GoogleFonts.fraunces(
          color: cream,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.fraunces(
          color: cream,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ink,
        foregroundColor: cream,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
          color: cream,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: moss,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: leaf,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: mist),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: lime,
          foregroundColor: ink,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: moss,
        indicatorColor: lime.withValues(alpha: 0.2),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.sourceSans3(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
