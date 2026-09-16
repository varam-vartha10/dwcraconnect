import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';

class LoanBalanceScreen extends StatelessWidget {
  const LoanBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Mock Data
    const double totalLoan = 50000.0;
    const double paidAmount = 15000.0;
    const double remainingAmount = totalLoan - paidAmount;
    const double progress = paidAmount / totalLoan;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activeLoans),
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
            // Summary Progress Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient.colors
                        .map((color) => color.withValues(alpha: 0.05))
                        .toList(),
                    begin: AppColors.primaryGradient.begin,
                    end: AppColors.primaryGradient.end,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 150,
                          width: 150,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            backgroundColor: AppColors.background,
                            color: AppColors.primaryPurple,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                            Text(
                              l10n.repaid,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem(
                          l10n.totalLoanAmount,
                          '₹$totalLoan',
                          AppColors.textPrimary,
                        ),
                        _buildSummaryItem(
                          l10n.remainingAmount,
                          '₹$remainingAmount',
                          AppColors.secondaryPink,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Detailed Info Cards
            Text(
              l10n.loanDetails,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildDetailCard(
              Icons.info_outline_rounded,
              l10n.loanStatus,
              l10n.active,
              AppColors.successGreen,
            ),
            _buildDetailCard(
              Icons.category_outlined,
              l10n.loanType,
              l10n.shgBankLinkage,
              AppColors.trustBlue,
            ),
            _buildDetailCard(
              Icons.percent_rounded,
              l10n.interestRate,
              '7% (${l10n.yearly})',
              AppColors.primaryPurple,
            ),
            _buildDetailCard(
              Icons.payments_outlined,
              l10n.paidAmount,
              '₹$paidAmount',
              AppColors.successGreen,
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.primaryPurple,
                side: const BorderSide(color: AppColors.primaryPurple),
                elevation: 0,
              ),
              child: Text(l10n.back),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
