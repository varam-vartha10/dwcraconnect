import '../../core/network/api_service.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications() async {
    final response = await ApiService.get('/notifications');
    if (response['success'] == true) {
      final List notifications = response['notifications'] ?? [];
      return notifications.map((n) => NotificationEntity(
        id: n['notificationId'] ?? '',
        title: n['title'] ?? '',
        message: n['message'] ?? '',
        category: n['type'] ?? 'other',
        time: _formatTime(DateTime.parse(n['createdAt'])),
        isRead: n['isRead'] ?? false,
      )).toList();
    }
    return [];
  }

  String _formatTime(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year}";
  }
}
