/// Centralized spacing scale used across the app.
///
/// Keeping spacing on an 4dp-based scale gives Eyra a calm, consistent
/// rhythm and avoids ad-hoc paddings scattered through the codebase.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// Minimum recommended touch target size for assistive-technology UIs.
  static const double minTouchTarget = 48;
}
