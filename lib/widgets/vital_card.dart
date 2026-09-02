import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/health_data.dart';
import 'glass_card.dart';
import 'glass_controls.dart';
import 'vitals_widgets.dart';

/// A compact glass tile for one vital: an animated ring with the live value at
/// its centre, a status dot, and a trend sparkline underneath.
class VitalCard extends StatelessWidget {
  const VitalCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.gradient,
    required this.min,
    required this.max,
    required this.status,
    required this.trend,
    this.decimals = 0,
    this.onTap,
  });

  final String title;
  final double value;
  final String unit;
  final IconData icon;
  final Gradient gradient;
  final double min;
  final double max;
  final VitalStatus status;
  final List<double> trend;
  final int decimals;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (status) {
      VitalStatus.normal => AppColors.good,
      VitalStatus.watch => AppColors.warning,
      VitalStatus.critical => AppColors.danger,
    };

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.mist),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: VitalRing(
              value: value,
              min: min,
              max: max,
              gradient: gradient,
              size: 116,
              stroke: 9,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedCounter(
                    value: value,
                    decimals: decimals,
                    style: const TextStyle(
                      color: AppColors.frost,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Sparkline(values: trend, color: AppColors.mist, height: 30),
          const SizedBox(height: 6),
          StatusPill.vital(status),
        ],
      ),
    );
  }
}
