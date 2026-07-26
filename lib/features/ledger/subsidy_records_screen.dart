import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/data_provider.dart';

class SubsidyRecordsScreen extends ConsumerStatefulWidget {
  const SubsidyRecordsScreen({super.key});

  @override
  ConsumerState<SubsidyRecordsScreen> createState() => _SubsidyRecordsScreenState();
}

class _SubsidyRecordsScreenState extends ConsumerState<SubsidyRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subsidies = ref.watch(subsidiesProvider);
    
    final filteredSubsidies = subsidies.where((s) {
      final matchesSearch = s.memberName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                          s.schemeName.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesFilter = _selectedFilter == 'All' || s.schemeName == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subsidyRecords),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
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
                    hintText: l10n.searchSubsidies,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', l10n.all),
                      _buildFilterChip('Vaddi Leni Runalu', 'Vaddi Leni Runalu'),
                      _buildFilterChip('SHG Empowerment Scheme', 'SHG Empowerment Scheme'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.background,
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(l10n.member, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                Expanded(flex: 3, child: Text(l10n.schemeName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text(l10n.amount, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)))),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filteredSubsidies.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = filteredSubsidies[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(flex: 3, child: Text(record.memberName, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 3, child: Text(record.schemeName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                          Expanded(
                            flex: 2, 
                            child: Align(
                              alignment: Alignment.centerRight, 
                              child: Text('₹${record.amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen))
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${l10n.receivedDate}: ${record.date.day} ${_getMonth(record.date.month)} ${record.date.year}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool value) {
          setState(() {
            _selectedFilter = key;
          });
        },
        selectedColor: AppColors.successGreen.withValues(alpha: 0.2),
        checkmarkColor: AppColors.successGreen,
      ),
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
