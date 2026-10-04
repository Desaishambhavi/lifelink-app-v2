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
///
/// The production `users` table has no `emergency_contact_name` column and we
/// make no schema changes, so that single field is cached on-device while every
/// other field round-trips through the database.
class SupabaseProfileRepository implements ProfileRepository {
  final _client = SupabaseService.instance.app;

  // Local overlay for the one column the DB doesn't have.
  static const _contactNameKey = 'll_emergency_contact_name';

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

    var profile = UserProfile.fromMap(email, row);
    final prefs = await SharedPreferences.getInstance();
    final cachedName = prefs.getString(_contactNameKey);
    if (cachedName != null && cachedName.isNotEmpty) {
      profile = profile.copyWith(emergencyContactName: cachedName);
    }
    return profile;
  }

  @override
  Future<void> save(UserProfile profile) async {
    // Cache the field the DB can't store.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_contactNameKey, profile.emergencyContactName);

    // Write only columns that exist in the production table.
    final data = profile.toMap()..remove('emergency_contact_name');

    // Update the existing row; insert only if this user has no profile row yet.
    // Avoids upsert, which would need a UNIQUE(email) constraint we don't touch.
    final existing = await _client
        .from('users')
        .select('email')
        .eq('email', profile.email)
        .maybeSingle();
    if (existing == null) {
      await _client.from('users').insert(data);
    } else {
      await _client.from('users').update(data).eq('email', profile.email);
    }
  }
}
