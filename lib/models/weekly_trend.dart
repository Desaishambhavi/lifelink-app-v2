/// A single day's averaged wellbeing metrics, part of the Mon–Sun trend set
/// mirrored from `/weekly_trends` in the original schema.
class DailyTrend {
  final String day; // 'Mon', 'Tue', ...
  final double heartRate;
  final double spo2;
  final double stress; // 0–100
  final double hydration; // 0–100

  const DailyTrend({
    required this.day,
    required this.heartRate,
    required this.spo2,
    required this.stress,
    required this.hydration,
  });

  factory DailyTrend.fromMap(String day, Map<String, dynamic> map) =>
      DailyTrend(
        day: day,
        heartRate: (map['heartRate'] as num?)?.toDouble() ?? 0,
        spo2: (map['spo2'] as num?)?.toDouble() ?? 0,
        stress: (map['stress'] as num?)?.toDouble() ?? 0,
        hydration: (map['hydration'] as num?)?.toDouble() ?? 0,
      );
}

/// The full seven-day trend, with a few convenience aggregates for the
/// analytics header cards.
class WeeklyTrend {
  final List<DailyTrend> days;

  const WeeklyTrend(this.days);

  double get avgHeartRate => _avg((d) => d.heartRate);
  double get avgSpo2 => _avg((d) => d.spo2);
  double get avgStress => _avg((d) => d.stress);
  double get avgHydration => _avg((d) => d.hydration);

  double _avg(double Function(DailyTrend) selector) {
    if (days.isEmpty) return 0;
    final sum = days.fold<double>(0, (acc, d) => acc + selector(d));
    return sum / days.length;
  }
}
