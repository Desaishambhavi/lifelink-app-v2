import 'package:flutter/material.dart';

/// LifeLink palette.
///
/// A single cohesive navy → frost blue ramp is the product identity. Semantic
/// accents (good / warning / danger) are intentionally restrained and used
/// ONLY for safety-critical states (fall detection, SOS, critical vitals) so
/// the interface never drifts into generic dashboard territory.
class AppColors {
  AppColors._();

  // --- Core ramp (darkest -> lightest) ---------------------------------------
  static const Color abyss = Color(0xFF021024); // deepest navy — background base
  static const Color deep = Color(0xFF052659); //  dark blue    — panels
  static const Color steel = Color(0xFF5483B3); // medium blue  — primary accent
  static const Color mist = Color(0xFF7DA0CA); //  light blue   — secondary accent
  static const Color frost = Color(0xFFC1E8FF); // near-white    — highlights/text

  // Extra tints derived from the ramp for depth.
  static const Color ink = Color(0xFF010A18); // near-black shadow tint
  static const Color midnight = Color(0xFF04183A); // between abyss & deep

  // --- Text ------------------------------------------------------------------
  static const Color textPrimary = Color(0xFFEAF4FF);
  static const Color textSecondary = Color(0xB3C1E8FF); // frost @ 70%
  static const Color textTertiary = Color(0x807DA0CA); //  mist  @ 50%

  // --- Glass surfaces (const ARGB to stay lint-clean) ------------------------
  static const Color glassFill = Color(0x0FFFFFFF); //   white @ ~6%
  static const Color glassFillStrong = Color(0x1FFFFFFF); // white @ ~12%
  static const Color glassStroke = Color(0x24FFFFFF); //  white @ ~14%
  static const Color glassHighlight = Color(0x3DFFFFFF); // white @ ~24%
  static const Color scrim = Color(0x99021024); //       abyss @ ~60%

  // --- Restrained semantic accents (safety-critical only) --------------------
  static const Color good = Color(0xFF54D6C4); //  calm teal   — healthy
  static const Color warning = Color(0xFFF2C14E); // muted amber — watch
  static const Color danger = Color(0xFFFF6B7A); //  soft coral  — critical

  /// A convenience helper for translucent overlays without deprecation noise.
  static Color white(double opacity) =>
      Colors.white.withValues(alpha: opacity);

  static Color of(Color base, double opacity) =>
      base.withValues(alpha: opacity);
}
