import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:intl/intl.dart';

class ExcelReportGenerator {
  static Future<List<int>> generateExcelReport({
    required Map<String, dynamic> reportData,
  }) async {
    final Workbook workbook = Workbook();

    final reportTitle = reportData['reportTitle'] ?? 'Financial Report';
    final reportType = reportData['reportType'] ?? 'report';
    final groupId = reportData['groupId'] ?? 'GRP001';
    final month = reportData['reportingMonth'] ?? '';
    final generatedAt = reportData['generatedAt'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(reportData['generatedAt']))
        : DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final summary = Map<String, dynamic>.from(reportData['summary'] ?? {});
    final List records = reportData['records'] ?? [];

    String sheetName = 'Financial Report';
    switch (reportType) {
      case 'monthly-collection':
        sheetName = 'Monthly Collection';
        break;
      case 'pending-emi':
        sheetName = 'Pending EMI';
        break;
      case 'subsidy-records':
        sheetName = 'Subsidy Records';
        break;
      case 'recovery':
        sheetName = 'Group Recovery';
        break;
    }

    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = sheetName;

    // Header Title
    final Range titleRange = sheet.getRangeByName('A1:G1');
    titleRange.merge();
    titleRange.setText('DWCRA CONNECT - $reportTitle');
    titleRange.cellStyle.bold = true;
    titleRange.cellStyle.fontSize = 14;
    titleRange.cellStyle.fontColor = '#6A1B9A';

    // Metadata Row
    sheet.getRangeByName('A2').setText('Group ID: $groupId');
    sheet.getRangeByName('C2').setText('Reporting Period: ${month.isEmpty ? "Overall" : month}');
    sheet.getRangeByName('E2').setText('Generated At: $generatedAt');

    // Summary Card Rows
    int currentRow = 4;
    switch (reportType) {
      case 'monthly-collection':
        sheet.getRangeByIndex(currentRow, 1).setText('Total Collected: Rs. ${summary['totalAmount'] ?? 0}');
        sheet.getRangeByIndex(currentRow, 4).setText('Total Transactions: ${summary['totalTransactions'] ?? 0}');
        break;
      case 'pending-emi':
        sheet.getRangeByIndex(currentRow, 1).setText('Total Pending Amount: Rs. ${summary['totalPendingAmount'] ?? 0}');
        sheet.getRangeByIndex(currentRow, 4).setText('Total Installments: ${summary['totalInstallments'] ?? 0}');
        break;
      case 'subsidy-records':
        sheet.getRangeByIndex(currentRow, 1).setText('Total Subsidy Amount: Rs. ${summary['totalAmount'] ?? 0}');
        sheet.getRangeByIndex(currentRow, 4).setText('Total Records: ${summary['totalRecords'] ?? 0}');
        break;
      case 'recovery':
        sheet.getRangeByIndex(currentRow, 1).setText('Group Loan Principal: Rs. ${summary['groupLoanTotal'] ?? 0}');
        sheet.getRangeByIndex(currentRow, 4).setText('Total Repaid To Date: Rs. ${summary['groupRepaidTotal'] ?? 0}');
        sheet.getRangeByIndex(currentRow, 6).setText('Outstanding Balance: Rs. ${summary['groupOutstandingTotal'] ?? 0}');
        break;
    }

    currentRow = 6; // Start Column Headers at row 6

    List<String> colHeaders = [];
    switch (reportType) {
      case 'monthly-collection':
        colHeaders = ['S.No', 'Member Name', 'Member ID', 'Transaction Ref', 'Payment Date', 'Payment Type', 'Amount (INR)', 'Status'];
        break;
      case 'pending-emi':
        colHeaders = ['S.No', 'Member Name', 'Member ID', 'Loan ID', 'Installment #', 'Due Date', 'EMI Amount (INR)', 'Status'];
        break;
      case 'subsidy-records':
        colHeaders = ['S.No', 'Member Name', 'Member ID', 'Scheme Name', 'Date Received', 'Amount (INR)', 'Status'];
        break;
      case 'recovery':
        colHeaders = ['S.No', 'Member Name', 'Member ID', 'Loan Amount (INR)', 'Repaid In Period (INR)', 'Total Repaid To Date (INR)', 'Outstanding Balance (INR)'];
        break;
    }

    // Set Headers with styling
    for (int col = 0; col < colHeaders.length; col++) {
      final Range cell = sheet.getRangeByIndex(currentRow, col + 1);
      cell.setText(colHeaders[col]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#6A1B9A';
      cell.cellStyle.fontColor = '#FFFFFF';
    }

    currentRow++; // Start data at row 7

    // Populate Data Rows
    for (int i = 0; i < records.length; i++) {
      final r = Map<String, dynamic>.from(records[i] as Map);

      sheet.getRangeByIndex(currentRow, 1).setNumber((i + 1).toDouble());
      sheet.getRangeByIndex(currentRow, 2).setText((r['memberName'] ?? 'Member').toString());
      sheet.getRangeByIndex(currentRow, 3).setText((r['memberId'] ?? '').toString());

      switch (reportType) {
        case 'monthly-collection':
          final d = r['paymentDate'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(r['paymentDate'])) : '-';
          sheet.getRangeByIndex(currentRow, 4).setText((r['transactionId'] ?? '').toString());
          sheet.getRangeByIndex(currentRow, 5).setText(d);
          sheet.getRangeByIndex(currentRow, 6).setText((r['paymentType'] ?? 'EMI Payment').toString());
          sheet.getRangeByIndex(currentRow, 7).setNumber(((r['amount'] ?? 0) as num).toDouble());
          sheet.getRangeByIndex(currentRow, 8).setText('Completed');
          break;

        case 'pending-emi':
          final d = r['dueDate'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(r['dueDate'])) : '-';
          sheet.getRangeByIndex(currentRow, 4).setText((r['loanId'] ?? '').toString());
          sheet.getRangeByIndex(currentRow, 5).setNumber(((r['installmentNumber'] ?? 1) as num).toDouble());
          sheet.getRangeByIndex(currentRow, 6).setText(d);
          sheet.getRangeByIndex(currentRow, 7).setNumber(((r['amount'] ?? 0) as num).toDouble());
          sheet.getRangeByIndex(currentRow, 8).setText((r['status'] ?? 'pending').toString().toUpperCase());
          break;

        case 'subsidy-records':
          final d = r['dateReceived'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(r['dateReceived'])) : '-';
          sheet.getRangeByIndex(currentRow, 4).setText((r['schemeName'] ?? 'Govt Scheme').toString());
          sheet.getRangeByIndex(currentRow, 5).setText(d);
          sheet.getRangeByIndex(currentRow, 6).setNumber(((r['amount'] ?? 0) as num).toDouble());
          sheet.getRangeByIndex(currentRow, 7).setText((r['status'] ?? 'received').toString().toUpperCase());
          break;

        case 'recovery':
          sheet.getRangeByIndex(currentRow, 4).setNumber(((r['loanAmount'] ?? 0) as num).toDouble());
          sheet.getRangeByIndex(currentRow, 5).setNumber(((r['repaidInPeriod'] ?? 0) as num).toDouble());
          sheet.getRangeByIndex(currentRow, 6).setNumber(((r['totalRepaidToDate'] ?? 0) as num).toDouble());
          sheet.getRangeByIndex(currentRow, 7).setNumber(((r['outstandingBalance'] ?? 0) as num).toDouble());
          break;
      }

      currentRow++;
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    return bytes;
  }
}
