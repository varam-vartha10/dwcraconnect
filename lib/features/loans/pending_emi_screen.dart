import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/data_provider.dart';

class PendingEmiScreen extends ConsumerWidget {
  const PendingEmiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final emisAsync = ref.watch(emisProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pendingEmi),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: emisAsync.when(
        data: (emis) {
          final pendingEmis = emis
              .where(
                (emi) => emi.status == 'pending' || emi.status == 'overdue',
              )
              .toList();
          final totalPending = pendingEmis.fold(
            0.0,
            (sum, item) => sum + item.amount,
          );
          final overdueAmount = pendingEmis
              .where((e) => e.isOverdue)
              .fold(0.0, (sum, item) => sum + item.amount);

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.secondaryPink.withValues(alpha: 0.05),
                  border: const Border(
                    bottom: BorderSide(color: Colors.black12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryStat(
                      l10n.totalPending,
                      '₹${totalPending.toInt()}',
                      AppColors.primaryPurple,
                    ),
                    _buildSummaryStat(
                      l10n.overdue,
                      '₹${overdueAmount.toInt()}',
                      AppColors.secondaryPink,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: AppColors.background,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        l10n.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        l10n.date,
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
                child: RefreshIndicator(
                  onRefresh: () => ref.refresh(emisProvider.future),
                  child: pendingEmis.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Center(child: Text(l10n.noRecentActivity)),
                          ],
                        )
                      : ListView.separated(
                          itemCount: pendingEmis.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final emi = pendingEmis[index];
                            return Container(
                              color: emi.isOverdue
                                  ? AppColors.secondaryPink.withValues(
                                      alpha: 0.03,
                                    )
                                  : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          emi.memberName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: emi.isOverdue
                                                ? AppColors.secondaryPink
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        if (emi.isOverdue)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.secondaryPink
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              l10n.overdue.toUpperCase(),
                                              style: const TextStyle(
                                                color: AppColors.secondaryPink,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "${emi.dueDate.day} ${_getMonth(emi.dueDate.month)} ${emi.dueDate.year}",
                                      style: TextStyle(
                                        color: emi.isOverdue
                                            ? AppColors.secondaryPink
                                            : AppColors.textSecondary,
                                        fontWeight: emi.isOverdue
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '₹${emi.amount.toInt()}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: emi.isOverdue
                                              ? AppColors.secondaryPink
                                              : AppColors.primaryPurple,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send_rounded),
                  label: Text(l10n.sendRemindersToAll),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(emisProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
