import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/auth_provider.dart';

class ManageMembersScreen extends ConsumerStatefulWidget {
  const ManageMembersScreen({super.key});

  @override
  ConsumerState<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends ConsumerState<ManageMembersScreen> {
  bool _isLoading = true;
  String? _error;
  String _groupId = 'GRP001';
  String _groupName = 'DWCRA SHG Group';
  int _totalMembers = 0;
  int _maxMembers = 10;
  List<Map<String, dynamic>> _roster = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchRoster();
  }

  Future<void> _fetchRoster() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(authProvider).user;
      final targetGroup = user?.groupId ?? 'GRP001';

      final response = await ApiService.get('/groups/$targetGroup/roster');

      if (!mounted) return;

      if (response['success'] == true) {
        final List rawRoster = response['roster'] ?? [];
        setState(() {
          _groupId = response['groupId'] ?? targetGroup;
          _groupName = response['groupName'] ?? targetGroup;
          _totalMembers = response['totalMembers'] ?? rawRoster.length;
          _maxMembers = response['maxMembers'] ?? 10;
          _roster = rawRoster.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load member roster.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showAddMemberDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final villageCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Member to Group $_groupId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(dialogCtx)),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Member Full Name *', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter member name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Mobile Number (10 digits) *', prefixIcon: Icon(Icons.phone_android_rounded)),
                  validator: (v) {
                    if (v == null || v.trim().length != 10) return 'Please enter 10-digit mobile number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: villageCtrl,
                  decoration: const InputDecoration(labelText: 'Village / Area *', prefixIcon: Icon(Icons.location_on_outlined)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter village name' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    setModalState(() => isSaving = true);
                    try {
                      final response = await ApiService.post('/groups/$_groupId/roster', {
                        'name': nameCtrl.text.trim(),
                        'phoneNumber': phoneCtrl.text.trim(),
                        'village': villageCtrl.text.trim(),
                      });
                      if (!mounted) return;
                      Navigator.pop(dialogCtx);
                      if (response['success'] == true) {
                        _fetchRoster();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(response['message'] ?? 'Member added to roster.'), backgroundColor: AppColors.successGreen),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(response['message'] ?? 'Failed to add member.'), backgroundColor: Colors.redAccent),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
                      );
                    } finally {
                      setModalState(() => isSaving = false);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Add Member to Group'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdateMobileDialog(String userId, String currentName, String currentPhone) {
    final phoneCtrl = TextEditingController(text: currentPhone.startsWith('TEMP-') ? '' : currentPhone);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Update Mobile for $currentName'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Member ID: $userId', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'New 10-Digit Mobile Number *', prefixIcon: Icon(Icons.phone_android_rounded)),
                  validator: (v) => v == null || v.trim().length != 10 ? 'Enter valid 10-digit phone number' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => isSaving = true);
                try {
                  final response = await ApiService.patch('/groups/$_groupId/roster/$userId/mobile', {
                    'newPhoneNumber': phoneCtrl.text.trim(),
                  });
                  if (!mounted) return;
                  Navigator.pop(dialogCtx);
                  if (response['success'] == true) {
                    _fetchRoster();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(response['message'] ?? 'Mobile number updated successfully!'), backgroundColor: AppColors.successGreen),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(response['message'] ?? 'Failed to update mobile.'), backgroundColor: Colors.redAccent),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
                  );
                } finally {
                  setDialogState(() => isSaving = false);
                }
              },
              child: isSaving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Update Mobile'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRoster = _roster.where((m) {
      final q = _searchQuery.toLowerCase();
      final name = (m['name'] ?? '').toString().toLowerCase();
      final id = (m['userId'] ?? '').toString().toLowerCase();
      final phone = (m['phoneNumber'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q) || phone.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage SHG Group Members'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchRoster),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchRoster, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header Group Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Group ID: $_groupId', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(_groupName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_totalMembers / $_maxMembers Members',
                              style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search member by name, ID, or phone...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Roster List
                    Expanded(
                      child: filteredRoster.isEmpty
                          ? const Center(child: Text('No group members found.'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: filteredRoster.length,
                              itemBuilder: (context, index) {
                                final m = filteredRoster[index];
                                final isRegistered = m['isRegistered'] == true;
                                final phone = (m['phoneNumber'] ?? 'Not Set').toString();

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: isRegistered ? AppColors.primaryPurple : Colors.grey.shade300,
                                      child: Text(
                                        (m['userId'] ?? 'M').toString().replaceFirst('SHG-', ''),
                                        style: TextStyle(
                                          color: isRegistered ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(m['name'] ?? 'Member', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(width: 8),
                                        if (m['position'] == 'president' || m['position'] == 'secretary')
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                                            child: Text((m['position'] ?? '').toString().toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                                          ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text('ID: ${m['userId']} | Mobile: $phone', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        Text('Village: ${m['village']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isRegistered ? AppColors.successGreen.withValues(alpha: 0.1) : Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: isRegistered ? AppColors.successGreen : Colors.orange),
                                          ),
                                          child: Text(
                                            isRegistered ? 'Active' : 'Not Registered',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isRegistered ? AppColors.successGreen : Colors.orange.shade800,
                                            ),
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (action) {
                                            if (action == 'update_mobile') {
                                              _showUpdateMobileDialog(m['userId'], m['name'], phone);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'update_mobile',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.phone_android_rounded, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Update Mobile Number'),
                                                ],
                                              ),
                                            ),
                                          ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _totalMembers >= _maxMembers ? null : _showAddMemberDialog,
        backgroundColor: AppColors.primaryPurple,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Add Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
