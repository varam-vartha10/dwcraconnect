import '../../core/network/api_service.dart';
import '../../domain/entities/subsidy_entity.dart';

class SubsidyRepository {
  Future<List<SubsidyEntity>> getSubsidies({String? memberId, String? groupId}) async {
    String endpoint = '/subsidies';
    if (memberId != null) endpoint += '?memberId=$memberId';
    if (groupId != null) endpoint += '?groupId=$groupId';

    final response = await ApiService.get(endpoint);
    if (response['success'] == true) {
      final List subsidies = response['subsidies'] ?? [];
      return subsidies.map((s) => SubsidyEntity(
        id: s['subsidyId'] ?? '',
        schemeName: s['schemeName'] ?? '',
        memberName: s['memberName'] ?? 'Member',
        amount: (s['amount'] as num).toDouble(),
        receivedDate: s['dateReceived'] != null ? DateTime.parse(s['dateReceived']) : DateTime.now(),
        status: s['status'] ?? 'pending',
      )).toList();
    }
    return [];
  }
}
