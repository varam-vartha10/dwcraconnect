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
  // Use Future.wait to fetch all data in parallel for speed
  final results = await Future.wait([
    ref.watch(loansProvider.future),
    ref.watch(subsidiesProvider.future),
    ref.watch(membersProvider.future),
    ref.watch(emisProvider.future),
  ]);

  final loans = results[0] as List;
  final subsidies = results[1] as List;
  final members = results[2] as List;
  final emis = results[3] as List;

  final totalLoan = loans.fold(0.0, (sum, item) => sum + (item.remainingAmount ?? 0.0));
  final totalSubsidy = subsidies.fold(0.0, (sum, item) => sum + (item.amount ?? 0.0));
  
  final pendingEmi = emis
      .where((e) => e.status == 'pending' || e.status == 'overdue')
      .fold(0.0, (sum, item) => sum + (item.amount ?? 0.0));

  return DashboardSummary(
    totalLoanOutstanding: totalLoan,
    totalSubsidyReceived: totalSubsidy,
    totalMembers: members.length,
    pendingEmiAmount: pendingEmi,
  );
});
