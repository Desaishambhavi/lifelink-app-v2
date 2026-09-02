/// How often a medication reminder repeats.
enum ReminderRepeat { once, daily, weekly }

extension ReminderRepeatLabel on ReminderRepeat {
  String get label => switch (this) {
        ReminderRepeat.once => 'Once',
        ReminderRepeat.daily => 'Daily',
        ReminderRepeat.weekly => 'Weekly',
      };
}

/// A scheduled medication reminder. In the original app these are backed by
/// local push notifications; here the schedule is modelled the same way so the
/// notification layer can be swapped in without touching the UI.
class MedicationReminder {
  final String id;
  final String medicationName;
  final String dosage;
  final int hour; // 0–23
  final int minute; // 0–59
  final ReminderRepeat repeat;
  final int weekday; // 1 (Mon) – 7 (Sun); used when repeat == weekly
  final bool enabled;
  final DateTime createdAt;

  const MedicationReminder({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.hour,
    required this.minute,
    required this.repeat,
    this.weekday = DateTime.monday,
    this.enabled = true,
    required this.createdAt,
  });

  /// The next time this reminder should fire, from [from].
  DateTime nextOccurrence([DateTime? from]) {
    final now = from ?? DateTime.now();
    var candidate = DateTime(now.year, now.month, now.day, hour, minute);

    switch (repeat) {
      case ReminderRepeat.once:
      case ReminderRepeat.daily:
        if (!candidate.isAfter(now)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;
      case ReminderRepeat.weekly:
        var daysUntil = (weekday - candidate.weekday) % 7;
        if (daysUntil < 0) daysUntil += 7;
        candidate = candidate.add(Duration(days: daysUntil));
        if (!candidate.isAfter(now)) {
          candidate = candidate.add(const Duration(days: 7));
        }
        return candidate;
    }
  }

  MedicationReminder copyWith({
    String? medicationName,
    String? dosage,
    int? hour,
    int? minute,
    ReminderRepeat? repeat,
    int? weekday,
    bool? enabled,
  }) {
    return MedicationReminder(
      id: id,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeat: repeat ?? this.repeat,
      weekday: weekday ?? this.weekday,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
    );
  }

  factory MedicationReminder.fromMap(Map<String, dynamic> map) =>
      MedicationReminder(
        id: map['id'] as String,
        medicationName: map['medication_name'] as String? ?? '',
        dosage: map['dosage'] as String? ?? '',
        hour: (map['hour'] as num?)?.toInt() ?? 8,
        minute: (map['minute'] as num?)?.toInt() ?? 0,
        repeat: ReminderRepeat.values[(map['repeat'] as num?)?.toInt() ?? 1],
        weekday: (map['weekday'] as num?)?.toInt() ?? DateTime.monday,
        enabled: map['enabled'] as bool? ?? true,
        createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'medication_name': medicationName,
        'dosage': dosage,
        'hour': hour,
        'minute': minute,
        'repeat': repeat.index,
        'weekday': weekday,
        'enabled': enabled,
        'created_at': createdAt.toIso8601String(),
      };
}
