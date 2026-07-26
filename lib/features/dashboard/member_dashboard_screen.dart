import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/data_provider.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/widgets/dwcra_logo.dart';
import '../../core/widgets/dwcra_drawer.dart';
import 'notifications_screen.dart';
import 'member_profile_screen.dart';

class MemberDashboardScreen extends ConsumerWidget {
  const MemberDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    final selectedIndex = ref.watch(memberBottomNavIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const DwcraLogo(size: 32, isHorizontal: true),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => ref.read(memberBottomNavIndexProvider.notifier).state = 1,
          ),
        ],
      ),
      drawer: const DwcraDrawer(),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          _MemberHome(name: user?.name ?? l10n.member),
          const NotificationsScreen(),
          const MemberProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => ref.read(memberBottomNavIndexProvider.notifier).state = index,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: l10n.home),
          BottomNavigationBarItem(icon: const Icon(Icons.notifications_rounded), label: l10n.alerts),
          BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: l10n.profile),
        ],
      ),
    );
  }
}

class _MemberHome extends ConsumerWidget {
  final String name;
  const _MemberHome({required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final member = ref.watch(currentMemberProvider);
    
    final loanBal = member?.remainingAmount ?? 0.0;
    final emiAmt = member?.emiAmount ?? 0.0;
    final subAmt = member?.subsidyAmount ?? 0.0;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildWelcomeCard(context, name, member?.shgGroup ?? 'Saraswati SHG', l10n),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(l10n.activeLoans, '₹${loanBal.toInt()}', Icons.account_balance_wallet_rounded, AppColors.shgTeal, onTap: () => context.push('/loan-balance')),
                _buildStatCard(l10n.nextEmi, '₹${emiAmt.toInt()}', Icons.event_note_rounded, AppColors.lotusPink, onTap: () => context.push('/emi-details')),
                _buildStatCard(l10n.subsidy, '₹${subAmt.toInt()}', Icons.savings_rounded, AppColors.fieldGreen, onTap: () => context.push('/subsidy-details')),
                _buildStatCard(
                  l10n.transactionHistory, 
                  l10n.viewAll, 
                  Icons.history_rounded, 
                  AppColors.indigo,
                  onTap: () => context.push('/transaction-history'),
                ),
                _buildStatCard(
                  l10n.trainingHub, 
                  '3 Videos', 
                  Icons.play_circle_fill_rounded, 
                  AppColors.fieldGreen,
                  onTap: () => context.push('/training-hub'),
                ),
              ],
            ),
          ),
          _buildSectionHeader(context, l10n.recentActivity, l10n),
          _buildTransactionList(ref, l10n),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String name, String group, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 35, backgroundColor: Colors.white.withOpacity(0.2), child: const Icon(Icons.person_rounded, size: 40, color: Colors.white)),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.namaste},', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70)),
                  Text(name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              group,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(onPressed: () => context.push('/transaction-history'), child: Text(l10n.viewAll)),
        ],
      ),
    );
  }

  Widget _buildTransactionList(WidgetRef ref, AppLocalizations l10n) {
    final transactions = ref.watch(memberTransactionsProvider);
    final recent = transactions.take(3).toList();
    
    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(l10n.noRecentActivity),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      itemBuilder: (context, index) {
        final tx = recent[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.background, 
              child: Icon(
                tx.type == 'Debit' ? Icons.remove_circle_outline : Icons.add_circle_outline, 
                color: tx.type == 'Debit' ? Colors.redAccent : AppColors.fieldGreen
              )
            ),
            title: Text(tx.description == 'EMI Repayment' ? l10n.loanRepayment : (tx.description == 'Monthly Savings' ? l10n.savings : tx.description), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${tx.date.day}/${tx.date.month}/${tx.date.year}"),
            trailing: Text(
              '${tx.type == 'Debit' ? '-' : '+'} ₹${tx.amount.toInt()}', 
              style: TextStyle(
                color: tx.type == 'Debit' ? Colors.redAccent : AppColors.fieldGreen, 
                fontWeight: FontWeight.bold
              )
            ),
          ),
        );
      },
    );
  }
}
