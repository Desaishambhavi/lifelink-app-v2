import '../core/app_config.dart';
import 'ai/ai_service.dart';
import 'ai/gemini_ai_service.dart';
import 'ai/mock_ai_service.dart';
import 'auth_service.dart';
import 'data/emergency_repository.dart';
import 'data/notification_repository.dart';
import 'data/profile_repository.dart';
import 'data/reminder_repository.dart';
import 'data/report_repository.dart';
import 'sensor/mock_sensor_source.dart';
import 'sensor/sensor_source.dart';
import 'sensor/supabase_sensor_source.dart';
import 'supabase_service.dart';
import 'tts_service.dart';

/// The single place where the app decides mock-vs-real for every dependency.
/// Flip the flags in [AppConfig] and everything downstream follows.
class Services {
  Services._();

  static late final AuthService auth;
  static late final SensorSource sensor;
  static late final AiService ai;
  static late final ProfileRepository profiles;
  static late final ReminderRepository reminders;
  static late final NotificationRepository notifications;
  static late final ReportRepository reports;
  static late final EmergencyRepository emergencies;
  static final TtsService tts = TtsService();

  static Future<void> init() async {
    // Bring up Supabase first if any real backend is enabled.
    if (AppConfig.supabaseEnabled) {
      await SupabaseService.instance.initApp();
    }

    if (AppConfig.useSupabaseAppData) {
      auth = SupabaseAuthService();
      profiles = SupabaseProfileRepository();
      reminders = SupabaseReminderRepository();
      notifications = SupabaseNotificationRepository();
      reports = SupabaseReportRepository();
      emergencies = SupabaseEmergencyRepository();
    } else {
      final mockAuth = MockAuthService();
      await mockAuth.restore();
      auth = mockAuth;
      profiles = MockProfileRepository();
      reminders = MockReminderRepository();
      notifications = MockNotificationRepository();
      reports = MockReportRepository();
      emergencies = MockEmergencyRepository();
    }

    sensor = AppConfig.useSupabaseSensorData
        ? SupabaseSensorSource()
        : MockSensorSource();
    ai = AppConfig.useGeminiAi ? GeminiAiService() : MockAiService();

    await sensor.start();
  }
}
