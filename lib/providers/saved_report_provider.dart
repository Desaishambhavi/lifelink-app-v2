import 'package:flutter/foundation.dart';

import '../models/health_report.dart';
import '../services/service_locator.dart';

/// Reports pinned to the user's profile (stored on-device via
/// [Services.savedReports]).
class SavedReportProvider extends ChangeNotifier {
  List<HealthReport> _reports = [];
  bool _loading = true;

  List<HealthReport> get reports => _reports;
  bool get loading => _loading;

  bool isSaved(String id) => _reports.any((r) => r.id == id);

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _reports = await Services.savedReports.list();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(HealthReport report) async {
    await Services.savedReports.add(report);
    _reports = await Services.savedReports.list();
    notifyListeners();
  }

  Future<void> remove(HealthReport report) async {
    await Services.savedReports.delete(report.id);
    _reports = await Services.savedReports.list();
    notifyListeners();
  }
}
