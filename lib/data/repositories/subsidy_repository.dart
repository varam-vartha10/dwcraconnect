import '../../core/network/api_service.dart';
import '../../core/network/cache_service.dart';
import '../../domain/entities/subsidy_entity.dart';

class SubsidyRepository {
  Future<List<SubsidyEntity>> getSubsidies({String? memberId, String? groupId}) async {
    final cacheKey = 'subsidies_${memberId ?? groupId ?? "all"}';
    final activeUser = memberId ?? await CacheService.getActiveUser() ?? 'guest';

    try {
      String endpoint = '/subsidies';
      if (memberId != null) endpoint += '?memberId=$memberId';
      if (groupId != null) endpoint += '?groupId=$groupId';

      final response = await ApiService.get(endpoint);
      if (response['success'] == true) {
        final List subsidies = response['subsidies'] ?? [];
        await CacheService.save(
          userId: activeUser,
          key: cacheKey,
          data: subsidies,
          groupId: groupId,
        );
        return _mapJsonToSubsidies(subsidies);
      }
    } catch (_) {
      final cached = await CacheService.get(userId: activeUser, key: cacheKey);
      if (cached != null && cached['data'] is List) {
        return _mapJsonToSubsidies(cached['data'] as List);
      }
      rethrow;
    }
    return [];
  }

  List<SubsidyEntity> _mapJsonToSubsidies(List subsidies) {
    return subsidies.map((s) {
      final map = Map<String, dynamic>.from(s as Map);
      return SubsidyEntity(
        id: map['subsidyId'] ?? '',
        schemeName: map['schemeName'] ?? '',
        memberName: map['memberName'] ?? 'Member',
        amount: ((map['amount'] ?? 0) as num).toDouble(),
        date: map['dateReceived'] != null ? DateTime.parse(map['dateReceived']) : DateTime.now(),
        status: map['status'] ?? 'pending',
      );
    }).toList();
  }
}
