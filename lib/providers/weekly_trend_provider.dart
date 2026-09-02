import 'package:flutter/foundation.dart';

import '../models/weekly_trend.dart';

/// Supplies the Mon–Sun wellbeing averages shown in Analytics.
///
/// In mock mode this is a stable, illustrative baseline that matches the
/// `weekly_trends` seed in supabase/schema.sql. When the app project is wired
/// up, swap [load] for a query against that table.
class WeeklyTrendProvider extends ChangeNotifier {
  WeeklyTrend _trend = _seed();
  bool _loading = false;

  WeeklyTrend get trend => _trend;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _trend = _seed();
    _loading = false;
    notifyListeners();
  }

  static WeeklyTrend _seed() => const WeeklyTrend([
        DailyTrend(day: 'Mon', heartRate: 74, spo2: 97, stress: 42, hydration: 68),
        DailyTrend(day: 'Tue', heartRate: 78, spo2: 96, stress: 55, hydration: 61),
        DailyTrend(day: 'Wed', heartRate: 72, spo2: 98, stress: 38, hydration: 74),
        DailyTrend(day: 'Thu', heartRate: 80, spo2: 96, stress: 60, hydration: 58),
        DailyTrend(day: 'Fri', heartRate: 76, spo2: 97, stress: 47, hydration: 65),
        DailyTrend(day: 'Sat', heartRate: 70, spo2: 98, stress: 30, hydration: 80),
        DailyTrend(day: 'Sun', heartRate: 69, spo2: 98, stress: 28, hydration: 83),
      ]);
}
