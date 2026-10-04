import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import 'pressable.dart';

/// The fundamental building block of the interface: a frosted-glass panel with
/// a real backdrop blur, a soft top-light sheen, a hairline stroke, and depth
/// shadow. Everything in the app is composed from these.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppTheme.radiusLg,
    this.blur = 24,
    this.onTap,
    this.onLongPress,
    this.highlight = false,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// A brighter, more prominent variant for hero surfaces.
  final bool highlight;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final light = AppColors.isLight;

    // Light mode is a clean, flat theme: solid light cards with a hairline
    // border and a soft shadow — not the dark-veil frosted glass, which only
    // reads correctly over the dark backdrop.
    final Widget panel = light
        ? ClipRRect(
            borderRadius: borderRadius,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: AppColors.deep, // #FFFFFF surface in the light palette
                border: Border.all(
                  color: highlight
                      ? const Color(0xFFD6E0EE)
                      : AppColors.glassStroke,
                  width: 1,
                ),
              ),
              child: child,
            ),
          )
        : ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: highlight
                        ? [AppColors.white(0.18), AppColors.white(0.05)]
                        : [AppColors.white(0.10), AppColors.white(0.03)],
                  ),
                  border: Border.all(
                    color: highlight ? AppColors.white(0.28) : AppColors.glassStroke,
                    width: 1,
                  ),
                ),
                child: child,
              ),
            ),
          );

    final shadowed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          light
              ? BoxShadow(
                  color: const Color(0xFF0B2545).withValues(alpha: 0.08),
                  blurRadius: 24,
                  spreadRadius: -8,
                  offset: const Offset(0, 12),
                )
              : BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.45),
                  blurRadius: 30,
                  spreadRadius: -6,
                  offset: const Offset(0, 18),
                ),
        ],
      ),
      child: panel,
    );

    final result = Padding(
      padding: margin ?? EdgeInsets.zero,
      child: shadowed,
    );

    if (onTap == null && onLongPress == null) return result;
    return Pressable(onTap: onTap, onLongPress: onLongPress, child: result);
  }
}
