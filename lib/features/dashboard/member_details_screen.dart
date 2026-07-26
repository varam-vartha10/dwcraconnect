import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/member_provider.dart';
import '../../domain/entities/member_entity.dart';

class MemberDetailsScreen extends ConsumerWidget {
  final String memberId;

  const MemberDetailsScreen({
    super.key,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final members = ref.watch(memberProvider);
    final member = members.firstWhere((m) => m.id == memberId, orElse: () => throw Exception('Member not found'));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, member.name),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, l10n.personalInfo),
                  _buildPersonalInfoCard(member, l10n),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, l10n.loans),
                  _buildLoanSummaryCard(context, member, l10n),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, l10n.emiStatus),
                  _buildEmiStatusCard(context, member, l10n),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, l10n.subsidyDetails),
                  _buildSubsidyList(context, member, l10n),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String name) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.shgTeal,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Icon(Icons.person_rounded, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: $memberId',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(MemberEntity member, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow(l10n.mobileNumber, member.mobile),
            const Divider(),
            _buildDetailRow(l10n.aadhaarMasked, member.aadhaar),
            const Divider(),
            _buildDetailRow(l10n.village, member.village),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLoanSummaryCard(BuildContext context, MemberEntity member, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn(l10n.totalLoanAmount, '₹${member.loanAmount.toInt()}', AppColors.shgTeal),
                _buildStatColumn(l10n.remainingAmount, '₹${member.remainingAmount.toInt()}', AppColors.lotusPink),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: member.repaymentProgress,
              backgroundColor: AppColors.background,
              color: AppColors.fieldGreen,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.repaidPercent((member.repaymentProgress * 100).toInt()), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(l10n.activeStatus, style: const TextStyle(fontSize: 12, color: AppColors.fieldGreen, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildEmiStatusCard(BuildContext context, MemberEntity member, AppLocalizations l10n) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_note_rounded, color: AppColors.lotusPink),
        title: Text('${l10n.nextEmi}: ₹${member.emiAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${l10n.dueDate}: 05 July 2026'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(l10n.pending, style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSubsidyList(BuildContext context, MemberEntity member, AppLocalizations l10n) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.savings_rounded, color: AppColors.fieldGreen),
        title: Text(l10n.schemeName),
        subtitle: Text(l10n.receivedOn('01 June 2026')),
        trailing: Text('₹${member.subsidyAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.fieldGreen)),
      ),
    );
  }
}
