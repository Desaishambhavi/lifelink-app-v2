import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/health_report.dart';
import '../security/report_encryption_service.dart';
import '../supabase_service.dart';

/// Reads/writes AI report summaries.
abstract class ReportRepository {
  Future<List<HealthReport>> list();
  Future<void> add(HealthReport report);
  Future<void> delete(String id);
}

/// Reports persisted locally (summary text kept, source PDF bytes are not).
class MockReportRepository implements ReportRepository {
  static const _key = 'll_reports';
  final _enc = ReportEncryptionService.instance;

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

  @override
  Future<List<HealthReport>> list() async {
    final items = await _read();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<void> add(HealthReport report) async {
    final items = await _read()..add(report);
    await _write(items);
  }

  @override
  Future<void> delete(String id) async {
    final items = await _read()..removeWhere((r) => r.id == id);
    await _write(items);
  }

  // _read() always returns plaintext summaries; _write() always encrypts before
  // storing — so every item on disk is encrypted regardless of how it got there.
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
}

/// Reports stored in the Supabase `reports` table.
class SupabaseReportRepository implements ReportRepository {
  final _client = SupabaseService.instance.app;
  final _enc = ReportEncryptionService.instance;
  String? get _email => _client.auth.currentUser?.email;

  @override
  Future<List<HealthReport>> list() async {
    final rows = await _client
        .from('reports')
        .select()
        .eq('user_email', _email ?? '')
        .order('uploaded_at', ascending: false);
    final futures = (rows as List).map((e) async {
      final m = e as Map<String, dynamic>;
      return HealthReport(
        id: '${m['id']}',
        title: m['report_name'] as String? ?? 'Report',
        sourceFileName: m['report_name'] as String? ?? '',
        language: ReportLanguage.values.firstWhere(
          (l) => l.label == m['language'],
          orElse: () => ReportLanguage.english,
        ),
        status: ReportStatus.ready,
        summary: await _enc.decrypt(m['summary'] as String? ?? ''),
        createdAt: DateTime.tryParse('${m['uploaded_at']}') ?? DateTime.now(),
      );
    });
    return Future.wait(futures);
  }

  @override
  Future<void> add(HealthReport report) async {
    await _client.from('reports').insert({
      'user_email': _email,
      'report_name': report.title,
      'summary': await _enc.encrypt(report.summary),
      'language': report.language.label,
    });
  }

  @override
  Future<void> delete(String id) async {
    // Deleting a row is normal CRUD, not a schema change. Scope to the signed-in
    // user so a report can only be removed by its owner.
    await _client
        .from('reports')
        .delete()
        .eq('id', id)
        .eq('user_email', _email ?? '');
  }
}
