import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reusable gradients that give the app its layered, glass-over-deep-water feel.
class AppGradients {
  AppGradients._();

  /// Primary full-screen backdrop: abyss at the top easing into deep blue.
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.abyss, AppColors.midnight, AppColors.deep],
    stops: [0.0, 0.5, 1.0],
  );

  /// Diagonal sheen laid over glass surfaces so they catch the "light".
  static const LinearGradient glassSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x33FFFFFF), Color(0x05FFFFFF)],
  );

  /// Steel -> mist accent used for progress arcs and highlights.
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.mist, AppColors.steel],
  );

  /// Bright frost -> mist fill for primary call-to-action buttons.
  static const LinearGradient frostButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.frost, AppColors.mist],
  );

  /// Radial glow used behind hero elements (heartbeat, SOS).
  static RadialGradient glow(Color color) => RadialGradient(
        colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0.0)],
        stops: const [0.0, 1.0],
      );
}
