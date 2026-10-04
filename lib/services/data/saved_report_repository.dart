import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/health_report.dart';
import '../security/report_encryption_service.dart';

/// Reports the user has chosen to pin to their profile, kept on-device.
///
/// The production database has no table for "profile-saved" reports and we make
/// no schema changes, so — like reminders and notifications — these persist via
/// SharedPreferences regardless of backend mode.
///
/// Summaries are AES-256-GCM encrypted on disk (same service as the reports
/// table). The service must be unlocked before calling [add]; [list] returns
/// the [ReportEncryptionService.lockedPlaceholder] sentinel for any encrypted
/// rows when the service is locked.
class SavedReportRepository {
  static const _key = 'll_profile_reports';
  final _enc = ReportEncryptionService.instance;

  // _read() always decrypts; _write() always encrypts — no double-encryption.
  Future<List<HealthReport>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final futures = (jsonDecode(raw) as List).map((e) async {
      final m = e as Map<String, dynamic>;
      return HealthReport(
        id: m['id'] as String,
        title: m['title'] as String,
        sourceFileName: m['sourceFileName'] as String,
        language: ReportLanguage.values[m['language'] as int],
        status: ReportStatus.values[m['status'] as int],
        summary: await _enc.decrypt(m['summary'] as String),
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
    });
    return Future.wait(futures);
  }

  Future<void> _write(List<HealthReport> items) async {
    final prefs = await SharedPreferences.getInstance();
    final rows = await Future.wait(items.map((r) async => {
          'id': r.id,
          'title': r.title,
          'sourceFileName': r.sourceFileName,
          'language': r.language.index,
          'status': r.status.index,
          'summary': await _enc.encrypt(r.summary),
          'createdAt': r.createdAt.toIso8601String(),
        }));
    await prefs.setString(_key, jsonEncode(rows));
  }

  Future<List<HealthReport>> list() async {
    final items = await _read();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Adds [report] unless one with the same id is already saved.
  Future<void> add(HealthReport report) async {
    final items = await _read();
    if (items.any((r) => r.id == report.id)) return;
    items.add(report);
    await _write(items);
  }

  Future<void> delete(String id) async {
    final items = await _read()..removeWhere((r) => r.id == id);
    await _write(items);
  }
}
