import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Legacy / Short Names (from feature/supplier-management branch)
  static const Color primary = Color(0xFF40826D);
  static const Color primaryLight = Color(0xFFA8D5C2);
  static const Color primaryDark = Color(0xFF2F5D50);

  static const Color secondary = Color(0xFFF4A261);
  static const Color secondaryDark = Color(0xFFD97706);

  static const Color background = Color(0xFFF7F8F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F5F4);

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFD1D5DB);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF4A261);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF3B82F6);

  // New / Long Names (from main branch)
  static const Color primaryColor = Color(0xFF00503E);
  static const Color primaryLightColor = Color(0xFFA8D5C2);
  static const Color primaryDarkColor = Color(0xFF002117);

  static const Color secondaryColor = Color(0xFFF4A261);
  static const Color secondaryDarkColor = Color(0xFF8E4E14);

  static const Color backgroundColor = Color(0xFFF8F9FF);
  static const Color surfaceColor = Color(0xFFFFFFFF);

  static const Color textPrimaryColor = Color(0xFF121C2A);
  static const Color textSecondaryColor = Color(0xFF3F4945);

  static const Color errorColor = Color(0xFFBA1A1A);
  static const Color errorContainerColor = Color(0xFFFFDAD6);
  static const Color onErrorContainerColor = Color(0xFF93000A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF246955),
        onPrimaryContainer: Color(0xFFA1E6CC),
        secondary: Color(0xFF8E4E14),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFCA867),
        onSecondaryContainer: Color(0xFF763B00),
        error: errorColor,
        onError: Colors.white,
        errorContainer: errorContainerColor,
        onErrorContainer: onErrorContainerColor,
        surface: surfaceColor,
        onSurface: textPrimaryColor,
        surfaceContainerHighest: Color(0xFFD9E3F7),
        onSurfaceVariant: textSecondaryColor,
        outline: Color(0xFF6F7974),
        outlineVariant: Color(0xFFBFC9C3),
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: Color(0xFF6F7974)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 1.25,
          color: textPrimaryColor,
        ),
        headlineLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        headlineMedium: GoogleFonts.bricolageGrotesque(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.33,
          color: textPrimaryColor,
        ),
        headlineSmall: GoogleFonts.bricolageGrotesque(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        titleLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: textPrimaryColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          height: 1.5,
          color: textPrimaryColor,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 1.42,
          color: textSecondaryColor,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          height: 1.42,
          color: textPrimaryColor,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondaryColor,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.33,
          color: textSecondaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F5F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.inter(color: textSecondaryColor, fontSize: 14),
        hintStyle: GoogleFonts.inter(
          color: const Color.fromRGBO(107, 114, 128, 0.6),
          fontSize: 14,
        ),
      ),
    );
  }
}
