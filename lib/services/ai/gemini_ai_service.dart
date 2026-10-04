import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
    // Prefer sending the report's TEXT rather than the raw PDF. A text prompt
    // costs a handful of tokens and uses Gemini's light, reliable path; the same
    // report sent as an inline document costs thousands of tokens and is what
    // triggers the "high demand" 503 under load. Fall back to the multimodal
    // path only when there's no extractable text (e.g. a scanned/image PDF).
    final extracted = bytes == null ? null : _extractPdfText(bytes);
    if (extracted != null && extracted.length >= 40) {
      final prompt =
          'Summarize the following medical report for a patient in '
          '${language.label}. Use the sections: Overview, Key Findings, '
          'Recommendations, Follow-up. Keep it clear and non-alarming. Write in '
          'plain text only — no markdown, asterisks, hashes or bold. End by '
          'noting it is an assistive summary, not a diagnosis.\n\n'
          'Report "$fileName":\n"""\n$extracted\n"""';
      return _invoke(prompt);
    }

    final prompt =
        'Summarize the attached medical report "$fileName" for a patient in '
        '${language.label}. Use the sections: Overview, Key Findings, '
        'Recommendations, Follow-up. Keep it clear and non-alarming. Write in '
        'plain text only — no markdown, asterisks, hashes or bold. End by '
        'noting it is an assistive summary, not a diagnosis.';
    return _invoke(prompt, fileBytes: bytes, fileName: fileName);
  }

  /// Extracts the text layer from a PDF, or null if it has none (scanned image
  /// pages) or can't be parsed. Capped so a very large report can't blow up the
  /// prompt.
  String? _extractPdfText(Uint8List bytes) {
    try {
      final document = PdfDocument(inputBytes: bytes);
      try {
        final text = PdfTextExtractor(document).extractText().trim();
        if (text.isEmpty) return null;
        const maxChars = 20000;
        return text.length > maxChars ? text.substring(0, maxChars) : text;
      } finally {
        document.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  /// How many times to attempt the call before giving up (1 initial + retries).
  static const int _maxAttempts = 4;

  Future<String> _invoke(
    String prompt, {
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    // Build a Gemini-native `contents` payload once: text prompt plus an
    // optional inline document/image part.
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
    final body = {
      'contents': [
        {'parts': parts},
      ],
    };

    // Gemini returns transient 503 "model overloaded" / "high demand" errors
    // under load — far more often for the heavier multimodal report requests
    // than for the tiny vitals prompt. Retry with exponential backoff before
    // degrading, since a retry typically succeeds.
    var lastMessage = 'temporarily unavailable';
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final isLast = attempt == _maxAttempts - 1;
      try {
        final res = await SupabaseService.instance.app.functions.invoke(
          'gemini-proxy',
          body: body,
        );

        // A passthrough proxy may return the error in the body with a 200 OK.
        final map = _asMap(res.data);
        final err = map?['error'];
        if (err != null) {
          lastMessage = _errorMessage(err);
          if (!isLast && _isTransient(lastMessage)) {
            await _backoff(attempt);
            continue;
          }
          return _unavailable(lastMessage);
        }

        return _extractText(res.data);
      } on FunctionException catch (e) {
        lastMessage = _functionErrorMessage(e);
        if (!isLast && (_isTransientStatus(e.status) || _isTransient(lastMessage))) {
          await _backoff(attempt);
          continue;
        }
        return _unavailable(lastMessage);
      } catch (e) {
        lastMessage = e.toString();
        if (!isLast && _isTransient(lastMessage)) {
          await _backoff(attempt);
          continue;
        }
        return _unavailable(lastMessage);
      }
    }
    return _unavailable(lastMessage);
  }

  String _unavailable(String message) =>
      'AI is temporarily unavailable ($message). Please try again shortly.';

  /// Exponential backoff with jitter: ~0.8s, 1.6s, 3.2s between attempts.
  Future<void> _backoff(int attempt) {
    final base = 800 * (1 << attempt);
    final jitter = Random().nextInt(300);
    return Future.delayed(Duration(milliseconds: base + jitter));
  }

  /// True for errors that a short retry can plausibly clear (overload / rate).
  bool _isTransient(String message) {
    final m = message.toLowerCase();
    return m.contains('503') ||
        m.contains('overloaded') ||
        m.contains('unavailable') ||
        m.contains('high demand') ||
        m.contains('500') ||
        m.contains('502') ||
        m.contains('504') ||
        m.contains('429') ||
        m.contains('rate limit') ||
        m.contains('timeout') ||
        m.contains('try again');
  }

  bool _isTransientStatus(int status) =>
      status == 429 || status == 500 || status == 502 || status == 503 || status == 504;

  /// Best-effort human message out of a thrown [FunctionException].
  String _functionErrorMessage(FunctionException e) {
    final map = _asMap(e.details);
    final err = map?['error'];
    if (err != null) return _errorMessage(err);
    if (e.details != null) return e.details.toString();
    return 'status ${e.status}';
  }

  String _errorMessage(dynamic err) =>
      (err is Map ? err['message'] : null)?.toString() ?? err.toString();

  /// Decode [data] into a JSON map when possible; null otherwise.
  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map) return data.cast<String, dynamic>();
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        return decoded is Map ? decoded.cast<String, dynamic>() : null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Pulls the model text out of Gemini's raw `generateContent` response, or a
  /// friendly message if the proxy returned an error / unexpected shape.
  String _extractText(dynamic data) {
    final map = _asMap(data);
    if (map == null) return data.toString();

    if (map['error'] != null) {
      return _unavailable(_errorMessage(map['error']));
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
