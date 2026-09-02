import 'dart:typed_data';

import '../../models/health_data.dart';
import '../../models/health_report.dart';
import '../../models/user_profile.dart';

/// AI capabilities used across the app. Backed by a mock by default and by
/// Gemini (via a Supabase Edge Function proxy) once enabled.
abstract class AiService {
  /// A plain-language interpretation of the current vitals.
  Future<String> analyzeVitals(HealthData latest, {UserProfile? profile});

  /// A structured summary of an uploaded medical report, in [language].
  Future<String> summarizeReport({
    required String fileName,
    required Uint8List? bytes,
    required ReportLanguage language,
  });
}
