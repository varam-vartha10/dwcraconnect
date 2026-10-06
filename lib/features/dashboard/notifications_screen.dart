import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/data_provider.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          TextButton(
            onPressed: () {
              ref.invalidate(notificationsProvider);
            },
            child: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.noNotifications),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification, l10n, ref);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationEntity n,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    Color categoryColor;
    IconData categoryIcon;

    switch (n.category) {
      case 'emi_upcoming':
      case 'emi_reminder':
        categoryColor = AppColors.shgTeal;
        categoryIcon = Icons.event_note_rounded;
        break;
      case 'emi_due':
        categoryColor = AppColors.harvestGold;
        categoryIcon = Icons.warning_amber_rounded;
        break;
      case 'emi_overdue':
        categoryColor = AppColors.lotusPink;
        categoryIcon = Icons.error_outline_rounded;
        break;
      case 'payment_success':
      case 'payment_confirmation':
        categoryColor = AppColors.fieldGreen;
        categoryIcon = Icons.check_circle_outline_rounded;
        break;
      case 'subsidy_update':
      case 'gov_scheme':
        categoryColor = AppColors.fieldGreen;
        categoryIcon = Icons.savings_rounded;
        break;
      case 'loan_update':
        categoryColor = AppColors.indigo;
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
                color: categoryColor.withValues(alpha: 0.1),
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
                    color: AppColors.lotusPink,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          n.title,
          style: TextStyle(
            fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              n.message,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              n.time,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        onTap: () async {
          if (!n.isRead) {
            n.isRead = true;
            await ref.read(notificationRepositoryProvider).markAsRead(n.id);
            ref.invalidate(notificationsProvider);
          }
        },
      ),
    );
  }
}
