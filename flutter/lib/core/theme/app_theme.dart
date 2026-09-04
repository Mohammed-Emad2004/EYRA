import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Builds the single Eyra dark theme.
///
/// [highContrast] slightly boosts text/border contrast for the
/// "High Contrast" accessibility setting.
/// [largeText] boosts the base type scale for the "Large Text" setting.
class AppTheme {
  AppTheme._();

  static ThemeData build({bool highContrast = false, bool largeText = false}) {
    final scale = largeText ? 1.18 : 1.0;
    final textTheme = AppTypography.textTheme(scaleFactor: scale);

    final primaryText = highContrast ? Colors.white : AppColors.textPrimary;
    final borderColor = highContrast
        ? AppColors.brightCyan.withOpacity(0.9)
        : AppColors.divider;

    final colorScheme = const ColorScheme.dark().copyWith(
      primary: AppColors.cyan,
      onPrimary: AppColors.deepNavy,
      secondary: AppColors.brightCyan,
      onSecondary: AppColors.deepNavy,
      surface: AppColors.surface,
      onSurface: primaryText,
      error: AppColors.error,
      onError: AppColors.deepNavy,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.deepNavy,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: 'Roboto',
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.deepNavy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryText, size: 26),
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerTheme: DividerThemeData(color: borderColor, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: borderColor, width: highContrast ? 1.4 : 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.cyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 16 * scale),
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 16 * scale),
        errorStyle: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: AppColors.deepNavy,
          minimumSize: const Size.fromHeight(56),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryText,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: borderColor, width: highContrast ? 1.6 : 1.2),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brightCyan,
          minimumSize: const Size(48, 48),
          textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.deepNavy : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.cyan : AppColors.elevatedSurface,
        ),
        trackOutlineColor: WidgetStateProperty.all(borderColor),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryNavy,
        selectedItemColor: AppColors.cyan,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: textTheme.labelMedium?.copyWith(color: AppColors.cyan),
        unselectedLabelStyle: textTheme.labelMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.elevatedSurface,
        contentTextStyle: textTheme.bodyLarge,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      iconTheme: IconThemeData(color: primaryText),
      focusColor: AppColors.cyan.withOpacity(0.24),
      highlightColor: AppColors.cyan.withOpacity(0.08),
    );
  }
}
