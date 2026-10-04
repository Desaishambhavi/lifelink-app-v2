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
import '../../services/security/report_encryption_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/entrance.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_controls.dart';
import '../../widgets/report_passphrase_gate.dart';
import '../../widgets/report_summary_sheet.dart';
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
    // Unlock (or set) the passphrase before generating so the repository can
    // encrypt the summary on save.
    if (!ReportEncryptionService.instance.isUnlocked) {
      final ok = await ReportPassphraseGate.show(context);
      if (!ok || !mounted) return;
    }

    final name = _fileName ?? 'Sample_Blood_Panel.pdf';
    final reports = context.read<ReportProvider>();
    await reports.generate(
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
          Text(
            'Upload a PDF and receive a clear summary in your language.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 18),
          Text('LANGUAGE',
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
                    style: TextStyle(
                        color: AppColors.frost, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    picked ? 'Ready to summarize' : 'or generate a sample summary',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatefulWidget {
  const _SummaryCard({required this.report});
  final HealthReport report;

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  bool _exporting = false;

  // Noto fonts are embedded in the PDF so summaries render as real glyphs
  // instead of tofu/boxes: Devanagari covers Hindi & Marathi, Kannada its own
  // script, and Noto Sans covers Latin, digits and the punctuation/symbols the
  // AI often emits (em-dashes, bullets, arrows) that the built-in Helvetica
  // cannot draw — the missing glyph is what made export fail entirely. Fetched
  // once via the printing package and reused across exports.
  static Future<pw.Font>? _latin, _latinBold, _devanagari, _kannada;

  static Future<pw.ThemeData> _pdfTheme(ReportLanguage language) async {
    final latin = await (_latin ??= PdfGoogleFonts.notoSansRegular());
    final latinBold = await (_latinBold ??= PdfGoogleFonts.notoSansBold());
    final devanagari =
        await (_devanagari ??= PdfGoogleFonts.notoSansDevanagariRegular());
    final kannada = await (_kannada ??= PdfGoogleFonts.notoSansKannadaRegular());

    final base = switch (language) {
      ReportLanguage.hindi || ReportLanguage.marathi => devanagari,
      ReportLanguage.kannada => kannada,
      ReportLanguage.english => latin,
    };

    // Any glyph missing from the base font falls back across every script, so
    // mixed content (English terms and digits inside a Hindi summary) is safe.
    return pw.ThemeData.withFont(
      base: base,
      bold: latinBold,
      fontFallback: [latin, devanagari, kannada],
    );
  }

  Future<void> _export() async {
    if (_exporting) return;
    final report = widget.report;
    final messenger = ScaffoldMessenger.of(context);
    // Flip to the loading state immediately so the tap is unmistakable — the
    // button shows a spinner while the fonts load and the PDF is built.
    setState(() => _exporting = true);
    try {
      final theme = await _pdfTheme(report.language);
      final doc = pw.Document(theme: theme);
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(level: 0, text: 'LifeLink — Report Summary'),
            pw.Text(report.title,
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 16),
            // `TextOverflow.span` lets a long summary flow across multiple
            // pages; without it the pdf package throws when the text is taller
            // than a single page.
            pw.Text(report.cleanSummary,
                overflow: pw.TextOverflow.span,
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)),
          ],
        ),
      );
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'lifelink_summary.pdf',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not export PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
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
              Icon(Icons.summarize_rounded, size: 18, color: AppColors.mist),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Summary · ${widget.report.language.label}',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: Services.tts.speaking,
                builder: (context, speaking, _) => GlassIconButton(
                  icon: speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                  size: 38,
                  onTap: () => speaking
                      ? Services.tts.stop()
                      : Services.tts.speak(widget.report.cleanSummary,
                          locale: widget.report.language.ttsLocale),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(widget.report.cleanSummary,
              style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 13.5, height: 1.55)),
          const SizedBox(height: 16),
          GlassButton(
            label: _exporting ? 'Preparing PDF…' : 'Export as PDF',
            icon: Icons.ios_share_rounded,
            kind: GlassButtonKind.ghost,
            loading: _exporting,
            onPressed: _exporting ? null : _export,
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report});
  final HealthReport report;

  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<ReportProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.deep,
        title: const Text('Delete report?'),
        content: Text(
            '"${report.title}" and its summary will be removed. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.delete(report);
      messenger.showSnackBar(
        const SnackBar(content: Text('Report deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () async {
        final enc = ReportEncryptionService.instance;
        var reportToShow = report;

        // If the service is locked the stored summary is a placeholder — unlock
        // first, then reload so we can show the decrypted content.
        if (!enc.isUnlocked ||
            report.summary == ReportEncryptionService.lockedPlaceholder) {
          if (!context.mounted) return;
          final ok = await ReportPassphraseGate.show(context);
          if (!ok || !context.mounted) return;
          await context.read<ReportProvider>().load();
          if (!context.mounted) return;
          reportToShow = context
              .read<ReportProvider>()
              .reports
              .firstWhere((r) => r.id == report.id, orElse: () => report);
        }

        if (!context.mounted) return;
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => ReportSummarySheet(report: reportToShow),
        );
      },
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
            child: Icon(Icons.description_rounded, color: AppColors.mist, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.frost, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${report.language.label} · ${_date(report.createdAt)}',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          GlassIconButton(
            icon: Icons.delete_outline_rounded,
            size: 38,
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
