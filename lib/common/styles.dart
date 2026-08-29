import 'package:flutter/material.dart';

/// Legacy visual tokens. The implementation is new, while values preserve the
/// established light UI so pages can be migrated without visual drift.
abstract final class AppColors {
  static const pageBackground = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF7F7F7);
  static const inputBackground = Color(0xFFF7F9F8);
  static const textPrimary = Color(0xFF151517);
  static const textSecondary = Color(0x99000000);
  static const textTertiary = Color(0x66000000);
  static const divider = Color(0x14000000);
  static const skeletonHighlight = Color(0x08000000);
  static const primary = Color(0xFFFF6699);
  static const success = Color(0xFF01BD8D);
  static const error = Color(0xFFF65354);
  static const warning = Color(0xFFFFA216);
  static const info = Color(0xFF407FF9);
  static const toastBackground = Color(0xE6151517);
  static const navigationUnselected = Color(0xFFAAAAAA);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    surface: AppColors.surface,
    error: AppColors.error,
  );

  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.pageBackground,
    cardColor: AppColors.surface,
    dividerColor: AppColors.divider,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    fontFamilyFallback: const ['PingFang SC', 'Microsoft YaHei', 'sans-serif'],
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.pageBackground,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 1,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.textPrimary,
      unselectedItemColor: AppColors.navigationUnselected,
      selectedLabelStyle: TextStyle(fontSize: 12),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
    ),
  );
}
