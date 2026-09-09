/// Abstraction boundary for phone battery monitoring.
///
/// [DeviceController] depends only on this interface, never on a concrete
/// battery plugin directly. Today the only implementation is
/// [MockBatteryService] for tests/development, and [AndroidBatteryService]
/// for real Android phone battery monitoring.
///
/// The battery level is exposed as a [Stream] so the UI updates
/// automatically when the phone's battery level changes, without
/// aggressive polling.
abstract class BatteryService {
  /// A stream that emits the current battery level as an integer
  /// percentage (0-100) whenever the battery level changes.
  ///
  /// Emits `null` if the battery level cannot be read.
  Stream<int?> get onBatteryLevelChanged;

  /// Returns the current battery level as an integer percentage (0-100),
  /// or `null` if the battery level cannot be read.
  Future<int?> getBatteryLevel();
}
