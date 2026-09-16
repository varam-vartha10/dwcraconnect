import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';

class ApplyLoanScreen extends StatefulWidget {
  const ApplyLoanScreen({super.key});

  @override
  State<ApplyLoanScreen> createState() => _ApplyLoanScreenState();
}

class _ApplyLoanScreenState extends State<ApplyLoanScreen> {
  final _amountController = TextEditingController();
  String _purpose = 'businessGrowth';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final purposes = {
      'businessGrowth': l10n.businessGrowth,
      'emergency': l10n.emergency,
      'education': l10n.education,
      'other': l10n.other,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.applyLoan)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.enterRequiredAmount,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixText: '₹ '),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.purposeOfLoan,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _purpose,
              items: purposes.entries.map<DropdownMenuItem<String>>((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (newValue) => setState(() => _purpose = newValue!),
              decoration: const InputDecoration(),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.applicationSubmitted),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
              child: Text(l10n.submitApplication),
            ),
          ],
        ),
      ),
    );
  }
}
