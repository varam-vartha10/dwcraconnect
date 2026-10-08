import '../../core/network/api_service.dart';
import '../../core/network/cache_service.dart';
import '../../domain/entities/loan_entity.dart';

class LoanRepository {
  Future<List<LoanEntity>> getLoans({String? memberId, String? groupId}) async {
    final cacheKey = 'loans_${memberId ?? groupId ?? "all"}';
    final activeUser = memberId ?? await CacheService.getActiveUser() ?? 'guest';

    try {
      String endpoint = '/loans';
      if (memberId != null) endpoint += '?memberId=$memberId';
      if (groupId != null) endpoint += '?groupId=$groupId';

      final response = await ApiService.get(endpoint);
      if (response['success'] == true) {
        final List loansJson = response['loans'] ?? [];
        await CacheService.save(
          userId: activeUser,
          key: cacheKey,
          data: loansJson,
          groupId: groupId,
        );
        return _mapJsonToLoans(loansJson);
      }
    } catch (_) {
      final cached = await CacheService.get(userId: activeUser, key: cacheKey);
      if (cached != null && cached['data'] is List) {
        return _mapJsonToLoans(cached['data'] as List);
      }
      rethrow;
    }
    return [];
  }

  List<LoanEntity> _mapJsonToLoans(List loansJson) {
    return loansJson.map((l) {
      final jsonMap = Map<String, dynamic>.from(l as Map);
      return LoanEntity(
        id: jsonMap['loanId'] ?? '',
        memberName: jsonMap['memberName'] ?? 'Member',
        totalAmount: ((jsonMap['principalAmount'] ?? 0) as num).toDouble(),
        remainingAmount: ((jsonMap['remainingAmount'] ?? jsonMap['principalAmount'] ?? 0) as num).toDouble(),
        status: jsonMap['status'] ?? 'pending',
        interestRate: ((jsonMap['interestRate'] ?? 7.0) as num).toDouble(),
        type: jsonMap['loanType'] ?? 'SHG Bank Linkage',
      );
    }).toList();
  }
}
