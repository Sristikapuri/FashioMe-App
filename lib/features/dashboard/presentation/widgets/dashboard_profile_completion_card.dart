import 'package:flutter/material.dart';
import 'package:fashio_me/app/theme/app_colors.dart';

class DashboardProfileCompletionCard extends StatelessWidget {
  const DashboardProfileCompletionCard({super.key, required this.completion});

  final double completion;

  @override
  Widget build(BuildContext context) {
    final percentage = (completion * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Completion',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: AppFonts.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: AppFonts.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completion,
              backgroundColor: AppColors.cardBackground,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            completion < 0.5
                ? 'Complete your profile for better recommendations'
                : completion < 1.0
                ? 'Almost there! Add more details'
                : 'Profile complete! Great job!',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
