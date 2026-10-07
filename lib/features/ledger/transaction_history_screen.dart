import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/data_provider.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/user_entity.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    final transactionsAsync = user?.role == UserRole.member
        ? ref.watch(memberTransactionsProvider)
        : ref.watch(transactionsProvider);

    final filterOptions = {
      'all': l10n.all,
      'credit': l10n.credit,
      'debit': l10n.debit,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(transactionsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchTransactions,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterOptions.entries.map((entry) {
                      final isSelected = _selectedFilter == entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          onSelected: (bool value) {
                            setState(() {
                              _selectedFilter = entry.key;
                            });
                          },
                          selectedColor: AppColors.primaryPurple.withValues(
                            alpha: 0.2,
                          ),
                          checkmarkColor: AppColors.primaryPurple,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.date,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      l10n.amount,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                final filteredTransactions = transactions.where((tx) {
                  final matchesSearch = tx.description.toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      ) ||
                      tx.transactionId.toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      );
                  final matchesFilter = _selectedFilter == 'all' ||
                      tx.type.toLowerCase() == _selectedFilter;
                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredTransactions.isEmpty) {
                  return Center(child: Text(l10n.noRecentActivity));
                }

                return ListView.separated(
                  itemCount: filteredTransactions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = filteredTransactions[index];
                    final isCredit = tx.type == 'Credit';

                    return InkWell(
                      onTap: () => _showTransactionDetailsSheet(context, tx),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                DateFormat('dd MMM yyyy').format(tx.date),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                tx.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${isCredit ? '+' : '-'} ₹${tx.amount.toInt().abs()}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCredit
                                        ? AppColors.fieldGreen
                                        : Colors.redAccent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetailsSheet(
    BuildContext context,
    TransactionEntity tx,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
              'Transaction Statement Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 16),
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
                    'Transaction ID',
                    tx.transactionId.isNotEmpty ? tx.transactionId : 'N/A',
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    'Payment Date',
                    DateFormat('dd MMM yyyy, hh:mm a').format(tx.date),
                  ),
                  const Divider(height: 16),
                  _buildDetailRow('Description', tx.description),
                  if (tx.installmentNumber != null) ...[
                    const Divider(height: 16),
                    _buildDetailRow('Installment', '#${tx.installmentNumber}'),
                  ],
                  if (tx.loanId.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow('Loan Reference', tx.loanId),
                  ],
                  const Divider(height: 16),
                  _buildDetailRow(
                    'Status',
                    tx.status.toUpperCase(),
                    color: AppColors.fieldGreen,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    'Amount',
                    '₹${tx.amount.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Close',
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
            fontSize: isBold ? 15 : 13,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
