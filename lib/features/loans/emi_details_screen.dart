import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/data_provider.dart';
import '../../domain/entities/emi_entity.dart';
import 'package:intl/intl.dart';

class EmiDetailsScreen extends ConsumerWidget {
  const EmiDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final emisAsync = ref.watch(emisProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emiDetails),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: emisAsync.when(
        data: (emis) {
          if (emis.isEmpty) {
            return Center(child: Text(l10n.noRecentActivity));
          }

          // Sort EMIs by installment number
          final sortedEmis = List<EmiEntity>.from(emis)..sort((a, b) => a.installmentNumber.compareTo(b.installmentNumber));
          
          // Find next pending EMI
          final nextEmi = sortedEmis.firstWhere((e) => e.status != 'paid', orElse: () => sortedEmis.last);
          final paidEmis = sortedEmis.where((e) => e.status == 'paid').length;
          final totalEmis = sortedEmis.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Next EMI Highlight Card
                Card(
                  elevation: 8,
                  shadowColor: AppColors.secondaryPink.withValues(alpha: 0.2),
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
                        Text(
                          '₹${nextEmi.amount.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${l10n.dueDate}: ${DateFormat('dd MMM yyyy').format(nextEmi.dueDate)}',
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
                  '${totalEmis - paidEmis} ${l10n.all} $totalEmis',
                  Icons.timelapse_rounded,
                  AppColors.primaryPurple,
                ),
                _buildScheduleInfoCard(
                  context,
                  l10n.interestRate,
                  '7% (${l10n.yearly})', // Map correctly if available
                  Icons.star_rounded,
                  AppColors.successGreen,
                ),
                
                const SizedBox(height: 24),
                
                // Helpful Reminder Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.trustBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.trustBlue.withValues(alpha: 0.3)),
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
                
                const SizedBox(height: 24),

                // Installment List Header
                Text(
                  'Installment Tracker (${paidEmis}/${totalEmis})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedEmis.length,
                  itemBuilder: (context, index) {
                    final emi = sortedEmis[index];
                    final isPaid = emi.status == 'paid';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPaid ? AppColors.successGreen.withValues(alpha: 0.1) : AppColors.background,
                          child: Text('${emi.installmentNumber}', style: TextStyle(color: isPaid ? AppColors.successGreen : AppColors.textPrimary)),
                        ),
                        title: Text('₹${emi.amount.toInt()}'),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(emi.dueDate)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(emi.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            emi.status.toUpperCase(),
                            style: TextStyle(color: _getStatusColor(emi.status), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.backToDashboard),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid': return AppColors.successGreen;
      case 'overdue': return Colors.redAccent;
      case 'pending': return Colors.orange;
      default: return AppColors.textSecondary;
    }
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
              color: iconColor.withValues(alpha: 0.1),
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
