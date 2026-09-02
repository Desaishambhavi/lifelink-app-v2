import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/app_notification.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/entrance.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_controls.dart';
import '../../widgets/glass_scaffold.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) _raise();
    });

  bool _raised = false;

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  Future<void> _raise() async {
    if (_raised) return;
    setState(() => _raised = true);
    HapticFeedback.heavyImpact();

    final profile = context.read<ProfileProvider>().profile;
    final gps = context.read<HealthProvider>().latest.gps;
    await context.read<EmergencyProvider>().raise(profile: profile, location: gps);

    if (!mounted) return;
    await context.read<NotificationProvider>().push(
          AppNotification(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: 'Emergency SOS sent',
            body: 'Your emergency contact has been alerted with your live location.',
            kind: NotificationKind.sos,
            timestamp: DateTime.now(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;

    return GlassScaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GlassIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            const Spacer(),
            Entrance(
              child: Text(
                _raised ? 'Alert sent' : 'Emergency SOS',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _raised
                  ? 'Your emergency contact has been notified with your live location.'
                  : 'Press and hold the button for a moment to alert your emergency contact.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
            ),
            const Spacer(),
            _HoldButton(controller: _hold, raised: _raised, onCancel: () {
              if (!_raised) _hold.reverse();
            }, onDown: () {
              if (!_raised) _hold.forward();
            }),
            const Spacer(),
            if (profile != null && !_raised)
              Entrance(
                child: GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.white(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.glassStroke),
                        ),
                        child: const Icon(Icons.person_rounded, color: AppColors.mist),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('WILL ALERT',
                                style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2)),
                            const SizedBox(height: 3),
                            Text(
                              profile.emergencyContactName.isEmpty
                                  ? 'Emergency contact'
                                  : profile.emergencyContactName,
                              style: const TextStyle(
                                  color: AppColors.frost, fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            Text(profile.emergencyContactPhone,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_raised)
              Entrance(
                child: GlassButton(
                  label: 'Done',
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({
    required this.controller,
    required this.raised,
    required this.onDown,
    required this.onCancel,
  });

  final AnimationController controller;
  final bool raised;
  final VoidCallback onDown;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: raised ? null : (_) => onDown(),
      onTapUp: raised ? null : (_) => onCancel(),
      onTapCancel: raised ? null : onCancel,
      child: SizedBox(
        width: 236,
        height: 236,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 236,
                  height: 236,
                  child: CircularProgressIndicator(
                    value: raised ? 1 : controller.value,
                    strokeWidth: 7,
                    backgroundColor: AppColors.white(0.08),
                    valueColor: const AlwaysStoppedAnimation(AppColors.danger),
                  ),
                ),
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.danger.withValues(alpha: raised ? 0.9 : 0.7),
                        AppColors.danger.withValues(alpha: 0.35),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: raised ? 6 : 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(raised ? Icons.check_rounded : Icons.sos_rounded,
                          color: Colors.white, size: 54),
                      const SizedBox(height: 6),
                      Text(
                        raised ? 'SENT' : 'HOLD',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
