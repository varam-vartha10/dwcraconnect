import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
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
        'phoneNumber': phoneNumber.trim(),
        'password': password,
      },
    );

    if (response['success'] != true || response['user'] == null) {
      throw Exception(response['message'] ?? 'Login failed');
    }

    final userData = Map<String, dynamic>.from(response['user']);
    final token = response['token'];

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static UserEntity _mapToEntity(Map<String, dynamic> data) {
    return UserEntity(
      id: data['userId'] ?? '',
      groupId: data['groupId'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      role: _parseRole(data['role']),
      position: _parsePosition(data['position']),
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
