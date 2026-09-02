/// Languages the AI report summariser can produce, matching the original app.
enum ReportLanguage { english, hindi, marathi, kannada }

extension ReportLanguageMeta on ReportLanguage {
  String get label => switch (this) {
        ReportLanguage.english => 'English',
        ReportLanguage.hindi => 'Hindi',
        ReportLanguage.marathi => 'Marathi',
        ReportLanguage.kannada => 'Kannada',
      };

  /// Native script name, used on the language chips for a professional touch.
  String get nativeLabel => switch (this) {
        ReportLanguage.english => 'English',
        ReportLanguage.hindi => 'हिंदी',
        ReportLanguage.marathi => 'मराठी',
        ReportLanguage.kannada => 'ಕನ್ನಡ',
      };

  /// BCP-47 tag for text-to-speech.
  String get ttsLocale => switch (this) {
        ReportLanguage.english => 'en-US',
        ReportLanguage.hindi => 'hi-IN',
        ReportLanguage.marathi => 'mr-IN',
        ReportLanguage.kannada => 'kn-IN',
      };
}

/// Where a report is in its lifecycle.
enum ReportStatus { processing, ready, failed }

/// An uploaded medical report and its AI-generated summary.
class HealthReport {
  final String id;
  final String title;
  final String sourceFileName;
  final ReportLanguage language;
  final ReportStatus status;
  final String summary;
  final DateTime createdAt;

  const HealthReport({
    required this.id,
    required this.title,
    required this.sourceFileName,
    required this.language,
    required this.status,
    required this.summary,
    required this.createdAt,
  });

  HealthReport copyWith({
    ReportStatus? status,
    String? summary,
    ReportLanguage? language,
  }) {
    return HealthReport(
      id: id,
      title: title,
      sourceFileName: sourceFileName,
      language: language ?? this.language,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      createdAt: createdAt,
    );
  }
}
