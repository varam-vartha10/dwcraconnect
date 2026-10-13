import '../../../../core/network/api_service.dart';

class ReportRepository {
  static Future<Map<String, dynamic>> fetchReportData({
    required String reportType,
    required String month, // YYYY-MM
  }) async {
    String apiType;
    switch (reportType.toLowerCase()) {
      case 'monthly collection':
      case 'monthly-collection':
        apiType = 'monthly-collection';
        break;
      case 'pending emi':
      case 'pending-emi':
        apiType = 'pending-emi';
        break;
      case 'subsidy records':
      case 'subsidy-records':
        apiType = 'subsidy-records';
        break;
      case 'recovery':
        apiType = 'recovery';
        break;
      default:
        apiType = reportType.toLowerCase().replaceAll(' ', '-');
    }

    final endpoint = '/reports/$apiType?month=$month';
    final response = await ApiService.get(endpoint);

    if (response['success'] == true) {
      return Map<String, dynamic>.from(response);
    } else {
      throw Exception(response['message'] ?? 'Failed to fetch report data.');
    }
  }
}
