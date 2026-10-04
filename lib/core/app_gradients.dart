import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reusable gradients that give the app its layered, glass-over-deep feel.
///
/// These are getters (not consts) because [AppColors] now resolves per theme
/// mode at runtime — the gradients follow whichever palette is active.
class AppGradients {
  AppGradients._();

  /// Primary full-screen backdrop: base easing into the panel tone.
  static LinearGradient get background => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.abyss, AppColors.midnight, AppColors.deep],
        stops: const [0.0, 0.5, 1.0],
      );

  /// Diagonal sheen laid over glass surfaces so they catch the "light".
  static LinearGradient get glassSheen => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.white(0.20), AppColors.white(0.02)],
      );

  /// Steel -> mist accent used for progress arcs and highlights.
  static LinearGradient get accent => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.mist, AppColors.steel],
      );

  /// Bright frost -> mist fill for primary call-to-action buttons.
  static LinearGradient get frostButton => LinearGradient(
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
