import 'dart:convert';
import 'dart:typed_data';

import '../../models/health_data.dart';
import '../../models/health_report.dart';
import '../../models/user_profile.dart';
import '../supabase_service.dart';
import 'ai_service.dart';

/// Real AI via Gemini, called through the project's `gemini-proxy` Supabase Edge
/// Function so the API key never ships in the client.
///
/// The deployed proxy is a thin passthrough: it accepts a Gemini-native
/// `contents` array, injects the key server-side, calls `generateContent`, and
/// returns Gemini's raw response. This client therefore sends `contents` and
/// parses `candidates[].content.parts[].text`. It degrades to a readable string
/// on any error rather than throwing, so the UI never breaks.
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
      // Build a Gemini-native `contents` payload: text prompt plus an optional
      // inline document/image part.
      final parts = <Map<String, dynamic>>[
        {'text': prompt},
        if (fileBytes != null)
          {
            'inline_data': {
              'mime_type': _mimeFor(fileName),
              'data': base64Encode(fileBytes),
            },
          },
      ];

      final res = await SupabaseService.instance.app.functions.invoke(
        'gemini-proxy',
        body: {
          'contents': [
            {'parts': parts},
          ],
        },
      );

      return _extractText(res.data);
    } catch (e) {
      return 'AI is temporarily unavailable ($e). Please try again shortly.';
    }
  }

  /// Pulls the model text out of Gemini's raw `generateContent` response, or a
  /// friendly message if the proxy returned an error / unexpected shape.
  String _extractText(dynamic data) {
    final map = data is String
        ? (jsonDecode(data) as Map<String, dynamic>?)
        : (data is Map ? data.cast<String, dynamic>() : null);
    if (map == null) return data.toString();

    if (map['error'] != null) {
      final err = map['error'];
      final msg = err is Map ? err['message'] : err.toString();
      return 'AI is temporarily unavailable ($msg). Please try again shortly.';
    }

    final candidates = map['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final parts = candidates.first['content']?['parts'];
      if (parts is List) {
        final text = parts
            .map((p) => (p is Map ? p['text'] : null)?.toString() ?? '')
            .join()
            .trim();
        if (text.isNotEmpty) return text;
      }
    }
    return 'No response was generated. Please try again.';
  }

  String _mimeFor(String? fileName) {
    final name = fileName?.toLowerCase() ?? '';
    if (name.endsWith('.pdf')) return 'application/pdf';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.txt')) return 'text/plain';
    return 'application/pdf';
  }
}
