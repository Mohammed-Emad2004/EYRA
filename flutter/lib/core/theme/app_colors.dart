import 'package:flutter/material.dart';

/// Centralized Eyra brand color palette.
///
/// Deep navy dominates the interface; cyan is reserved for accents,
/// focus states, and important status signals only.
class AppColors {
  AppColors._();

  static const Color deepNavy = Color(0xFF03111F);
  static const Color primaryNavy = Color(0xFF061B2E);
  static const Color surface = Color(0xFF0A263D);
  static const Color elevatedSurface = Color(0xFF0E314B);

  static const Color cyan = Color(0xFF18D8FF);
  static const Color brightCyan = Color(0xFF63E8FF);
  static const Color iceBlue = Color(0xFFB9F5FF);

  static const Color textPrimary = Color(0xFFF5FAFF);
  static const Color textSecondary = Color(0xFFA9C3D3);
  static const Color textMuted = Color(0xFF6F8B9B);

  // Semantic status colors. Always paired with an icon/label,
  // never used as the sole carrier of meaning.
  static const Color success = Color(0xFF3DDC97);
  static const Color warning = Color(0xFFFFC55C);
  static const Color error = Color(0xFFFF6B6B);

  static const Color divider = Color(0x1FFFFFFF); // subtle hairline on navy
  static const Color overlay = Color(0x99030F1C);

  /// Subtle glow used sparingly behind the logo / primary CTA.
  static const Color cyanGlow = Color(0x3318D8FF);
}
