import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'core/services/firebase/firebase_auth_service.dart';
import 'core/state/app_settings_controller.dart';
import 'core/state/assistance_controller.dart';
import 'core/state/auth_controller.dart';
import 'core/state/camera_controller.dart';
import 'core/state/device_controller.dart';
import 'core/state/setup_controller.dart';
import 'core/state/telemetry_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final settingsController = AppSettingsController();
  await settingsController.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsController),
        ChangeNotifierProvider(
          create: (_) => AuthController(authService: FirebaseAuthService()),
        ),
        ChangeNotifierProvider(create: (_) => DeviceController()),
        ChangeNotifierProvider(create: (_) => AssistanceController()),
        ChangeNotifierProvider(create: (_) => SetupController()),
        ChangeNotifierProvider(create: (_) => TelemetryController()),
        ChangeNotifierProvider(create: (_) => EyraCameraController()),
      ],
      child: const EyraApp(),
    ),
  );
}
