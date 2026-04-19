import 'package:flutter/material.dart';

/// Ember & Ink palette — burnt orange embers over deep ink surfaces.
class AppColors {
  AppColors._();

  // Primary
  static const Color emberOrange = Color(0xFFE8612C);
  static const Color amberGold = Color(0xFFF59E3A);
  static const Color inkNavy = Color(0xFF1A1A2E);
  static const Color emberDeep = Color(0xFFD4541F);
  static const Color emberSoft = Color(0xFFFDEEE6);

  // Semantic
  static const Color hudleTeal = Color(0xFF0D9488);
  static const Color hudleRose = Color(0xFFE11D48);

  // Dark surfaces (default)
  static const Color inkBase = Color(0xFF0F0F1A);
  static const Color inkSurface = Color(0xFF1A1A2E);
  static const Color inkElevated = Color(0xFF242438);
  static const Color inkBorder = Color(0xFF2E2E48);
  static const Color inkMuted = Color(0xFF3D3D5C);

  // Light surfaces
  static const Color paperBase = Color(0xFFFFF8F5);
  static const Color paperSurface = Color(0xFFFFFFFF);
  static const Color paperBorder = Color(0xFFFFDDD0);

  // Text
  static const Color textPrimary = Color(0xFFF5F0EC);
  static const Color textSecondary = Color(0xFFB0A898);
  static const Color textOnLight = Color(0xFF1A1210);

  // Priority
  static const Color priorityLow = Color(0xFF059669);
  static const Color priorityMedium = Color(0xFFF59E3A);
  static const Color priorityHigh = Color(0xFFE8612C);
  static const Color priorityUrgent = Color(0xFFE11D48);

  // Status
  static const Color statusNotStarted = Color(0xFF64748B);
  static const Color statusInProgress = Color(0xFF1A3A5C);
  static const Color statusDone = Color(0xFF0D9488);

  static const LinearGradient emberGradient = LinearGradient(
    colors: [emberOrange, amberGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
