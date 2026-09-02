import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/health_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/report_provider.dart';
import '../providers/weekly_trend_provider.dart';
import '../widgets/glass_bottom_nav.dart';
import '../widgets/glass_scaffold.dart';
import 'analytics/analytics_screen.dart';
import 'fall_alert/fall_alert_screen.dart';
import 'health_report/health_report_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'reminder/reminder_screen.dart';

/// The signed-in home: five tabs behind a floating glass bar. It also watches
/// for a fall event and throws up the full-screen alert wherever the user is.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _fallShown = false;

  static const _items = [
    GlassNavItem(icon: Icons.space_dashboard_rounded, label: 'Home'),
    GlassNavItem(icon: Icons.medication_rounded, label: 'Reminders'),
    GlassNavItem(icon: Icons.insights_rounded, label: 'Analytics'),
    GlassNavItem(icon: Icons.description_rounded, label: 'Reports'),
    GlassNavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().load();
      context.read<ReminderProvider>().load();
      context.read<NotificationProvider>().load();
      context.read<ReportProvider>().load();
      context.read<WeeklyTrendProvider>().load();
    });
  }

  void _openProfile() => setState(() => _index = 4);

  void _maybeShowFall() {
    final health = context.read<HealthProvider>();
    if (!health.fallActive || _fallShown) return;
    _fallShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FallAlertScreen(), fullscreenDialog: true),
      );
      _fallShown = false;
      if (mounted) context.read<HealthProvider>().acknowledgeFall();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<HealthProvider>().fallActive;
    _maybeShowFall();

    final tabs = [
      HomeScreen(onOpenProfile: _openProfile),
      ReminderScreen(onOpenProfile: _openProfile),
      AnalyticsScreen(onOpenProfile: _openProfile),
      HealthReportScreen(onOpenProfile: _openProfile),
      const ProfileScreen(),
    ];

    return GlassScaffold(
      bottomNavigationBar: GlassBottomNav(
        index: _index,
        items: _items,
        onTap: (i) => setState(() => _index = i),
      ),
      body: IndexedStack(index: _index, children: tabs),
    );
  }
}
