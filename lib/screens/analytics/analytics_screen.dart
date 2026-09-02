import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_gradients.dart';
import '../../models/weekly_trend.dart';
import '../../providers/health_provider.dart';
import '../../providers/weekly_trend_provider.dart';
import '../../widgets/entrance.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/top_bar.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key, this.onOpenProfile});
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthProvider>();
    final trend = context.watch<WeeklyTrendProvider>().trend;

    final hr = health.history.map((e) => e.heartRate.toDouble()).toList();
    final spo2 = health.history.map((e) => e.spo2).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        TopBar(title: 'Analytics', eyebrow: 'Insights', onProfile: onOpenProfile),
        const SizedBox(height: 22),
        Entrance(
          child: Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Avg HR',
                  value: trend.avgHeartRate.toStringAsFixed(0),
                  unit: 'BPM',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  label: 'Avg SpO2',
                  value: trend.avgSpo2.toStringAsFixed(0),
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
            subtitle: 'Recent readings',
            values: hr,
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
            subtitle: 'Recent readings',
            values: spo2,
            unit: '%',
            gradient: const LinearGradient(colors: [AppColors.frost, AppColors.steel]),
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
              style: const TextStyle(
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
                  style: const TextStyle(
                      color: AppColors.frost, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(width: 3),
              Text(unit,
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
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
    this.fixedMin,
    this.fixedMax,
  });

  final String title;
  final String subtitle;
  final List<double> values;
  final String unit;
  final Gradient gradient;
  final Color color;
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

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeader(context, title, subtitle,
              values.isEmpty ? '—' : '${values.last.toStringAsFixed(0)} $unit'),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: values.length < 2
                ? const Center(
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
                barTouchData: BarTouchData(enabled: false),
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
                            style: const TextStyle(
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
                          gradient: const LinearGradient(
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
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          ],
        ),
      ),
      Text(trailing,
          style: const TextStyle(
              color: AppColors.frost, fontSize: 15, fontWeight: FontWeight.w800)),
    ],
  );
}
