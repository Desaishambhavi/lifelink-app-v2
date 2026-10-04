import 'package:flutter/foundation.dart';

import '../services/service_locator.dart';

/// Loads the last [sampleWindow] sensor readings and reduces them to an
/// averaged trend for the analytics charts: the plotted line is the mean of
/// consecutive buckets (so it's the *average* shape of the window, not raw
/// noise), and [avgHr] / [avgSpo2] are the overall means across the window.
class AnalyticsProvider extends ChangeNotifier {
  /// How many recent readings to average over.
  static const int sampleWindow = 100;

  /// How many averaged points to plot (down-sample target).
  static const int _buckets = 20;

  bool _loading = true;
  String? _error;
  int _sampleCount = 0;
  List<double> _hrSeries = const [];
  List<double> _spo2Series = const [];
  double _avgHr = 0;
  double _avgSpo2 = 0;

  bool get loading => _loading;
  String? get error => _error;
  int get sampleCount => _sampleCount;
  List<double> get hrSeries => _hrSeries;
  List<double> get spo2Series => _spo2Series;
  double get avgHr => _avgHr;
  double get avgSpo2 => _avgSpo2;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final readings = await Services.sensor.history(count: sampleWindow);

      // Only count genuine (non-zero / valid) samples so sensor drop-outs don't
      // drag the averages toward zero.
      final hr = readings
          .map((r) => r.heartRate.toDouble())
          .where((v) => v > 0)
          .toList();
      // The wearable records a plausible SpO2 on every row but marks
      // `spo2_valid` false on all of them, so gating on that flag hides SpO2
      // entirely. Keep physiologically sane readings instead and drop the
      // sensor's ~70 noise floor (and impossible >100 values).
      final spo2 = readings
          .map((r) => r.spo2)
          .where((v) => v > 70 && v <= 100)
          .toList();

      _sampleCount = readings.length;
      _avgHr = _mean(hr);
      _avgSpo2 = _mean(spo2);
      _hrSeries = _bucketAverages(hr, _buckets);
      _spo2Series = _bucketAverages(spo2, _buckets);
    } catch (_) {
      _error = 'Could not load analytics';
      _hrSeries = const [];
      _spo2Series = const [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  double _mean(List<double> v) =>
      v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;

  /// Collapse [values] into at most [buckets] points, each the mean of a
  /// contiguous slice — a mean-based down-sample of the window.
  List<double> _bucketAverages(List<double> values, int buckets) {
    if (values.length <= buckets) return List.of(values);
    final double size = values.length / buckets;
    final out = <double>[];
    for (var b = 0; b < buckets; b++) {
      final start = (b * size).floor();
      final end = ((b + 1) * size).floor().clamp(start + 1, values.length);
      final slice = values.sublist(start, end);
      out.add(slice.reduce((a, b) => a + b) / slice.length);
    }
    return out;
  }
}
