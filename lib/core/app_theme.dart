import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// The single source of truth for typography, shape, and Material theming.
///
/// LifeLink is a dark, glass-forward interface, so the theme is tuned for a
/// deep navy canvas with frost-white text and Manrope's clean geometry.
class AppTheme {
  AppTheme._();

  static const double radiusSm = 14;
  static const double radiusMd = 22;
  static const double radiusLg = 30;
  static const double radiusXl = 40;

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ).copyWith(
      displayLarge: GoogleFonts.manrope(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.textSecondary,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: AppColors.textPrimary,
      ),
      labelSmall: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppColors.textTertiary,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.abyss,
      canvasColor: Colors.transparent,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.frost,
        onPrimary: AppColors.abyss,
        secondary: AppColors.mist,
        onSecondary: AppColors.abyss,
        surface: AppColors.deep,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
      ),
      splashFactory: InkRipple.splashFactory,
      splashColor: AppColors.glassHighlight,
      highlightColor: Colors.transparent,
      dividerColor: AppColors.glassStroke,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: AppColors.frost),
      ),
      iconTheme: const IconThemeData(color: AppColors.frost, size: 22),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.deep,
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
    );
  }
}
