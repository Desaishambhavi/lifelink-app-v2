import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_profile.dart';
import '../supabase_service.dart';

/// Reads and writes the user's health profile.
abstract class ProfileRepository {
  Future<UserProfile?> load();
  Future<void> save(UserProfile profile);
}

/// Local, single-user profile backed by SharedPreferences. Seeds a sensible
/// demo profile on first run so the app never shows an empty state.
class MockProfileRepository implements ProfileRepository {
  static const _key = 'll_profile';
  final String email;

  MockProfileRepository({this.email = 'demo@lifelink.health'});

  @override
  Future<UserProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      final seeded = _seed();
      await save(seeded);
      return seeded;
    }
    return UserProfile.fromMap(email, jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toMap()));
  }

  UserProfile _seed() => UserProfile(
        id: email,
        name: 'Aarav Sharma',
        email: email,
        age: 24,
        gender: 'Male',
        heightCm: 176,
        weightKg: 71,
        bloodGroup: 'O+',
        emergencyContactName: 'Priya Sharma',
        emergencyContactPhone: '+91 98765 43210',
      );
}

/// Profile stored in the Supabase `users` table, keyed on the signed-in email.
class SupabaseProfileRepository implements ProfileRepository {
  final _client = SupabaseService.instance.app;

  String? get _email => _client.auth.currentUser?.email;

  @override
  Future<UserProfile?> load() async {
    final email = _email;
    if (email == null) return null;
    final row = await _client
        .from('users')
        .select()
        .eq('email', email)
        .maybeSingle();
    if (row == null) return null;
    return UserProfile.fromMap(email, row);
  }

  @override
  Future<void> save(UserProfile profile) async {
    final data = profile.toMap()..['email'] = profile.email;
    await _client.from('users').upsert(data, onConflict: 'email');
  }
}
