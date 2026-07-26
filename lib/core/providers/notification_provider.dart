import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_entity.dart';
import '../../data/repositories/mock_repository.dart';

class NotificationNotifier extends StateNotifier<List<NotificationEntity>> {
  NotificationNotifier() : super(MockRepository.notifications);

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id)
          NotificationEntity(
            id: n.id,
            title: n.title,
            message: n.message,
            category: n.category,
            time: n.time,
            isRead: true,
          )
        else
          n,
    ];
  }

  void markAllRead() {
    state = [
      for (final n in state)
        NotificationEntity(
          id: n.id,
          title: n.title,
          message: n.message,
          category: n.category,
          time: n.time,
          isRead: true,
        ),
    ];
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<NotificationEntity>>((ref) {
  return NotificationNotifier();
});
