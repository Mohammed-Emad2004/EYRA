import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'core/state/app_settings_controller.dart';
import 'core/state/auth_controller.dart';
import 'core/state/device_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsController = AppSettingsController();
  await settingsController.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsController),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => DeviceController()),
      ],
      child: const EyraApp(),
    ),
  );
}
