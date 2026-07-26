import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';

class MeetingAttendanceScreen extends StatefulWidget {
  const MeetingAttendanceScreen({super.key});

  @override
  State<MeetingAttendanceScreen> createState() => _MeetingAttendanceScreenState();
}

class _MeetingAttendanceScreenState extends State<MeetingAttendanceScreen> {
  final List<Map<String, dynamic>> _members = [
    {'name': 'Lakshmi Devi', 'present': true},
    {'name': 'Savitri Amma', 'present': true},
    {'name': 'Anasuya G.', 'present': false},
    {'name': 'Rajeswari P.', 'present': true},
    {'name': 'Bhavani K.', 'present': true},
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.markAttendance),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              child: ListTile(
                leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primaryPurple),
                title: Text(l10n.groupMeetingAt(l10n.groupMeeting, '18 June 2026'), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${l10n.location}: ${l10n.shgCenter}'),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(member['name'][0])),
                  title: Text(member['name']),
                  trailing: Switch(
                    value: member['present'],
                    onChanged: (val) => setState(() => member['present'] = val),
                    activeThumbColor: AppColors.successGreen,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: () => context.pop(),
              child: Text(l10n.save),
            ),
          ),
        ],
      ),
    );
  }
}
