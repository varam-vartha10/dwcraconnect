class NotificationEntity {
  final String id;
  final String title;
  final String message;
  final String category;
  final String time;
  bool isRead;

  NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.time,
    this.isRead = false,
  });
}
