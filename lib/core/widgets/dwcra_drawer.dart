import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../utils/logout_dialog.dart';
import 'dwcra_logo.dart';
import '../../domain/entities/user_entity.dart';

class DwcraDrawer extends ConsumerWidget {
  const DwcraDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final l10n = AppLocalizations.of(context)!;

    String positionLabel = l10n.member;
    if (user?.position == UserPosition.president) {
      positionLabel = l10n.president;
    } else if (user?.position == UserPosition.secretary) {
      positionLabel = l10n.secretary;
    }

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Row(
              children: [
                const DwcraLogo(size: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? l10n.member,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        positionLabel.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_rounded, color: AppColors.primaryPurple),
            title: Text(l10n.dashboard),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_rounded, color: AppColors.primaryPurple),
            title: Text(l10n.settings),
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.language_rounded, color: AppColors.primaryPurple),
            title: Text(l10n.changeLanguage),
            onTap: () {
              Navigator.pop(context);
              context.push('/language-selection');
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text(l10n.logout, style: const TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              LogoutDialog.show(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
