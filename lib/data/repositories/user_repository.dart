import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/member_entity.dart';
import '../../core/network/api_service.dart';
import '../../core/network/cache_service.dart';

class UserRepository {
  static Future<UserEntity> login(
    String phoneNumber,
    String password,
  ) async {
    // 1. Safe normalization: Trim and remove common artifacts, but don't be over-restrictive
    final cleanPhone = phoneNumber.trim();

    // 2. Call the API
    final response = await ApiService.post(
      '/auth/login',
      {
        'phoneNumber': cleanPhone,
        'password': password,
      },
    );

    // 3. Verify response
    if (response['success'] != true || response['user'] == null) {
      throw Exception(response['message'] ?? 'Login failed');
    }

    final userData = Map<String, dynamic>.from(response['user']);
    final token = response['token'];

    // 4. Persistence
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      
      // Cache in-memory token to speed up subsequent requests
      ApiService.setToken(token);
    }

    if (userData['userId'] != null) {
      await CacheService.setActiveUser(userData['userId']);
    }

    return _mapToEntity(userData);
  }

  static Future<UserEntity?> getProfile() async {
    try {
      final response = await ApiService.get('/auth/me');
      
      if (response['success'] == true && response['user'] != null) {
        return _mapToEntity(Map<String, dynamic>.from(response['user']));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<UserEntity> updateProfile({
    String? name,
    String? phoneNumber,
    String? village,
    String? aadhaar,
  }) async {
    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (village != null) body['village'] = village;
    if (aadhaar != null) body['aadhaar'] = aadhaar;

    final response = await ApiService.patch('/users/profile', body);
    
    if (response['success'] == true && response['user'] != null) {
      return _mapToEntity(Map<String, dynamic>.from(response['user']));
    }
    throw Exception(response['message'] ?? 'Update failed');
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await ApiService.post('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Password change failed');
    }
  }

  static Future<void> logout() async {
    final activeUser = await CacheService.getActiveUser();
    if (activeUser != null) {
      await CacheService.clearUserCache(activeUser);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await ApiService.clearCache();
  }

  static UserEntity _mapToEntity(Map<String, dynamic> data) {
    return UserEntity(
      id: data['userId'] ?? '',
      groupId: data['groupId'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      role: _parseRole(data['role']),
      position: _parsePosition(data['position']),
      village: data['village'],
      aadhaar: data['aadhaar'],
    );
  }

  static Future<List<UserModel>> getUsersByGroup(
    String groupId,
  ) async {
    final response = await ApiService.get(
      '/users/group/$groupId',
    );

    if (response['success'] != true) {
      throw Exception(
        response['message'] ?? 'Failed to fetch group members',
      );
    }

    final List usersJson = response['users'] ?? [];

    return usersJson
        .map(
          (json) => UserModel.fromJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList();
  }

  static Future<List<MemberEntity>> getGroupMembersSummary(String groupId) async {
    final activeUser = await CacheService.getActiveUser() ?? 'guest';
    final cacheKey = 'group_members_summary_$groupId';

    try {
      final response = await ApiService.get('/account/groups/$groupId/members/summary');
      
      if (response['success'] == true && response['members'] != null) {
        final List membersJson = response['members'];
        await CacheService.save(
          userId: activeUser,
          key: cacheKey,
          data: membersJson,
          groupId: groupId,
        );
        return _mapJsonToGroupMembers(membersJson, groupId);
      }
    } catch (_) {
      final cached = await CacheService.get(userId: activeUser, key: cacheKey);
      if (cached != null && cached['data'] is List) {
        return _mapJsonToGroupMembers(cached['data'] as List, groupId);
      }
    }

    // Fallback to basic user fetching if summary fails
    final users = await getUsersByGroup(groupId);
    return users.map((u) => MemberEntity(
      id: u.userId,
      name: u.name,
      mobile: u.phoneNumber,
      aadhaar: u.aadhaar ?? '',
      village: u.village ?? '',
      shgGroup: u.groupId,
      loanAmount: 0,
      paidAmount: 0,
      remainingAmount: 0,
      emiAmount: 0,
      subsidyAmount: 0,
    )).toList();
  }

  static List<MemberEntity> _mapJsonToGroupMembers(List membersJson, String groupId) {
    return membersJson.map((json) {
      final data = Map<String, dynamic>.from(json as Map);
      return MemberEntity(
        id: data['userId'] ?? '',
        name: data['name'] ?? '',
        mobile: data['phoneNumber'] ?? '',
        aadhaar: data['aadhaar'] ?? 'XXXX-XXXX-XXXX',
        village: data['village'] ?? '',
        shgGroup: groupId,
        loanAmount: (data['totalPrincipal'] as num?)?.toDouble() ?? 0.0,
        paidAmount: (data['totalPaid'] as num?)?.toDouble() ?? 0.0,
        remainingAmount: (data['remainingBalance'] as num?)?.toDouble() ?? 0.0,
        emiAmount: (data['nextEmiAmount'] as num?)?.toDouble() ?? 0.0,
        subsidyAmount: (data['subsidyAmount'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  static UserRole _parseRole(String? role) {
    if (role == null) return UserRole.unknown;
    final normalizedRole = role.toLowerCase();
    
    switch (normalizedRole) {
      case 'leader':
        return UserRole.leader;
      case 'member':
        return UserRole.member;
      default:
        return UserRole.unknown;
    }
  }

  static UserPosition _parsePosition(String? position) {
    if (position == null) return UserPosition.member;
    final normalizedPos = position.toLowerCase();

    switch (normalizedPos) {
      case 'president':
        return UserPosition.president;
      case 'secretary':
        return UserPosition.secretary;
      case 'member':
        return UserPosition.member;
      default:
        return UserPosition.member;
    }
  }
}
