import 'package:flutter/material.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_top_icon_button.dart';

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.title,
    required this.onLeadingTap,
    required this.onSearchTap,
    required this.onTrailingTap,
    required this.trailingIcon,
  });
  final String title;
  final VoidCallback onLeadingTap;
  final VoidCallback onSearchTap;
  final VoidCallback onTrailingTap;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 12),
      child: Row(
        children: [
          DashboardTopIconButton(icon: Icons.menu_rounded, onTap: onLeadingTap),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 28,
                fontFamily: AppFonts.bold,
              ),
            ),
          ),
          DashboardTopIconButton(
            icon: Icons.search_rounded,
            onTap: onSearchTap,
          ),
          const SizedBox(width: 8),
          DashboardTopIconButton(icon: trailingIcon, onTap: onTrailingTap),
        ],
      ),
    );
  }
}
