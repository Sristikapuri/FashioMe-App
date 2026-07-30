import 'package:flutter/material.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_luxury_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_palette.dart';

class DashboardConfidenceCard extends StatelessWidget {
  const DashboardConfidenceCard({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return DashboardLuxuryCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 86,
            width: 86,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 7,
                  backgroundColor: AppColors.cardBackground.withValues(
                    alpha: 0.08,
                  ),
                  color: DashboardPalette.gold,
                ),
                Center(
                  child: Text(
                    '$score%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: AppFonts.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Style Confidence',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontFamily: AppFonts.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Great! Your profile is well optimized for personalized recommendations.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
