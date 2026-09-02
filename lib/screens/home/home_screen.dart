import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_gradients.dart';
import '../../core/app_routes.dart';
import '../../models/health_data.dart';
import '../../providers/health_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/entrance.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_controls.dart';
import '../../widgets/live_map_panel.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/vital_card.dart';
import '../../widgets/vitals_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenProfile});
  final VoidCallback? onOpenProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _analysis;
  bool _analyzing = false;

  Future<void> _analyze() async {
    setState(() => _analyzing = true);
    final profile = context.read<ProfileProvider>().profile;
    final text = await context.read<HealthProvider>().analyze(profile);
    if (!mounted) return;
    setState(() {
      _analysis = text;
      _analyzing = false;
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthProvider>();
    final latest = health.latest;
    final name = context.watch<ProfileProvider>().profile?.name.split(' ').first ??
        'there';

    final hrTrend = health.history.map((e) => e.heartRate.toDouble()).toList();
    final spo2Trend = health.history.map((e) => e.spo2).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        TopBar(title: name, eyebrow: _greeting, onProfile: widget.onOpenProfile),
        const SizedBox(height: 22),
        Entrance(child: _StatusHero(status: health.status, latest: latest)),
        const SizedBox(height: 16),
        Entrance(
          delay: const Duration(milliseconds: 80),
          child: Row(
            children: [
              Expanded(
                child: VitalCard(
                  title: 'Heart rate',
                  value: latest.heartRate.toDouble(),
                  unit: 'BPM',
                  icon: Icons.favorite_rounded,
                  gradient: AppGradients.accent,
                  min: 40,
                  max: 160,
                  status: latest.heartRateStatus,
                  trend: hrTrend,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: VitalCard(
                  title: 'Blood oxygen',
                  value: latest.spo2,
                  unit: 'SpO2 %',
                  icon: Icons.air_rounded,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.frost, AppColors.steel],
                  ),
                  min: 80,
                  max: 100,
                  status: latest.spo2Status,
                  trend: spo2Trend,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Entrance(
          delay: const Duration(milliseconds: 140),
          child: LiveMapPanel(gps: latest.gps),
        ),
        const SizedBox(height: 16),
        Entrance(
          delay: const Duration(milliseconds: 200),
          child: _AiInsightCard(
            analysis: _analysis,
            analyzing: _analyzing,
            onAnalyze: _analyze,
          ),
        ),
        const SizedBox(height: 16),
        Entrance(
          delay: const Duration(milliseconds: 260),
          child: _QuickActions(
            onSos: () => Navigator.of(context).pushNamed(AppRoutes.emergency),
            onTestFall: () => context.read<HealthProvider>().triggerFallDemo(),
          ),
        ),
      ],
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.status, required this.latest});
  final VitalStatus status;
  final HealthData latest;

  @override
  Widget build(BuildContext context) {
    final (headline, color) = switch (status) {
      VitalStatus.normal => ('Your vitals look healthy', AppColors.good),
      VitalStatus.watch => ('Keep an eye on your vitals', AppColors.warning),
      VitalStatus.critical => ('Your vitals need attention', AppColors.danger),
    };

    return GlassCard(
      highlight: true,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.good, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text('LIVE MONITORING',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        )),
                  ],
                ),
                const SizedBox(height: 14),
                Text(headline,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Continuously tracking your heart rate, oxygen and motion.',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 12),
                StatusPill.vital(status),
              ],
            ),
          ),
          const SizedBox(width: 8),
          HeartbeatPulse(
            size: 96,
            color: color,
            child: Icon(Icons.monitor_heart_rounded, color: color, size: 34),
          ),
        ],
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({
    required this.analysis,
    required this.analyzing,
    required this.onAnalyze,
  });

  final String? analysis;
  final bool analyzing;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 18, color: AppColors.mist),
              const SizedBox(width: 8),
              Text('AI insight', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (analysis != null)
                ValueListenableBuilder<bool>(
                  valueListenable: Services.tts.speaking,
                  builder: (context, speaking, _) => GlassIconButton(
                    icon: speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                    size: 38,
                    onTap: () => speaking
                        ? Services.tts.stop()
                        : Services.tts.speak(analysis!),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: analysis == null
                ? Column(
                    key: const ValueKey('empty'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Get a plain-language reading of your current vitals, '
                        'generated on demand.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13, height: 1.45),
                      ),
                      const SizedBox(height: 16),
                      GlassButton(
                        label: analyzing ? 'Analyzing' : 'Analyze my vitals',
                        icon: Icons.insights_rounded,
                        loading: analyzing,
                        onPressed: onAnalyze,
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('result'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysis!,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13.5, height: 1.55),
                      ),
                      const SizedBox(height: 14),
                      GlassButton(
                        label: analyzing ? 'Refreshing' : 'Re-analyze',
                        icon: Icons.refresh_rounded,
                        kind: GlassButtonKind.ghost,
                        loading: analyzing,
                        onPressed: onAnalyze,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onSos, required this.onTestFall});
  final VoidCallback onSos;
  final VoidCallback onTestFall;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            onTap: onSos,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.sos_rounded, color: AppColors.danger),
                ),
                const SizedBox(height: 12),
                const Text('Emergency SOS',
                    style: TextStyle(
                        color: AppColors.frost, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GlassCard(
            onTap: onTestFall,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.white(0.06),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.glassStroke),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.mist),
                ),
                const SizedBox(height: 12),
                const Text('Test fall alert',
                    style: TextStyle(
                        color: AppColors.frost, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
