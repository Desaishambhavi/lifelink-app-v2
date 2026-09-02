import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_gradients.dart';
import '../models/health_data.dart';
import 'pressable.dart';

enum GlassButtonKind { primary, ghost }

/// A tactile call-to-action. `primary` is the bright frost gradient; `ghost` is
/// a translucent glass pill.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.kind = GlassButtonKind.primary,
    this.expand = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final GlassButtonKind kind;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final primary = kind == GlassButtonKind.primary;
    final enabled = onPressed != null && !loading;
    final fg = primary ? AppColors.abyss : AppColors.frost;

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 19, color: fg),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
    );

    final body = Container(
      height: 56,
      width: expand ? double.infinity : null,
      padding: expand ? null : const EdgeInsets.symmetric(horizontal: 26),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: primary ? AppGradients.frostButton : null,
        color: primary ? null : AppColors.white(0.08),
        border: primary
            ? null
            : Border.all(color: AppColors.glassStroke, width: 1),
        boxShadow: primary
            ? [
                BoxShadow(
                  color: AppColors.frost.withValues(alpha: 0.28),
                  blurRadius: 26,
                  spreadRadius: -6,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: child,
    );

    final wrapped = primary
        ? body
        : ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: body,
            ),
          );

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Pressable(onTap: enabled ? onPressed : null, child: wrapped),
    );
  }
}

/// A circular frosted icon button, optionally showing an unread badge.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.badge = 0,
    this.size = 44,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int badge;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white(0.08),
                    border: Border.all(color: AppColors.glassStroke, width: 1),
                  ),
                  child: Icon(icon, size: size * 0.44, color: color ?? AppColors.frost),
                ),
              ),
            ),
            if (badge > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 18),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.abyss, width: 1.5),
                  ),
                  child: Text(
                    badge > 9 ? '9+' : '$badge',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A compact status chip with a leading dot, colour-coded by severity.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  factory StatusPill.vital(VitalStatus status) {
    return switch (status) {
      VitalStatus.normal => const StatusPill(label: 'Normal', color: AppColors.good),
      VitalStatus.watch => const StatusPill(label: 'Watch', color: AppColors.warning),
      VitalStatus.critical =>
        const StatusPill(label: 'Critical', color: AppColors.danger),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// A section title with an optional trailing text action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        if (action != null)
          Pressable(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                color: AppColors.mist,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
