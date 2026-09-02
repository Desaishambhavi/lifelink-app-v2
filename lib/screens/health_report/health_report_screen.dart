import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/health_report.dart';
import '../../providers/report_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/entrance.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_controls.dart';
import '../../widgets/top_bar.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({super.key, this.onOpenProfile});
  final VoidCallback? onOpenProfile;

  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends State<HealthReportScreen> {
  ReportLanguage _language = ReportLanguage.english;
  String? _fileName;
  Uint8List? _bytes;

  Future<void> _pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _fileName = file.name;
      _bytes = bytes;
    });
  }

  Future<void> _generate() async {
    final name = _fileName ?? 'Sample_Blood_Panel.pdf';
    await context.read<ReportProvider>().generate(
          fileName: name,
          bytes: _bytes,
          language: _language,
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final current = provider.current;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        TopBar(title: 'Health reports', eyebrow: 'AI summaries', onProfile: widget.onOpenProfile),
        const SizedBox(height: 22),
        Entrance(child: _uploadCard(provider)),
        if (current != null && current.status == ReportStatus.ready) ...[
          const SizedBox(height: 16),
          Entrance(child: _SummaryCard(report: current)),
        ],
        if (provider.reports.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionHeader(title: 'Past reports'),
          const SizedBox(height: 12),
          for (final r in provider.reports)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReportRow(report: r),
            ),
        ],
      ],
    );
  }

  Widget _uploadCard(ReportProvider provider) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Summarize a report',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Upload a PDF and receive a clear summary in your language.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 18),
          const Text('LANGUAGE',
              style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final lang in ReportLanguage.values)
                _LangChip(
                  label: lang.nativeLabel,
                  selected: _language == lang,
                  onTap: () => setState(() => _language = lang),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _DropZone(fileName: _fileName, onTap: _pick),
          const SizedBox(height: 16),
          GlassButton(
            label: provider.generating ? 'Generating summary' : 'Generate summary',
            icon: Icons.auto_awesome_outlined,
            loading: provider.generating,
            onPressed: provider.generating ? null : _generate,
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.frost : AppColors.white(0.06),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? AppColors.frost : AppColors.glassStroke,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.abyss : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({required this.fileName, required this.onTap});
  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final picked = fileName != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.white(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: picked ? AppColors.mist.withValues(alpha: 0.5) : AppColors.glassStroke,
          ),
        ),
        child: Row(
          children: [
            Icon(
              picked ? Icons.picture_as_pdf_rounded : Icons.upload_file_rounded,
              color: AppColors.mist,
              size: 26,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    picked ? fileName! : 'Tap to upload a PDF',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.frost, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    picked ? 'Ready to summarize' : 'or generate a sample summary',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});
  final HealthReport report;

  Future<void> _export() async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, text: 'LifeLink — Report Summary'),
          pw.Text(report.title,
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 16),
          pw.Text(report.summary, style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)),
        ],
      ),
    );
    await Printing.sharePdf(bytes: await doc.save(), filename: 'lifelink_summary.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_rounded, size: 18, color: AppColors.mist),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Summary · ${report.language.label}',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: Services.tts.speaking,
                builder: (context, speaking, _) => GlassIconButton(
                  icon: speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                  size: 38,
                  onTap: () => speaking
                      ? Services.tts.stop()
                      : Services.tts.speak(report.summary, locale: report.language.ttsLocale),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(report.summary,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13.5, height: 1.55)),
          const SizedBox(height: 16),
          GlassButton(
            label: 'Export as PDF',
            icon: Icons.ios_share_rounded,
            kind: GlassButtonKind.ghost,
            onPressed: _export,
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report});
  final HealthReport report;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _ReportSheet(report: report),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.white(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassStroke),
            ),
            child: const Icon(Icons.description_rounded, color: AppColors.mist, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.frost, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${report.language.label} · ${_date(report.createdAt)}',
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _ReportSheet extends StatelessWidget {
  const _ReportSheet({required this.report});
  final HealthReport report;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, controller) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.deep, AppColors.abyss],
            ),
            border: Border(top: BorderSide(color: AppColors.glassStroke)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.white(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(report.title,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('${report.language.label} summary',
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
              const SizedBox(height: 18),
              Text(report.summary,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}
