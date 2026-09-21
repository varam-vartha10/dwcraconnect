import '../../core/network/api_service.dart';
import '../../domain/entities/loan_entity.dart';

class LoanRepository {
  Future<List<LoanEntity>> getLoans({String? memberId, String? groupId}) async {
    String endpoint = '/loans';
    if (memberId != null) endpoint += '?memberId=$memberId';
    if (groupId != null) endpoint += '?groupId=$groupId';

    final response = await ApiService.get(endpoint);
    if (response['success'] == true) {
      final List loans = response['loans'] ?? [];
      return loans.map((l) => LoanEntity(
        id: l['loanId'] ?? '',
        memberName: l['memberName'] ?? 'Member',
        totalAmount: (l['principalAmount'] as num).toDouble(),
        remainingAmount: (l['remainingAmount'] ?? l['principalAmount'] as num).toDouble(),
        status: l['status'] ?? 'pending',
        interestRate: (l['interestRate'] as num).toDouble(),
        type: l['loanType'] ?? 'SHG Bank Linkage',
      )).toList();
    }
    return [];
  }
}
