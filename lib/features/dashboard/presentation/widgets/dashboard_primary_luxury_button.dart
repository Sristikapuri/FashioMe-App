import 'package:flutter/material.dart';
import 'package:fashio_me/app/theme/app_colors.dart';

class DashboardPrimaryLuxuryButton extends StatelessWidget {
  const DashboardPrimaryLuxuryButton({super.key, 
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 42 : 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onTap == null
              ? const LinearGradient(
                  colors: [AppColors.textSecondary, AppColors.disabled],
                )
              : AppColors.accentGradient,
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24820000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(compact ? 14 : 18),
            ),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              fontFamily: AppFonts.bold,
            ),
          ),
        ),
      ),
    );
  }
}
