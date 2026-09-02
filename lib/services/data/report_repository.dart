import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/health_report.dart';
import '../supabase_service.dart';

/// Reads/writes AI report summaries.
abstract class ReportRepository {
  Future<List<HealthReport>> list();
  Future<void> add(HealthReport report);
}

/// Reports persisted locally (summary text kept, source PDF bytes are not).
class MockReportRepository implements ReportRepository {
  static const _key = 'll_reports';

  Future<List<HealthReport>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) {
      final m = e as Map<String, dynamic>;
      return HealthReport(
        id: m['id'] as String,
        title: m['title'] as String,
        sourceFileName: m['sourceFileName'] as String,
        language: ReportLanguage.values[m['language'] as int],
        status: ReportStatus.values[m['status'] as int],
        summary: m['summary'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
    }).toList();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items
          .map((r) => {
                'id': r.id,
                'title': r.title,
                'sourceFileName': r.sourceFileName,
                'language': r.language.index,
                'status': r.status.index,
                'summary': r.summary,
                'createdAt': r.createdAt.toIso8601String(),
              })
          .toList()),
    );
  }
}

/// Reports stored in the Supabase `reports` table.
class SupabaseReportRepository implements ReportRepository {
  final _client = SupabaseService.instance.app;
  String? get _email => _client.auth.currentUser?.email;

  @override
  Future<List<HealthReport>> list() async {
    final rows = await _client
        .from('reports')
        .select()
        .eq('user_email', _email ?? '')
        .order('uploaded_at', ascending: false);
    return (rows as List).map((e) {
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
        summary: m['summary'] as String? ?? '',
        createdAt: DateTime.tryParse('${m['uploaded_at']}') ?? DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<void> add(HealthReport report) async {
    await _client.from('reports').insert({
      'user_email': _email,
      'report_name': report.title,
      'summary': report.summary,
      'language': report.language.label,
    });
  }
}
