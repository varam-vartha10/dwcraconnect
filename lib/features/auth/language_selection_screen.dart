import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../domain/entities/user_entity.dart';
import '../../core/widgets/dwcra_logo.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  String _selectedLanguage = 'en';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              // App Logo at Top
              const Center(
                child: DwcraLogo(
                  size: 150,
                  isCircular: true,
                ),
              ),
              const SizedBox(height: 40),
              // Screen Title
              Text(
                l10n.chooseLanguage,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.selectLanguageToContinue,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              // Language Cards
              _buildLanguageCard(
                title: l10n.english,
                subtitle: 'Modern & Global',
                languageCode: 'en',
                icon: Icons.language_rounded,
              ),
              const SizedBox(height: 20),
              _buildLanguageCard(
                title: l10n.telugu,
                subtitle: 'మాతృభాష & సులభం',
                languageCode: 'te',
                icon: Icons.translate_rounded,
              ),
              const Spacer(),
              // Continue Button
              Container(
                margin: const EdgeInsets.only(bottom: 40),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    // Save language selection locally
                    await ref.read(localeProvider.notifier).setLocale(Locale(_selectedLanguage));
                    
                    if (!mounted) return;
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.languageChanged),
                        backgroundColor: AppColors.successGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    // Redirect logic: if logged in, go to dashboard, else login
                    final authState = ref.read(authProvider);
                    if (authState.user != null) {
                      if (authState.user!.role == UserRole.leader) {
                        context.go('/leader-dashboard');
                      } else {
                        context.go('/member-dashboard');
                      }
                    } else {
                      context.go('/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: Text(
                    l10n.continueBtn,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required String title,
    required String subtitle,
    required String languageCode,
    required IconData icon,
  }) {
    final isSelected = _selectedLanguage == languageCode;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = languageCode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : Colors.grey.shade200,
            width: 2.5,
          ),
          // Glow effect for selected option
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 4,
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primaryPurple.withValues(alpha: 0.1)
                    : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isSelected ? AppColors.primaryPurple : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryPurple,
                size: 32,
              ),
          ],
        ),
      ),
    );
  }
}
