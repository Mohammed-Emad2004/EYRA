import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyra/core/models/detection_log.dart';
import 'package:eyra/core/models/obstacle.dart';
import 'package:eyra/core/services/http/http_obstacle_detection_service.dart';
import 'package:eyra/core/services/obstacle_detection_service.dart';
import 'package:eyra/core/services/text_to_speech_service.dart';
import 'package:eyra/core/state/app_settings_controller.dart';
import 'package:eyra/core/state/assistance_controller.dart';

class FakeTextToSpeechService implements TextToSpeechService {
  final List<String> spokenHistory = [];
  String? currentLanguage;
  bool speaking = false;

  @override
  bool get isSpeaking => speaking;

  @override
  Future<void> speak(String text) async {
    spokenHistory.add(text);
  }

  @override
  Future<void> stop() async {
    speaking = false;
  }

  @override
  Future<void> repeatLast() async {
    if (spokenHistory.isNotEmpty) {
      await speak(spokenHistory.last);
    }
  }

  @override
  Future<void> setLanguage(String localeId) async {
    currentLanguage = localeId;
  }

  @override
  void dispose() {}
}

class FakeObstacleDetectionService implements ObstacleDetectionService {
  final _batchController = StreamController<List<DetectionLog>>.broadcast();

  @override
  bool get isReady => true;

  @override
  Stream<DetectionLog> get detections => const Stream.empty();

  @override
  Stream<List<DetectionLog>> get batchDetections => _batchController.stream;

  void emit(List<DetectionLog> logs) {
    _batchController.add(logs);
  }

  @override
  void start() {}

  @override
  void stop() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  group('FRONT Rectangle Intersection Logic', () {
    test('Identifies boxes inside, intersecting, and outside FRONT rectangle', () {
      const w = 640.0;
      const h = 480.0;
      // Front zone is [160, 0, 480, 480]

      // Completely outside (left)
      expect(
        HttpObstacleDetectionService.checkFrontIntersection(
          box: [0, 50, 100, 200],
          imageWidth: w,
          imageHeight: h,
        ),
        isFalse,
      );

      // Completely outside (right)
      expect(
        HttpObstacleDetectionService.checkFrontIntersection(
          box: [500, 50, 630, 200],
          imageWidth: w,
          imageHeight: h,
        ),
        isFalse,
      );

      // Partially entering from the left (crosses 160)
      expect(
        HttpObstacleDetectionService.checkFrontIntersection(
          box: [100, 50, 200, 300],
          imageWidth: w,
          imageHeight: h,
        ),
        isTrue,
      );

      // Partially entering from the right (crosses 480)
      expect(
        HttpObstacleDetectionService.checkFrontIntersection(
          box: [450, 50, 550, 300],
          imageWidth: w,
          imageHeight: h,
        ),
        isTrue,
      );

      // Fully centered inside
      expect(
        HttpObstacleDetectionService.checkFrontIntersection(
          box: [200, 100, 400, 350],
          imageWidth: w,
          imageHeight: h,
        ),
        isTrue,
      );
    });

    test('Works with normalized coordinates (0.0 - 1.0)', () {
      // Left [0.0 - 0.20]
      expect(
        HttpObstacleDetectionService.checkFrontIntersection(
          box: [0.05, 0.1, 0.20, 0.8],
          imageWidth: 1.0,
          imageHeight: 1.0,
        ),
        isFalse,
      );

      // Center [0.30 - 0.70]
      expect(
        HttpObstacleDetectionService.checkFrontIntersection(
          box: [0.30, 0.1, 0.70, 0.9],
          imageWidth: 1.0,
          imageHeight: 1.0,
        ),
        isTrue,
      );
    });
  });

