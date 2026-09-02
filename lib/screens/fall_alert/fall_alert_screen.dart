import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/app_notification.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/glass_controls.dart';
import '../../widgets/vitals_widgets.dart';

/// Full-screen, time-critical alert shown when a fall is detected. If the user
/// doesn't respond within the countdown, an SOS is sent automatically.
class FallAlertScreen extends StatefulWidget {
  const FallAlertScreen({super.key});

  @override
  State<FallAlertScreen> createState() => _FallAlertScreenState();
}

class _FallAlertScreenState extends State<FallAlertScreen> {
  static const _seconds = 15;
  int _remaining = _seconds;
  Timer? _timer;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _sendSos();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendSos() async {
    if (_resolved) return;
    _resolved = true;
    _timer?.cancel();

    final profile = context.read<ProfileProvider>().profile;
    final gps = context.read<HealthProvider>().latest.gps;
    await context.read<EmergencyProvider>().raise(
          profile: profile,
          location: gps,
          message: 'Fall detected. Automatic SOS from LifeLink.',
        );
    if (!mounted) return;
    await context.read<NotificationProvider>().push(
          AppNotification(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: 'Fall detected — SOS sent',
            body: 'A fall was detected and your emergency contact was alerted.',
            kind: NotificationKind.fall,
            timestamp: DateTime.now(),
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  void _dismiss() {
    _resolved = true;
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3A0A12), AppColors.abyss],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                const Spacer(),
                HeartbeatPulse(
                  size: 200,
                  color: AppColors.danger,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.danger.withValues(alpha: 0.18),
                      border: Border.all(color: AppColors.danger, width: 2),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: AppColors.danger, size: 60),
                  ),
                ),
                const SizedBox(height: 40),
                Text('Fall detected',
                    style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 12),
                Text(
                  'Sending an emergency alert in',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_remaining',
                  style: const TextStyle(
                      color: AppColors.danger, fontSize: 64, fontWeight: FontWeight.w800),
                ),
                const Text('seconds',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                const Spacer(),
                GlassButton(
                  label: "I'm OK — dismiss",
                  icon: Icons.check_rounded,
                  onPressed: _dismiss,
                ),
                const SizedBox(height: 12),
                GlassButton(
                  label: 'Send SOS now',
                  icon: Icons.sos_rounded,
                  kind: GlassButtonKind.ghost,
                  onPressed: _sendSos,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
