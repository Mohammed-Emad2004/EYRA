import 'package:flutter/material.dart';

/// Theme-aware accessor for Eyra's color palette.
///
/// Pass a [BuildContext] to resolve colors from the current theme.
/// [AppColors] itself is kept for use inside theme definitions
/// (app_theme.dart, app_typography.dart) where context is unavailable.
class AppColors {
  AppColors._();

  // --- Dark mode (original) palette ---
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

  static const Color divider = Color(0x1FFFFFFF);
  static const Color overlay = Color(0x99030F1C);

  /// Subtle glow used sparingly behind the logo / primary CTA.
  static const Color cyanGlow = Color(0x3318D8FF);

  /// Returns the current theme's success color.
  static Color successOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.success
        : AppColorsLight.success;
  }

  /// Returns the current theme's warning color.
  static Color warningOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.warning
        : AppColorsLight.warning;
  }

  /// Returns the current theme's error color.
  static Color errorOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.error
        : AppColorsLight.error;
  }
}

/// Light-mode Eyra palette.
///
/// Mirrors [AppColors] with appropriate light-surface values. Cyan accent
/// uses a darker, more saturated variant for readability on white backgrounds.
class AppColorsLight {
  AppColorsLight._();

  static const Color deepNavy = Color(0xFFF8FAFB);
  static const Color primaryNavy = Color(0xFFF0F3F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color elevatedSurface = Color(0xFFF5F7F9);

  static const Color cyan = Color(0xFF0FAACC);
  static const Color brightCyan = Color(0xFF0D9BBF);
  static const Color iceBlue = Color(0xFFE6F7FB);

  static const Color textPrimary = Color(0xFF0A1929);
  static const Color textSecondary = Color(0xFF4A6572);
  static const Color textMuted = Color(0xFF708C99);

  static const Color success = Color(0xFF2E9E6B);
  static const Color warning = Color(0xFFC4930A);
  static const Color error = Color(0xFFD43D3D);

  static const Color divider = Color(0x1A000000);
  static const Color overlay = Color(0x66F8FAFB);

  static const Color cyanGlow = Color(0x1A0FAACC);
}
