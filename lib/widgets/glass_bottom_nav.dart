import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'pressable.dart';

class GlassNavItem {
  const GlassNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// A floating, frosted tab bar in the iOS mould: the selected tab swells into a
/// labelled pill while the others stay as quiet icons.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.index,
    required this.items,
    required this.onTap,
  });

  final int index;
  final List<GlassNavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: AppColors.white(0.08),
              border: Border.all(color: AppColors.glassStroke, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: -8,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(child: _tab(context, i)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int i) {
    final selected = i == index;
    final item = items[i];
    return Pressable(
      onTap: () => onTap(i),
      pressedScale: 0.92,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.white(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.glassStroke : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 21,
              color: selected ? AppColors.frost : AppColors.textTertiary,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: AppColors.frost,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
