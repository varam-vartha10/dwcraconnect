import '../../core/network/api_service.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionRepository {
  Future<List<TransactionEntity>> getTransactions({
    String? memberId,
    String? groupId,
    int page = 1,
    int limit = 20,
  }) async {
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
      return txs.map((t) {
        final txId = t['transactionId'] ?? '';
        final notes = t['notes'] as String?;
        final rawType = t['type'] ?? 'loan_payment';
        final status = t['status'] ?? 'completed';

        return TransactionEntity(
          id: txId,
          transactionId: txId,
          loanId: t['loanId'] ?? '',
          emiId: t['emiId'] ?? '',
          memberName: t['memberName'] ?? 'Member',
          description: (notes != null && notes.isNotEmpty) ? notes : rawType,
          amount: (t['amount'] as num).toDouble(),
          date: DateTime.parse(t['paymentDate']),
          type: rawType == 'loan_payment' || rawType == 'savings_withdrawal' ? 'Debit' : 'Credit',
          rawType: rawType,
          status: status,
          installmentNumber: t['installmentNumber'] as int?,
        );
      }).toList();
    }
    return [];
  }
}
