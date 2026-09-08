import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/assistance_session.dart';
import '../models/detection_log.dart';
import '../models/obstacle.dart';
import '../services/assistance_service.dart';
import '../services/mock/mock_assistance_service.dart';
import '../services/mock/mock_obstacle_detection_service.dart';
import '../services/obstacle_detection_service.dart';

/// Live-assistance session state shared across Home and Live Assistance
/// screens.
///
/// This controller is the abstraction boundary those screens depend on.
/// It never talks to a real (or mock) detector or session store
/// directly - it coordinates an injected [AssistanceService] (session
/// lifecycle) and an injected [ObstacleDetectionService] (detections).
/// By default those are [MockAssistanceService] and
/// [MockObstacleDetectionService], but a real backend
/// [AssistanceService] and a real local YOLO/ONNX
/// [ObstacleDetectionService] can be passed in instead without changing
/// this class or any screen.
class AssistanceController extends ChangeNotifier {
  AssistanceController({
    AssistanceService? assistanceService,
    ObstacleDetectionService? detectionService,
  })  : _assistanceService = assistanceService ?? MockAssistanceService(),
        _detectionService = detectionService ?? MockObstacleDetectionService() {
    _detectionSubscription = _detectionService.detections.listen(_onDetection);
  }

  final AssistanceService _assistanceService;
  final ObstacleDetectionService _detectionService;
  late final StreamSubscription<DetectionLog> _detectionSubscription;

  bool _isAssistanceActive = false;
  AssistanceSession? _currentSession;
  DetectionLog? _latestDetection;

  bool get isAssistanceActive => _isAssistanceActive;
  AssistanceSession? get currentSession => _currentSession;
  DetectionLog? get latestDetectionLog => _latestDetection;

  /// The current detection translated to the existing [Obstacle] UI
  /// model, so Home/Live Assistance/ObstacleCard keep working unchanged.
  Obstacle? get latestObstacle => _latestDetection?.toObstacle();

  /// Whether the underlying obstacle detector (mock or a real model) is
  /// ready to run.
  bool get isDetectorReady => _detectionService.isReady;

  static AssistanceController of(BuildContext context, {bool listen = false}) {
    return Provider.of<AssistanceController>(context, listen: listen);
  }

  Future<void> startAssistance({required String userId}) async {
    _currentSession = await _assistanceService.startSession(
      userId: userId,
    );
    _isAssistanceActive = true;
    _detectionService.start();
    notifyListeners();
  }

  Future<void> stopAssistance() async {
    _detectionService.stop();
    _isAssistanceActive = false;
    final session = _currentSession;
    _currentSession = null;
    notifyListeners();
    if (session != null) {
      await _assistanceService.stopSession(session.sessionId);
    }
  }

  void _onDetection(DetectionLog log) {
    _latestDetection = log;
    notifyListeners();
  }

  @override
  void dispose() {
    _detectionSubscription.cancel();
    super.dispose();
  }
}
