import 'package:flutter/material.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/widgets/selected_image.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_luxury_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_palette.dart';

class DashboardImagePreview extends StatelessWidget {
  const DashboardImagePreview({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return DashboardLuxuryCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Reference',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: AppFonts.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 190,
              width: double.infinity,
              child: buildSelectedImage(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: DashboardPalette.cardAlt,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: DashboardPalette.mutedText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
