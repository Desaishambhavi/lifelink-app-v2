import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_config.dart';

/// Owns the Supabase client(s). The app project and the (separate) sensor
/// project can be the same or different — this hides that decision from callers.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _appReady = false;
  SupabaseClient? _sensorClient;

  /// Called from main() before runApp when app-data is enabled.
  Future<void> initApp() async {
    if (!AppConfig.useSupabaseAppData || _appReady) return;
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _appReady = true;
  }

  /// The authenticated app client (profiles, reminders, reports, …).
  SupabaseClient get app => Supabase.instance.client;

  /// The sensor client. Reuses the app client when both point at one project.
  SupabaseClient get sensor {
    final sameProject = AppConfig.sensorSupabaseUrl == AppConfig.supabaseUrl;
    if (sameProject && _appReady) return Supabase.instance.client;
    return _sensorClient ??= SupabaseClient(
      AppConfig.sensorSupabaseUrl,
      AppConfig.sensorSupabaseAnonKey,
    );
  }
}
