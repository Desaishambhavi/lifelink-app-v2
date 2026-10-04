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
  static const String appName = 'LifeLink v2';
  static const String appTagline = 'Smart health monitoring, always on.';

  // ---------------------------------------------------------------------------
  // DATA MODE
  // ---------------------------------------------------------------------------
  // While these are false the app uses mock services (no network, dummy data).
  // Enable each independently once its credentials are filled in below.
  static const bool useSupabaseAppData = true; // profiles, reports, alerts
  static const bool useSupabaseSensorData = true; // live vitals from sensor_logs
  static const bool useGeminiAi = true; // gemini-proxy deployed with key secret

  /// Convenience: true only when the app should attempt any Supabase init.
  static bool get supabaseEnabled =>
      useSupabaseAppData || useSupabaseSensorData;

  // ---------------------------------------------------------------------------
  // APP SUPABASE PROJECT  (auth, profiles, reminders, notifications, SOS)
  // ---------------------------------------------------------------------------
  // TODO: paste your APP Supabase project URL + anon key, then set
  //       useSupabaseAppData = true. The anon key is public and safe to ship
  //       (protect data with Row Level Security).
  static const String supabaseUrl = 'https://bfhraobrnaifvuyscoim.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmaHJhb2JybmFpZnZ1eXNjb2ltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg3Nzk3NzYsImV4cCI6MjA5NDM1NTc3Nn0.CWsxxBIacpKj85z0C_Le5i4Pfze0a1mlXdVUE007zL4';

  // ---------------------------------------------------------------------------
  // SENSOR SUPABASE PROJECT  (SEPARATE — your existing ESP32 database)
  // ---------------------------------------------------------------------------
  // Kept deliberately separate so this app NEVER touches your existing sensor
  // data. Point it at your real project, set the table/columns to match your
  // schema, then set useSupabaseSensorData = true.
  // Same project as the app data here: profiles, reports, SOS and the ESP32
  // sensor tables all live in one Supabase project. SupabaseService detects the
  // match and reuses the single authenticated client.
  static const String sensorSupabaseUrl =
      'https://bfhraobrnaifvuyscoim.supabase.co';
  static const String sensorSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmaHJhb2JybmFpZnZ1eXNjb2ltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg3Nzk3NzYsImV4cCI6MjA5NDM1NTc3Nn0.CWsxxBIacpKj85z0C_Le5i4Pfze0a1mlXdVUE007zL4';

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
      'https://bfhraobrnaifvuyscoim.functions.supabase.co/gemini-proxy';
  static const String geminiModel = 'gemini-2.5-flash';

  // ---------------------------------------------------------------------------
  // DEMO / MOCK AUTH
  // ---------------------------------------------------------------------------
  // Used by the mock auth flow so the app is fully explorable without a backend.
  static const String demoEmail = 'demo@lifelink.health';
  static const String demoPassword = 'lifelink';
}
