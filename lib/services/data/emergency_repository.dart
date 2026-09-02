import '../../models/emergency_alert.dart';
import '../supabase_service.dart';

/// Records emergency SOS events.
abstract class EmergencyRepository {
  Future<void> raise(EmergencyAlert alert);
  Future<List<EmergencyAlert>> recent();
}

/// Session-scoped SOS log for mock mode.
class MockEmergencyRepository implements EmergencyRepository {
  final List<EmergencyAlert> _alerts = [];

  @override
  Future<void> raise(EmergencyAlert alert) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _alerts.insert(0, alert);
  }

  @override
  Future<List<EmergencyAlert>> recent() async =>
      List.unmodifiable(_alerts);
}

/// SOS events written to the Supabase `emergency_alerts` table.
class SupabaseEmergencyRepository implements EmergencyRepository {
  final _client = SupabaseService.instance.app;
  String? get _email => _client.auth.currentUser?.email;

  @override
  Future<void> raise(EmergencyAlert alert) async {
    await _client.from('emergency_alerts').insert({
      'user_email': _email,
      'message': alert.message,
      'acknowledged': false,
      'event_timestamp': alert.timestamp.toIso8601String(),
    });
  }

  @override
  Future<List<EmergencyAlert>> recent() async {
    final rows = await _client
        .from('emergency_alerts')
        .select()
        .order('created_at', ascending: false)
        .limit(20);
    return (rows as List).map((e) {
      final m = e as Map<String, dynamic>;
      return EmergencyAlert(
        id: '${m['id']}',
        timestamp: DateTime.tryParse('${m['event_timestamp'] ?? m['created_at']}') ??
            DateTime.now(),
        userName: '',
        contactName: '',
        contactPhone: '',
        location: null,
        message: m['message'] as String? ?? '',
        resolved: m['acknowledged'] as bool? ?? false,
      );
    }).toList();
  }
}
