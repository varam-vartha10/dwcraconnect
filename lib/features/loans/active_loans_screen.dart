import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/data_provider.dart';

class ActiveLoansScreen extends ConsumerStatefulWidget {
  const ActiveLoansScreen({super.key});

  @override
  ConsumerState<ActiveLoansScreen> createState() => _ActiveLoansScreenState();
}

class _ActiveLoansScreenState extends ConsumerState<ActiveLoansScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loans = ref.watch(loansProvider);
    final filteredLoans = loans.where((l) => 
      l.memberName.toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activeLoans),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchMembers,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.background,
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(l10n.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text(l10n.loanAmount, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text(l10n.remaining, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text(l10n.status, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filteredLoans.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final loan = filteredLoans[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(loan.memberName, style: const TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: Text('₹${loan.totalAmount.toInt()}')),
                      Expanded(
                        flex: 2, 
                        child: Text(
                          '₹${loan.remainingAmount.toInt()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          loan.status == 'Active' ? l10n.active : loan.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: loan.status == 'Grace Period' ? Colors.orange : AppColors.successGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
