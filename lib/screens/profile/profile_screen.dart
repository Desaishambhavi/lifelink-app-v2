import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_gradients.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/entrance.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_controls.dart';
import '../../widgets/glass_text_field.dart';
import '../landing/landing_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    if (provider.loading || profile == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.frost));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Entrance(
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.accent,
                  border: Border.all(color: AppColors.white(0.25), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.steel.withValues(alpha: 0.4),
                      blurRadius: 26,
                      spreadRadius: -6,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Text(profile.initials,
                    style: const TextStyle(
                        color: AppColors.abyss, fontSize: 28, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 16),
              Text(profile.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(profile.email,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Entrance(
          delay: const Duration(milliseconds: 80),
          child: Row(
            children: [
              Expanded(child: _StatTile(label: 'Age', value: '${profile.age}', unit: 'yrs')),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(label: 'Blood', value: profile.bloodGroup, unit: '')),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(label: 'Gender', value: profile.gender, unit: '')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Entrance(
          delay: const Duration(milliseconds: 140),
          child: Row(
            children: [
              Expanded(
                  child: _StatTile(
                      label: 'Height', value: profile.heightCm.toStringAsFixed(0), unit: 'cm')),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatTile(
                      label: 'Weight', value: profile.weightKg.toStringAsFixed(0), unit: 'kg')),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatTile(
                      label: 'BMI',
                      value: profile.bmi.toStringAsFixed(1),
                      unit: profile.bmiLabel)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Entrance(
          delay: const Duration(milliseconds: 200),
          child: GlassCard(
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
                  ),
                  child: const Icon(Icons.contact_emergency_rounded, color: AppColors.danger),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('EMERGENCY CONTACT',
                          style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      Text(
                        profile.emergencyContactName.isEmpty
                            ? 'Not set'
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
        const SizedBox(height: 24),
        Entrance(
          delay: const Duration(milliseconds: 260),
          child: GlassButton(
            label: 'Edit profile',
            icon: Icons.edit_outlined,
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _EditProfileSheet(profile: profile),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GlassButton(
          label: 'Sign out',
          icon: Icons.logout_rounded,
          kind: GlassButtonKind.ghost,
          onPressed: () async {
            await context.read<AuthProvider>().signOut();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LandingScreen()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.unit});
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.frost, fontSize: 20, fontWeight: FontWeight.w800)),
          if (unit.isNotEmpty)
            Text(unit,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile});
  final UserProfile profile;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _name = TextEditingController(text: widget.profile.name);
  late final _age = TextEditingController(text: '${widget.profile.age}');
  late final _height = TextEditingController(text: widget.profile.heightCm.toStringAsFixed(0));
  late final _weight = TextEditingController(text: widget.profile.weightKg.toStringAsFixed(0));
  late final _blood = TextEditingController(text: widget.profile.bloodGroup);
  late final _contactName =
      TextEditingController(text: widget.profile.emergencyContactName);
  late final _contactPhone =
      TextEditingController(text: widget.profile.emergencyContactPhone);

  @override
  void dispose() {
    for (final c in [_name, _age, _height, _weight, _blood, _contactName, _contactPhone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final updated = widget.profile.copyWith(
      name: _name.text.trim(),
      age: int.tryParse(_age.text) ?? widget.profile.age,
      heightCm: double.tryParse(_height.text) ?? widget.profile.heightCm,
      weightKg: double.tryParse(_weight.text) ?? widget.profile.weightKg,
      bloodGroup: _blood.text.trim(),
      emergencyContactName: _contactName.text.trim(),
      emergencyContactPhone: _contactPhone.text.trim(),
    );
    await context.read<ProfileProvider>().save(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.deep, AppColors.abyss],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.white(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Edit profile', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 18),
                GlassTextField(controller: _name, label: 'Full name', icon: Icons.person_outline_rounded),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GlassTextField(
                          controller: _age,
                          label: 'Age',
                          icon: Icons.cake_outlined,
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassTextField(
                          controller: _blood, label: 'Blood group', icon: Icons.bloodtype_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GlassTextField(
                          controller: _height,
                          label: 'Height (cm)',
                          icon: Icons.height_rounded,
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassTextField(
                          controller: _weight,
                          label: 'Weight (kg)',
                          icon: Icons.monitor_weight_outlined,
                          keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GlassTextField(
                    controller: _contactName,
                    label: 'Emergency contact name',
                    icon: Icons.contact_emergency_outlined),
                const SizedBox(height: 14),
                GlassTextField(
                    controller: _contactPhone,
                    label: 'Emergency contact phone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 24),
                GlassButton(label: 'Save changes', icon: Icons.check_rounded, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
