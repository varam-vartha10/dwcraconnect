import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/widgets/dwcra_logo.dart';
import '../../core/widgets/dwcra_drawer.dart';
import 'member_profile_screen.dart';
import 'member_list_screen.dart';
import 'reports_screen.dart';

class LeaderDashboardScreen extends ConsumerWidget {
  const LeaderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    final selectedIndex = ref.watch(leaderBottomNavIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const DwcraLogo(size: 32, isHorizontal: true),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      drawer: const DwcraDrawer(),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          _LeaderHome(name: user?.name ?? l10n.leader),
          const MemberListScreen(),
          const ReportsScreen(),
          const MemberProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => ref.read(leaderBottomNavIndexProvider.notifier).state = index,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_rounded),
            label: l10n.dashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_rounded),
            label: l10n.members,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assessment_rounded),
            label: l10n.reports,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}

class _LeaderHome extends ConsumerWidget {
  final String name;
  const _LeaderHome({required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(dashboardSummaryProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(context, name, l10n),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  l10n.totalMembers, 
                  '${summary.totalMembers}', 
                  Icons.group_rounded, 
                  AppColors.shgTeal,
                  onTap: () => ref.read(leaderBottomNavIndexProvider.notifier).state = 1,
                ),
                _buildActionCard(
                  l10n.activeLoans, 
                  '₹${summary.totalLoanOutstanding.toInt()}', 
                  Icons.account_balance_wallet_rounded, 
                  AppColors.shgTeal,
                  onTap: () => context.push('/active-loans')
                ),
                _buildActionCard(
                  l10n.pendingEmi, 
                  '₹${summary.pendingEmiAmount.toInt()}', 
                  Icons.pending_actions_rounded, 
                  AppColors.lotusPink,
                  onTap: () => context.push('/pending-emi')
                ),
                _buildActionCard(
                  l10n.subsidyRecords, 
                  '₹${summary.totalSubsidyReceived.toInt()}', 
                  Icons.savings_rounded, 
                  AppColors.fieldGreen,
                  onTap: () => context.push('/subsidy-records')
                ),
                _buildActionCard(l10n.groupLedger, '', Icons.menu_book_rounded, AppColors.indigo,
                    onTap: () => context.push('/group-ledger')),
                _buildActionCard(
                  l10n.reports, 
                  '', 
                  Icons.pie_chart_rounded, 
                  AppColors.shgTeal,
                  onTap: () => ref.read(leaderBottomNavIndexProvider.notifier).state = 2,
                ),
                _buildActionCard(l10n.notifications, l10n.newNotifications(3), Icons.notifications_active_rounded, AppColors.lotusPink, 
                    onTap: () => context.push('/notifications')),
                _buildActionCard(l10n.meetingAttendance, '', Icons.how_to_reg_rounded, AppColors.indigo,
                    onTap: () => context.push('/meeting-attendance')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildCommunityPulse(context, l10n),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCommunityPulse(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.communityPulse, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _PulseRow(label: l10n.monthlyThriftCollected, value: '94%', color: AppColors.shgTeal),
          const SizedBox(height: 12),
          _PulseRow(label: l10n.repaymentDiscipline, value: '98%', color: AppColors.fieldGreen),
          const SizedBox(height: 12),
          _PulseRow(label: l10n.trainingCompletion, value: '7/12', color: AppColors.harvestGold),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Icon(Icons.person_rounded, size: 35, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcomeLeader,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            l10n.groupAnalytics,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAnalyticsItem(l10n.savings, '₹1.2L', Icons.trending_up_rounded),
              _buildAnalyticsItem(l10n.repayment, '98%', Icons.check_circle_rounded),
              _buildAnalyticsItem(l10n.creditScore, '820', Icons.speed_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
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
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              if (value.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PulseRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
