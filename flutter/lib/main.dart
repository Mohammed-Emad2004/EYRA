import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'core/services/android_battery_service.dart';
import 'core/services/firebase/firebase_auth_service.dart';
import 'core/services/firebase/firestore_assistance_service.dart';
import 'core/services/firebase/firestore_device_service.dart';
import 'core/services/firebase/firestore_detection_log_service.dart';
import 'core/services/firebase/firestore_settings_service.dart';
import 'core/services/firebase/firestore_telemetry_service.dart';
import 'core/services/firebase/firestore_user_service.dart';
import 'core/services/http/http_obstacle_detection_service.dart';
import 'core/services/local/flutter_tts_service.dart';
import 'core/services/local/speech_recognition_service.dart';
import 'core/services/text_to_speech_service.dart';
import 'core/state/app_settings_controller.dart';
import 'core/state/assistance_controller.dart';
import 'core/state/auth_controller.dart';
import 'core/state/camera_controller.dart';
import 'core/state/device_controller.dart';
import 'core/state/setup_controller.dart';
import 'core/state/telemetry_controller.dart';
import 'core/state/voice_command_controller.dart';
import 'features/voice/voice_command_router.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EyraRoot());
}

/// Top-level widget. AuthController and VoiceCommandController live here
/// — they never get disposed or recreated across auth state changes.
/// All other controllers are scoped to the auth-aware provider trees.
class EyraRoot extends StatefulWidget {
  const EyraRoot({super.key});

  @override
  State<EyraRoot> createState() => _EyraRootState();
}

class _EyraRootState extends State<EyraRoot> {
  late final FlutterTtsService _ttsService;

  @override
  void initState() {
    super.initState();
    _ttsService = FlutterTtsService();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TextToSpeechService>.value(value: _ttsService),
        ChangeNotifierProvider(
          create: (_) => AuthController(
            authService: FirebaseAuthService(),
            userService: FirestoreUserService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => VoiceCommandController(
            voiceCommandService: SpeechRecognitionService(),
            textToSpeechService: _ttsService,
          )..initialize(),
        ),
      ],
      child: const _AuthGate(),
    );
  }
}

/// Switches between authenticated and unauthenticated provider trees
/// based on auth state. When the UID changes, the old tree is fully
/// disposed and a new tree is created — no state leaks between users.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        final userId = auth.currentUser?.userId;
        if (userId != null) {
          return _AuthenticatedTree(key: ValueKey(userId), userId: userId);
        }
        return const _UnauthenticatedTree();
      },
    );
  }
}

/// Provider tree for unauthenticated state. Uses mock/local services.
class _UnauthenticatedTree extends StatefulWidget {
  const _UnauthenticatedTree();

  @override
  State<_UnauthenticatedTree> createState() => _UnauthenticatedTreeState();
}

class _UnauthenticatedTreeState extends State<_UnauthenticatedTree> {
  late final EyraCameraController _cameraController;
  late final HttpObstacleDetectionService _detectionService;

  @override
  void initState() {
    super.initState();
    _cameraController = EyraCameraController();
    _detectionService = HttpObstacleDetectionService(
      cameraStream: _cameraController.imageStream,
    );
    debugPrint(
      '[DIAGNOSTIC] _UnauthenticatedTreeState.initState: '
      'EyraCameraController(id: ${identityHashCode(_cameraController)}), '
      'CameraService(id: ${identityHashCode(_cameraController.service)}), '
      'cameraStream(id: ${identityHashCode(_cameraController.imageStream)}), '
      'HttpObstacleDetectionService(id: ${identityHashCode(_detectionService)})',
    );
  }

