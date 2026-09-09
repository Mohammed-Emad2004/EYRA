import 'dart:async';

import '../battery_service.dart';

/// Local mock implementation of [BatteryService].
///
/// Returns a fixed battery level for tests/development. The stream
/// never emits new values unless manually triggered via
/// [emitBatteryLevel].
class MockBatteryService implements BatteryService {
  MockBatteryService({int initialLevel = 78})
      : _currentLevel = initialLevel;

  int _currentLevel;
  final _controller = StreamController<int?>.broadcast();

  @override
  Stream<int?> get onBatteryLevelChanged => _controller.stream;

  @override
  Future<int?> getBatteryLevel() async {
    return _currentLevel;
  }

  /// Manually set the battery level for testing purposes.
  /// This will emit the new value on the stream.
  void emitBatteryLevel(int level) {
    _currentLevel = level;
    _controller.add(level);
  }

  void dispose() {
    _controller.close();
  }
}
