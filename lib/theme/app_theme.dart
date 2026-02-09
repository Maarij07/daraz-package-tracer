import 'package:flutter/material.dart';

class AppColors {
  static const Color orange = Color(0xFFF85606);
  static const Color darkOrange = Color(0xFFD94800);
  static const Color black = Color(0xFF1A1A2E);
  static const Color pureBlack = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F5F5);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF424242);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.orange,
      scaffoldBackgroundColor: AppColors.offWhite,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.orange,
        onPrimary: AppColors.white,
        secondary: AppColors.black,
        onSecondary: AppColors.white,
        error: Colors.red,
        onError: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.pureBlack,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pureBlack,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.pureBlack,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.grey,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
