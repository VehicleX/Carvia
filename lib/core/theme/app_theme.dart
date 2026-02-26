import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme {
    const ColorScheme darkColorScheme = ColorScheme.dark(
      surface: Color(0xFF000000),      // Background
      onSurface: Color(0xFFFFFFFF),    // Text & Icons
      primary: Color(0xFFFF3B3B),      // Buttons & Active states (RED ACCENT)
      onPrimary: Color(0xFFFFFFFF),    // Button Text
      secondary: Color(0xFF868686),    // Secondary text
      outline: Color(0xFF868686),      // Borders
      error: Color(0xFF868686),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkColorScheme.surface,
      primaryColor: darkColorScheme.primary,
      colorScheme: darkColorScheme,
      canvasColor: darkColorScheme.surface,
      cardColor: darkColorScheme.surface,
      dialogBackgroundColor: darkColorScheme.surface,
      
      // Typography
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: darkColorScheme.onSurface,
        displayColor: darkColorScheme.onSurface,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkColorScheme.onSurface),
        titleTextStyle: TextStyle(color: darkColorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkColorScheme.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: darkColorScheme.secondary),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    const ColorScheme lightColorScheme = ColorScheme.light(
      surface: Color(0xFFFFFFFF),      // Background
      onSurface: Color(0xFF000000),    // Text & Icons
      primary: Color(0xFFFF3B3B),      // Buttons & Active states (RED ACCENT)
      onPrimary: Color(0xFFFFFFFF),    // Button Text
      secondary: Color(0xFF868686),    // Secondary text
      outline: Color(0xFF868686),      // Borders
      error: Color(0xFF868686),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightColorScheme.surface,
      primaryColor: lightColorScheme.primary,
      colorScheme: lightColorScheme,
      canvasColor: lightColorScheme.surface,
      cardColor: lightColorScheme.surface,
      dialogBackgroundColor: lightColorScheme.surface,
      
      // Typography
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: lightColorScheme.onSurface,
        displayColor: lightColorScheme.onSurface,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: lightColorScheme.onSurface),
        titleTextStyle: TextStyle(color: lightColorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightColorScheme.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: lightColorScheme.secondary),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
