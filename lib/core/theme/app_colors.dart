import 'package:flutter/material.dart';

abstract final class AppColors {
  // --- DARK THEME (The Core) ---
  static const deepBlue = Color(0xFF111184);
  static const redPrimary = Color(0xFFE02E2E); 
  static const redGlow    = Color(0xFFFF3B3B);
  static const redDark    = Color(0xFF7A1010);

  static const bg900 = Color(0xFF080824); 
  static const bg800 = Color(0xFF111184); 
  static const bg700 = Color(0xFF1B1B9E); 
  static const bg600 = Color(0xFF2626B8); 

  static const border = Color(0xFF1E1E6B);
  static const cardBg = Color(0xFF0C0C40);

  static const textPrimary   = Color(0xFFF0F0FF);
  static const textSecondary = Color(0xFFB0B0E6);
  static const textTertiary  = Color(0xFF7070B0);
  static const textCode      = Color(0xFF00FFD1);

  // --- LIGHT THEME (Cyber-White) ---
  // A clean, high-contrast look that still feels like a tactical tool
  static const lightScaffold = Color(0xFFF4F7FF); // Very light blue-ish white
  static const lightSurface  = Color(0xFFFFFFFF); // Pure white
  static const lightCard     = Color(0xFFFFFFFF);
  static const lightBorder   = Color(0xFFDCE1F0);
  
  static const lightTextPrimary   = Color(0xFF080830); // Deep dark blue
  static const lightTextSecondary = Color(0xFF4A4A80);
  static const lightTextTertiary  = Color(0xFF8A8AA8);
  
  static const lightAccent = Color(0xFFE02E2E); // Keep the dangerous red
  static const lightBlueAccent = Color(0xFF111184); // The signature blue as an accent

  // Severity (Common for both or tweaked in theme)
  static const criticalFg = Color(0xFFFF3B3B);
  static const criticalBg = Color(0xFF3B0000);
  static const highFg     = Color(0xFFFF9F00);
  static const highBg     = Color(0xFF3B2500);
  static const mediumFg   = Color(0xFFFFE000);
  static const mediumBg   = Color(0xFF3B3400);
  static const lowFg      = Color(0xFF00FF85);
  static const lowBg      = Color(0xFF003B1E);
  static const infoFg     = Color(0xFF00B2FF);
  static const infoBg     = Color(0xFF00223B);

  static const live    = Color(0xFF00FF85);
  static const offline = Color(0xFF666688);
  static const pending = Color(0xFFFF9F00);
}
