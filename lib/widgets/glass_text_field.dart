import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// A text field dressed to match the glass system: translucent fill, hairline
/// stroke, and a frost focus ring.
class GlassTextField extends StatelessWidget {
  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.hint,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final String? hint;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          textInputAction: textInputAction,
          style: const TextStyle(
            color: AppColors.frost,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: AppColors.frost,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            prefixIcon: icon == null
                ? null
                : Icon(icon, color: AppColors.mist, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.white(0.06),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: _border(AppColors.glassStroke),
            focusedBorder: _border(AppColors.frost.withValues(alpha: 0.6), 1.4),
            errorBorder: _border(AppColors.danger.withValues(alpha: 0.6)),
            focusedErrorBorder: _border(AppColors.danger, 1.4),
            errorStyle: const TextStyle(color: AppColors.danger, fontSize: 11.5),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: width),
      );
}
