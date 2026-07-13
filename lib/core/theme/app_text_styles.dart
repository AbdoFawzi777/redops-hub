import 'package:flutter/material.dart';
import 'package:redops_hub/core/theme/app_colors.dart';

abstract final class AppTextStyles {
  static const codeStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    color: AppColors.textCode,
    height: 1.6,
  );

  static TextTheme get darkTextTheme => const TextTheme(
    headlineLarge:  TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
        color: AppColors.textPrimary, letterSpacing: -0.5),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary),
    headlineSmall:  TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary),
    bodyLarge:   TextStyle(fontSize: 15, color: AppColors.textPrimary,   height: 1.6),
    bodyMedium:  TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
    bodySmall:   TextStyle(fontSize: 11, color: AppColors.textTertiary),
    labelLarge:  TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
        color: AppColors.textSecondary, letterSpacing: 1),
  );

  static TextTheme get lightTextTheme => const TextTheme(
    headlineLarge:  TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
        color: AppColors.lightTextPrimary, letterSpacing: -0.5),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
        color: AppColors.lightTextPrimary),
    headlineSmall:  TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
        color: AppColors.lightTextPrimary),
    bodyLarge:   TextStyle(fontSize: 15, color: AppColors.lightTextPrimary, height: 1.6),
    bodyMedium:  TextStyle(fontSize: 13, color: AppColors.lightTextSecondary, height: 1.5),
    bodySmall:   TextStyle(fontSize: 11, color: AppColors.lightTextTertiary),
    labelLarge:  TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
        color: AppColors.lightTextSecondary, letterSpacing: 1),
  );
}
