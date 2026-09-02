import 'package:flutter/foundation.dart';

import '../services/service_locator.dart';

/// Drives the auth screens and gates the app shell.
class AuthProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  bool _signedIn = Services.auth.isSignedIn;

  bool get loading => _loading;
  String? get error => _error;
  bool get isSignedIn => _signedIn;
  String get name => Services.auth.currentName ?? 'LifeLink User';
  String get email => Services.auth.currentEmail ?? '';

  Future<bool> signIn(String email, String password) async {
    _begin();
    final err = await Services.auth.signIn(email.trim(), password);
    _signedIn = err == null && Services.auth.isSignedIn;
    _end(err);
    return err == null;
  }

  Future<bool> signUp(String name, String email, String password) async {
    _begin();
    final err = await Services.auth.signUp(name.trim(), email.trim(), password);
    _signedIn = err == null && Services.auth.isSignedIn;
    // Signup succeeded but no session => the project requires email
    // confirmation. Don't navigate into a session-less state.
    if (err == null && !_signedIn) {
      _end('Account created. Please confirm your email, then sign in.');
      return false;
    }
    _end(err);
    return _signedIn;
  }

  Future<void> signOut() async {
    await Services.auth.signOut();
    _signedIn = false;
    notifyListeners();
  }

  void _begin() {
    _loading = true;
    _error = null;
    notifyListeners();
  }

  void _end(String? error) {
    _loading = false;
    _error = error;
    notifyListeners();
  }
}
