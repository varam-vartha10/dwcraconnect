import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data_provider.dart';

class DashboardSummary {
  final double totalLoanOutstanding;
  final double totalSubsidyReceived;
  final int totalMembers;
  final double pendingEmiAmount;

  DashboardSummary({
    required this.totalLoanOutstanding,
    required this.totalSubsidyReceived,
    required this.totalMembers,
    required this.pendingEmiAmount,
  });
}

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final loans = ref.watch(loansProvider);
  final subsidies = ref.watch(subsidiesProvider);
  final members = ref.watch(membersProvider);
  
  // Wait for EMIs from the backend
  final emis = await ref.watch(emisProvider.future);

  final totalLoan = loans.fold(0.0, (sum, item) => sum + item.remainingAmount);
  final totalSubsidy = subsidies.fold(0.0, (sum, item) => sum + item.amount);
  
  // Calculate only pending/overdue EMIs
  final pendingEmi = emis
      .where((e) => e.status == 'pending' || e.status == 'overdue')
      .fold(0.0, (sum, item) => sum + item.amount);

  return DashboardSummary(
    totalLoanOutstanding: totalLoan,
    totalSubsidyReceived: totalSubsidy,
    totalMembers: members.length,
    pendingEmiAmount: pendingEmi,
  );
});
