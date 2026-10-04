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

  /// The summary with markdown markers stripped, for clean on-screen reading,
  /// text-to-speech and PDF export. The model sometimes emits `*`, `**bold**`,
  /// `#` headings etc. which should never be shown to the reader as literals.
  String get cleanSummary => _stripMarkdown(summary);

  static String _stripMarkdown(String input) {
    var t = input;
    // Bold / italic wrappers: **text** / __text__ -> text
    t = t.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1');
    t = t.replaceAll(RegExp(r'__(.+?)__'), r'$1');
    // Bullet markers at the start of a line: "* " / "- " / "+ " -> "• "
    t = t.replaceAll(RegExp(r'^[ \t]*[\*\-\+][ \t]+', multiLine: true), '• ');
    // Heading markers at the start of a line: "### " -> ""
    t = t.replaceAll(RegExp(r'^[ \t]*#{1,6}[ \t]*', multiLine: true), '');
    // Any leftover emphasis asterisks and inline-code backticks.
    t = t.replaceAll('*', '').replaceAll('`', '');
    // Collapse runs of blank lines left behind.
    t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return t.trim();
  }

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
