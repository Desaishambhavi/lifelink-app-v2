import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_notification.dart';
import '../supabase_service.dart';

/// Reads/writes the in-app notification centre.
abstract class NotificationRepository {
  Future<List<AppNotification>> list();
  Future<void> add(AppNotification notification);
  Future<void> markAllRead();
  Future<void> clear();
}

/// Notifications persisted locally, seeded with a realistic history.
class MockNotificationRepository implements NotificationRepository {
  static const _key = 'll_notifications';

  Future<List<AppNotification>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      final seeded = _seed();
      await _write(seeded);
      return seeded;
    }
    return (jsonDecode(raw) as List)
        .map((e) => AppNotification.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _write(List<AppNotification> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toMap()).toList()));
  }

  @override
  Future<List<AppNotification>> list() async {
    final items = await _read();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  @override
  Future<void> add(AppNotification notification) async {
    final items = await _read()..insert(0, notification);
    await _write(items);
  }

  @override
  Future<void> markAllRead() async {
    final items = await _read();
    await _write(items.map((e) => e.copyWith(read: true)).toList());
  }

  @override
  Future<void> clear() async {
    await _write(const []);
  }

  List<AppNotification> _seed() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        title: 'Vitals stable',
        body: 'Your heart rate and SpO2 have stayed within healthy ranges this hour.',
        kind: NotificationKind.vitals,
        timestamp: now.subtract(const Duration(minutes: 12)),
      ),
      AppNotification(
        id: 'n2',
        title: 'Medication reminder',
        body: 'Vitamin D3 — 1 capsule is scheduled for 9:00 AM.',
        kind: NotificationKind.reminder,
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'n3',
        title: 'Weekly summary ready',
        body: 'Your resting heart rate improved 3% versus last week.',
        kind: NotificationKind.system,
        timestamp: now.subtract(const Duration(hours: 20)),
        read: true,
      ),
    ];
  }
}

/// Notifications stored in the Supabase `notifications` table.
class SupabaseNotificationRepository implements NotificationRepository {
  final _client = SupabaseService.instance.app;
  String? get _email => _client.auth.currentUser?.email;

  @override
  Future<List<AppNotification>> list() async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_email', _email ?? '')
        .order('created_at', ascending: false);
    return (rows as List).map((e) {
      final m = e as Map<String, dynamic>;
      return AppNotification(
        id: '${m['id']}',
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        kind: NotificationKind.values[(m['kind'] as num?)?.toInt() ?? 5],
        timestamp: DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
        read: m['read'] as bool? ?? false,
      );
    }).toList();
  }

  @override
  Future<void> add(AppNotification n) async {
    await _client.from('notifications').insert({
      'user_email': _email,
      'title': n.title,
      'body': n.body,
      'kind': n.kind.index,
      'read': n.read,
    });
  }

  @override
  Future<void> markAllRead() async {
    await _client
        .from('notifications')
        .update({'read': true}).eq('user_email', _email ?? '');
  }

  @override
  Future<void> clear() async {
    await _client.from('notifications').delete().eq('user_email', _email ?? '');
  }
}
