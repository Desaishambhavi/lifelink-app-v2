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

  // The most recent GENUINE GPS fix. sensor_logs currently carries no location,
  // so we seed this from the historical GPS table and reuse it whenever a live
  // reading has no fix.
  GpsPoint? _lastGoodGps;
  static const _gpsFallbackTable = 'device_sensor_data';

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
    await _loadLastKnownGps();

    // Newest 30 rows (descending), then reversed so _history runs oldest→newest
    // and _latest is the most recent reading.
    _vitalsSub = _client
        .from(AppConfig.sensorTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(30)
        .listen((rows) {
      _history
        ..clear()
        ..addAll(rows.map(_map).toList().reversed);
      // Remember the newest genuine fix seen in this batch, if any.
      for (final r in _history) {
        if (r.gps.hasFix) _lastGoodGps = r.gps;
      }
      if (_history.isNotEmpty) {
        var latest = _history.last;
        // No live fix → fall back to the last known genuine location.
        if (!latest.gps.hasFix && _lastGoodGps != null) {
          latest = latest.copyWith(gps: _lastGoodGps);
        }
        _latest = latest;
        if (!_vitalsController.isClosed) _vitalsController.add(_latest);
      }
    });

    _fallSub = _client
        .from(AppConfig.fallEventsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
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

  /// Seeds [_lastGoodGps] with the most recent non-zero location on record, so
  /// the map shows a real place even when the live stream reports no fix.
  Future<void> _loadLastKnownGps() async {
    try {
      final rows = await _client
          .from(_gpsFallbackTable)
          .select('gps_latitude,gps_longitude')
          .neq('gps_latitude', 0)
          .order('created_at', ascending: false)
          .limit(1);
      if (rows is List && rows.isNotEmpty) {
        final r = rows.first as Map<String, dynamic>;
        final lat = (r['gps_latitude'] as num?)?.toDouble() ?? 0;
        final lng = (r['gps_longitude'] as num?)?.toDouble() ?? 0;
        if (lat != 0 || lng != 0) {
          _lastGoodGps = GpsPoint(latitude: lat, longitude: lng);
        }
      }
    } catch (_) {
      // Best-effort: if the lookup fails, live readings simply show no fix.
    }
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
