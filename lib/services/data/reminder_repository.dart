import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/medication_reminder.dart';
import '../supabase_service.dart';

/// CRUD for medication reminders.
abstract class ReminderRepository {
  Future<List<MedicationReminder>> list();
  Future<void> add(MedicationReminder reminder);
  Future<void> update(MedicationReminder reminder);
  Future<void> remove(String id);
}

/// Reminders persisted locally via SharedPreferences, seeded with examples.
class MockReminderRepository implements ReminderRepository {
  static const _key = 'll_reminders';

  Future<List<MedicationReminder>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      final seeded = _seed();
      await _write(seeded);
      return seeded;
    }
    final list = (jsonDecode(raw) as List)
        .map((e) => MedicationReminder.fromMap(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<void> _write(List<MedicationReminder> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toMap()).toList()));
  }

  @override
  Future<List<MedicationReminder>> list() async {
    final items = await _read();
    items.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return items;
  }

  @override
  Future<void> add(MedicationReminder reminder) async {
    final items = await _read()..add(reminder);
    await _write(items);
  }

  @override
  Future<void> update(MedicationReminder reminder) async {
    final items = await _read();
    final i = items.indexWhere((e) => e.id == reminder.id);
    if (i >= 0) items[i] = reminder;
    await _write(items);
  }

  @override
  Future<void> remove(String id) async {
    final items = await _read()..removeWhere((e) => e.id == id);
    await _write(items);
  }

  List<MedicationReminder> _seed() {
    final now = DateTime.now();
    return [
      MedicationReminder(
        id: 'seed-1',
        medicationName: 'Vitamin D3',
        dosage: '1 capsule',
        hour: 9,
        minute: 0,
        repeat: ReminderRepeat.daily,
        createdAt: now,
      ),
      MedicationReminder(
        id: 'seed-2',
        medicationName: 'Metformin',
        dosage: '500 mg',
        hour: 21,
        minute: 30,
        repeat: ReminderRepeat.daily,
        createdAt: now,
      ),
    ];
  }
}

/// Reminders stored in the Supabase `medication_reminders` table.
class SupabaseReminderRepository implements ReminderRepository {
  final _client = SupabaseService.instance.app;
  String? get _email => _client.auth.currentUser?.email;

  @override
  Future<List<MedicationReminder>> list() async {
    final rows = await _client
        .from('medication_reminders')
        .select()
        .eq('user_email', _email ?? '')
        .order('hour');
    return (rows as List)
        .map((e) => MedicationReminder.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> add(MedicationReminder reminder) async {
    await _client.from('medication_reminders').insert({
      ...reminder.toMap(),
      'user_email': _email,
    });
  }

  @override
  Future<void> update(MedicationReminder reminder) async {
    await _client
        .from('medication_reminders')
        .update(reminder.toMap())
        .eq('id', reminder.id);
  }

  @override
  Future<void> remove(String id) async {
    await _client.from('medication_reminders').delete().eq('id', id);
  }
}
