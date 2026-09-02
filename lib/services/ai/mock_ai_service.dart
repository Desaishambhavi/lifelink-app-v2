import 'dart:typed_data';

import '../../models/health_data.dart';
import '../../models/health_report.dart';
import '../../models/user_profile.dart';
import 'ai_service.dart';

/// Offline stand-in for Gemini. Produces professional, context-aware text from
/// the actual vitals/inputs so the UI is fully exercised without a key. Swap in
/// [GeminiAiService] to get real model output.
class MockAiService implements AiService {
  @override
  Future<String> analyzeVitals(HealthData latest, {UserProfile? profile}) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final hr = latest.heartRate;
    final spo2 = latest.spo2;
    final who = profile?.name.split(' ').first ?? 'there';

    final hrLine = switch (latest.heartRateStatus) {
      VitalStatus.normal =>
        'Your heart rate of $hr BPM sits comfortably within the resting range, indicating steady cardiovascular activity.',
      VitalStatus.watch =>
        'Your heart rate of $hr BPM is slightly outside the typical resting band. This is often benign — recent movement, caffeine, or stress — but worth a second reading in a few minutes.',
      VitalStatus.critical =>
        'Your heart rate of $hr BPM is notably outside the resting range. If you feel light-headed, breathless, or unwell, please sit down and consider contacting a clinician.',
    };

    final spo2Line = switch (latest.spo2Status) {
      VitalStatus.normal =>
        'Blood-oxygen saturation is ${spo2.toStringAsFixed(0)}%, which reflects healthy oxygen delivery.',
      VitalStatus.watch =>
        'Blood-oxygen saturation is ${spo2.toStringAsFixed(0)}%. Ensure the sensor is snug and take a slow, deep breath before re-measuring.',
      VitalStatus.critical =>
        'Blood-oxygen saturation is ${spo2.toStringAsFixed(0)}%, below the comfortable threshold. Re-measure at rest; if it stays low, seek medical advice.',
    };

    return 'Hello $who. $hrLine $spo2Line\n\n'
        'Overall, your readings are being monitored continuously. Keep hydrated, '
        'maintain steady breathing, and revisit the analytics tab to see how these '
        'values trend across the day.';
  }

  @override
  Future<String> summarizeReport({
    required String fileName,
    required Uint8List? bytes,
    required ReportLanguage language,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    final h = _headers[language]!;
    final size = bytes == null ? '—' : '${(bytes.length / 1024).toStringAsFixed(0)} KB';

    return '${h.overview}\n'
        'A structured review of "$fileName" ($size). The document has been parsed '
        'and the clinically relevant sections extracted below.\n\n'
        '${h.findings}\n'
        '• Vital signs recorded are within expected reference ranges.\n'
        '• No acute abnormalities were flagged in the summary panels.\n'
        '• Metabolic and haematology markers appear stable.\n\n'
        '${h.recommendations}\n'
        '• Maintain current routine and hydration.\n'
        '• Continue any prescribed medication as directed.\n'
        '• Repeat routine screening at the interval advised by your physician.\n\n'
        '${h.followUp}\n'
        'Share this summary with your doctor for clinical confirmation. This is an '
        'assistive summary, not a diagnosis.';
  }

  static const Map<ReportLanguage, _Headers> _headers = {
    ReportLanguage.english: _Headers(
      overview: 'OVERVIEW',
      findings: 'KEY FINDINGS',
      recommendations: 'RECOMMENDATIONS',
      followUp: 'FOLLOW-UP',
    ),
    ReportLanguage.hindi: _Headers(
      overview: 'सारांश',
      findings: 'मुख्य निष्कर्ष',
      recommendations: 'सिफारिशें',
      followUp: 'अनुवर्ती',
    ),
    ReportLanguage.marathi: _Headers(
      overview: 'आढावा',
      findings: 'मुख्य निष्कर्ष',
      recommendations: 'शिफारसी',
      followUp: 'पाठपुरावा',
    ),
    ReportLanguage.kannada: _Headers(
      overview: 'ಅವಲೋಕನ',
      findings: 'ಪ್ರಮುಖ ಫಲಿತಾಂಶಗಳು',
      recommendations: 'ಶಿಫಾರಸುಗಳು',
      followUp: 'ಅನುಸರಣೆ',
    ),
  };
}

class _Headers {
  final String overview;
  final String findings;
  final String recommendations;
  final String followUp;
  const _Headers({
    required this.overview,
    required this.findings,
    required this.recommendations,
    required this.followUp,
  });
}
