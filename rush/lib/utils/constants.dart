import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Orange (like WeWard)
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8F66);
  static const Color primaryDark = Color(0xFFE55A2B);

  // Secondary - Blue for XP
  static const Color secondary = Color(0xFF4A90D9);
  static const Color secondaryLight = Color(0xFF7AB3E8);
  static const Color secondaryDark = Color(0xFF3A7BC8);

  // Accent colors
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFF8F66);

  // Background - Light theme
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  // XP and levels - Blue
  static const Color xpBlue = Color(0xFF4A90D9);
  static const Color xpBar = Color(0xFF4A90D9);
  static const Color xpBarBackground = Color(0xFFE8E8E8);

  // Status colors
  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);

  // POI category colors
  static const Color poiAcademic = Color(0xFF74B9FF);
  static const Color poiSports = Color(0xFF55EFC4);
  static const Color poiLandmark = Color(0xFFFFD93D);

  // Text - Dark for light theme
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textMuted = Color(0xFFADB5BD);

  // Steps gauge
  static const Color stepsGaugeOrange = Color(0xFFFF6B35);
  static const Color stepsGaugeBackground = Color(0xFFE8E8E8);

  // Navigation
  static const Color navBackground = Color(0xFF1E2A3A);
  static const Color navSelected = Color(0xFFFFFFFF);
  static const Color navUnselected = Color(0xFF8A95A5);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBackground,
        selectedItemColor: AppColors.navSelected,
        unselectedItemColor: AppColors.navUnselected,
      ),
    );
  }
}

class AppConstants {
  // App info
  static const String appName = 'RUSH';
  static const String appTagline = 'Run. Unlock. Share. Hustle.';

  // Map defaults (Universidad de Montemorelos coordinates)
  static const double defaultLatitude = 25.1935;
  static const double defaultLongitude = -99.8270;
  static const double defaultZoom = 16.0;

  // Gamification
  static const int xpPerKm = 50;
  static const int xpPerMinute = 2;
  static const double poiVisitRadius = 30.0; // meters

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
