import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_gradients.dart';
import '../../models/medication_reminder.dart';
import '../../providers/reminder_provider.dart';
import '../../widgets/entrance.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_controls.dart';
import '../../widgets/top_bar.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key, this.onOpenProfile});
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();
    final next = provider.next;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        TopBar(title: 'Reminders', eyebrow: 'Medications', onProfile: onOpenProfile),
        const SizedBox(height: 22),
        if (next != null)
          Entrance(child: _NextDueCard(reminder: next)),
        if (next != null) const SizedBox(height: 20),
        SectionHeader(
          title: 'Schedule',
          action: 'Add',
          onAction: () => _openSheet(context),
        ),
        const SizedBox(height: 12),
        if (provider.items.isEmpty)
          const _EmptyState()
        else
          for (var i = 0; i < provider.items.length; i++)
            Entrance(
              delay: Duration(milliseconds: 60 * i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReminderTile(reminder: provider.items[i]),
              ),
            ),
        const SizedBox(height: 8),
        GlassButton(
          label: 'Add reminder',
          icon: Icons.add_rounded,
          kind: GlassButtonKind.ghost,
          onPressed: () => _openSheet(context),
        ),
      ],
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddReminderSheet(),
    );
  }
}

class _NextDueCard extends StatelessWidget {
  const _NextDueCard({required this.reminder});
  final MedicationReminder reminder;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay(hour: reminder.hour, minute: reminder.minute).format(context);
    return GlassCard(
      highlight: true,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppGradients.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.medication_liquid_rounded, color: AppColors.abyss),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NEXT DUE',
                    style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(reminder.medicationName,
                    style: Theme.of(context).textTheme.titleLarge),
                Text('${reminder.dosage} · ${reminder.repeat.label}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Text(time,
              style: const TextStyle(
                  color: AppColors.frost, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder});
  final MedicationReminder reminder;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ReminderProvider>();
    final time = TimeOfDay(hour: reminder.hour, minute: reminder.minute).format(context);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Opacity(
            opacity: reminder.enabled ? 1 : 0.45,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.white(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassStroke),
              ),
              child: const Icon(Icons.medication_rounded, color: AppColors.mist, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.medicationName,
                    style: const TextStyle(
                        color: AppColors.frost, fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text('$time · ${reminder.dosage} · ${reminder.repeat.label}',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5)),
              ],
            ),
          ),
          Switch.adaptive(
            value: reminder.enabled,
            activeThumbColor: AppColors.abyss,
            activeTrackColor: AppColors.frost,
            inactiveThumbColor: AppColors.mist,
            inactiveTrackColor: AppColors.white(0.08),
            onChanged: (_) => provider.toggle(reminder),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textTertiary, size: 20),
            onPressed: () => provider.remove(reminder.id),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.medication_outlined, color: AppColors.textTertiary, size: 36),
          const SizedBox(height: 12),
          const Text('No reminders yet',
              style: TextStyle(color: AppColors.frost, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Add your first medication reminder to stay on track.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  ReminderRepeat _repeat = ReminderRepeat.daily;
  int _weekday = DateTime.monday;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    final reminder = MedicationReminder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      medicationName: _name.text.trim(),
      dosage: _dosage.text.trim().isEmpty ? '1 dose' : _dosage.text.trim(),
      hour: _time.hour,
      minute: _time.minute,
      repeat: _repeat,
      weekday: _weekday,
      createdAt: DateTime.now(),
    );
    await context.read<ReminderProvider>().add(reminder);
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
              Text('New reminder', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 18),
              _field(_name, 'Medication name', Icons.medication_rounded),
              const SizedBox(height: 14),
              _field(_dosage, 'Dosage (e.g. 500 mg)', Icons.science_outlined),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _pickerTile(
                      icon: Icons.schedule_rounded,
                      label: 'Time',
                      value: _time.format(context),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _time);
                        if (picked != null) setState(() => _time = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('REPEAT',
                  style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final r in ReminderRepeat.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _chip(r.label, _repeat == r, () => setState(() => _repeat = r)),
                    ),
                ],
              ),
              if (_repeat == ReminderRepeat.weekly) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _days.length; i++)
                      _chip(_days[i], _weekday == i + 1, () => setState(() => _weekday = i + 1)),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              GlassButton(label: 'Save reminder', icon: Icons.check_rounded, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon) {
    return TextField(
      controller: c,
      style: const TextStyle(color: AppColors.frost, fontWeight: FontWeight.w600),
      cursorColor: AppColors.frost,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, color: AppColors.mist, size: 20),
        filled: true,
        fillColor: AppColors.white(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.glassStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.glassStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.frost.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassStroke),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.mist, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            const Spacer(),
            Text(value,
                style: const TextStyle(color: AppColors.frost, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.frost : AppColors.white(0.06),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? AppColors.frost : AppColors.glassStroke),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.abyss : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
