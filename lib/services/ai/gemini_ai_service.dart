import 'dart:typed_data';

import '../../core/app_config.dart';
import '../../models/health_data.dart';
import '../../models/health_report.dart';
import '../../models/user_profile.dart';
import '../supabase_service.dart';
import 'ai_service.dart';

/// Real AI via Gemini, called through a Supabase Edge Function proxy so the
/// API key never ships in the client. Falls back to a readable error string
/// rather than throwing, so the UI degrades gracefully.
class GeminiAiService implements AiService {
  @override
  Future<String> analyzeVitals(HealthData latest, {UserProfile? profile}) {
    final prompt =
        'You are a careful health assistant. In 3-4 short sentences, interpret '
        'these live vitals for a layperson and give gentle, non-alarming '
        'guidance. Heart rate: ${latest.heartRate} BPM. SpO2: '
        '${latest.spo2.toStringAsFixed(0)}%. '
        '${profile != null ? 'Person: ${profile.age}y ${profile.gender}.' : ''} '
        'Do not diagnose.';
    return _invoke(prompt);
  }

  @override
  Future<String> summarizeReport({
    required String fileName,
    required Uint8List? bytes,
    required ReportLanguage language,
  }) {
    final prompt =
        'Summarize the attached medical report "$fileName" for a patient in '
        '${language.label}. Use the sections: Overview, Key Findings, '
        'Recommendations, Follow-up. Keep it clear and non-alarming. End by '
        'noting it is an assistive summary, not a diagnosis.';
    return _invoke(prompt, fileBytes: bytes, fileName: fileName);
  }

  Future<String> _invoke(
    String prompt, {
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final res = await SupabaseService.instance.app.functions.invoke(
        'gemini-proxy',
        body: {
          'model': AppConfig.geminiModel,
          'prompt': prompt,
          if (fileBytes != null) 'fileName': fileName,
        },
      );
      final data = res.data;
      if (data is Map && data['text'] is String) return data['text'] as String;
      if (data is String) return data;
      return data.toString();
    } catch (e) {
      return 'AI is temporarily unavailable ($e). Please try again shortly.';
    }
  }
}
