import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eyra/app/app.dart';
import 'package:eyra/core/state/app_settings_controller.dart';
import 'package:eyra/core/state/assistance_controller.dart';
import 'package:eyra/core/state/auth_controller.dart';
import 'package:eyra/core/state/camera_controller.dart';
import 'package:eyra/core/state/device_controller.dart';
import 'package:eyra/core/state/setup_controller.dart';
import 'package:eyra/core/state/telemetry_controller.dart';
import 'package:eyra/core/widgets/eyra_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<ChangeNotifierProvider> buildControllerProviders(AppSettingsController settingsController) {
    return [
      ChangeNotifierProvider.value(value: settingsController),
      ChangeNotifierProvider(create: (_) => AuthController()),
      ChangeNotifierProvider(create: (_) => DeviceController()),
      ChangeNotifierProvider(create: (_) => AssistanceController()),
      ChangeNotifierProvider(create: (_) => SetupController()),
      ChangeNotifierProvider(create: (_) => TelemetryController()),
      ChangeNotifierProvider(create: (_) => EyraCameraController()),
    ];
  }

  Future<Widget> buildTestApp() async {
    // Avoid touching real platform storage in tests.
    SharedPreferences.setMockInitialValues({});

    final settingsController = AppSettingsController();
    await settingsController.load();

    return MultiProvider(
      providers: buildControllerProviders(settingsController),
      child: const EyraApp(),
    );
  }

  testWidgets('Splash screen shows the Eyra logo and tagline', (tester) async {
    await tester.pumpWidget(await buildTestApp());
    // Let the fade-in animation run without waiting for the
    // auto-navigation timer to fire.
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(EyraLogo), findsOneWidget);
    expect(find.text('Assistive Vision'), findsOneWidget);
  });

  testWidgets('Splash screen navigates to Login after the delay', (tester) async {
    await tester.pumpWidget(await buildTestApp());

    // The splash screen auto-navigates to Login after ~1.8s.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('Arabic language setting flips text direction to RTL', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settingsController = AppSettingsController();
    await settingsController.load();
    await settingsController.setLanguage(AppLanguage.arabic);

    await tester.pumpWidget(
      MultiProvider(
        providers: buildControllerProviders(settingsController),
        child: const EyraApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final directionality = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });
}
