import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:redops_hub/core/theme/app_colors.dart';
import 'package:redops_hub/core/theme/app_text_styles.dart';

// Persistent Theme and Language Provider
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  try {
    final box = Hive.box('redops_settings');
    final themeIndex = box.get('theme_mode');
    if (themeIndex != null) {
      return ThemeMode.values[themeIndex];
    }
  } catch (_) {}
  return ThemeMode.light;
});

final languageProvider = StateProvider<Locale>((ref) {
  try {
    final box = Hive.box('redops_settings');
    final langCode = box.get('language_code');
    if (langCode != null) {
      return Locale(langCode);
    }
  } catch (_) {}
  return const Locale('en');
});

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightScaffold,
    primaryColor: AppColors.deepBlue,
    
    colorScheme: const ColorScheme.light(
      primary: AppColors.deepBlue,
      secondary: AppColors.redPrimary,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      error: AppColors.criticalFg,
      outline: AppColors.lightBorder,
    ),
    
    textTheme: AppTextStyles.lightTextTheme,

    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 4,
      shadowColor: AppColors.deepBlue.withValues(alpha: 0.1),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightBorder, width: 1),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.lightBorder,
      thickness: 1,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightScaffold,
      foregroundColor: AppColors.lightTextPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.deepBlue, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.lightTextSecondary),
      hintStyle: const TextStyle(color: AppColors.lightTextTertiary, fontSize: 14),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.deepBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: AppColors.deepBlue.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg900,
    primaryColor: AppColors.redPrimary,
    
    colorScheme: const ColorScheme.dark(
      primary: AppColors.redPrimary,
      secondary: AppColors.textCode,
      surface: AppColors.cardBg,
      onSurface: AppColors.textPrimary,
      error: AppColors.criticalFg,
      outline: AppColors.border,
    ),
    
    textTheme: AppTextStyles.darkTextTheme,

    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg900,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg800.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.redPrimary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.redPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: AppColors.redPrimary.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );
}
