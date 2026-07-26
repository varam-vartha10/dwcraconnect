import 'package:flutter/material.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> reportTypes = [
      {
        'title': l10n.monthlyCollection,
        'icon': Icons.calendar_month_rounded,
        'color': AppColors.primaryPurple,
      },
      {
        'title': l10n.pendingEmi,
        'icon': Icons.pending_actions_rounded,
        'color': AppColors.secondaryPink,
      },
      {
        'title': l10n.subsidyRecords,
        'icon': Icons.savings_rounded,
        'color': AppColors.successGreen,
      },
      {
        'title': l10n.recovery,
        'icon': Icons.trending_up_rounded,
        'color': AppColors.trustBlue,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              l10n.selectReportType,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: reportTypes.length,
              itemBuilder: (context, index) {
                final report = reportTypes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: report['color'].withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(report['icon'], color: report['color']),
                    ),
                    title: Text(
                      report['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showExportOptions(context, report['title'], l10n),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context, String title, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.exportReport(title),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildExportButton(
                    context,
                    l10n.exportPdf,
                    Icons.picture_as_pdf_rounded,
                    Colors.redAccent,
                    () {
                      Navigator.pop(context);
                      _showSuccessSnackBar(context, l10n.pdfExportSuccess);
                    },
                  ),
                  _buildExportButton(
                    context,
                    l10n.exportExcel,
                    Icons.table_view_rounded,
                    Colors.green,
                    () {
                      Navigator.pop(context);
                      _showSuccessSnackBar(context, l10n.excelExportSuccess);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
