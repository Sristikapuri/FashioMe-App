import 'package:flutter/material.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_luxury_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_network_image.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_palette.dart';

class DashboardForYouCard extends StatelessWidget {
  const DashboardForYouCard({super.key, 
    required this.loading,
    required this.forYou,
    required this.autoOccasion,
    required this.autoReason,
    required this.decisionReasons,
    required this.wardrobeCount,
    required this.wardrobeCategories,
    required this.profileData,
  });

  final bool loading;
  final DashboardRecommendation? forYou;
  final String autoOccasion;
  final String autoReason;
  final List<String> decisionReasons;
  final int wardrobeCount;
  final List<String> wardrobeCategories;
  final DashboardProfileData profileData;

  @override
  Widget build(BuildContext context) {
    final fitParts = [
      if (profileData.gender.isNotEmpty) 'Gender: ${profileData.gender}',
      if (profileData.bodyType.isNotEmpty) 'Body: ${profileData.bodyType}',
      if (profileData.faceShape.isNotEmpty) 'Face: ${profileData.faceShape}',
      if (profileData.skinTone.isNotEmpty) 'Tone: ${profileData.skinTone}',
    ];
    final wardrobeSummary = wardrobeCount > 0
        ? 'You have $wardrobeCount item${wardrobeCount == 1 ? '' : 's'} available for matching.'
              '${wardrobeCategories.isNotEmpty ? ' Categories: ${wardrobeCategories.join(', ')}.' : ''}'
        : 'Add wardrobe pieces so the engine can match real items you already own.';

    return DashboardLuxuryCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: DashboardPalette.gold,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FOR YOU',
                      style: TextStyle(
                        color: DashboardPalette.mutedText,
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontFamily: AppFonts.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Personalized outfit direction',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontFamily: AppFonts.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: DashboardPalette.cardAlt,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Adaptive',
                  style: TextStyle(
                    color: DashboardPalette.gold,
                    fontSize: 11,
                    fontFamily: AppFonts.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading)
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Crafting your personalized style direction...',
                    style: TextStyle(color: DashboardPalette.mutedText),
                  ),
                ),
              ],
            )
          else if (forYou == null)
            Text(
              'Add a few wardrobe pieces or generate a look in AI Stylist to unlock a personalized pick.',
              style: TextStyle(color: DashboardPalette.mutedText),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: DashboardNetworkImage(url: forYou!.imageUrl, height: 200),
            ),
            const SizedBox(height: 14),
            Text(
              autoOccasion.toUpperCase(),
              style: TextStyle(
                color: DashboardPalette.mutedText,
                fontSize: 11,
                letterSpacing: 1.2,
                fontFamily: AppFonts.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              forYou!.title.isEmpty
                  ? 'Your custom recommendation'
                  : forYou!.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontFamily: AppFonts.bold,
              ),
            ),
            const SizedBox(height: 14),
            DashboardForYouInfoBlock(label: 'Why this occasion', body: autoReason),
            const SizedBox(height: 10),
            DashboardForYouInfoBlock(
              label: 'Decision breakdown',
              bullets: decisionReasons,
            ),
            if (forYou!.explanation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                forYou!.explanation,
                style: TextStyle(
                  color: DashboardPalette.mutedText,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 10),
            DashboardForYouInfoBlock(label: 'Your wardrobe', body: wardrobeSummary),
            if (fitParts.isNotEmpty) ...[
              const SizedBox(height: 10),
              DashboardForYouInfoBlock(
                label: 'Fit profile',
                body: fitParts.join(' · '),
              ),
            ],
            if (forYou!.wardrobeItemsUsed.isNotEmpty) ...[
              const SizedBox(height: 10),
              DashboardForYouInfoBlock(
                label: 'Matched wardrobe items',
                bullets: forYou!.wardrobeItemsUsed.take(4).toList(),
              ),
            ],
            if (forYou!.paletteLabels.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: forYou!.paletteLabels
                    .take(4)
                    .map(
                      (label) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: DashboardPalette.cardAlt,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: DashboardPalette.gold,
                            fontSize: 12,
                            fontFamily: AppFonts.bold,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class DashboardForYouInfoBlock extends StatelessWidget {
  const DashboardForYouInfoBlock({super.key, required this.label, this.body, this.bullets});

  final String label;
  final String? body;
  final List<String>? bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardPalette.cardAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: DashboardPalette.mutedText,
              fontSize: 10,
              letterSpacing: 1.2,
              fontFamily: AppFonts.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (body != null)
            Text(
              body!,
              style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
            ),
          if (bullets != null)
            ...bullets!.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: DashboardPalette.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
