import 'package:battery_plus/battery_plus.dart';

import '../services/battery_service.dart';

/// Real Android phone battery monitoring using [battery_plus].
///
/// Provides a stream of battery level changes and allows reading
/// the current battery level. Emits `null` if the battery level
/// cannot be read.
class AndroidBatteryService implements BatteryService {
  AndroidBatteryService({Battery? battery})
      : _battery = battery ?? Battery();

  final Battery _battery;

  @override
  Stream<int?> get onBatteryLevelChanged {
    return _battery.onBatteryStateChanged.asyncMap((_) async {
      try {
        return await _battery.batteryLevel;
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Future<int?> getBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      return level;
    } catch (_) {
      return null;
    }
  }
}