  @override
  void dispose() {
    _detectionService.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppSettingsController()..load(),
        ),
        ChangeNotifierProvider(create: (_) => DeviceController()),
        ChangeNotifierProvider(
          create: (context) => AssistanceController(
            detectionService: _detectionService,
            textToSpeechService:
                Provider.of<TextToSpeechService>(context, listen: false),
            settingsController:
                Provider.of<AppSettingsController>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(create: (_) => TelemetryController()),
        ChangeNotifierProvider(create: (_) => SetupController()),
        ChangeNotifierProvider.value(value: _cameraController),
      ],
      child: const _VoiceLanguageSync(
        child: VoiceCommandRouter(child: EyraApp()),
      ),
    );
  }
}

/// Provider tree for authenticated state. All user-scoped services use
/// the provided [userId]. Disposed and recreated cleanly when UID changes.
class _AuthenticatedTree extends StatefulWidget {
  final String userId;
  const _AuthenticatedTree({required this.userId, super.key});

  @override
  State<_AuthenticatedTree> createState() => _AuthenticatedTreeState();
}

class _AuthenticatedTreeState extends State<_AuthenticatedTree> {
  late final EyraCameraController _cameraController;
  late final HttpObstacleDetectionService _detectionService;

  @override
  void initState() {
    super.initState();
    _cameraController = EyraCameraController();
    _detectionService = HttpObstacleDetectionService(
      cameraStream: _cameraController.imageStream,
      sessionId: widget.userId,
    );
    debugPrint(
      '[DIAGNOSTIC] _AuthenticatedTreeState.initState: '
      'EyraCameraController(id: ${identityHashCode(_cameraController)}), '
      'CameraService(id: ${identityHashCode(_cameraController.service)}), '
      'cameraStream(id: ${identityHashCode(_cameraController.imageStream)}), '
      'HttpObstacleDetectionService(id: ${identityHashCode(_detectionService)})',
    );
  }

  @override
  void dispose() {
    _detectionService.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppSettingsController(
            settingsService: FirestoreSettingsService(userId: widget.userId),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => DeviceController(
            deviceService: FirestoreDeviceService(userId: widget.userId),
            batteryService: AndroidBatteryService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AssistanceController(
            assistanceService: FirestoreAssistanceService(userId: widget.userId),
            detectionService: _detectionService,
            detectionLogService: FirestoreDetectionLogService(userId: widget.userId),
            textToSpeechService:
                Provider.of<TextToSpeechService>(context, listen: false),
            settingsController:
                Provider.of<AppSettingsController>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TelemetryController(
            telemetryService: FirestoreTelemetryService(userId: widget.userId),
          ),
        ),
        ChangeNotifierProvider(create: (_) => SetupController()),
        ChangeNotifierProvider.value(value: _cameraController),
      ],
      child: const _VoiceLanguageSync(
        child: VoiceCommandRouter(child: EyraApp()),
      ),
    );
  }
}

/// Sits below the [MultiProvider] so its [BuildContext] can see
/// [AppSettingsController]. Handles:
/// 1. Starting Voice Ready Mode once on first build (post-frame callback).
/// 2. Syncing [AppSettingsController.language] → [VoiceCommandController]
///    whenever the settings change.
/// 3. Stopping Voice Ready Mode when the authenticated tree is disposed.
class _VoiceLanguageSync extends StatefulWidget {
  final Widget child;
  const _VoiceLanguageSync({required this.child});

  @override
  State<_VoiceLanguageSync> createState() => _VoiceLanguageSyncState();
}

class _VoiceLanguageSyncState extends State<_VoiceLanguageSync> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vc = Provider.of<VoiceCommandController>(context, listen: false);
      final settings =
          Provider.of<AppSettingsController>(context, listen: false);
      vc.setAppLanguage(settings.language);
      vc.startVoiceReadyMode();
    });
  }

  @override
  void dispose() {
    final vc = Provider.of<VoiceCommandController>(context, listen: false);
    vc.stopVoiceReadyMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    // Sync language to voice controller whenever settings change.
    final vc = Provider.of<VoiceCommandController>(context, listen: false);
    vc.setAppLanguage(settings.language);
    return widget.child;
  }
}
