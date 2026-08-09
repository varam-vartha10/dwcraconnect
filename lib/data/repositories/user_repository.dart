
import '../../domain/entities/user_entity.dart';
import '../../core/network/api_service.dart';

class UserRepository {
  static Future<UserEntity> login(
    String phoneNumber,
    String password,
  ) async {
    final response = await ApiService.post(
      '/auth/login',
      {
        'phoneNumber': phoneNumber,
        'password': password,
      },
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Login failed');
    }

    final userData = Map<String, dynamic>.from(response['user']);

    return UserEntity(
      id: userData['userId'] ?? '',
      groupId: userData['groupId'] ?? '',
      name: userData['name'] ?? '',
      phoneNumber: userData['phoneNumber'] ?? '',
      role: _parseRole(userData['role']),
      position: _parsePosition(userData['position']),
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'leader':
        return UserRole.leader;
      case 'member':
        return UserRole.member;
      default:
        return UserRole.unknown;
    }
  }

  static UserPosition _parsePosition(String? position) {
    switch (position) {
      case 'president':
        return UserPosition.president;
      case 'secretary':
        return UserPosition.secretary;
      default:
        return UserPosition.member;
    }
  }
}