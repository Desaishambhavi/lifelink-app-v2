import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_colors.dart';
import '../models/health_data.dart';
import 'glass_card.dart';

/// A live-location panel rendered as a calm, animated location beacon rather
/// than a heavy map tile — no API key, no imagery, and it matches the glass
/// aesthetic. The wearer sits at the centre as a map-style dot; soft "ping"
/// ripples radiate outward and the fix coordinates update from the sensor feed.
class LiveMapPanel extends StatefulWidget {
  const LiveMapPanel({super.key, required this.gps, this.height = 190, this.timestamp});

  final GpsPoint gps;
  final double height;
  final DateTime? timestamp;

  @override
  State<LiveMapPanel> createState() => _LiveMapPanelState();
}

class _LiveMapPanelState extends State<LiveMapPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Opens the current fix in Google Maps (external app / browser).
  Future<void> _openInMaps() async {
    final gps = widget.gps;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${gps.latitude},${gps.longitude}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fall back to the platform default handler if the external app launch
      // is refused (e.g. no browser/maps app available).
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gps = widget.gps;
    final live = gps.satellites > 0;
    final hasLocation = gps.latitude != 0 || gps.longitude != 0;
    final badge = live
        ? '${gps.satellites} satellites'
        : (hasLocation ? 'Last known' : 'Acquiring fix');
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.my_location_rounded, size: 18, color: AppColors.mist),
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
                  badge,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (widget.timestamp != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 5),
                Text(
                  'Last recorded at ${DateFormat('d MMM yyyy, h:mm a').format(widget.timestamp!)}',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
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
                          CustomPaint(painter: _LocationPulsePainter(_c.value)),
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
                  if (hasLocation)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.white(0.10),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppColors.glassStroke),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_rounded,
                                size: 13, color: AppColors.frost),
                            const SizedBox(width: 6),
                            Text(
                              'Open in Maps',
                              style: TextStyle(
                                color: AppColors.frost,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (hasLocation)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _openInMaps,
                        behavior: HitTestBehavior.opaque,
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
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: AppColors.frost,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// A calm "live location" beacon: a map-style dot at the wearer's position with
/// soft ping ripples radiating outward over a faint dot grid. No sweep, rings or
/// crosshair — nothing that reads as tactical/radar.
class _LocationPulsePainter extends CustomPainter {
  _LocationPulsePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) / 2 * 0.9;

    // Faint dot grid — reads as a quiet map surface rather than a radar screen.
    final dot = Paint()..color = AppColors.white(0.05);
    const gap = 26.0;
    for (double y = gap / 2; y < size.height; y += gap) {
      for (double x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }

    // Expanding location-ping ripples (three, phase-staggered so one is always
    // radiating). Each fades and thins as it grows.
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final radius = maxR * p;
      final fade = (1 - p);
      if (radius <= 0) continue;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * fade + 0.5
          ..color = AppColors.mist.withValues(alpha: fade * 0.5),
      );
    }

    // Soft glow beneath the marker.
    canvas.drawCircle(
      center,
      18,
      Paint()
        ..color = AppColors.frost.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Central location dot: an accent ring with a dark core — the familiar
    // "you are here" map marker.
    canvas.drawCircle(center, 9, Paint()..color = AppColors.frost);
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.steel,
    );
    canvas.drawCircle(center, 3.4, Paint()..color = AppColors.abyss);
  }

  @override
  bool shouldRepaint(_LocationPulsePainter old) => old.t != t;
}
