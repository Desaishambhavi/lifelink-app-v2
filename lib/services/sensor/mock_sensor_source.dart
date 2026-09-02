import 'dart:async';
import 'dart:math' as math;

import '../../models/health_data.dart';
import 'sensor_source.dart';

/// A believable, self-contained vitals simulator.
///
/// It performs a bounded random-walk around healthy baselines so the charts,
/// rings and AI analysis all have living data to work with — no hardware and
/// no network required. Writes to a real ESP32 table later replace this class
/// without touching anything else.
class MockSensorSource implements SensorSource {
  MockSensorSource();

  final _rng = math.Random();
  final _vitalsController = StreamController<HealthData>.broadcast();
  final _fallController = StreamController<bool>.broadcast();
  final List<HealthData> _history = [];

  Timer? _timer;
  HealthData _latest = HealthData.empty();

  // Baselines the walk drifts around.
  double _hr = 74;
  double _spo2 = 98;
  static const double _baseLat = 15.3647; // a stable demo location
  static const double _baseLng = 75.1240;

  @override
  Stream<HealthData> get vitals => _vitalsController.stream;

  @override
  Stream<bool> get fallDetected => _fallController.stream;

  @override
  HealthData get latest => _latest;

  @override
  List<HealthData> recent([int count = 20]) {
    if (_history.length <= count) return List.unmodifiable(_history);
    return List.unmodifiable(_history.sublist(_history.length - count));
  }

  @override
  Future<void> start() async {
    // Prime a short history so the analytics charts aren't empty on first paint.
    final now = DateTime.now();
    for (var i = 19; i >= 0; i--) {
      _history.add(_synth(now.subtract(Duration(seconds: i * 2))));
    }
    _latest = _history.last;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      final reading = _synth(DateTime.now());
      _push(reading);
    });
  }

  void _push(HealthData reading) {
    _latest = reading;
    _history.add(reading);
    if (_history.length > 240) _history.removeAt(0);
    if (!_vitalsController.isClosed) _vitalsController.add(reading);
  }

  HealthData _synth(DateTime at) {
    // Gentle random walk, clamped to a healthy envelope.
    _hr += (_rng.nextDouble() - 0.5) * 3.2;
    _hr = _hr.clamp(58, 104);
    _spo2 += (_rng.nextDouble() - 0.5) * 0.6;
    _spo2 = _spo2.clamp(94, 100);

    // Accelerometer sits near 1g (rest) with light jitter.
    double jitter() => (_rng.nextDouble() - 0.5) * 0.12;
    final ax = jitter();
    final ay = jitter();
    final az = 1.0 + jitter();

    return HealthData(
      heartRate: _hr.round(),
      spo2: double.parse(_spo2.toStringAsFixed(1)),
      spo2Valid: true,
      timestamp: at,
      acceleration: Acceleration(x: ax, y: ay, z: az),
      gps: GpsPoint(
        latitude: _baseLat + (_rng.nextDouble() - 0.5) * 0.0009,
        longitude: _baseLng + (_rng.nextDouble() - 0.5) * 0.0009,
        satellites: 7 + _rng.nextInt(4),
      ),
    );
  }

  @override
  void simulateFall() {
    // A fall reads as a large acceleration spike; surface it and flag it.
    final at = DateTime.now();
    final spike = HealthData(
      heartRate: (_hr + 22).round().clamp(40, 180),
      spo2: double.parse(_spo2.toStringAsFixed(1)),
      spo2Valid: true,
      timestamp: at,
      acceleration: const Acceleration(x: 2.6, y: 1.9, z: 2.9),
      gps: GpsPoint(
        latitude: _baseLat,
        longitude: _baseLng,
        satellites: 9,
      ),
    );
    _push(spike);
    if (!_fallController.isClosed) _fallController.add(true);
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _vitalsController.close();
    await _fallController.close();
  }
}
