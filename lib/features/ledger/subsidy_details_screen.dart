import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';

class SubsidyDetailsScreen extends StatelessWidget {
  const SubsidyDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Mock Data for Subsidies
    final List<Map<String, dynamic>> subsidies = [
      {
        'scheme': 'Vaddi Leni Runalu (Zero Interest)',
        'amount': '₹450.00',
        'date': '15 May 2026',
        'status': l10n.received,
      },
      {
        'scheme': 'SHG Empowerment Scheme',
        'amount': '₹15,000.00',
        'date': '10 April 2026',
        'status': l10n.received,
      },
      {
        'scheme': 'PMAY-G Subsidy',
        'amount': '₹1,20,000.00',
        'date': '01 March 2026',
        'status': l10n.received,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subsidyDetails),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subsidies.length,
        itemBuilder: (context, index) {
          final item = subsidies[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['scheme'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item['status'],
                          style: const TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(l10n.subsidyAmount, item['amount'], theme),
                  const SizedBox(height: 8),
                  _buildDetailRow(l10n.receivedDate, item['date'], theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
