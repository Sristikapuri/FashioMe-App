import 'package:flutter/material.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_palette.dart';

class DashboardActionPanel extends StatelessWidget {
  const DashboardActionPanel({super.key, 
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: DashboardPalette.outline),
        backgroundColor: DashboardPalette.card,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
