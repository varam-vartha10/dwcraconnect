import 'package:flutter/material.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/data_provider.dart';

class MemberListScreen extends ConsumerStatefulWidget {
  const MemberListScreen({super.key});

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final members = ref.watch(membersProvider);
    final filteredMembers = members.where((m) => 
      m.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
      m.id.toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memberList),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchMembers,
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: AppColors.background,
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(l10n.memberId, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                Expanded(flex: 3, child: Text(l10n.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                Expanded(flex: 3, child: Text(l10n.mobileNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              ],
            ),
          ),

          // Member List
          Expanded(
            child: ListView.separated(
              itemCount: filteredMembers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = filteredMembers[index];
                return InkWell(
                  onTap: () {
                    context.push('/member-details/${member.id}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            member.id,
                            style: const TextStyle(fontSize: 13, color: AppColors.shgTeal, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            member.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            member.mobile,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
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
