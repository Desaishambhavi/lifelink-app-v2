import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_gradients.dart';
import '../core/app_routes.dart';
import '../providers/notification_provider.dart';
import '../providers/profile_provider.dart';
import 'glass_controls.dart';
import 'pressable.dart';

/// The persistent header on every primary tab: a title/eyebrow on the left, a
/// notification bell (with unread badge) and the user avatar on the right.
class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.title,
    this.eyebrow,
    this.onProfile,
  });

  final String title;
  final String? eyebrow;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;
    final initials = context.watch<ProfileProvider>().profile?.initials ?? 'LL';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GlassIconButton(
          icon: Icons.notifications_none_rounded,
          badge: unread,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
        ),
        const SizedBox(width: 12),
        Pressable(
          onTap: onProfile,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.accent,
              border: Border.all(color: AppColors.white(0.25), width: 1),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.abyss,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
