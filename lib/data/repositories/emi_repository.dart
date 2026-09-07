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
}
