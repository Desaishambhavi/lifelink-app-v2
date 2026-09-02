import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_gradients.dart';

/// The atmospheric backdrop for every screen: a deep navy gradient with three
/// softly-lit orbs drifting on slow Lissajous paths. Purely decorative and
/// GPU-cheap (one repeating controller), it gives the glass something to
/// refract without any imagery.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final t = _c.value * 2 * math.pi;
                  return Stack(
                    children: [
                      _orb(
                        color: AppColors.steel,
                        size: w * 0.9,
                        x: w * (0.15 + 0.10 * math.sin(t)),
                        y: h * (0.10 + 0.06 * math.cos(t * 0.8)),
                        opacity: 0.30,
                      ),
                      _orb(
                        color: AppColors.mist,
                        size: w * 0.8,
                        x: w * (0.55 + 0.12 * math.cos(t * 0.7)),
                        y: h * (0.55 + 0.08 * math.sin(t)),
                        opacity: 0.22,
                      ),
                      _orb(
                        color: AppColors.frost,
                        size: w * 0.6,
                        x: w * (0.65 + 0.10 * math.sin(t * 1.2)),
                        y: h * (0.16 + 0.10 * math.cos(t)),
                        opacity: 0.14,
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _orb({
    required Color color,
    required double size,
    required double x,
    required double y,
    required double opacity,
  }) {
    return Positioned(
      left: x - size / 2,
      top: y - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
