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

final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  final loans = ref.watch(loansProvider);
  final subsidies = ref.watch(subsidiesProvider);
  final members = ref.watch(membersProvider);
  final emis = ref.watch(emisProvider);

  final totalLoan = loans.fold(0.0, (sum, item) => sum + item.remainingAmount);
  final totalSubsidy = subsidies.fold(0.0, (sum, item) => sum + item.amount);
  final pendingEmi = emis.fold(0.0, (sum, item) => sum + item.amount);

  return DashboardSummary(
    totalLoanOutstanding: totalLoan,
    totalSubsidyReceived: totalSubsidy,
    totalMembers: members.length,
    pendingEmiAmount: pendingEmi,
  );
});
