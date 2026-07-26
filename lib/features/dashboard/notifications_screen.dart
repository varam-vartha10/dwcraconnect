import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/data_provider.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _markAllRead(WidgetRef ref) {
    final notifications = ref.read(notificationsProvider);
    ref.read(notificationsProvider.notifier).state = notifications.map((n) {
      n.isRead = true;
      return n;
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(ref),
            child: Text(
              l10n.markAllRead,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(l10n.noNotifications),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification, l10n, ref);
              },
            ),
    );
  }

  Widget _buildNotificationCard(NotificationEntity n, AppLocalizations l10n, WidgetRef ref) {
    Color categoryColor;
    IconData categoryIcon;

    switch (n.category) {
      case 'EMI Reminder':
        categoryColor = AppColors.secondaryPink;
        categoryIcon = Icons.event_note_rounded;
        break;
      case 'Govt Scheme':
        categoryColor = AppColors.successGreen;
        categoryIcon = Icons.account_balance_rounded;
        break;
      case 'Loan Update':
        categoryColor = AppColors.trustBlue;
        categoryIcon = Icons.monetization_on_rounded;
        break;
      default:
        categoryColor = AppColors.primaryPurple;
        categoryIcon = Icons.notifications_rounded;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: n.isRead ? 1 : 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(categoryIcon, color: categoryColor),
            ),
            if (!n.isRead)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryPink,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          n.title,
          style: TextStyle(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(n.message, style: TextStyle(color: AppColors.textPrimary.withOpacity(0.8))),
            const SizedBox(height: 8),
            Text(n.time, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        onTap: () {
          final notifications = ref.read(notificationsProvider);
          ref.read(notificationsProvider.notifier).state = notifications.map((item) {
            if (item.id == n.id) item.isRead = true;
            return item;
          }).toList();
        },
      ),
    );
  }
}
