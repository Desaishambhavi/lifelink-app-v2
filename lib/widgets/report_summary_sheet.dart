import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/health_report.dart';
import '../services/security/report_encryption_service.dart';

/// Bottom sheet that shows a report's full (markdown-cleaned) summary. Shared by
/// the Reports screen and the Profile screen's saved reports.
class ReportSummarySheet extends StatelessWidget {
  const ReportSummarySheet({super.key, required this.report});
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
            gradient: LinearGradient(
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
              Text(report.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('${report.language.label} summary',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
              const SizedBox(height: 18),
              if (report.cleanSummary == ReportEncryptionService.lockedPlaceholder)
                Row(
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Text('Summary is encrypted — unlock to view.',
                        style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                            fontStyle: FontStyle.italic)),
                  ],
                )
              else
                Text(report.cleanSummary,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}
