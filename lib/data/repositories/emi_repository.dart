import 'dart:io';
import '../../core/network/api_service.dart';
import '../../core/network/cache_service.dart';
import '../../domain/entities/emi_entity.dart';

class EmiRepository {
  Future<List<EmiEntity>> getEmis({
    String? memberId,
    String? groupId,
    String? loanId,
    String? status,
  }) async {
    final cacheKey = 'emis_${memberId ?? groupId ?? "all"}';
    final activeUser = memberId ?? await CacheService.getActiveUser() ?? 'guest';

    try {
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
        if (emiList is List) {
          await CacheService.save(
            userId: activeUser,
            key: cacheKey,
            data: emiList,
            groupId: groupId,
          );
          return _mapJsonToEmis(emiList);
        }
      }
    } catch (_) {
      final cached = await CacheService.get(userId: activeUser, key: cacheKey);
      if (cached != null && cached['data'] is List) {
        return _mapJsonToEmis(cached['data'] as List);
      }
      rethrow;
    }
    return [];
  }

  Future<Map<String, dynamic>> payEmi({
    required String emiId,
    required double amount,
    String? notes,
  }) async {
    try {
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
    } on SocketException {
      throw Exception('Internet connection is required to complete EMI payment.');
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('internet connection')) {
        throw Exception('Internet connection is required to complete EMI payment.');
      }
      rethrow;
    }
  }

  List<EmiEntity> _mapJsonToEmis(List emiList) {
    return emiList
        .map((json) => EmiEntity.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }
}
