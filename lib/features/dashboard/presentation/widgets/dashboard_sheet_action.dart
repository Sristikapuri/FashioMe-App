import 'package:flutter/material.dart';

import 'package:fashio_me/app/theme/app_colors.dart';

class DashboardSheetAction extends StatelessWidget {
  const DashboardSheetAction({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontFamily: AppFonts.bold,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
      ),
    );
  }
}
