import '../../core/network/api_service.dart';
import '../../core/network/cache_service.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionRepository {
  Future<List<TransactionEntity>> getTransactions({
    String? memberId,
    String? groupId,
    int page = 1,
    int limit = 20,
  }) async {
    final cacheKey = 'txs_${memberId ?? groupId ?? "all"}';
    final activeUser = memberId ?? await CacheService.getActiveUser() ?? 'guest';

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (memberId != null && memberId.isNotEmpty) queryParams['memberId'] = memberId;
      if (groupId != null && groupId.isNotEmpty) queryParams['groupId'] = groupId;

      final uri = Uri(path: '/transactions', queryParameters: queryParams);
      final response = await ApiService.get(uri.toString());

      if (response['success'] == true) {
        final List txs = response['transactions'] ?? [];
        await CacheService.save(
          userId: activeUser,
          key: cacheKey,
          data: txs,
          groupId: groupId,
        );
        return _mapJsonToTxs(txs);
      }
    } catch (_) {
      final cached = await CacheService.get(userId: activeUser, key: cacheKey);
      if (cached != null && cached['data'] is List) {
        return _mapJsonToTxs(cached['data'] as List);
      }
      rethrow;
    }
    return [];
  }

  List<TransactionEntity> _mapJsonToTxs(List txs) {
    return txs.map((t) {
      final map = Map<String, dynamic>.from(t as Map);
      final txId = map['transactionId'] ?? '';
      final notes = map['notes'] as String?;
      final rawType = map['type'] ?? 'loan_payment';
      final status = map['status'] ?? 'completed';

      return TransactionEntity(
        id: txId,
        transactionId: txId,
        loanId: map['loanId'] ?? '',
        emiId: map['emiId'] ?? '',
        memberName: map['memberName'] ?? 'Member',
        description: (notes != null && notes.isNotEmpty) ? notes : rawType,
        amount: ((map['amount'] ?? 0) as num).toDouble(),
        date: DateTime.parse(map['paymentDate'] ?? map['createdAt'] ?? DateTime.now().toIso8601String()),
        type: rawType == 'loan_payment' || rawType == 'savings_withdrawal' ? 'Debit' : 'Credit',
        rawType: rawType,
        status: status,
        installmentNumber: map['installmentNumber'] as int?,
      );
    }).toList();
  }
}
