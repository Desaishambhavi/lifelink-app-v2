import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/health_data.dart';
import 'glass_card.dart';

/// A live-location panel rendered as an animated radar rather than a heavy map
/// tile — no API key, no imagery, and it matches the glass aesthetic. The
/// wearer sits at the centre; a sweep line rotates continuously and the fix
/// coordinates update from the sensor feed.
class LiveMapPanel extends StatefulWidget {
  const LiveMapPanel({super.key, required this.gps, this.height = 190});

  final GpsPoint gps;
  final double height;

  @override
  State<LiveMapPanel> createState() => _LiveMapPanelState();
}

class _LiveMapPanelState extends State<LiveMapPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gps = widget.gps;
    final fix = gps.hasFix;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location_rounded, size: 18, color: AppColors.mist),
              const SizedBox(width: 8),
              Text('Live location', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.white(0.06),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.glassStroke),
                ),
                child: Text(
                  fix ? '${gps.satellites} satellites' : 'Acquiring fix',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.midnight, AppColors.abyss],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) =>
                          CustomPaint(painter: _RadarPainter(_c.value)),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _coord('LAT', gps.latitude.toStringAsFixed(5)),
                        const SizedBox(height: 4),
                        _coord('LNG', gps.longitude.toStringAsFixed(5)),
                      ],
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

  Widget _coord(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.frost,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) / 2 * 0.94;

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.white(0.06);

    // Range rings + crosshair.
    for (final f in const [0.4, 0.7, 1.0]) {
      canvas.drawCircle(center, maxR * f, grid);
    }
    canvas.drawLine(
        Offset(center.dx - maxR, center.dy), Offset(center.dx + maxR, center.dy), grid);
    canvas.drawLine(
        Offset(center.dx, center.dy - maxR), Offset(center.dx, center.dy + maxR), grid);

    // Sweep trail.
    final angle = t * 2 * math.pi;
    final sweep = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: maxR), angle - 0.6, 0.6, false)
      ..close();
    canvas.drawPath(
      sweep,
      Paint()
        ..shader = SweepGradient(
          startAngle: angle - 0.6,
          endAngle: angle,
          colors: [AppColors.mist.withValues(alpha: 0), AppColors.mist.withValues(alpha: 0.28)],
          transform: GradientRotation(0),
        ).createShader(Rect.fromCircle(center: center, radius: maxR)),
    );
    // Leading edge line.
    canvas.drawLine(
      center,
      center + Offset(math.cos(angle) * maxR, math.sin(angle) * maxR),
      Paint()
        ..strokeWidth = 1.5
        ..color = AppColors.mist.withValues(alpha: 0.55),
    );

    // Fixed reference blips.
    for (final b in const [Offset(0.62, 0.3), Offset(0.3, 0.68), Offset(0.75, 0.66)]) {
      final p = Offset(b.dx * size.width, b.dy * size.height);
      canvas.drawCircle(p, 2.4, Paint()..color = AppColors.steel.withValues(alpha: 0.7));
    }

    // Pulsing centre marker (the wearer).
    final pulse = (t * 1.6) % 1;
    canvas.drawCircle(
      center,
      maxR * 0.16 * pulse + 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.frost.withValues(alpha: (1 - pulse) * 0.6),
    );
    canvas.drawCircle(center, 5, Paint()..color = AppColors.frost);
    canvas.drawCircle(
      center,
      5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.steel,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.t != t;
}
