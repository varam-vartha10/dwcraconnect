import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';

class EmiDetailsScreen extends StatelessWidget {
  const EmiDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Mock Data for EMI
    const String emiAmount = "₹1,200";
    const String nextDueDate = "05 July 2026";
    const int remainingEmis = 24;
    const int totalEmis = 36;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emiDetails),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Next EMI Highlight Card
            Card(
              elevation: 8,
              shadowColor: AppColors.secondaryPink.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondaryPink, Color(0xFFAD1457)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.nextEmi,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      emiAmount,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${l10n.dueDate}: $nextDueDate',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // EMI Schedule Summary
            Text(
              l10n.repaymentSchedule,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildScheduleInfoCard(
              context,
              l10n.remainingEmis,
              '$remainingEmis of $totalEmis',
              Icons.timelapse_rounded,
              AppColors.primaryPurple,
            ),
            _buildScheduleInfoCard(
              context,
              l10n.interestRate,
              '0% (Interest Subvention)',
              Icons.star_rounded,
              AppColors.successGreen,
            ),
            
            const SizedBox(height: 24),
            
            // Helpful Reminder Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.trustBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.trustBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.trustBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.timelyRepaymentTip,
                      style: const TextStyle(color: AppColors.trustBlue, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Payment History / Back Action
            OutlinedButton(
              onPressed: () => context.pop(),
              child: Text(l10n.backToDashboard),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleInfoCard(BuildContext context, String title, String value, IconData icon, Color iconColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          trailing: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
