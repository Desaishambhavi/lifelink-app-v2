import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_config.dart';
import '../../core/app_routes.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/entrance.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_controls.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/vitals_widgets.dart';

/// The first impression: a calm hero, three capability highlights, and two
/// clear paths forward. Everything eases in on load.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _features = [
    (
      Icons.favorite_border_rounded,
      'Real-time vitals',
      'Heart rate, SpO2 and motion, streamed live from your wearable.'
    ),
    (
      Icons.auto_awesome_outlined,
      'AI health insights',
      'Plain-language reading of your vitals and medical reports.'
    ),
    (
      Icons.shield_outlined,
      'Fall detection & SOS',
      'Automatic alerts and one-tap emergency contact.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Entrance(
              child: HeartbeatPulse(
                size: 150,
                color: AppColors.frost,
                child: const BrandMark(size: 96),
              ),
            ),
            const SizedBox(height: 32),
            Entrance(
              delay: const Duration(milliseconds: 120),
              child: Text(
                AppConfig.appName,
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            const SizedBox(height: 10),
            Entrance(
              delay: const Duration(milliseconds: 200),
              child: Text(
                AppConfig.appTagline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const Spacer(flex: 2),
            for (var i = 0; i < _features.length; i++)
              Entrance(
                delay: Duration(milliseconds: 280 + i * 90),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FeatureRow(
                    icon: _features[i].$1,
                    title: _features[i].$2,
                    body: _features[i].$3,
                  ),
                ),
              ),
            const Spacer(flex: 2),
            Entrance(
              delay: const Duration(milliseconds: 560),
              child: GlassButton(
                label: 'Get started',
                icon: Icons.arrow_forward_rounded,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.signup),
              ),
            ),
            const SizedBox(height: 12),
            Entrance(
              delay: const Duration(milliseconds: 640),
              child: GlassButton(
                label: 'I already have an account',
                kind: GlassButtonKind.ghost,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.login),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassStroke),
            ),
            child: Icon(icon, color: AppColors.mist, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
