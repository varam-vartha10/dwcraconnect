import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfReportGenerator {
  static Future<Uint8List> generatePdfReport({
    required Map<String, dynamic> reportData,
  }) async {
    final pdf = pw.Document();

    final reportTitle = reportData['reportTitle'] ?? 'Financial Report';
    final reportType = reportData['reportType'] ?? '';
    final groupId = reportData['groupId'] ?? 'GRP001';
    final month = reportData['reportingMonth'] ?? '';
    final generatedAt = reportData['generatedAt'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(reportData['generatedAt']))
        : DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final summary = Map<String, dynamic>.from(reportData['summary'] ?? {});
    final List records = reportData['records'] ?? [];

    final primaryColor = PdfColor.fromHex('#6A1B9A');
    final secondaryColor = PdfColor.fromHex('#F3E5F5');
    final textColor = PdfColor.fromHex('#212121');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DWCRA CONNECT',
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Women Self Help Group (SHG) Financial Management',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: secondaryColor,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'Group: $groupId',
                      style: pw.TextStyle(
                        color: primaryColor,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: primaryColor, thickness: 1.5),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated on $generatedAt | Confidential SHG Financial Record',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 8, color: primaryColor, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          final List<pw.Widget> widgets = [];

          // Report Subheader
          widgets.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (month.isNotEmpty)
                  pw.Text(
                    'Reporting Month: $month',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 12));

          // Summary Cards Section
          widgets.add(_buildSummaryCardPdf(summary, reportType, secondaryColor, primaryColor));
          widgets.add(pw.SizedBox(height: 16));

          // Detailed Table Section
          if (records.isEmpty) {
            widgets.add(
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'No records found for the selected reporting period.',
                  style: pw.TextStyle(
                    color: PdfColors.grey700,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            );
          } else {
            widgets.add(_buildTablePdf(records, reportType, primaryColor));
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryCardPdf(
    Map<String, dynamic> summary,
    String reportType,
    PdfColor bgColor,
    PdfColor primaryColor,
  ) {
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');

    List<pw.Widget> items = [];

    switch (reportType) {
      case 'monthly-collection':
        items = [
          _summaryText('Total Collected:', currencyFormatter.format(summary['totalAmount'] ?? 0)),
          _summaryText('Successful Transactions:', '${summary['totalTransactions'] ?? 0}'),
        ];
        break;
      case 'pending-emi':
        items = [
          _summaryText('Total Pending Amount:', currencyFormatter.format(summary['totalPendingAmount'] ?? 0)),
          _summaryText('Total Installments:', '${summary['totalInstallments'] ?? 0}'),
        ];
        break;
      case 'subsidy-records':
        items = [
          _summaryText('Total Subsidy Granted:', currencyFormatter.format(summary['totalAmount'] ?? 0)),
          _summaryText('Total Subsidy Records:', '${summary['totalRecords'] ?? 0}'),
        ];
        break;
      case 'recovery':
        items = [
          _summaryText('Group Total Loan:', currencyFormatter.format(summary['groupLoanTotal'] ?? 0)),
          _summaryText('Total Repaid To Date:', currencyFormatter.format(summary['groupRepaidTotal'] ?? 0)),
          _summaryText('Group Outstanding Balance:', currencyFormatter.format(summary['groupOutstandingTotal'] ?? 0)),
        ];
        break;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: primaryColor, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: items,
      ),
    );
  }

  static pw.Widget _summaryText(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildTablePdf(List records, String reportType, PdfColor headerBg) {
    final NumberFormat currency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');

    List<String> headers = [];
    List<List<String>> dataRows = [];

    switch (reportType) {
      case 'monthly-collection':
        headers = ['#', 'Member Name', 'Member ID', 'Tx Ref', 'Date', 'Payment Type', 'Amount'];
        dataRows = List<List<String>>.from(records.asMap().entries.map((e) {
          final i = e.key + 1;
          final r = Map<String, dynamic>.from(e.value as Map);
          final dateStr = r['paymentDate'] != null
              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(r['paymentDate']))
              : '-';
          return <String>[
            '$i',
            r['memberName'] ?? 'Member',
            r['memberId'] ?? '',
            r['transactionId'] ?? '',
            dateStr,
            r['paymentType'] ?? 'EMI Payment',
            currency.format(r['amount'] ?? 0),
          ];
        }));
        break;

      case 'pending-emi':
        headers = ['#', 'Member Name', 'Member ID', 'Loan ID', 'Inst #', 'Due Date', 'Amount', 'Status'];
        dataRows = List<List<String>>.from(records.asMap().entries.map((e) {
          final i = e.key + 1;
          final r = Map<String, dynamic>.from(e.value as Map);
          final dateStr = r['dueDate'] != null
              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(r['dueDate']))
              : '-';
          return <String>[
            '$i',
            r['memberName'] ?? 'Member',
            r['memberId'] ?? '',
            r['loanId'] ?? '',
            '${r['installmentNumber'] ?? 1}',
            dateStr,
            currency.format(r['amount'] ?? 0),
            (r['status'] ?? 'pending').toString().toUpperCase(),
          ];
        }));
        break;

      case 'subsidy-records':
        headers = ['#', 'Member Name', 'Member ID', 'Scheme Name', 'Date Received', 'Amount', 'Status'];
        dataRows = List<List<String>>.from(records.asMap().entries.map((e) {
          final i = e.key + 1;
          final r = Map<String, dynamic>.from(e.value as Map);
          final dateStr = r['dateReceived'] != null
              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(r['dateReceived']))
              : '-';
          return <String>[
            '$i',
            r['memberName'] ?? 'Member',
            r['memberId'] ?? '',
            r['schemeName'] ?? 'Govt Scheme',
            dateStr,
            currency.format(r['amount'] ?? 0),
            (r['status'] ?? 'received').toString().toUpperCase(),
          ];
        }));
        break;

      case 'recovery':
        headers = ['#', 'Member Name', 'Member ID', 'Loan Amount', 'Repaid (Period)', 'Total Repaid', 'Outstanding'];
        dataRows = List<List<String>>.from(records.asMap().entries.map((e) {
          final i = e.key + 1;
          final r = Map<String, dynamic>.from(e.value as Map);
          return <String>[
            '$i',
            r['memberName'] ?? 'Member',
            r['memberId'] ?? '',
            currency.format(r['loanAmount'] ?? 0),
            currency.format(r['repaidInPeriod'] ?? 0),
            currency.format(r['totalRepaidToDate'] ?? 0),
            currency.format(r['outstandingBalance'] ?? 0),
          ];
        }));
        break;
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: dataRows,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
      headerDecoration: pw.BoxDecoration(color: headerBg),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }
}
