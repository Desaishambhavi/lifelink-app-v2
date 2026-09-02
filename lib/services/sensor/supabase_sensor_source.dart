import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';
import '../../models/health_data.dart';
import '../supabase_service.dart';
import 'sensor_source.dart';

/// Live vitals from the ESP32 stream stored in Supabase.
///
/// Subscribes to the newest rows of [AppConfig.sensorTable] via Realtime and
/// maps them onto [HealthData]. The mapper is deliberately forgiving so it
/// works whether the table is `sensor_logs`, `device_readings`, or
/// `device_sensor_data`.
class SupabaseSensorSource implements SensorSource {
  SupabaseSensorSource();

  final SupabaseClient _client = SupabaseService.instance.sensor;
  final _vitalsController = StreamController<HealthData>.broadcast();
  final _fallController = StreamController<bool>.broadcast();
  final List<HealthData> _history = [];

  HealthData _latest = HealthData.empty();
  StreamSubscription? _vitalsSub;
  StreamSubscription? _fallSub;
  int? _lastFallId;

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
    _vitalsSub = _client
        .from(AppConfig.sensorTable)
        .stream(primaryKey: ['id'])
        .order('created_at')
        .limit(30)
        .listen((rows) {
      _history
        ..clear()
        ..addAll(rows.map(_map));
      if (_history.isNotEmpty) {
        _latest = _history.last;
        if (!_vitalsController.isClosed) _vitalsController.add(_latest);
      }
    });

    _fallSub = _client
        .from(AppConfig.fallEventsTable)
        .stream(primaryKey: ['id'])
        .order('created_at')
        .limit(1)
        .listen((rows) {
      if (rows.isEmpty) return;
      final id = (rows.first['id'] as num?)?.toInt();
      if (id != null && id != _lastFallId) {
        final first = _lastFallId == null;
        _lastFallId = id;
        if (!first && !_fallController.isClosed) _fallController.add(true);
      }
    });
  }

  HealthData _map(Map<String, dynamic> r) {
    num? pick(List<String> keys) {
      for (final k in keys) {
        final v = r[k];
        if (v is num) return v;
      }
      return null;
    }

    final spo2Valid = r['spo2_valid'];
    return HealthData(
      heartRate: pick(['heart_rate_bpm', 'heart_rate'])?.toInt() ?? 0,
      spo2: pick(['spo2'])?.toDouble() ?? 0,
      spo2Valid: spo2Valid == true || spo2Valid == 1,
      timestamp: DateTime.tryParse('${r['created_at'] ?? r['event_timestamp']}') ??
          DateTime.now(),
      acceleration: Acceleration(
        x: pick(['accel_x'])?.toDouble() ?? 0,
        y: pick(['accel_y'])?.toDouble() ?? 0,
        z: pick(['accel_z'])?.toDouble() ?? 0,
      ),
      gps: GpsPoint(
        latitude: pick(['latitude', 'gps_latitude'])?.toDouble() ?? 0,
        longitude: pick(['longitude', 'gps_longitude'])?.toDouble() ?? 0,
        satellites: pick(['gps_satellites'])?.toInt() ??
            (r['gps_fix'] == true ? 9 : 0),
      ),
    );
  }

  @override
  void simulateFall() {
    // No-op with real hardware; falls come from the device itself.
  }

  @override
  Future<void> dispose() async {
    await _vitalsSub?.cancel();
    await _fallSub?.cancel();
    await _vitalsController.close();
    await _fallController.close();
  }
}
