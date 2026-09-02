import 'package:flutter/foundation.dart';

import '../models/health_report.dart';
import '../services/service_locator.dart';

/// Handles uploading a report and turning it into an AI summary.
class ReportProvider extends ChangeNotifier {
  List<HealthReport> _reports = [];
  bool _loading = true;
  bool _generating = false;
  HealthReport? _current;

  List<HealthReport> get reports => _reports;
  bool get loading => _loading;
  bool get generating => _generating;
  HealthReport? get current => _current;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _reports = await Services.reports.list();
    _loading = false;
    notifyListeners();
  }

  Future<HealthReport> generate({
    required String fileName,
    required Uint8List? bytes,
    required ReportLanguage language,
  }) async {
    _generating = true;
    _current = HealthReport(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: fileName,
      sourceFileName: fileName,
      language: language,
      status: ReportStatus.processing,
      summary: '',
      createdAt: DateTime.now(),
    );
    notifyListeners();

    final summary = await Services.ai
        .summarizeReport(fileName: fileName, bytes: bytes, language: language);

    _current = _current!.copyWith(status: ReportStatus.ready, summary: summary);
    await Services.reports.add(_current!);
    _reports = await Services.reports.list();
    _generating = false;
    notifyListeners();
    return _current!;
  }

  void selectLanguage(ReportLanguage language) {
    if (_current == null) return;
    _current = _current!.copyWith(language: language);
    notifyListeners();
  }
}
