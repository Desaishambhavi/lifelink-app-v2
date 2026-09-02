import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/health_data.dart';
import '../models/user_profile.dart';
import '../services/service_locator.dart';

/// Live vitals, rolling history, and fall state — the heartbeat of the app.
class HealthProvider extends ChangeNotifier {
  HealthProvider() {
    _latest = Services.sensor.latest;
    _history = Services.sensor.recent(30);
    _vitalsSub = Services.sensor.vitals.listen(_onReading);
    _fallSub = Services.sensor.fallDetected.listen((_) {
      _fallActive = true;
      notifyListeners();
    });
  }

  late HealthData _latest;
  late List<HealthData> _history;
  bool _fallActive = false;

  StreamSubscription<HealthData>? _vitalsSub;
  StreamSubscription<bool>? _fallSub;

  HealthData get latest => _latest;
  List<HealthData> get history => _history;
  bool get fallActive => _fallActive;
  VitalStatus get status => _latest.overallStatus;

  /// True once at least one real reading has arrived.
  bool get hasData => _history.isNotEmpty && _latest.heartRate > 0;

  void _onReading(HealthData reading) {
    _latest = reading;
    _history = Services.sensor.recent(30);
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
    _vitalsSub?.cancel();
    _fallSub?.cancel();
    super.dispose();
  }
}
