import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:fashio_me/features/dashboard/presentation/utils/dashboard_name_utils.dart';
import 'package:fashio_me/features/dashboard/presentation/view_model/dashboard_view_model.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_hero_banner.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_info_strip.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_mini_look_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_occasion_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_section_title.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_season_card.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key, 
    required this.state,
    required this.selectedEvent,
    required this.events,
    required this.onEventTap,
  });

  final DashboardState state;
  final String selectedEvent;
  final List<(String, IconData)> events;
  final ValueChanged<String> onEventTap;

  void _showSeasonalLookDialog(
    BuildContext context,
    String title,
    String imageUrl,
    String description,
    String occasionKey,
    DashboardViewModel notifier,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF14141E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 280,
                        color: const Color(0xFF1A1A24),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white54),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 280,
                        color: const Color(0xFF1A1A24),
                        child: const Icon(Icons.image_not_supported, color: Colors.white38, size: 40),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        title.replaceAll('\n', ' '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEASONAL STYLE INSIGHT',
                      style: TextStyle(
                        color: Colors.purpleAccent.shade100,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Close'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurpleAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await notifier.generateHomeRecommendation(
                                occasion: occasionKey,
                                syncCurrentRecommendation: true,
                              );
                              notifier.setIndex(1);
                            },
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('Open Stylist'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    final firstName = dashboardFirstName(state.profileData.displayName);
    
    const summerUrl = 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=600&q=80';
    const monsoonUrl = 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600&q=80';
    const winterUrl = 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600&q=80';
    const festiveUrl = 'https://images.unsplash.com/photo-1610189352649-1a7b2d7e9be5?w=600&q=80';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 140),
      children: [
        DashboardHeroBanner(
          title: 'Good Morning,\n$firstName',
          subtitle:
              'Your AI stylist has fresh outfit ideas, color picks, and closet inspiration ready for today.',
          badgeText: 'AI Stylist',
          onTap: () => notifier.setIndex(1),
        ),
        const SizedBox(height: 20),

        DashboardSectionTitle(
          title: 'Browse by Occasion',
          actionLabel: 'View All',
          onAction: () {},
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final item = events[index];
            return DashboardOccasionCard(
              label: item.$1,
              icon: item.$2,
              isSelected: selectedEvent == item.$1,
              onTap: () => onEventTap(item.$1),
            );
          },
        ),
        const SizedBox(height: 24),
        DashboardInfoStrip(
          icon: Icons.auto_awesome_rounded,
          title: 'Create your next look',
          subtitle: 'Open AI Stylist for personalized outfit generation.',
          onTap: () {
            notifier.generateHomeRecommendation(
              occasion: selectedEvent,
              syncCurrentRecommendation: true,
            );
            notifier.setIndex(1);
          },
        ),
        const SizedBox(height: 24),
        DashboardSectionTitle(
          title: 'Looks for $selectedEvent',
          actionLabel: 'View All',
          onAction: () => notifier.setIndex(3),
        ),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.homeRecommendations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: 122,
              child: DashboardMiniLookCard(
                item: state.homeRecommendations[index],
                onTap: () {
                  notifier.selectRecommendation(
                    state.homeRecommendations[index],
                  );
                  notifier.setIndex(1);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const DashboardSectionTitle(title: 'Seasonal Inspiration'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardSeasonCard(
                title: 'Summer\nVibes',
                imagePath: summerUrl,
                onTap: () => _showSeasonalLookDialog(
                  context,
                  'Summer Vibes',
                  summerUrl,
                  'Lightweight linen, breathable cottons, sun-soaked pastels, and easy sandals crafted for warm summer days.',
                  'Summer',
                  notifier,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DashboardSeasonCard(
                title: 'Monsoon\nChic',
                imagePath: monsoonUrl,
                onTap: () => _showSeasonalLookDialog(
                  context,
                  'Monsoon Chic',
                  monsoonUrl,
                  'Water-resistant outerwear, quick-dry fabrics, vibrant trench coats, and stylish boots for rainy weather.',
                  'Monsoon',
                  notifier,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DashboardSeasonCard(
                title: 'Winter\nLayers',
                imagePath: winterUrl,
                onTap: () => _showSeasonalLookDialog(
                  context,
                  'Winter Layers',
                  winterUrl,
                  'Oversized wool knits, structured long coats, cashmere scarves, and dark rich leather layers for cold weather.',
                  'Winter',
                  notifier,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DashboardSeasonCard(
                title: 'Festive\nLooks',
                imagePath: festiveUrl,
                onTap: () => _showSeasonalLookDialog(
                  context,
                  'Festive Looks',
                  festiveUrl,
                  'Embroidered silk kurtas, velvet bandhgalas, heritage sarees, and regal ethnic fusion for celebration days.',
                  'Festive',
                  notifier,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

