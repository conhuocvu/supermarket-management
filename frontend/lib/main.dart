import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/app_state.dart';
import 'widgets/responsive_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const GreenMartSMSApp(),
    ),
  );
}

class GreenMartSMSApp extends StatelessWidget {
  const GreenMartSMSApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Custom Color Palette from DESIGN.md
    const primaryColor = Color(0xFF00503E); // Viridian green
    const primaryContainer = Color(0xFF246955);
    const onPrimaryContainer = Color(0xFFA1E6CC);
    const secondaryColor = Color(0xFF8E4E14);
    const secondaryContainer = Color(0xFFFCA867);
    const onSecondaryContainer = Color(0xFF763B00);
    const surfaceColor = Color(0xFFFFFFFF);
    const backgroundColor = Color(0xFFF7F8F7);
    const errorColor = Color(0xFFBA1A1A);
    const onSurface = Color(0xFF191C20);
    const onSurfaceVariant = Color(0xFF3F4945);
    const outlineColor = Color(0xFF6F7974);
    const outlineVariantColor = Color(0xFFBFC9C3);

    // Light Theme Configuration
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00503E),
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondaryColor,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        background: backgroundColor,
        onBackground: onSurface,
        surface: surfaceColor,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outlineColor,
        outlineVariant: outlineVariantColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      dividerColor: outlineVariantColor,
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.02,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.bricolageGrotesque(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01,
          color: onSurface,
        ),
        headlineSmall: GoogleFonts.bricolageGrotesque(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: onSurface,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: onSurface,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: onSurfaceVariant,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
      ),
    );

    // Dark Theme Configuration
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF90D4BB),
        onPrimary: const Color(0xFF002117),
        primaryContainer: const Color(0xFF246955),
        onPrimaryContainer: const Color(0xFFA1E6CC),
        secondary: const Color(0xFFFFB781),
        secondaryContainer: const Color(0xFF703800),
        onSecondaryContainer: const Color(0xFFFFDCC4),
        background: const Color(0xFF191C20),
        onBackground: const Color(0xFFE1E2E8),
        surface: const Color(0xFF2E3135),
        onSurface: const Color(0xFFE1E2E8),
        onSurfaceVariant: const Color(0xFFBFC9C3),
        outline: const Color(0xFF6F7974),
        outlineVariant: const Color(0xFF3F4945),
        error: const Color(0xFFFFDAD6),
      ),
      scaffoldBackgroundColor: const Color(0xFF191C20),
      cardColor: const Color(0xFF2E3135),
      dividerColor: const Color(0xFF3F4945),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.02,
          color: const Color(0xFFE1E2E8),
        ),
        headlineMedium: GoogleFonts.bricolageGrotesque(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01,
          color: const Color(0xFFE1E2E8),
        ),
        headlineSmall: GoogleFonts.bricolageGrotesque(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE1E2E8),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE1E2E8),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFE1E2E8),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: const Color(0xFFE1E2E8),
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: const Color(0xFFBFC9C3),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF2E3135),
        elevation: 8,
      ),
    );

    return MaterialApp(
      title: 'GreenMart SMS',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const ResponsiveScaffold(),
      debugShowCheckedModeBanner: false,
    );
  }
}
