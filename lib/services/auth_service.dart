import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_service.dart';

/// Authentication surface. Returns `null` on success or a human-readable
/// message on failure, so the UI never has to catch provider-specific errors.
abstract class AuthService {
  Future<String?> signIn(String email, String password);
  Future<String?> signUp(String name, String email, String password);
  Future<void> signOut();
  String? get currentEmail;
  String? get currentName;
  bool get isSignedIn;
}

/// Passwordless-friendly mock: any well-formed credentials succeed, and the
/// session survives restarts via SharedPreferences.
class MockAuthService implements AuthService {
  static const _emailKey = 'll_auth_email';
  static const _nameKey = 'll_auth_name';

  String? _email;
  String? _name;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString(_emailKey);
    _name = prefs.getString(_nameKey);
  }

  @override
  Future<String?> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!email.contains('@')) return 'Please enter a valid email address.';
    if (password.length < 4) return 'Password must be at least 4 characters.';
    await _persist(email, _name ?? email.split('@').first);
    return null;
  }

  @override
  Future<String?> signUp(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (name.trim().isEmpty) return 'Please enter your name.';
    if (!email.contains('@')) return 'Please enter a valid email address.';
    if (password.length < 4) return 'Password must be at least 4 characters.';
    await _persist(email, name.trim());
    return null;
  }

  Future<void> _persist(String email, String name) async {
    _email = email;
    _name = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    await prefs.setString(_nameKey, name);
  }

  @override
  Future<void> signOut() async {
    _email = null;
    _name = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
  }

  @override
  String? get currentEmail => _email;

  @override
  String? get currentName => _name;

  @override
  bool get isSignedIn => _email != null;
}

/// Real auth backed by Supabase.
class SupabaseAuthService implements AuthService {
  final _client = SupabaseService.instance.app;

  @override
  Future<String?> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return null;
    } catch (e) {
      return _pretty(e);
    }
  }

  @override
  Future<String?> signUp(String name, String email, String password) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      return null;
    } catch (e) {
      return _pretty(e);
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  String? get currentEmail => _client.auth.currentUser?.email;

  @override
  String? get currentName =>
      _client.auth.currentUser?.userMetadata?['full_name'] as String?;

  @override
  bool get isSignedIn => _client.auth.currentUser != null;

  String _pretty(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid login')) return 'Incorrect email or password.';
    return 'Authentication failed. Please try again.';
  }
}
