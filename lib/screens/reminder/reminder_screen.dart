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
      builder: (_) => const _ReminderSheet(),
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
            child: Icon(Icons.medication_liquid_rounded, color: AppColors.abyss),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEXT DUE',
                    style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(reminder.medicationName,
                    style: Theme.of(context).textTheme.titleLarge),
                Text('${reminder.dosage} · ${reminder.repeatLabel}',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Text(time,
              style: TextStyle(
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
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ReminderSheet(existing: reminder),
      ),
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
              child: Icon(Icons.medication_rounded, color: AppColors.mist, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.medicationName,
                    style: TextStyle(
                        color: AppColors.frost, fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text('$time · ${reminder.dosage} · ${reminder.repeatLabel}',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12.5)),
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
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.textTertiary, size: 20),
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
          Icon(Icons.medication_outlined, color: AppColors.textTertiary, size: 36),
          const SizedBox(height: 12),
          Text('No reminders yet',
              style: TextStyle(color: AppColors.frost, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Add your first medication reminder to stay on track.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({this.existing});

  /// When non-null the sheet edits this reminder instead of creating a new one.
  final MedicationReminder? existing;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  late TimeOfDay _time;
  late Set<int> _days;

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.medicationName;
      _dosage.text = e.dosage;
      _time = TimeOfDay(hour: e.hour, minute: e.minute);
      _days = {...e.days};
    } else {
      _time = const TimeOfDay(hour: 9, minute: 0);
      _days = {1, 2, 3, 4, 5, 6, 7}; // default: every day
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    super.dispose();
  }

  void _setPreset(Set<int> days) => setState(() => _days = {...days});

  void _toggleDay(int weekday) => setState(() {
        if (!_days.remove(weekday)) _days.add(weekday);
      });

  bool _presetActive(Set<int> preset) =>
      _days.length == preset.length && _days.containsAll(preset);

  String get _repeatSummary {
    if (_days.isEmpty) return 'Reminds once, at the next ${_time.format(context)}.';
    if (_days.length == 7) return 'Repeats every day.';
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = _days.toList()..sort();
    return 'Repeats on ${sorted.map((d) => names[d]).join(', ')}.';
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    final provider = context.read<ReminderProvider>();
    final navigator = Navigator.of(context);
    final name = _name.text.trim();
    final dosage = _dosage.text.trim().isEmpty ? '1 dose' : _dosage.text.trim();
    final e = widget.existing;
    if (e != null) {
      await provider.update(e.copyWith(
        medicationName: name,
        dosage: dosage,
        hour: _time.hour,
        minute: _time.minute,
        days: {..._days},
      ));
    } else {
      await provider.add(MedicationReminder(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        medicationName: name,
        dosage: dosage,
        hour: _time.hour,
        minute: _time.minute,
        days: {..._days},
        createdAt: DateTime.now(),
      ));
    }
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          decoration: BoxDecoration(
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
                Text(_isEdit ? 'Edit reminder' : 'New reminder',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 18),
                _field(_name, 'Medication name', Icons.medication_rounded),
                const SizedBox(height: 14),
                _field(_dosage, 'Dosage (e.g. 500 mg)', Icons.science_outlined),
                const SizedBox(height: 18),
                _pickerTile(
                  icon: Icons.schedule_rounded,
                  label: 'Time',
                  value: _time.format(context),
                  onTap: () async {
                    final picked =
                        await showTimePicker(context: context, initialTime: _time);
                    if (picked != null) setState(() => _time = picked);
                  },
                ),
                const SizedBox(height: 18),
                Text('REPEAT',
                    style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _chip('Once', _days.isEmpty, () => _setPreset(const {})),
                    _chip(
                        'Every day',
                        _presetActive(const {1, 2, 3, 4, 5, 6, 7}),
                        () => _setPreset(const {1, 2, 3, 4, 5, 6, 7})),
                    _chip('Weekdays', _presetActive(const {1, 2, 3, 4, 5}),
                        () => _setPreset(const {1, 2, 3, 4, 5})),
                    _chip('Weekends', _presetActive(const {6, 7}),
                        () => _setPreset(const {6, 7})),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < _dayLetters.length; i++)
                      _dayToggle(_dayLetters[i], i + 1),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_repeatSummary,
                    style:
                        TextStyle(color: AppColors.textTertiary, fontSize: 12.5)),
                const SizedBox(height: 24),
                GlassButton(
                    label: _isEdit ? 'Save changes' : 'Save reminder',
                    icon: Icons.check_rounded,
                    onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dayToggle(String letter, int weekday) {
    final selected = _days.contains(weekday);
    return GestureDetector(
      onTap: () => _toggleDay(weekday),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.frost : AppColors.white(0.06),
          border: Border.all(
              color: selected ? AppColors.frost : AppColors.glassStroke),
        ),
        child: Text(
          letter,
          style: TextStyle(
            color: selected ? AppColors.abyss : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon) {
    return TextField(
      controller: c,
      style: TextStyle(color: AppColors.frost, fontWeight: FontWeight.w600),
      cursorColor: AppColors.frost,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, color: AppColors.mist, size: 20),
        filled: true,
        fillColor: AppColors.white(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.glassStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.glassStroke),
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
            Text(label, style: TextStyle(color: AppColors.textSecondary)),
            const Spacer(),
            Text(value,
                style: TextStyle(color: AppColors.frost, fontWeight: FontWeight.w700)),
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
