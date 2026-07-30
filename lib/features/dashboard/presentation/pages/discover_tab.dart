import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/app/di/providers.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/extensions/context_extensions.dart';
import 'package:fashio_me/features/dashboard/domain/utils/occasion_recommender.dart';
import 'package:fashio_me/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_color_dot.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_discover_look_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_filter_chip.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_for_you_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_guide_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_luxury_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_network_image.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_palette.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_section_title.dart';

class DiscoverTab extends ConsumerStatefulWidget {
  const DiscoverTab({super.key, required this.state});

  final DashboardState state;

  @override
  ConsumerState<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<DiscoverTab> {
  bool _forYouLoading = true;
  DashboardRecommendation? _forYou;
  List<String> _archiveOccasions = const [];
  List<String> _wardrobeCategories = const [];
  String _autoOccasion = kRecommendableOccasions.first;

  @override
  void initState() {
    super.initState();
    _loadForYou();
  }

  Future<void> _loadForYou() async {
    setState(() => _forYouLoading = true);

    var archiveOccasions = <String>[];
    try {
      final entries = await ref.read(getStyleArchiveUsecaseProvider)();
      archiveOccasions = entries
          .map((entry) => normalizeArchiveOccasion(entry.occasion))
          .take(12)
          .toList();
    } catch (_) {
      // Archive history is a secondary signal; ignore failures.
    }

    final wardrobeCategories = widget.state.wardrobeItems
        .map((item) => item.category)
        .where((category) => category.trim().isNotEmpty)
        .toSet()
        .take(6)
        .toList();

    final autoOccasion = deriveBestOccasion(
      widget.state.profileData,
      wardrobeCategories,
      archiveOccasions,
    );

    final forYou = await ref
        .read(dashboardViewModelProvider.notifier)
        .generateRecommendation(
          occasion: autoOccasion,
          profileData: widget.state.profileData,
          preferenceScores: widget.state.stylePreferenceScores,
        );

    if (!mounted) return;
    setState(() {
      _archiveOccasions = archiveOccasions;
      _wardrobeCategories = wardrobeCategories;
      _autoOccasion = autoOccasion;
      _forYou = forYou;
      _forYouLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    final filters = [
      'Trending',
      'Celebrity',
      'Traditional',
      'Minimal',
      'Color Guide',
    ];
    final items = state.discoverItems.where((item) {
      if (state.discoverFilter == 'Trending') return true;
      return item.category.toLowerCase().contains(
        state.discoverFilter.toLowerCase(),
      );
    }).toList();
    final dailyFallback = DiscoverEntry(
      id: 'daily-${DateTime.now().toIso8601String().substring(0, 10)}',
      title: state.currentRecommendation.title,
      category: 'Trending',
      imageUrl: state.currentRecommendation.imageUrl,
      caption: state.currentRecommendation.explanation,
      height: 220,
    );
    final visibleItems = items.isNotEmpty
        ? items
        : (state.discoverItems.isNotEmpty
              ? state.discoverItems
              : [dailyFallback]);
    final trendingItems = <DiscoverEntry>[
      dailyFallback,
      ...visibleItems.where((item) => item.id != dailyFallback.id),
      const DiscoverEntry(id: 'trending-office', title: 'Modern Office Edit', category: 'Trending', imageUrl: 'assets/images/weekend.jpg', caption: 'Polished layers for work and meetings.', height: 220),
      const DiscoverEntry(id: 'trending-party', title: 'Party Evening Look', category: 'Trending', imageUrl: 'assets/images/party.jpg', caption: 'Statement pieces for your next night out.', height: 220),
      const DiscoverEntry(id: 'trending-travel', title: 'Travel Day Layers', category: 'Trending', imageUrl: 'assets/images/travel.jpg', caption: 'Comfortable layers that still look styled.', height: 220),
      const DiscoverEntry(id: 'trending-brunch', title: 'Weekend Brunch', category: 'Trending', imageUrl: 'assets/images/brunch.jpg', caption: 'Relaxed styling for daytime plans.', height: 220),
    ];

    return RefreshIndicator(
      onRefresh: _loadForYou,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 140),
        children: [
          DashboardForYouCard(
            loading: _forYouLoading,
            forYou: _forYou,
            autoOccasion: _autoOccasion,
            autoReason: deriveAutoReason(state.profileData),
            decisionReasons: explainOccasionChoice(
              state.profileData,
              _wardrobeCategories,
              _archiveOccasions,
              _autoOccasion,
            ),
            wardrobeCount: state.wardrobeItems.length,
            wardrobeCategories: _wardrobeCategories,
            profileData: state.profileData,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = filters[index];
                return DashboardFilterChip(
                  label: filter,
                  selected: filter == state.discoverFilter,
                  onTap: () => notifier.setDiscoverFilter(filter),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          DashboardSectionTitle(
            title: 'Trending Looks',
            actionLabel: 'View All',
            onAction: () => _showDiscoverSectionSheet(
              context,
              'Trending Looks',
              trendingItems: trendingItems,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trendingItems.length > 5 ? 5 : trendingItems.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: 148,
                child: DashboardDiscoverLookCard(
                  item: trendingItems[index],
                  onTap: () => notifier.saveDiscoverItem(trendingItems[index]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          DashboardSectionTitle(
            title: 'Color Inspiration',
            actionLabel: 'View All',
            onAction: () => _showColorInspirationSheet(context, state),
          ),
          const SizedBox(height: 12),
          DashboardLuxuryCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: state.currentRecommendation.palette
                  .map((color) => DashboardColorDot(color: Color(color)))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          DashboardSectionTitle(
            title: 'Style Guides',
            actionLabel: 'View All',
            onAction: () => _showDiscoverSectionSheet(context, 'Style Guides'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 178,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                DashboardGuideCard(
                  title: 'How to Dress for Your Body Shape',
                  imagePath: 'assets/images/party.jpg',
                ),
                SizedBox(width: 12),
                DashboardGuideCard(
                  title: 'Perfect Colors for Your Skin Tone',
                  imagePath: 'assets/images/brunch.jpg',
                ),
                SizedBox(width: 12),
                DashboardGuideCard(
                  title: 'Occasion Based Outfit Guide',
                  imagePath: 'assets/images/wedding.jpg',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DashboardSectionTitle(
            title: 'Fashion Tips & Articles',
            actionLabel: 'View All',
            onAction: () =>
                _showDiscoverSectionSheet(context, 'Fashion Tips & Articles'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 178,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _ArticleCard(title: '10 Style Tips Every Man Should Know', subtitle: 'Simple rules for fit, color, and proportion.'),
                SizedBox(width: 12),
                _ArticleCard(title: 'Effortless Everyday Style', subtitle: 'Build polished outfits from versatile basics.'),
                SizedBox(width: 12),
                _ArticleCard(title: 'Layering Like a Pro', subtitle: 'Use texture and proportion to layer confidently.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: DashboardLuxuryCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 28),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: DashboardPalette.mutedText, fontSize: 12)),
        ],
      ),
    ),
  );
}

void _showDiscoverSectionSheet(
  BuildContext context,
  String title, {
  List<DiscoverEntry>? trendingItems,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Container(
        height: context.screenHeight * 0.75,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 22,
                    fontFamily: AppFonts.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: trendingItems != null && trendingItems.isNotEmpty
                  ? ListView.separated(
                      itemCount: trendingItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = trendingItems[index];
                        return DashboardLuxuryCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: DashboardNetworkImage(
                                  url: item.imageUrl,
                                  height: 70,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.caption,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: DashboardPalette.mutedText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : ListView(
                      children: const [
                        ListTile(
                          leading: Icon(
                            Icons.article_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            'Mastering Seasonal Colors',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Understand color harmony based on warm vs cool skin undertones.',
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.article_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            'Building a Capsule Wardrobe',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Essential 10 pieces that give you over 30 distinct outfit combinations.',
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.article_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            'Footwear & Silhouette Pairing',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Which shoes suit slim vs athletic body cuts.',
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    },
  );
}

void _showColorInspirationSheet(BuildContext context, DashboardState state) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final palette = state.currentRecommendation.palette;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Color Inspiration Palette',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 22,
                fontFamily: AppFonts.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personalized for your ${state.profileData.skinTone} skin tone and style preference.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: palette.map((colorHex) {
                final color = Color(colorHex);
                final hexStr =
                    '#${colorHex.toRadixString(16).substring(2).toUpperCase()}';
                return Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: AppColors.softShadow,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hexStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Done',
                  style: TextStyle(fontFamily: AppFonts.bold),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
