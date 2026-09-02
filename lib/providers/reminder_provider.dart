import 'package:flutter/foundation.dart';

import '../models/medication_reminder.dart';
import '../services/service_locator.dart';

/// Manages the medication reminder list.
class ReminderProvider extends ChangeNotifier {
  List<MedicationReminder> _items = [];
  bool _loading = true;

  List<MedicationReminder> get items => _items;
  bool get loading => _loading;

  MedicationReminder? get next {
    final enabled = _items.where((r) => r.enabled).toList();
    if (enabled.isEmpty) return null;
    enabled.sort((a, b) => a.nextOccurrence().compareTo(b.nextOccurrence()));
    return enabled.first;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await Services.reminders.list();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(MedicationReminder reminder) async {
    await Services.reminders.add(reminder);
    await load();
  }

  Future<void> update(MedicationReminder reminder) async {
    await Services.reminders.update(reminder);
    await load();
  }

  Future<void> toggle(MedicationReminder reminder) async {
    await Services.reminders.update(reminder.copyWith(enabled: !reminder.enabled));
    await load();
  }

  Future<void> remove(String id) async {
    await Services.reminders.remove(id);
    await load();
  }
}
