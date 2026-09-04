import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized typography for Eyra.
///
/// Base sizes are intentionally large for an assistive-technology product.
/// [scaleFactor] is driven by the "Large Text" accessibility setting and is
/// applied on top of the base scale (1.0 = default, 1.2 = large text mode).
class AppTypography {
  AppTypography._();

  static TextTheme textTheme({double scaleFactor = 1.0}) {
    double s(double size) => size * scaleFactor;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: s(34),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: s(28),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
      ),
      headlineLarge: TextStyle(
        fontSize: s(26),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize: s(22),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
      ),
      titleLarge: TextStyle(
        fontSize: s(20),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        fontSize: s(18),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      bodyLarge: TextStyle(
        fontSize: s(17),
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontSize: s(15),
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: s(16),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontSize: s(13),
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.4,
      ),
      labelSmall: TextStyle(
        fontSize: s(12),
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.6,
      ),
    );
  }
}
