import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:fashio_me/features/dashboard/presentation/utils/dashboard_name_utils.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_hero_banner.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_info_strip.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_mini_look_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_occasion_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_search_bar.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    final firstName = dashboardFirstName(state.profileData.displayName);
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
        DashboardSearchBar(
          initialValue: state.searchQuery,
          onSubmitted: notifier.searchDashboard,
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
                imagePath: 'assets/images/weekend.jpg',
                onTap: () async {
                  await notifier.generateHomeRecommendation(
                    occasion: 'Summer',
                    syncCurrentRecommendation: true,
                  );
                  notifier.setIndex(1);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DashboardSeasonCard(
                title: 'Monsoon\nChic',
                imagePath: 'assets/images/travel.jpg',
                onTap: () async {
                  await notifier.generateHomeRecommendation(
                    occasion: 'Monsoon',
                    syncCurrentRecommendation: true,
                  );
                  notifier.setIndex(1);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DashboardSeasonCard(
                title: 'Winter\nLayers',
                imagePath: 'assets/images/outfit.jpg',
                onTap: () async {
                  await notifier.generateHomeRecommendation(
                    occasion: 'Winter',
                    syncCurrentRecommendation: true,
                  );
                  notifier.setIndex(1);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DashboardSeasonCard(
                title: 'Festive\nLooks',
                imagePath: 'assets/images/wedding.jpg',
                onTap: () async {
                  await notifier.generateHomeRecommendation(
                    occasion: 'Festive',
                    syncCurrentRecommendation: true,
                  );
                  notifier.setIndex(1);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
