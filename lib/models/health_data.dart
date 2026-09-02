import 'dart:math' as math;

/// Severity buckets used to colour and describe a single vital.
enum VitalStatus { normal, watch, critical }

/// Three-axis accelerometer sample from the MPU6050 on the wearable.
class Acceleration {
  final double x;
  final double y;
  final double z;

  const Acceleration({this.x = 0, this.y = 0, this.z = 0});

  /// Magnitude of the acceleration vector, in g.
  double get total => math.sqrt(x * x + y * y + z * z);

  factory Acceleration.fromMap(Map<String, dynamic> map) => Acceleration(
        x: (map['x'] as num?)?.toDouble() ?? 0,
        y: (map['y'] as num?)?.toDouble() ?? 0,
        z: (map['z'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {'x': x, 'y': y, 'z': z, 'total': total};
}

/// A GPS fix from the wearable's location module.
class GpsPoint {
  final double latitude;
  final double longitude;
  final int satellites;

  const GpsPoint({
    required this.latitude,
    required this.longitude,
    this.satellites = 0,
  });

  bool get hasFix => satellites > 0 || latitude != 0 || longitude != 0;

  factory GpsPoint.fromMap(Map<String, dynamic> map) => GpsPoint(
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
        satellites: (map['satellites'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'satellites': satellites,
      };
}

/// One immutable reading of the user's vitals at a moment in time.
///
/// Mirrors the `/sensorData/{pushKey}` shape from the original firmware so a
/// real Supabase sensor row maps onto it 1:1.
class HealthData {
  final int heartRate; // BPM
  final double spo2; // %
  final bool spo2Valid;
  final DateTime timestamp;
  final Acceleration acceleration;
  final GpsPoint gps;

  const HealthData({
    required this.heartRate,
    required this.spo2,
    required this.spo2Valid,
    required this.timestamp,
    required this.acceleration,
    required this.gps,
  });

  VitalStatus get heartRateStatus {
    if (heartRate < 50 || heartRate > 120) return VitalStatus.critical;
    if (heartRate < 60 || heartRate > 100) return VitalStatus.watch;
    return VitalStatus.normal;
  }

  VitalStatus get spo2Status {
    if (!spo2Valid) return VitalStatus.watch;
    if (spo2 < 90) return VitalStatus.critical;
    if (spo2 < 95) return VitalStatus.watch;
    return VitalStatus.normal;
  }

  /// Worst of the individual vital states — drives the overall health ring.
  VitalStatus get overallStatus {
    final states = [heartRateStatus, spo2Status];
    if (states.contains(VitalStatus.critical)) return VitalStatus.critical;
    if (states.contains(VitalStatus.watch)) return VitalStatus.watch;
    return VitalStatus.normal;
  }

  factory HealthData.fromMap(Map<String, dynamic> map) => HealthData(
        heartRate: (map['heartRate'] as num?)?.toInt() ?? 0,
        spo2: (map['spo2'] as num?)?.toDouble() ?? 0,
        spo2Valid: map['spo2Valid'] as bool? ?? false,
        timestamp: map['timestamp'] is int
            ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
            : DateTime.tryParse('${map['timestamp']}') ?? DateTime.now(),
        acceleration:
            Acceleration.fromMap(map['acceleration'] as Map<String, dynamic>? ?? const {}),
        gps: GpsPoint.fromMap(map['gps'] as Map<String, dynamic>? ?? const {}),
      );

  Map<String, dynamic> toMap() => {
        'heartRate': heartRate,
        'spo2': spo2,
        'spo2Valid': spo2Valid,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'acceleration': acceleration.toMap(),
        'gps': gps.toMap(),
      };

  /// A neutral placeholder used before the first reading arrives.
  factory HealthData.empty() => HealthData(
        heartRate: 0,
        spo2: 0,
        spo2Valid: false,
        timestamp: DateTime.now(),
        acceleration: const Acceleration(),
        gps: const GpsPoint(latitude: 0, longitude: 0),
      );
}
