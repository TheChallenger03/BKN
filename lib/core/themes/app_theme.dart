import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryTeal = Color(0xFF00D9C0);
  static const Color secondaryTeal = Color(0xFF00B4A0);
  static const Color darkTeal = Color(0xFF008B7A);

  static const Color backgroundDark = Color(0xFF0F1419);
  static const Color surfaceDark = Color(0xFF1A1F26);
  static const Color cardDark = Color(0xFF242A33);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryTeal, secondaryTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glowGradient = LinearGradient(
    colors: [primaryTeal, darkTeal],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static Color glassBackground = Colors.white.withValues(alpha: 0.08);
  static Color glassBorder = Colors.white.withValues(alpha: 0.15);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      
      colorScheme: ColorScheme.dark(
        primary: primaryTeal,
        secondary: secondaryTeal,
        surface: surfaceDark,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white.withValues(alpha: 0.9),
      ),
      
      cardTheme: CardThemeData(
        color: glassBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: glassBorder,
            width: 1,
          ),
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.black,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),
      
      iconTheme: IconThemeData(
        color: Colors.white.withValues(alpha: 0.9),
      ),
      
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          color: Colors.white.withValues(alpha: 0.95),
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
        ),
        bodyMedium: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
        ),
        bodySmall: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryTeal, width: 2),
        ),
      ),
    );
  }
}