import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _activeUserKey = 'active_cached_user';

  static String _buildKey(String userId, String key) {
    return 'cache_${userId}_$key';
  }

  static Future<void> setActiveUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeUserKey, userId);
  }

  static Future<String?> getActiveUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeUserKey);
  }

  static Future<void> save({
    required String userId,
    required String key,
    required dynamic data,
    String? groupId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullKey = _buildKey(userId, key);

      final payload = {
        'userId': userId,
        'groupId': groupId ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'lastSyncedIso': DateTime.now().toIso8601String(),
        'data': data,
      };

      await prefs.setString(fullKey, jsonEncode(payload));
      await prefs.setString(_activeUserKey, userId);
    } catch (e) {
      if (kDebugMode) print('Cache save error for $key: $e');
    }
  }

  static Future<Map<String, dynamic>?> get({
    required String userId,
    required String key,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullKey = _buildKey(userId, key);
      final raw = prefs.getString(fullKey);

      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded['userId'] != userId) return null; // Scope security check

      return decoded;
    } catch (e) {
      if (kDebugMode) print('Cache read error for $key: $e');
      return null;
    }
  }

  static Future<void> clearUserCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final prefix = 'cache_${userId}_';

      for (final k in keys) {
        if (k.startsWith(prefix)) {
          await prefs.remove(k);
        }
      }

      final active = prefs.getString(_activeUserKey);
      if (active == userId) {
        await prefs.remove(_activeUserKey);
      }
    } catch (e) {
      if (kDebugMode) print('Cache clear error: $e');
    }
  }
}

class CacheResult<T> {
  final T data;
  final bool isOffline;
  final DateTime? lastSyncedAt;

  CacheResult({
    required this.data,
    required this.isOffline,
    this.lastSyncedAt,
  });
}
