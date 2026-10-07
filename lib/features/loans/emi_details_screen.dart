import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/data_provider.dart';
import '../../core/providers/dashboard_provider.dart';
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
          final sortedEmis = List<EmiEntity>.from(
            emis,
          )..sort((a, b) => a.installmentNumber.compareTo(b.installmentNumber));

          // Find next pending EMI
          final hasUnpaid = sortedEmis.any((e) => e.status != 'paid');
          final nextEmi = hasUnpaid
              ? sortedEmis.firstWhere((e) => e.status != 'paid')
              : sortedEmis.last;

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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: hasUnpaid
                            ? [AppColors.secondaryPink, const Color(0xFFAD1457)]
                            : [AppColors.fieldGreen, const Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Text(
                          hasUnpaid ? l10n.nextEmi : 'All EMIs Paid',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
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
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${l10n.dueDate}: ${DateFormat('dd MMM yyyy').format(nextEmi.dueDate)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasUnpaid) ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryPurple,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              icon: const Icon(Icons.payment_rounded),
                              label: const Text(
                                'Pay EMI Now',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: () => _showPaymentConfirmationSheet(
                                context,
                                ref,
                                nextEmi,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // EMI Schedule Summary
                Text(
                  l10n.repaymentSchedule,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                  '7% (${l10n.yearly})',
                  Icons.star_rounded,
                  AppColors.fieldGreen,
                ),

                const SizedBox(height: 24),

                // Helpful Reminder Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.trustBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.trustBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.trustBlue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.timelyRepaymentTip,
                          style: const TextStyle(
                            color: AppColors.trustBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Installment List Header
                Text(
                  'Installment Tracker ($paidEmis/$totalEmis)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                          backgroundColor: isPaid
                              ? AppColors.fieldGreen.withValues(alpha: 0.1)
                              : AppColors.background,
                          child: Text(
                            '${emi.installmentNumber}',
                            style: TextStyle(
                              color: isPaid
                                  ? AppColors.fieldGreen
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        title: Text('₹${emi.amount.toInt()}'),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy').format(emi.dueDate),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  emi.status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                emi.status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(emi.status),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!isPaid) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: AppColors.primaryPurple,
                                ),
                                onPressed: () => _showPaymentConfirmationSheet(
                                  context,
                                  ref,
                                  emi,
                                ),
                              ),
                            ],
                          ],
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

  void _showPaymentConfirmationSheet(
    BuildContext context,
    WidgetRef ref,
    EmiEntity emi,
  ) {
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Confirm EMI Payment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please review the payment details before proceeding:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Installment',
                          '#${emi.installmentNumber}',
                        ),
                        const Divider(height: 16),
                        _buildDetailRow(
                          'Due Date',
                          DateFormat('dd MMM yyyy').format(emi.dueDate),
                        ),
                        const Divider(height: 16),
                        _buildDetailRow(
                          'Status',
                          emi.status.toUpperCase(),
                          color: emi.status == 'overdue'
                              ? Colors.redAccent
                              : Colors.orange,
                        ),
                        const Divider(height: 16),
                        _buildDetailRow(
                          'Payable Amount',
                          '₹${emi.amount.toStringAsFixed(2)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isProcessing
                          ? null
                          : () async {
                              setState(() {
                                isProcessing = true;
                              });

                              try {
                                final repo = ref.read(emiRepositoryProvider);
                                final res = await repo.payEmi(
                                  emiId: emi.id,
                                  amount: emi.amount,
                                );

                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext); // Close sheet
                                }

                                // Refresh Riverpod state
                                ref.invalidate(emisProvider);
                                ref.invalidate(loansProvider);
                                ref.invalidate(transactionsProvider);
                                ref.invalidate(notificationsProvider);
                                ref.invalidate(dashboardSummaryProvider);
                                ref.invalidate(membersProvider);

                                if (context.mounted) {
                                  _showPaymentSuccessDialog(context, res, emi);
                                }
                              } catch (e) {
                                setState(() {
                                  isProcessing = false;
                                });
                                final errorMsg = e
                                    .toString()
                                    .replaceAll('Exception: ', '');
                                if (context.mounted) {
                                  _showErrorDialog(context, errorMsg);
                                }
                              }
                            },
                      child: isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Confirm & Pay Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentSuccessDialog(
    BuildContext context,
    Map<String, dynamic> response,
    EmiEntity emi,
  ) {
    final txnId = response['transactionId'] ??
        (response['transaction']?['transactionId'] ?? 'N/A');
    final remaining = response['remainingBalance'] ??
        response['loan']?['remainingAmount'] ??
        0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.fieldGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.fieldGreen,
                size: 60,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Confirmed!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Installment #${emi.installmentNumber} payment of ₹${emi.amount.toStringAsFixed(2)} was successfully processed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Transaction ID', txnId),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Updated Balance',
                    '₹${(remaining as num).toInt()}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.fieldGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Payment Failed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 16 : 13,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.fieldGreen;
      case 'overdue':
        return Colors.redAccent;
      case 'pending':
        return Colors.orange;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildScheduleInfoCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
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
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
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
      ),
    );
  }
}
