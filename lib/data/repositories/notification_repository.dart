import '../../core/network/api_service.dart';
import '../../core/network/cache_service.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications() async {
    final activeUser = await CacheService.getActiveUser() ?? 'guest';
    const cacheKey = 'notifications';

    try {
      final response = await ApiService.get('/notifications');
      if (response['success'] == true) {
        final List notifications = response['notifications'] ?? [];
        await CacheService.save(
          userId: activeUser,
          key: cacheKey,
          data: notifications,
        );
        return _mapJsonToNotifs(notifications);
      }
    } catch (_) {
      final cached = await CacheService.get(userId: activeUser, key: cacheKey);
      if (cached != null && cached['data'] is List) {
        return _mapJsonToNotifs(cached['data'] as List);
      }
      rethrow;
    }
    return [];
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await ApiService.patch('/notifications/$notificationId/read', {});
      return response['success'] == true;
    } catch (_) {
      return false;
    }
  }

  List<NotificationEntity> _mapJsonToNotifs(List notifications) {
    return notifications.map((n) {
      final map = Map<String, dynamic>.from(n as Map);
      return NotificationEntity(
        id: map['notificationId'] ?? '',
        title: map['title'] ?? '',
        message: map['message'] ?? '',
        category: map['type'] ?? 'other',
        time: _formatTime(DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String())),
        isRead: map['isRead'] ?? false,
      );
    }).toList();
  }

  String _formatTime(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year}";
  }
}
