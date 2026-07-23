import 'package:flutter/material.dart';

abstract final class AppColors {
  // --- V3 COLOR SYSTEM (Tactical Neon Palette) ---
  static const v3OuterBg     = Color(0xFF05050F);
  static const v3Bg          = Color(0xFF080824);
  static const v3CardBg      = Color(0xFF0C0C38);
  static const v3CardBorder  = Color(0xFF1A1A4A);
  
  static const v3TextPrimary   = Color(0xFFF0F0FF);
  static const v3TextSecondary = Color(0xFFE0E0FF);
  static const v3TextMuted     = Color(0xFF3A3A6A);
  static const v3TextMutedLight= Color(0xFF2A2A5A);

  // Semantic Colors
  static const v3Live     = Color(0xFF00FF85); // Success / Active C2 / Live
  static const v3Critical = Color(0xFFFF3B3B); // Alert / Vulnerability Critical
  static const v3OpsRed   = Color(0xFFE02E2E); // Primary Action Buttons (FAB, Launch)
  static const v3Warning  = Color(0xFFFF9F00); // Warning / High / Beacon Jitter
  static const v3Intel    = Color(0xFF00D4FF); // Cyan / Info / Intelligence / Coverage
  static const v3Covert   = Color(0xFF9B59B6); // Purple / Field Reporter Suite
  static const v3Elite    = Color(0xFFFFD700); // Gold / Operator Badges & Ranks
  static const v3Code     = Color(0xFF00FFD1); // Turquoise / Technical IDs / Code
  static const v3ConsoleBg= Color(0xFF030D04); // Dark Green Terminal Log Background

  // --- DYNAMIC THEME GETTERS (Light vs Dark Mode) ---
  static Color dynamicBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF080824)
        : const Color(0xFFF4F5FB);
  }

  static Color dynamicOuterBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF05050F)
        : const Color(0xFFFFFFFF);
  }

  static Color dynamicCardBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0C0C38)
        : const Color(0xFFFFFFFF);
  }

  static Color dynamicCardBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A4A)
        : const Color(0xFFE2E8F0);
  }

  static Color dynamicTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF0F0FF)
        : const Color(0xFF0F172A);
  }

  static Color dynamicTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFE0E0FF)
        : const Color(0xFF334155);
  }

  static Color dynamicTextMuted(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF5A5A9A)
        : const Color(0xFF64748B);
  }

  static Color dynamicConsoleBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF030D04)
        : const Color(0xFF0F172A);
  }

  // Backwards Compatibility Static Constants
  static const deepBlue   = Color(0xFF111184);
  static const redPrimary = Color(0xFFE02E2E); 
  static const redGlow    = Color(0xFFFF3B3B);
  static const redDark    = Color(0xFF7A1010);

  static const bg900 = Color(0xFF080824); 
  static const bg800 = Color(0xFF111184); 
  static const bg700 = Color(0xFF1B1B9E); 
  static const bg600 = Color(0xFF2626B8); 

  static const bg         = Color(0xFF080824);
  static const outerBg    = Color(0xFF05050F);
  static const cardBg     = Color(0xFF0C0C38);
  static const cardBorder = Color(0xFF1A1A4A);
  static const border     = Color(0xFF1A1A4A);
  static const consoleBg  = Color(0xFF030D04);

  static const textPrimary   = Color(0xFFF0F0FF);
  static const textSecondary = Color(0xFFE0E0FF);
  static const textMuted     = Color(0xFF3A3A6A);
  static const textCode      = Color(0xFF00FFD1);
  static const textTertiary  = Color(0xFF3A3A6A);

  static const lightScaffold = Color(0xFFF4F5FB);
  static const lightSurface  = Color(0xFFFFFFFF);
  static const lightCard     = Color(0xFFFFFFFF);
  static const lightBorder   = Color(0xFFE2E8F0);
  
  static const lightTextPrimary   = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF334155);
  static const lightTextTertiary  = Color(0xFF64748B);
  
  static const lightAccent = Color(0xFFE02E2E);
  static const lightBlueAccent = Color(0xFF111184);

  static const criticalFg = Color(0xFFFF3B3B);
  static const criticalBg = Color(0xFF3B0000);
  static const highFg     = Color(0xFFFF9F00);
  static const highBg     = Color(0xFF3B2500);
  static const mediumFg   = Color(0xFFFFD700);
  static const mediumBg   = Color(0xFF3B3400);
  static const lowFg      = Color(0xFF00FF85);
  static const lowBg      = Color(0xFF003B1E);
  static const infoFg     = Color(0xFF00D4FF);
  static const infoBg     = Color(0xFF00223B);

  static const live    = Color(0xFF00FF85);
  static const offline = Color(0xFF3A3A6A);
  static const pending = Color(0xFFFF9F00);
}
