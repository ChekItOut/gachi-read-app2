import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Base Colors
  static const Color background = Color(0xFFF2F5FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF344154);
  static const Color secondaryText = Color(0xFF738096);
  static const Color border = Color(0xFFDDE5EF);
  static const Color divider = Color(0xFFE8EDF3);

  // Accent Colors
  static const Color primary = Color(0xFF58BE82);
  static const Color primaryActive = Color(0xFF4FB879);
  static const Color softMint = Color(0xFFE6F4F0);
  static const Color softBlue = Color(0xFFEAF2FA);
  static const Color warning = Color(0xFFF05A4A);
  static const Color pointYellow = Color(0xFFFFE177);
  static const Color purple = Color(0xFFC982F2);

  // Additional
  static const Color chipBackground = Color(0xFFF3F6FA);
  static const Color iconBackground = Color(0xFFF3F5FA);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.surface,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.softMint,
        onSecondary: AppColors.primaryText,
        error: AppColors.warning,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.notoSansKrTextTheme().copyWith(
        displayLarge: GoogleFonts.notoSansKr(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryText,
        ),
        displayMedium: GoogleFonts.notoSansKr(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryText,
        ),
        headlineLarge: GoogleFonts.notoSansKr(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
        headlineMedium: GoogleFonts.notoSansKr(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
        titleLarge: GoogleFonts.notoSansKr(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
        titleMedium: GoogleFonts.notoSansKr(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
        ),
        bodyLarge: GoogleFonts.notoSansKr(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryText,
        ),
        bodyMedium: GoogleFonts.notoSansKr(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.primaryText,
        ),
        labelLarge: GoogleFonts.notoSansKr(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryText,
        ),
        labelMedium: GoogleFonts.notoSansKr(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryText,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.notoSansKr(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.notoSansKr(
          color: AppColors.secondaryText.withValues(alpha: 0.6),
          fontSize: 15,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.notoSansKr(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansKr(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
