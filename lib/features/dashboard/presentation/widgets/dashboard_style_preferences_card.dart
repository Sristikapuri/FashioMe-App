import 'package:flutter/material.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';

class DashboardStylePreferencesCard extends StatelessWidget {
  const DashboardStylePreferencesCard({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBackground.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Style Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: AppFonts.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.profileData.stylePreferences.isEmpty)
            Text(
              'No style preferences set yet',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.profileData.stylePreferences.map((preference) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    preference,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontFamily: AppFonts.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
