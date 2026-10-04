/// A scheduled medication reminder.
///
/// Repeat is modelled like a phone clock alarm: a set of weekdays
/// (1 = Mon … 7 = Sun). No days selected = a one-time reminder; all seven =
/// every day; any subset = those days only. Backed by local push notifications.
class MedicationReminder {
  final String id;
  final String medicationName;
  final String dosage;
  final int hour; // 0–23
  final int minute; // 0–59
  final Set<int> days; // weekdays (1–7) to repeat on; empty = one-time
  final bool enabled;
  final DateTime createdAt;

  const MedicationReminder({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.hour,
    required this.minute,
    this.days = const {},
    this.enabled = true,
    required this.createdAt,
  });

  bool get isOnce => days.isEmpty;
  bool get isDaily => days.length == 7;

  /// Human label for the repeat cadence (clock-app style).
  String get repeatLabel {
    if (days.isEmpty) return 'Once';
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && days.containsAll(const {1, 2, 3, 4, 5})) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.containsAll(const {6, 7})) return 'Weekends';
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = days.toList()..sort();
    return sorted.map((d) => names[d]).join(', ');
  }

  /// The next time this reminder should fire, from [from].
  DateTime nextOccurrence([DateTime? from]) {
    final now = from ?? DateTime.now();
    if (days.isEmpty) {
      final base = DateTime(now.year, now.month, now.day, hour, minute);
      return base.isAfter(now) ? base : base.add(const Duration(days: 1));
    }
    DateTime? best;
    for (final d in days) {
      final occ = nextOccurrenceForWeekday(d, now);
      if (best == null || occ.isBefore(best)) best = occ;
    }
    return best!;
  }

  /// Next fire time restricted to a single [weekday] (1 = Mon … 7 = Sun).
  DateTime nextOccurrenceForWeekday(int weekday, [DateTime? from]) {
    final now = from ?? DateTime.now();
    final base = DateTime(now.year, now.month, now.day, hour, minute);
    var daysUntil = (weekday - base.weekday) % 7;
    if (daysUntil < 0) daysUntil += 7;
    var candidate = base.add(Duration(days: daysUntil));
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  MedicationReminder copyWith({
    String? medicationName,
    String? dosage,
    int? hour,
    int? minute,
    Set<int>? days,
    bool? enabled,
  }) {
    return MedicationReminder(
      id: id,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      days: days ?? this.days,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
    );
  }

  factory MedicationReminder.fromMap(Map<String, dynamic> map) {
    Set<int> days;
    final rawDays = map['days'];
    if (rawDays is List) {
      days = rawDays.map((e) => (e as num).toInt()).toSet();
    } else {
      // Legacy records stored a `repeat` enum index (0=once, 1=daily, 2=weekly)
      // plus a single `weekday`. Convert to the day-set model.
      final repeatIdx = (map['repeat'] as num?)?.toInt() ?? 1;
      final weekday = (map['weekday'] as num?)?.toInt() ?? DateTime.monday;
      days = switch (repeatIdx) {
        0 => <int>{}, // once
        2 => {weekday}, // weekly (single day)
        _ => {1, 2, 3, 4, 5, 6, 7}, // daily
      };
    }
    return MedicationReminder(
      id: map['id'] as String,
      medicationName: map['medication_name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      hour: (map['hour'] as num?)?.toInt() ?? 8,
      minute: (map['minute'] as num?)?.toInt() ?? 0,
      days: days,
      enabled: map['enabled'] as bool? ?? true,
      createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'medication_name': medicationName,
        'dosage': dosage,
        'hour': hour,
        'minute': minute,
        'days': days.toList()..sort(),
        'enabled': enabled,
        'created_at': createdAt.toIso8601String(),
      };
}
