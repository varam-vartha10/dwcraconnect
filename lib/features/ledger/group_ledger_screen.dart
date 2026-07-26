import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';

class GroupLedgerScreen extends StatelessWidget {
  const GroupLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Mock Data for Group Ledger
    const double totalDistributed = 1500000.0;
    const double totalRepaid = 950000.0;
    const double repaymentRate = (totalRepaid / totalDistributed);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groupLedger),
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
            // Repayment Analytics Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      l10n.groupRepaymentProgress,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 160,
                          width: 160,
                          child: CircularProgressIndicator(
                            value: repaymentRate,
                            strokeWidth: 14,
                            backgroundColor: AppColors.background,
                            color: AppColors.successGreen,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${(repaymentRate * 100).toInt()}%',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.successGreen,
                              ),
                            ),
                            Text(
                              l10n.repaid,
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Summary Cards
            _buildSummaryCard(
              context,
              l10n.totalLoanDistributed,
              '₹15,00,000',
              Icons.account_balance_rounded,
              AppColors.trustBlue,
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(
              context,
              l10n.totalLoanRepaid,
              '₹9,50,000',
              Icons.assignment_turned_in_rounded,
              AppColors.successGreen,
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(
              context,
              l10n.outstandingAmount,
              '₹5,50,000',
              Icons.pending_actions_rounded,
              AppColors.secondaryPink,
            ),
            
            const SizedBox(height: 32),
            
            // Monthly Trend Chart (Simplified using Bars)
            Text(
              l10n.monthlyCollectionTrend,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTrendBar(l10n.june, 0.9, '₹1.2L'),
                    const SizedBox(height: 12),
                    _buildTrendBar(l10n.may, 0.8, '₹1.1L'),
                    const SizedBox(height: 12),
                    _buildTrendBar(l10n.april, 0.75, '₹1.0L'),
                    const SizedBox(height: 12),
                    _buildTrendBar(l10n.march, 0.85, '₹1.15L'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        subtitle: Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  Widget _buildTrendBar(String month, double percentage, String amount) {
    return Row(
      children: [
        SizedBox(width: 50, child: Text(month, style: const TextStyle(fontWeight: FontWeight.bold))),
        const SizedBox(width: 12),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: AppColors.background,
            color: AppColors.primaryPurple,
          ),
        ),
        const SizedBox(width: 12),
        Text(amount, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
