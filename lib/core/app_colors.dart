import 'package:flutter/material.dart';

/// LifeLink palette — now **theme-aware**.
///
/// The app supports two modes: a **black** dark theme and a **white** light
/// theme. Rather than thread `Theme.of(context)` through ~280 call sites, the
/// existing semantic names (`AppColors.abyss`, `AppColors.frost`, …) are kept
/// but resolve at runtime to whichever [_Palette] is active. Flip the mode with
/// [setLight]; the widget tree is rebuilt from the top (see ThemeProvider) so
/// every surface re-reads the new values.
class AppColors {
  AppColors._();

  static _Palette _current = _dark;

  /// Switch the whole palette to light (white) or dark (black).
  static void setLight(bool light) => _current = light ? _light : _dark;

  static bool get isLight => _current.isLight;

  // --- Core ramp (semantic; values differ per mode) --------------------------
  static Color get abyss => _current.abyss; //     background base
  static Color get deep => _current.deep; //       panels / surface
  static Color get steel => _current.steel; //     primary accent
  static Color get mist => _current.mist; //       secondary accent
  static Color get frost => _current.frost; //     foreground highlight / text
  static Color get ink => _current.ink; //         shadow tint
  static Color get midnight => _current.midnight; //between abyss & deep

  // --- Text ------------------------------------------------------------------
  static Color get textPrimary => _current.textPrimary;
  static Color get textSecondary => _current.textSecondary;
  static Color get textTertiary => _current.textTertiary;

  // --- Glass surfaces --------------------------------------------------------
  static Color get glassFill => _current.glassFill;
  static Color get glassFillStrong => _current.glassFillStrong;
  static Color get glassStroke => _current.glassStroke;
  static Color get glassHighlight => _current.glassHighlight;
  static Color get scrim => _current.scrim;

  // --- Restrained semantic accents (shared across modes) ---------------------
  static const Color good = Color(0xFF2FB6A3); //  teal   — healthy
  static const Color warning = Color(0xFFE0A62E); // amber — watch
  static const Color danger = Color(0xFFE5545F); //  coral — critical

  /// A translucent "veil" in the current foreground colour — white on the dark
  /// theme, dark navy on the light theme — so frosted surfaces read on either
  /// background. Most glass fills in the app go through this.
  static Color white(double opacity) =>
      _current.veil.withValues(alpha: opacity);

  static Color of(Color base, double opacity) =>
      base.withValues(alpha: opacity);

  // --- The two palettes ------------------------------------------------------

  static const _Palette _dark = _Palette(
    isLight: false,
    abyss: Color(0xFF000000),
    midnight: Color(0xFF070709),
    deep: Color(0xFF15171C),
    steel: Color(0xFF5483B3),
    mist: Color(0xFF7DA0CA),
    frost: Color(0xFFEAF4FF),
    ink: Color(0xFF000000),
    textPrimary: Color(0xFFEAF4FF),
    textSecondary: Color(0xB3E6F0FF),
    textTertiary: Color(0x807DA0CA),
    glassFill: Color(0x0FFFFFFF),
    glassFillStrong: Color(0x1FFFFFFF),
    glassStroke: Color(0x24FFFFFF),
    glassHighlight: Color(0x3DFFFFFF),
    scrim: Color(0x99000000),
    veil: Color(0xFFFFFFFF),
  );

  static const _Palette _light = _Palette(
    isLight: true,
    abyss: Color(0xFFFFFFFF),
    midnight: Color(0xFFF1F5FA),
    deep: Color(0xFFFFFFFF),
    steel: Color(0xFF3D6DA6),
    mist: Color(0xFF4E77A8),
    frost: Color(0xFF0B2545), // dark navy foreground on white
    ink: Color(0xFF9FB4CC), // soft cool-grey shadow on white
    textPrimary: Color(0xFF0B1F3A),
    textSecondary: Color(0x9E0B1F3A),
    textTertiary: Color(0x6B0B1F3A),
    glassFill: Color(0x0A0B2545),
    glassFillStrong: Color(0x140B2545),
    glassStroke: Color(0x1F0B2545),
    glassHighlight: Color(0x120B2545),
    scrim: Color(0x33000000),
    veil: Color(0xFF0B2545), // dark navy veil for glass on white
  );
}

/// One resolved set of colours for a single mode.
class _Palette {
  const _Palette({
    required this.isLight,
    required this.abyss,
    required this.midnight,
    required this.deep,
    required this.steel,
    required this.mist,
    required this.frost,
    required this.ink,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassStroke,
    required this.glassHighlight,
    required this.scrim,
    required this.veil,
  });

  final bool isLight;
  final Color abyss;
  final Color midnight;
  final Color deep;
  final Color steel;
  final Color mist;
  final Color frost;
  final Color ink;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color glassFill;
  final Color glassFillStrong;
  final Color glassStroke;
  final Color glassHighlight;
  final Color scrim;
  final Color veil;
}
