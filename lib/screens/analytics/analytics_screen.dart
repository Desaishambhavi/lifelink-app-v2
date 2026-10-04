import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_gradients.dart';
import '../../models/weekly_trend.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/weekly_trend_provider.dart';
import '../../widgets/entrance.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/top_bar.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, this.onOpenProfile});
  final VoidCallback? onOpenProfile;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    // Pull the last 100 readings and average them for the charts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final trend = context.watch<WeeklyTrendProvider>().trend;
    final analytics = context.watch<AnalyticsProvider>();

    // Headline averages come from the 100-reading window (fall back to the
    // weekly trend until the fetch resolves).
    final avgHr = analytics.avgHr > 0 ? analytics.avgHr : trend.avgHeartRate;
    final avgSpo2 = analytics.avgSpo2 > 0 ? analytics.avgSpo2 : trend.avgSpo2;
    final windowNote = analytics.loading
        ? 'Averaging last ${AnalyticsProvider.sampleWindow} readings…'
        : (analytics.error ??
            'Avg of last ${analytics.sampleCount} readings');

    return RefreshIndicator(
      onRefresh: () => context.read<AnalyticsProvider>().load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          TopBar(
              title: 'Analytics',
              eyebrow: 'Insights',
              onProfile: widget.onOpenProfile),
          const SizedBox(height: 22),
          Entrance(
            child: Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: 'Avg HR',
                    value: avgHr.toStringAsFixed(0),
                    unit: 'BPM',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatChip(
                    label: 'Avg SpO2',
                    value: avgSpo2.toStringAsFixed(0),
                    unit: '%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatChip(
                    label: 'Hydration',
                    value: trend.avgHydration.toStringAsFixed(0),
                    unit: '%',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Entrance(
            delay: const Duration(milliseconds: 80),
            child: _LineChartCard(
              title: 'Heart rate',
              subtitle: windowNote,
              values: analytics.hrSeries,
              average: analytics.avgHr,
              unit: 'BPM',
              gradient: AppGradients.accent,
              color: AppColors.mist,
            ),
          ),
          const SizedBox(height: 16),
          Entrance(
            delay: const Duration(milliseconds: 140),
            child: _LineChartCard(
              title: 'Blood oxygen',
              subtitle: windowNote,
              values: analytics.spo2Series,
              average: analytics.avgSpo2,
              unit: '%',
              gradient:
                  LinearGradient(colors: [AppColors.frost, AppColors.steel]),
              color: AppColors.frost,
              fixedMin: 88,
              fixedMax: 100,
            ),
          ),
          const SizedBox(height: 16),
          Entrance(
            delay: const Duration(milliseconds: 200),
            child: _WeeklyBarsCard(trend: trend),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.unit});
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              )),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: TextStyle(
                      color: AppColors.frost, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(width: 3),
              Text(unit,
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  const _LineChartCard({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.unit,
    required this.gradient,
    required this.color,
    this.average,
    this.fixedMin,
    this.fixedMax,
  });

  final String title;
  final String subtitle;
  final List<double> values;
  final String unit;
  final Gradient gradient;
  final Color color;

  /// The window average, drawn as a dashed reference line and shown in the
  /// header.
  final double? average;
  final double? fixedMin;
  final double? fixedMax;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    final minV = fixedMin ??
        (values.isEmpty ? 0 : values.reduce(math.min) - 4);
    final maxV = fixedMax ??
        (values.isEmpty ? 100 : values.reduce(math.max) + 4);
    final hasAvg = average != null && average! > 0;
    final headline = hasAvg
        ? '${average!.toStringAsFixed(unit == '%' ? 1 : 0)} $unit avg'
        : (values.isEmpty ? '—' : '${values.last.toStringAsFixed(0)} $unit');

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeader(context, title, subtitle, headline),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: values.length < 2
                ? Center(
                    child: Text('Collecting data…',
                        style: TextStyle(color: AppColors.textTertiary)))
                : LineChart(
                    LineChartData(
                      minY: minV.toDouble(),
                      maxY: maxV.toDouble(),
                      minX: 0,
                      maxX: (values.length - 1).toDouble(),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      extraLinesData: hasAvg
                          ? ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: average!,
                                  color: color.withValues(alpha: 0.45),
                                  strokeWidth: 1.4,
                                  dashArray: const [6, 5],
                                ),
                              ],
                            )
                          : const ExtraLinesData(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          gradient: gradient,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withValues(alpha: 0.28),
                                color.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBarsCard extends StatelessWidget {
  const _WeeklyBarsCard({required this.trend});
  final WeeklyTrend trend;

  @override
  Widget build(BuildContext context) {
    final maxHr = trend.days.map((d) => d.heartRate).fold<double>(0, math.max) + 10;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeader(context, 'Weekly heart rate', 'Daily averages',
              '${trend.avgHeartRate.toStringAsFixed(0)} BPM'),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxHr,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: const BarTouchData(enabled: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= trend.days.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            trend.days[i].day,
                            style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < trend.days.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: trend.days[i].heartRate,
                          width: 14,
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [AppColors.steel, AppColors.frost],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _chartHeader(BuildContext context, String title, String subtitle, String trailing) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          ],
        ),
      ),
      Text(trailing,
          style: TextStyle(
              color: AppColors.frost, fontSize: 15, fontWeight: FontWeight.w800)),
    ],
  );
}
