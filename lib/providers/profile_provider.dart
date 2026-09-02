import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/service_locator.dart';

/// Loads and edits the user's health profile.
class ProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  bool _loading = true;

  UserProfile? get profile => _profile;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _profile = await Services.profiles.load();
    _loading = false;
    notifyListeners();
  }

  Future<void> save(UserProfile updated) async {
    _profile = updated;
    notifyListeners();
    await Services.profiles.save(updated);
  }
}
