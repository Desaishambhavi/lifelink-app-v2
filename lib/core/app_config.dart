/// Central configuration and feature-swap points for LifeLink.
///
/// Everything the app needs to talk to real backends lives here in ONE place.
/// Until you drop in real credentials, the app runs fully on in-memory mock
/// data — nothing below is required to launch, demo, or develop the app.
///
/// To go live:
///   1. Fill in the credentials for the section you want to enable.
///   2. Flip the matching `use...` flag to `true`.
///   3. Hot-restart. No other code changes are needed.
class AppConfig {
  AppConfig._();

  /// Human-facing app metadata.
  static const String appName = 'LifeLink';
  static const String appTagline = 'Smart health monitoring, always on.';

  // ---------------------------------------------------------------------------
  // DATA MODE
  // ---------------------------------------------------------------------------
  // While these are false the app uses mock services (no network, dummy data).
  // Enable each independently once its credentials are filled in below.
  static const bool useSupabaseAppData = false; // profiles, reminders, alerts
  static const bool useSupabaseSensorData = false; // live vitals stream
  static const bool useGeminiAi = false; // real Gemini calls

  /// Convenience: true only when the app should attempt any Supabase init.
  static bool get supabaseEnabled =>
      useSupabaseAppData || useSupabaseSensorData;

  // ---------------------------------------------------------------------------
  // APP SUPABASE PROJECT  (auth, profiles, reminders, notifications, SOS)
  // ---------------------------------------------------------------------------
  // TODO: paste your APP Supabase project URL + anon key, then set
  //       useSupabaseAppData = true. The anon key is public and safe to ship
  //       (protect data with Row Level Security).
  static const String supabaseUrl = 'https://YOUR-APP-PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_APP_ANON_KEY';

  // ---------------------------------------------------------------------------
  // SENSOR SUPABASE PROJECT  (SEPARATE — your existing ESP32 database)
  // ---------------------------------------------------------------------------
  // Kept deliberately separate so this app NEVER touches your existing sensor
  // data. Point it at your real project, set the table/columns to match your
  // schema, then set useSupabaseSensorData = true.
  static const String sensorSupabaseUrl =
      'https://YOUR-SENSOR-PROJECT.supabase.co';
  static const String sensorSupabaseAnonKey = 'YOUR_SENSOR_ANON_KEY';

  // Table the live vitals stream reads from. `sensor_logs` is the richest
  // (heart rate + SpO2 + accel + GPS); switch to `device_readings` or
  // `device_sensor_data` if that is what your firmware writes to.
  static const String sensorTable = 'sensor_logs';
  static const String fallEventsTable = 'fall_events';

  // App-data tables (see supabase/schema.sql).
  static const String usersTable = 'users';
  static const String remindersTable = 'medication_reminders';
  static const String notificationsTable = 'notifications';
  static const String reportsTable = 'reports';
  static const String emergencyAlertsTable = 'emergency_alerts';
  static const String weeklyTrendsTable = 'weekly_trends';

  // ---------------------------------------------------------------------------
  // GEMINI AI  (vitals interpretation + medical report summaries)
  // ---------------------------------------------------------------------------
  // Recommended: keep the real key server-side in a Supabase Edge Function
  // proxy and point `geminiProxyUrl` at it, so the key never ships in the app.
  static const String geminiProxyUrl =
      'https://YOUR-APP-PROJECT.functions.supabase.co/gemini-proxy';
  static const String geminiModel = 'gemini-2.5-flash';

  // ---------------------------------------------------------------------------
  // DEMO / MOCK AUTH
  // ---------------------------------------------------------------------------
  // Used by the mock auth flow so the app is fully explorable without a backend.
  static const String demoEmail = 'demo@lifelink.health';
  static const String demoPassword = 'lifelink';
}
