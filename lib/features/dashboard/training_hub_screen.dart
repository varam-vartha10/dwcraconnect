import 'package:flutter/material.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';

class TrainingHubScreen extends StatelessWidget {
  const TrainingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainingHub)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTrainingCard(
            l10n.finLitTitle,
            l10n.finLitDesc,
            Icons.menu_book_rounded,
            AppColors.primaryPurple,
          ),
          _buildTrainingCard(
            l10n.govSchemeTitle,
            l10n.govSchemeDesc,
            Icons.account_balance_rounded,
            AppColors.successGreen,
          ),
          _buildTrainingCard(
            l10n.digiMarketTitle,
            l10n.digiMarketDesc,
            Icons.shopping_bag_rounded,
            AppColors.secondaryPink,
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingCard(String title, String desc, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primaryPurple),
        onTap: () {},
      ),
    );
  }
}
