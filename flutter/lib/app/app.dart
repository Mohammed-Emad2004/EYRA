import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'routes.dart';
import '../core/state/app_settings_controller.dart';
import '../core/theme/app_theme.dart';

/// Root widget for Eyra.
///
/// Wraps the [MaterialApp] with a [Directionality] driven by the current
/// language setting, so switching English/Arabic immediately flips the
/// whole UI between LTR and RTL.
class EyraApp extends StatelessWidget {
  const EyraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();

    final themeMode = switch (settings.themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return Directionality(
      textDirection: settings.textDirection,
      child: MaterialApp(
        title: 'Eyra',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.buildLight(
          highContrast: settings.highContrast,
          largeText: settings.largeText,
        ),
        darkTheme: AppTheme.buildDark(
          highContrast: settings.highContrast,
          largeText: settings.largeText,
        ),
        themeMode: themeMode,
        locale: settings.locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final clampedScaler = mediaQuery.textScaler.clamp(
            minScaleFactor: 0.9,
            maxScaleFactor: 1.3,
          );
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: clampedScaler),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
