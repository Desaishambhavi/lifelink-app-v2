import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/health_data.dart';
import '../models/user_profile.dart';
import '../services/service_locator.dart';

/// Live vitals, rolling history, and fall state — the heartbeat of the app.
///
/// Raw samples arrive from the sensor as fast as the source produces them. To
/// keep the displayed numbers steady and meaningful, every incoming sample is
/// buffered and collapsed into a single **5-second average** for heart rate and
/// SpO2. The averaged sample is what the UI, charts and AI analysis all see.
class HealthProvider extends ChangeNotifier {
  /// Vitals are averaged over this rolling window before being displayed.
  static const Duration averageWindow = Duration(seconds: 5);
  static const int _maxHistory = 30;

  HealthProvider() {
    _latest = Services.sensor.latest;
    _history = List.of(Services.sensor.recent(_maxHistory));
    _vitalsSub = Services.sensor.vitals.listen(_onReading);
    _fallSub = Services.sensor.fallDetected.listen((_) {
      _fallActive = true;
      notifyListeners();
    });
    _avgTimer = Timer.periodic(averageWindow, (_) => _flushWindow());
  }

  late HealthData _latest;
  late List<HealthData> _history;
  bool _fallActive = false;

  // Samples received since the last 5-second flush.
  final List<HealthData> _window = [];
  Timer? _avgTimer;
  StreamSubscription<HealthData>? _vitalsSub;
  StreamSubscription<bool>? _fallSub;

  HealthData get latest => _latest;
  List<HealthData> get history => _history;
  bool get fallActive => _fallActive;
  VitalStatus get status => _latest.overallStatus;

  /// True once at least one real reading has arrived.
  bool get hasData => _history.isNotEmpty && _latest.heartRate > 0;

  /// Buffer every incoming sample; the timer turns a window into one average.
  void _onReading(HealthData reading) => _window.add(reading);

  /// Collapse the readings seen during the last window into one averaged sample.
  void _flushWindow() {
    if (_window.isEmpty) return; // No new data this window — keep the last value.
    final samples = List.of(_window);
    _window.clear();

    // Average only genuine (non-zero) readings so a sensor drop-out doesn't
    // drag the mean down to zero.
    final hr = samples.map((s) => s.heartRate).where((v) => v > 0).toList();
    final spo2 = samples.map((s) => s.spo2).where((v) => v > 0).toList();

    final averaged = samples.last.copyWith(
      heartRate: hr.isEmpty ? 0 : (hr.reduce((a, b) => a + b) / hr.length).round(),
      spo2: spo2.isEmpty
          ? 0
          : double.parse(
              (spo2.reduce((a, b) => a + b) / spo2.length).toStringAsFixed(1)),
      spo2Valid: samples.any((s) => s.spo2Valid),
    );

    _latest = averaged;
    final next = [..._history, averaged];
    _history =
        next.length > _maxHistory ? next.sublist(next.length - _maxHistory) : next;
    notifyListeners();
  }

  Future<String> analyze(UserProfile? profile) =>
      Services.ai.analyzeVitals(_latest, profile: profile);

  /// Demo affordance — raise a synthetic fall event (mock mode only).
  void triggerFallDemo() => Services.sensor.simulateFall();

  void acknowledgeFall() {
    _fallActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _avgTimer?.cancel();
    _vitalsSub?.cancel();
    _fallSub?.cancel();
    super.dispose();
  }
}
