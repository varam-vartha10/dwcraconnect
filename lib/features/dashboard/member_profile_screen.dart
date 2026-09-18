import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/dwcra_logo.dart';
import '../../core/utils/logout_dialog.dart';
import '../../core/providers/data_provider.dart';

class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    final member = ref.watch(currentMemberProvider);
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      const DwcraLogo(size: 100),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? l10n.member,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.phoneNumber ?? l10n.mobileNumber,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, l10n.personalInfo),
                      _buildInfoCard([
                        _buildInfoTile(
                          context,
                          Icons.phone_android_rounded,
                          l10n.mobileNumber,
                          user?.phoneNumber ?? 'N/A',
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: AppColors.primaryPurple,
                            ),
                            onPressed: () => _showEditPhoneDialog(context, ref, user?.phoneNumber ?? ''),
                          ),
                        ),
                        _buildInfoTile(
                          context,
                          Icons.credit_card_rounded,
                          l10n.aadhaarMasked,
                          member?.aadhaar ?? '**** **** 1234',
                        ),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionHeader(context, l10n.groupInfo),
                      _buildInfoCard([
                        _buildInfoTile(
                          context,
                          Icons.group_work_rounded,
                          l10n.shgGroup,
                          member?.shgGroup ?? 'Saraswati SHG',
                        ),
                        _buildInfoTile(
                          context,
                          Icons.location_city_rounded,
                          l10n.village,
                          member?.village ?? 'Gudlavalleru',
                        ),
                      ]),

                      const SizedBox(height: 32),

                      // Actions
                      _buildActionTile(
                        context,
                        Icons.lock_reset_rounded,
                        l10n.changePassword,
                        AppColors.secondaryPink,
                        () => _showChangePasswordDialog(context, ref),
                      ),
                      const SizedBox(height: 12),
                      _buildActionTile(
                        context,
                        Icons.settings_outlined,
                        l10n.settings,
                        AppColors.primaryPurple,
                        () => context.push('/settings'),
                      ),
                      const SizedBox(height: 12),
                      _buildActionTile(
                        context,
                        Icons.language_rounded,
                        l10n.changeLanguage,
                        AppColors.trustBlue,
                        () => context.push('/language-selection'),
                      ),
                      const SizedBox(height: 12),
                      _buildActionTile(
                        context,
                        Icons.logout_rounded,
                        l10n.logout,
                        Colors.redAccent,
                        () => LogoutDialog.show(context),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (authState.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _showEditPhoneDialog(BuildContext context, WidgetRef ref, String currentPhone) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentPhone);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.mobileNumber),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(hintText: l10n.enterPhoneHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authProvider.notifier).updateProfile(phoneNumber: controller.text);
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentController = TextEditingController();
    final newController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changePassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Current Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: InputDecoration(hintText: l10n.enterPasswordHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await ref.read(authProvider.notifier).changePassword(
                currentController.text, 
                newController.text
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Password updated successfully' : 'Failed to change password'),
                    backgroundColor: success ? AppColors.successGreen : Colors.redAccent,
                  ),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(child: Column(children: children));
  }

  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryPurple, size: 24),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: trailing,
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
