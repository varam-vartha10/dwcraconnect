import '../../core/network/api_service.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionRepository {
  Future<List<TransactionEntity>> getTransactions({String? memberId, String? groupId}) async {
    String endpoint = '/transactions';
    if (memberId != null) endpoint += '?memberId=$memberId';
    if (groupId != null) endpoint += '?groupId=$groupId';

    final response = await ApiService.get(endpoint);
    if (response['success'] == true) {
      final List txs = response['transactions'] ?? [];
      return txs.map((t) => TransactionEntity(
        id: t['transactionId'] ?? '',
        memberName: t['memberName'] ?? 'Member',
        description: t['notes'] ?? t['type'] ?? 'Transaction',
        amount: (t['amount'] as num).toDouble(),
        date: DateTime.parse(t['paymentDate']),
        type: t['type'] == 'loan_payment' || t['type'] == 'savings_withdrawal' ? 'Debit' : 'Credit',
      )).toList();
    }
    return [];
  }
}
