import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// The LifeLink logo mark: an ECG heartbeat trace inside a softly-glowing
/// rounded tile. Hand-drawn so the brand never looks like a stock icon.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 72, this.glow = true});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.steel, AppColors.deep],
        ),
        border: Border.all(color: AppColors.white(0.25), width: 1),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.steel.withValues(alpha: 0.5),
                  blurRadius: 28,
                  spreadRadius: -4,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.2),
        child: CustomPaint(painter: _EcgPainter()),
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  static const _points = <Offset>[
    Offset(0.00, 0.55),
    Offset(0.24, 0.55),
    Offset(0.36, 0.55),
    Offset(0.44, 0.28),
    Offset(0.52, 0.82),
    Offset(0.60, 0.14),
    Offset(0.68, 0.55),
    Offset(0.80, 0.55),
    Offset(1.00, 0.55),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < _points.length; i++) {
      final p = Offset(_points[i].dx * size.width, _points[i].dy * size.height);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    // Soft under-glow.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.frost.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.06
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.frost,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
