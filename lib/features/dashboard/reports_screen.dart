import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../reports/data/repositories/report_repository.dart';
import '../reports/services/pdf_report_generator.dart';
import '../reports/services/excel_report_generator.dart';
import '../reports/services/file_saver_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isExporting = false;
  String? _exportingTitle;

  String get _monthParam => DateFormat('yyyy-MM').format(_selectedDate);
  String get _formattedMonth => DateFormat('MMMM yyyy').format(_selectedDate);

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
  }

  Future<void> _handleExport({
    required String reportTitle,
    required String exportType, // 'pdf' or 'excel'
    required AppLocalizations l10n,
  }) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
      _exportingTitle = reportTitle;
    });

    try {
      // 1. Fetch real database records from backend
      final reportData = await ReportRepository.fetchReportData(
        reportType: reportTitle,
        month: _monthParam,
      );

      final cleanTitle = reportTitle.replaceAll(' ', '_');
      final filename = 'DWCRA_${cleanTitle}_$_monthParam.$exportType';

      String savedPath = '';

      // 2. Generate PDF or Excel Bytes
      if (exportType == 'pdf') {
        final pdfBytes = await PdfReportGenerator.generatePdfReport(
          reportData: reportData,
        );
        savedPath = await FileSaverService.saveAndOpenFile(
          bytes: pdfBytes,
          filename: filename,
          fileType: 'pdf',
        );
      } else {
        final excelBytes = await ExcelReportGenerator.generateExcelReport(
          reportData: reportData,
        );
        if (excelBytes.isEmpty) {
          throw Exception('Failed to generate Excel workbook.');
        }
        savedPath = await FileSaverService.saveAndOpenFile(
          bytes: excelBytes,
          filename: filename,
          fileType: 'excel',
        );
      }

      if (!mounted) return;

      _showSuccessSnackBar(
        context,
        exportType == 'pdf' ? l10n.pdfExportSuccess : l10n.excelExportSuccess,
        savedPath,
        filename,
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(
        context,
        e.toString().replaceAll('Exception: ', ''),
        () => _handleExport(
          reportTitle: reportTitle,
          exportType: exportType,
          l10n: l10n,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportingTitle = null;
        });
      }
    }
  }

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
      appBar: AppBar(title: Text(l10n.reports)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryPurple.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: AppColors.primaryPurple,
                  onPressed: _isExporting ? null : _previousMonth,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppColors.primaryPurple,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formattedMonth,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: AppColors.primaryPurple,
                  onPressed: _isExporting ? null : _nextMonth,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
            child: Text(
              l10n.selectReportType,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: reportTypes.length,
              itemBuilder: (context, index) {
                final report = reportTypes[index];
                final isCurrentExporting = _isExporting && _exportingTitle == report['title'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: report['color'].withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(report['icon'], color: report['color']),
                    ),
                    title: Text(
                      report['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'Period: $_formattedMonth',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: isCurrentExporting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: _isExporting
                        ? null
                        : () => _showExportOptions(context, report['title'], l10n),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(
    BuildContext context,
    String title,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.exportReport(title),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reporting Period: $_formattedMonth',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildExportButton(
                    bottomSheetContext,
                    l10n.exportPdf,
                    Icons.picture_as_pdf_rounded,
                    Colors.redAccent,
                    () {
                      Navigator.pop(bottomSheetContext);
                      _handleExport(
                        reportTitle: title,
                        exportType: 'pdf',
                        l10n: l10n,
                      );
                    },
                  ),
                  _buildExportButton(
                    bottomSheetContext,
                    l10n.exportExcel,
                    Icons.table_view_rounded,
                    Colors.green,
                    () {
                      Navigator.pop(bottomSheetContext);
                      _handleExport(
                        reportTitle: title,
                        exportType: 'xlsx',
                        l10n: l10n,
                      );
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
              color: color.withValues(alpha: 0.1),
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

  void _showSuccessSnackBar(
    BuildContext context,
    String message,
    String savedPath,
    String filename,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(filename, style: const TextStyle(fontSize: 11)),
          ],
        ),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'SHARE',
          textColor: Colors.white,
          onPressed: () {
            FileSaverService.shareFile(
              filePath: savedPath,
              title: 'DWCRA Connect $filename',
            );
          },
        ),
      ),
    );
  }

  void _showErrorSnackBar(
    BuildContext context,
    String errorMsg,
    VoidCallback onRetry,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMsg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: onRetry,
        ),
      ),
    );
  }
}
