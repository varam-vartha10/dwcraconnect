import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';

class LogoutDialog extends ConsumerWidget {
  const LogoutDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const LogoutDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.logout_rounded, color: Colors.redAccent),
          const SizedBox(width: 12),
          Text(l10n.logout),
        ],
      ),
      content: Text(
        l10n.logoutConfirm,
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.no,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            // Close dialog
            Navigator.pop(context);
            // Perform logout
            ref.read(authProvider.notifier).logout();
            // Navigate to login
            context.go('/login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(80, 40),
          ),
          child: Text(l10n.yes),
        ),
      ],
    );
  }
}