  group('AssistanceController Speech & Zone Filtering', () {
    late FakeTextToSpeechService tts;
    late FakeObstacleDetectionService detector;
    late AppSettingsController settings;
    late AssistanceController controller;

    setUp(() async {
      tts = FakeTextToSpeechService();
      detector = FakeObstacleDetectionService();
      settings = AppSettingsController();
      controller = AssistanceController(
        detectionService: detector,
        textToSpeechService: tts,
        settingsController: settings,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('Does NOT speak objects outside the FRONT rectangle', () async {
      final leftLog = DetectionLog(
        logId: '1',
        sessionId: 's',
        detectedLabel: 'car',
        spatialDirection: SpatialDirection.left,
        dangerLevel: DangerLevel.high,
        audioSpokenText: 'car on your left',
        createdAt: DateTime.now(),
        isInFrontZone: false,
      );

      final rightLog = DetectionLog(
        logId: '2',
        sessionId: 's',
        detectedLabel: 'person',
        spatialDirection: SpatialDirection.right,
        dangerLevel: DangerLevel.high,
        audioSpokenText: 'person on your right',
        createdAt: DateTime.now(),
        isInFrontZone: false,
      );

      detector.emit([leftLog, rightLog]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      detector.emit([leftLog, rightLog]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(tts.spokenHistory, isEmpty);
    });

    test('Does NOT speak detection that appears in only ONE frame (temporal stability)', () async {
      await settings.setLanguage(AppLanguage.arabic);

      final motorcycleLog = DetectionLog(
        logId: '1',
        sessionId: 's',
        detectedLabel: 'motorcycle',
        spatialDirection: SpatialDirection.center,
        dangerLevel: DangerLevel.high,
        audioSpokenText: 'motorcycle ahead',
        createdAt: DateTime.now(),
        isInFrontZone: true,
        confidence: 0.85,
      );

      // Emit only once (single unstable frame)
      detector.emit([motorcycleLog]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Must NOT be spoken!
      expect(tts.spokenHistory, isEmpty);
    });

    test('Speaks detection when confirmed across 2 consecutive frames', () async {
      await settings.setLanguage(AppLanguage.arabic);

      final personLog = DetectionLog(
        logId: '1',
        sessionId: 's',
        detectedLabel: 'person',
        spatialDirection: SpatialDirection.center,
        dangerLevel: DangerLevel.high,
        audioSpokenText: 'person ahead',
        createdAt: DateTime.now(),
        isInFrontZone: true,
        confidence: 0.85,
      );

      // Frame 1
      detector.emit([personLog]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(tts.spokenHistory, isEmpty); // Not spoken yet

      // Frame 2 (consecutive confirmation)
      detector.emit([personLog]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(tts.spokenHistory.length, equals(1));
      expect(tts.spokenHistory.first, equals('أمامك شخص.'));
    });

    test('Does NOT speak detection below confidence threshold (0.45)', () async {
      await settings.setLanguage(AppLanguage.arabic);

      final lowConfLog = DetectionLog(
        logId: '1',
        sessionId: 's',
        detectedLabel: 'person',
        spatialDirection: SpatialDirection.center,
        dangerLevel: DangerLevel.high,
        audioSpokenText: 'person ahead',
        createdAt: DateTime.now(),
        isInFrontZone: true,
        confidence: 0.35, // Below 0.45 threshold
      );

      // Emit twice across consecutive frames
      detector.emit([lowConfLog]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      detector.emit([lowConfLog]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(tts.spokenHistory, isEmpty);
    });

    test('Combines multiple FRONT detections into one natural Arabic sentence', () async {
      await settings.setLanguage(AppLanguage.arabic);

      final personLog = DetectionLog(
        logId: '1',
        sessionId: 's',
        detectedLabel: 'person',
        spatialDirection: SpatialDirection.center,
        dangerLevel: DangerLevel.high,
        audioSpokenText: 'person ahead',
        createdAt: DateTime.now(),
        isInFrontZone: true,
        confidence: 0.75,
      );

      final chairLog = DetectionLog(
        logId: '2',
        sessionId: 's',
        detectedLabel: 'chair',
        spatialDirection: SpatialDirection.center,
        dangerLevel: DangerLevel.medium,
        audioSpokenText: 'chair ahead',
        createdAt: DateTime.now(),
        isInFrontZone: true,
        confidence: 0.70,
      );

      final carLog = DetectionLog(
        logId: '3',
        sessionId: 's',
        detectedLabel: 'car',
        spatialDirection: SpatialDirection.center,
        dangerLevel: DangerLevel.low,
        audioSpokenText: 'car ahead',
        createdAt: DateTime.now(),
        isInFrontZone: true,
        confidence: 0.80,
      );

      final batch = [personLog, chairLog, carLog];
      // Frame 1
      detector.emit(batch);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // Frame 2 (confirms stability)
      detector.emit(batch);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(tts.spokenHistory.length, equals(1));
      expect(tts.spokenHistory.first, equals('أمامك شخص، كرسي، وسيارة.'));
      expect(tts.currentLanguage, equals('ar-EG'));

      // Confirm NO directional words
      for (final forbidden in ['على يسارك', 'على يمينك', 'يسار', 'يمين', 'LEFT', 'RIGHT']) {
        expect(tts.spokenHistory.first.contains(forbidden), isFalse);
      }
    });

    test('Combines FRONT detections into English sentence when language is English', () async {
      await settings.setLanguage(AppLanguage.english);

      final personLog = DetectionLog(
        logId: '1',
        sessionId: 's',
        detectedLabel: 'person',
        spatialDirection: SpatialDirection.center,
        dangerLevel: DangerLevel.high,
        audioSpokenText: 'person ahead',
        createdAt: DateTime.now(),
        isInFrontZone: true,
        confidence: 0.75,
      );

      final carLog = DetectionLog(
        logId: '2',
        sessionId: 's',
        detectedLabel: 'car',
        spatialDirection: SpatialDirection.center,
        dangerLevel: DangerLevel.medium,
        audioSpokenText: 'car ahead',
        createdAt: DateTime.now(),
        isInFrontZone: true,
        confidence: 0.80,
      );

      final batch = [personLog, carLog];
      detector.emit(batch);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      detector.emit(batch);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(tts.spokenHistory.length, equals(1));
      expect(tts.spokenHistory.first, equals('person and car ahead.'));
      expect(tts.currentLanguage, equals('en-US'));
    });

    test('Deduplicates identical objects in the same frame and respects cooldown', () async {
      await settings.setLanguage(AppLanguage.arabic);

      final chair1 = DetectionLog(
        logId: '1',
        sessionId: 's',
        detectedLabel: 'chair',
        spatialDirection: SpatialDirection.center,
        dangerLevel: DangerLevel.high,
        audioSpokenText: 'chair ahead',
        createdAt: DateTime.now(),
        isInFrontZone: true,
        confidence: 0.70,
      );
      final chair2 = DetectionLog(
        logId: '2',
        sessionId: 's',
        detectedLabel: 'chair',
        spatialDirection: SpatialDirection.center,
        dangerLevel: DangerLevel.high,
        audioSpokenText: 'chair ahead',
        createdAt: DateTime.now(),
        isInFrontZone: true,
        confidence: 0.72,
      );

      // Frame 1
      detector.emit([chair1, chair2]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // Frame 2
      detector.emit([chair1, chair2]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(tts.spokenHistory.length, equals(1));
      expect(tts.spokenHistory.first, equals('أمامك كرسي.')); // Deduped!

      // Emit another frame immediately -> should be blocked by cooldown
      detector.emit([chair1]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(tts.spokenHistory.length, equals(1)); // Still only 1 spoken call!
    });
  });
}
