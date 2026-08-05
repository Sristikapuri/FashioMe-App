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
      const DiscoverEntry(
        id: 'trending-office',
        title: 'Modern Office Edit',
        category: 'Trending',
        imageUrl: 'assets/images/weekend.jpg',
        caption: 'Polished layers for work and meetings.',
        height: 220,
      ),
      const DiscoverEntry(
        id: 'trending-party',
        title: 'Party Evening Look',
        category: 'Trending',
        imageUrl: 'assets/images/party.jpg',
        caption: 'Statement pieces for your next night out.',
        height: 220,
      ),
      const DiscoverEntry(
        id: 'trending-travel',
        title: 'Travel Day Layers',
        category: 'Trending',
        imageUrl: 'assets/images/travel.jpg',
        caption: 'Comfortable layers that still look styled.',
        height: 220,
      ),
      const DiscoverEntry(
        id: 'trending-brunch',
        title: 'Weekend Brunch',
        category: 'Trending',
        imageUrl: 'assets/images/brunch.jpg',
        caption: 'Relaxed styling for daytime plans.',
        height: 220,
      ),
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
              children: [
                DashboardGuideCard(
                  title: 'How to Dress for Your Body Shape',
                  imagePath: 'assets/images/party.jpg',
                  onTap: () => _showArticleDetailSheet(context, mockFashionArticles[4]),
                ),
                const SizedBox(width: 12),
                DashboardGuideCard(
                  title: 'Perfect Colors for Your Skin Tone',
                  imagePath: 'assets/images/brunch.jpg',
                  onTap: () => _showArticleDetailSheet(context, mockFashionArticles[3]),
                ),
                const SizedBox(width: 12),
                DashboardGuideCard(
                  title: 'Occasion Based Outfit Guide',
                  imagePath: 'assets/images/wedding.jpg',
                  onTap: () => _showArticleDetailSheet(context, mockFashionArticles[5]),
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
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mockFashionArticles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final article = mockFashionArticles[index];
                return _ArticleCard(
                  article: article,
                  onTap: () => _showArticleDetailSheet(context, article),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FashionArticle {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String readTime;
  final String author;
  final String date;
  final IconData icon;
  final List<String> paragraphs;
  final List<String> keyTakeaways;

  const FashionArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.readTime,
    required this.author,
    required this.date,
    required this.icon,
    required this.paragraphs,
    required this.keyTakeaways,
  });
}

final List<FashionArticle> mockFashionArticles = [
  const FashionArticle(
    id: 'art-1',
    title: '10 Style Rules Every Fashion Lover Should Know',
    subtitle: 'Simple, essential guidelines for fit, color, and proportion.',
    category: 'FUNDAMENTALS',
    readTime: '4 min read',
    author: 'FashioMe Editorial',
    date: 'August 2026',
    icon: Icons.checkroom_outlined,
    paragraphs: [
      'Fit is the single most important rule in personal style. Clothing that contours your frame without pulling or sagging instantly elevates your appearance, regardless of brand or price tag.',
      'Color balance creates visual harmony. A classic formula is the 60-30-10 rule: 60% dominant neutral base (like charcoal, navy, or beige), 30% complementary secondary tone (white, cream, or soft grey), and 10% accent color (burgundy, emerald, or gold).',
      'Invest in high-quality footwear and leather goods. Shoes are often the first element people notice about an outfit. Keeping them polished and well-maintained instantly grounds your presence.',
    ],
    keyTakeaways: [
      'Prioritize proper fit and tailoring over designer labels.',
      'Limit every outfit to a maximum of 3 core colors.',
      'Maintain your footwear regularly for a polished finish.',
    ],
  ),
  const FashionArticle(
    id: 'art-2',
    title: 'Effortless Everyday Style & Capsule Wardrobes',
    subtitle: 'Build polished, versatile outfits from 10 essential basics.',
    category: 'WARDROBE BUILDING',
    readTime: '5 min read',
    author: 'Sophia Vance',
    date: 'July 2026',
    icon: Icons.wb_sunny_outlined,
    paragraphs: [
      'A capsule wardrobe consists of timeless, versatile pieces that seamlessly mix and match. By curating high-quality essentials, you eliminate decision fatigue every morning.',
      'Start with core neutral foundations: crisp white tops, tailored trousers, dark denim, a neutral blazer, and classic sneakers or loafers. These items form the backbone of dozens of distinct looks.',
      'Elevate simple combinations with intentional accessories—a structured leather bag, delicate jewelry, or classic sunglasses add instant polish.',
    ],
    keyTakeaways: [
      'Curate 10-15 core pieces that work together effortlessly.',
      'Choose breathable, durable fabrics like cotton, wool, and linen.',
      'Use accessories to add personal character to basic outfits.',
    ],
  ),
  const FashionArticle(
    id: 'art-3',
    title: 'Layering Like a Pro for Every Season',
    subtitle: 'Use texture, length, and weight to layer with confidence.',
    category: 'STYLING MASTERCLASS',
    readTime: '3 min read',
    author: 'Marcus Chen',
    date: 'July 2026',
    icon: Icons.layers_outlined,
    paragraphs: [
      'Mastering texture and proportion is the secret to successful layering. Start with your thinnest, most form-fitting garment as a base, then build outwards with structured knits or outerwear.',
      'Mix textures to create visual depth: pair smooth silk or satin with coarse wool cardigans, ribbed knits, or structured trench coats.',
      'Pay attention to hem and collar reveals. A subtle peep of a white tee under a crewneck sweater gives an intentionally styled finish.',
    ],
    keyTakeaways: [
      'Layer garments from thinnest to thickest fabric.',
      'Combine contrasting materials (e.g. leather with soft knitwear).',
      'Leave outer layers unbuttoned for dynamic movement.',
    ],
  ),
  const FashionArticle(
    id: 'art-4',
    title: 'Mastering Seasonal Colors & Skin Undertones',
    subtitle: 'Identify warm vs cool undertones to pick your best shades.',
    category: 'COLOR THEORY',
    readTime: '6 min read',
    author: 'Elena Rostova',
    date: 'June 2026',
    icon: Icons.palette_outlined,
    paragraphs: [
      'Your skin\'s undertone (warm, cool, or neutral) determines which colors illuminate your complexion best. Warm tones thrive in olive, mustard, terracotta, and gold. Cool tones look radiant in sapphire, emerald, slate grey, and crisp white.',
      'Inspect your wrist veins in natural light: greenish veins indicate warm undertones, while blue/purple veins indicate cool undertones.',
    ],
    keyTakeaways: [
      'Match your clothing palette to your natural skin undertones.',
      'Wear your most flattering colors closest to your face.',
      'Monochromatic outfits add vertical height and elegance.',
    ],
  ),
  const FashionArticle(
    id: 'art-5',
    title: 'How to Dress for Your Body Shape',
    subtitle: 'Flatter your silhouette with strategic cuts and proportions.',
    category: 'FIT & SILHOUETTE',
    readTime: '5 min read',
    author: 'FashioMe Editorial',
    date: 'June 2026',
    icon: Icons.accessibility_new_outlined,
    paragraphs: [
      'Dressing for your body shape is about creating visual balance and highlighting your favorite features. Athletic frames benefit from soft draping and waist-cinching, while pear silhouettes shine with structured shoulders.',
      'Vertical lines and monochromatic columns elongate your figure, while high-waisted cuts draw attention to the narrowest part of your torso.',
    ],
    keyTakeaways: [
      'Balance broad shoulders with wider pant leg openings or skirts.',
      'Highlight your waistline with belts or high-waisted cuts.',
      'Use structured shoulders to add posture and stature.',
    ],
  ),
  const FashionArticle(
    id: 'art-6',
    title: 'Occasion-Based Dressing: Casual to Gala',
    subtitle: 'Decipher dress codes for weddings, parties, and corporate events.',
    category: 'DRESS CODES',
    readTime: '4 min read',
    author: 'David Sterling',
    date: 'May 2026',
    icon: Icons.event_available_outlined,
    paragraphs: [
      'Navigating dress codes requires striking the sweet spot between comfort and respect for the event. Smart Casual bridges relaxed and refined—think tailored chinos, silk blouses, or clean loafers.',
      'Cocktail and Gala attire call for luxurious fabrics like velvet, satin, and lace, complemented by refined jewelry and sleek tailoring.',
    ],
    keyTakeaways: [
      'When in doubt, being slightly overdressed is always chic.',
      'Adapt fabric choices to the event\'s location and climate.',
      'Ensure garments are freshly pressed and steamed.',
    ],
  ),
];

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.article,
    required this.onTap,
  });

  final FashionArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 220,
      child: DashboardLuxuryCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  article.icon,
                  color: AppColors.primary,
                  size: 26,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    article.readTime,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              article.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              article.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DashboardPalette.mutedText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showArticleDetailSheet(BuildContext context, FashionArticle article) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      article.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 22,
                        height: 1.25,
                        fontFamily: AppFonts.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          article.author,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                        Text(
                          article.date,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            article.readTime,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),
                    ...article.paragraphs.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          p,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DashboardPalette.gold.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: DashboardPalette.gold, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Key Takeaways',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...article.keyTakeaways.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('✓ ', style: TextStyle(color: DashboardPalette.gold, fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.bookmark_border),
                        label: const Text('Save Article to Bookmarks'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('"${article.title}" saved to your bookmarks!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
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
                  : ListView.separated(
                      itemCount: mockFashionArticles.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final article = mockFashionArticles[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _showArticleDetailSheet(context, article);
                          },
                          child: DashboardLuxuryCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    article.icon,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        article.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        article.subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: DashboardPalette.mutedText,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right,
                                  color: DashboardPalette.mutedText,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final palette = state.currentRecommendation.palette;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
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
        ),
      );
    },
  );
}
