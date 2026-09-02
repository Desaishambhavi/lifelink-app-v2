import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/entrance.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_controls.dart';
import '../../widgets/glass_scaffold.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final items = provider.items;

    return GlassScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                GlassIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Notifications',
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                if (items.isNotEmpty)
                  GlassIconButton(
                    icon: Icons.done_all_rounded,
                    onTap: () => context.read<NotificationProvider>().markAllRead(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const _Empty()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Entrance(
                          delay: Duration(milliseconds: 50 * i),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _NotificationTile(item: items[i]),
                          ),
                        ),
                      const SizedBox(height: 8),
                      GlassButton(
                        label: 'Clear all',
                        icon: Icons.delete_sweep_outlined,
                        kind: GlassButtonKind.ghost,
                        onPressed: () => context.read<NotificationProvider>().clear(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});
  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _meta(item.kind);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      highlight: !item.read,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.title,
                          style: const TextStyle(
                              color: AppColors.frost, fontWeight: FontWeight.w700, fontSize: 14.5)),
                    ),
                    if (!item.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.mist, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.body,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12.5, height: 1.4)),
                const SizedBox(height: 8),
                Text(_ago(item.timestamp),
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _meta(NotificationKind kind) => switch (kind) {
        NotificationKind.vitals => (Icons.favorite_rounded, AppColors.good),
        NotificationKind.reminder => (Icons.medication_rounded, AppColors.mist),
        NotificationKind.fall => (Icons.warning_amber_rounded, AppColors.danger),
        NotificationKind.sos => (Icons.sos_rounded, AppColors.danger),
        NotificationKind.report => (Icons.description_rounded, AppColors.steel),
        NotificationKind.system => (Icons.info_outline_rounded, AppColors.mist),
      };

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined, color: AppColors.textTertiary, size: 40),
          SizedBox(height: 12),
          Text('No notifications',
              style: TextStyle(color: AppColors.frost, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text("You're all caught up.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
