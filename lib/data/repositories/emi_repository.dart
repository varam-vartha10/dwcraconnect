import '../../core/network/api_service.dart';
import '../../domain/entities/emi_entity.dart';

class EmiRepository {
  Future<List<EmiEntity>> getEmis({
    String? memberId,
    String? groupId,
    String? loanId,
    String? status,
  }) async {
    final queryParameters = <String, String>{};

    void addQueryParam(String key, String? value) {
      final trimmedValue = value?.trim();
      if (trimmedValue != null && trimmedValue.isNotEmpty) {
        queryParameters[key] = trimmedValue;
      }
    }

    addQueryParam('memberId', memberId);
    addQueryParam('groupId', groupId);
    addQueryParam('loanId', loanId);
    addQueryParam('status', status);

    final endpoint = Uri(
      path: '/emis',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();

    final response = await ApiService.get(endpoint);

    if (response['success'] == true) {
      final emiList = response['emis'];
      if (emiList is! List) {
        throw Exception('Invalid EMI response');
      }
      return emiList
          .map((json) => EmiEntity.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } else {
      throw Exception(response['message'] ?? 'Failed to load EMIs');
    }
  }

  Future<Map<String, dynamic>> payEmi({
    required String emiId,
    required double amount,
    String? notes,
  }) async {
    final response = await ApiService.post('/emis/pay', {
      'emiId': emiId,
      'amount': amount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });

    if (response['success'] == true) {
      return Map<String, dynamic>.from(response);
    } else {
      throw Exception(response['message'] ?? 'EMI payment failed');
    }
  }
}
