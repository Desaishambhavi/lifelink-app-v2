import '../../models/health_data.dart';

/// Abstraction over the live vitals stream.
///
/// The rest of the app only ever talks to this interface, so swapping the mock
/// simulator for the real Supabase/ESP32 feed is a one-line change in the
/// service locator — no UI or provider code changes.
abstract class SensorSource {
  /// Broadcast stream of vitals as they arrive.
  Stream<HealthData> get vitals;

  /// Emits `true` the moment a fall is detected.
  Stream<bool> get fallDetected;

  /// The most recent reading (or an empty reading before the first arrives).
  HealthData get latest;

  /// The last [count] readings, newest last.
  List<HealthData> recent([int count = 20]);

  /// Begin producing/subscribing to data.
  Future<void> start();

  /// Manually raise a fall event — used by the demo affordance in mock mode.
  void simulateFall();

  /// Tear down timers/subscriptions.
  Future<void> dispose();
}
