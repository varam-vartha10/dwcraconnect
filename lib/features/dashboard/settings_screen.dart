import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSettingsSection(context, l10n.personalInfo, [
              _buildSettingsTile(
                context,
                Icons.language_rounded,
                l10n.changeLanguage,
                onTap: () => context.push('/language-selection'),
              ),
              _buildSwitchTile(
                context,
                Icons.dark_mode_rounded,
                l10n.darkMode,
                isDarkMode,
                (value) => ref.read(themeProvider.notifier).toggleTheme(value),
              ),
            ]),
            _buildSettingsSection(context, l10n.notificationSettings, [
              _buildSwitchTile(
                context,
                Icons.notifications_active_rounded,
                l10n.notifications,
                _notificationsEnabled,
                (value) => setState(() => _notificationsEnabled = value),
              ),
            ]),
            _buildSettingsSection(context, l10n.securitySettings, [
              _buildSettingsTile(
                context,
                Icons.lock_outline_rounded,
                l10n.securitySettings,
                onTap: () {},
              ),
              _buildSettingsTile(
                context,
                Icons.cloud_upload_outlined,
                l10n.backupRestore,
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 32),
            Text('${l10n.appVersion}: 1.0.0', style: theme.textTheme.bodySmall),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryPurple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryPurple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primaryPurple,
      ),
    );
  }
}
