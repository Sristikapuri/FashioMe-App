import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/utils/snackbar_utils.dart';
import 'package:fashio_me/core/widgets/selected_image.dart';
import 'package:fashio_me/features/auth/presentation/pages/login_page.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_session_providers.dart';
import 'package:fashio_me/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:fashio_me/features/silhouette/domain/entities/silhouette_profile.dart';
import 'package:fashio_me/features/silhouette/presentation/providers/silhouette_profile_providers.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final TextEditingController _wardrobeSearchController;
  late final TextEditingController _discoverSearchController;
  String _wardrobeQuery = '';
  String _discoverQuery = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _wardrobeSearchController = TextEditingController();
    _discoverSearchController = TextEditingController();
    _wardrobeSearchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _wardrobeQuery = _wardrobeSearchController.text.trim().toLowerCase();
      });
    });
    _discoverSearchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _discoverQuery = _discoverSearchController.text.trim().toLowerCase();
      });
    });
    _fadeController.forward();
    _slideController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authSessionViewModelProvider.notifier).restoreSession();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _wardrobeSearchController.dispose();
    _discoverSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final silhouetteProfile = ref
        .watch(silhouetteProfileProvider)
        .maybeWhen(data: (profile) => profile, orElse: () => null);

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: _buildAppBar(dashboardState),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            ref.read(dashboardViewModelProvider.notifier).setIndex(index);
          },
          children: [
            _homeTab(dashboardState),
            _aiSyncTab(dashboardState),
            _wardrobeTab(dashboardState),
            _discoverTab(dashboardState),
            _ProfileTab(silhouetteProfile: silhouetteProfile),
          ],
        ),
      ),
      floatingActionButton: dashboardState.currentIndex == 2
          ? FloatingActionButton.extended(
              onPressed: _showAddOutfitDialog,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Outfit'),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(dashboardState),
    );
  }

  PreferredSizeWidget _buildAppBar(DashboardState state) {
    final firstName = state.profileData.displayName.split(' ').first;
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return AppBar(
      backgroundColor: AppColors.dashboardBackground,
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $firstName',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Ready to discover today\'s perfect look?',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.softShadow,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          onPressed: () {
            showAppSnackBar(
              context,
              'Style alerts are ${state.profileData.notificationsEnabled ? 'enabled' : 'disabled'} in your profile.',
              isError: false,
            );
          },
        ),
        const SizedBox(width: 8),
        Container(
          margin: const EdgeInsets.only(right: 16),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: const DecorationImage(
              image: AssetImage('assets/app_icon/fashiome_app_icon.jpg'),
              fit: BoxFit.cover,
            ),
            boxShadow: AppColors.softShadow,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(DashboardState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(
                child: _buildNavItem(
                  0,
                  Icons.home_rounded,
                  'Home',
                  state.currentIndex == 0,
                ),
              ),
              Flexible(
                child: _buildNavItem(
                  1,
                  Icons.smart_toy_rounded,
                  'AI Sync',
                  state.currentIndex == 1,
                ),
              ),
              Flexible(
                child: _buildNavItem(
                  2,
                  Icons.checkroom_rounded,
                  'Wardrobe',
                  state.currentIndex == 2,
                ),
              ),
              Flexible(
                child: _buildNavItem(
                  3,
                  Icons.explore_rounded,
                  'Discover',
                  state.currentIndex == 3,
                ),
              ),
              Flexible(
                child: _buildNavItem(
                  4,
                  Icons.person_rounded,
                  'Profile',
                  state.currentIndex == 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(dashboardViewModelProvider.notifier).setIndex(index);
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accent : AppColors.navUnselected,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.navUnselected,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ HOME TAB ============
  Widget _homeTab(DashboardState state) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHomeWelcome(state),
        const SizedBox(height: 20),

        // AI Style of the Day Section
        _buildAIStyleOfDaySection(state),
        const SizedBox(height: 24),

        // Action Buttons
        _buildActionButtons(state),
        const SizedBox(height: 24),

        // Recommended For You
        _buildSectionHeader(
          'Recommended For You',
          () => _goToTab(1, 'See all recommendations'),
        ),
        const SizedBox(height: 14),
        _recommendedCarousel(state),
        const SizedBox(height: 24),

        // Colors That Suit You
        _buildSectionHeader('Colors That Suit You', null),
        const SizedBox(height: 14),
        _buildColorChipsSection(),
        const SizedBox(height: 24),

        // Hairstyle Suggestion
        _buildHairstyleSuggestionCard(),
        const SizedBox(height: 24),

        // Your Style Profile
        _buildStyleProfileSection(state),
        const SizedBox(height: 24),

        // Occasion-Based Suggestions
        _buildSectionHeader('Today\'s Occasion Ideas', null),
        const SizedBox(height: 14),
        _buildOccasionIdeaChips(),
        const SizedBox(height: 24),

        // Trending Styles
        _buildSectionHeader('Trending Styles', null),
        const SizedBox(height: 14),
        _trendingStylesCarousel(),
        const SizedBox(height: 24),

        // Recently Saved
        _buildSectionHeader('Recently Saved', null),
        const SizedBox(height: 14),
        _recentlySavedCarousel(state),
      ],
    );
  }

  Widget _buildHomeWelcome(DashboardState state) {
    final firstName = state.profileData.displayName.trim().isEmpty
        ? 'there'
        : state.profileData.displayName.trim().split(' ').first;
    final paletteHint = state.aiStyleOfDay.paletteLabels.take(2).join(' + ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $firstName',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${state.profileData.styleMood} style, ${state.profileData.bodyType.toLowerCase()} build, ${paletteHint.isEmpty ? state.profileData.skinTone.toLowerCase() : paletteHint.toLowerCase()} palette.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIStyleOfDaySection(DashboardState state) {
    final recommendation = state.aiStyleOfDay;
    final outfitParts = recommendation.outfit
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .take(3)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'AI Style of the Day',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Outfit Image
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: recommendation.imageUrl.isNotEmpty
                      ? Image.network(
                          recommendation.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Personalized for your ${state.profileData.bodyType.toLowerCase()} body type, ${state.profileData.skinTone.toLowerCase()} skin tone, and ${state.profileData.styleMood.toLowerCase()} mood.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag(recommendation.occasion, AppColors.accent),
                    _buildTag(recommendation.category, AppColors.accent),
                    _buildTag('AI 89%', AppColors.accent),
                  ],
                ),
                const SizedBox(height: 12),
                for (final part in outfitParts) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.accent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          part,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showWhyThisWorks(recommendation),
                  child: Row(
                    children: [
                      const Text(
                        'Why this works',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.accent,
                        size: 12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactActionButton(
                        icon: Icons.visibility_outlined,
                        label: 'View Details',
                        onTap: () => _showRecommendationDetail(recommendation),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCompactActionButton(
                        icon: Icons.favorite_border,
                        label: 'Save',
                        onTap: () async {
                          await ref
                              .read(dashboardViewModelProvider.notifier)
                              .saveRecommendation(recommendation);
                          if (!mounted) return;
                          _goToTab(2, 'Saved to Wardrobe');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(DashboardState state) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.camera_alt_rounded,
            label: 'Analyze My Style',
            onTap: () => _goToTab(1, 'Analyze outfit'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.auto_awesome_rounded,
            label: 'Generate Outfit',
            onTap: () async {
              final recommendation = await ref
                  .read(dashboardViewModelProvider.notifier)
                  .generateFreshHomeRecommendation();
              if (!mounted) return;
              showAppSnackBar(
                context,
                '${recommendation.occasion} ${recommendation.category.toLowerCase()} look generated',
                isError: false,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.chat_bubble_rounded,
            label: 'Ask AI Stylist',
            onTap: () => _openChatBot(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.accent, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorChipsSection() {
    final recommendation = ref.watch(dashboardViewModelProvider).aiStyleOfDay;
    final colors = List.generate(recommendation.palette.length, (index) {
      return {
        'color': recommendation.palette[index],
        'name': recommendation.paletteLabels.length > index
            ? recommendation.paletteLabels[index]
            : 'Color ${index + 1}',
      };
    }).take(6).toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((colorData) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Color(colorData['color'] as int),
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.softShadow,
          ),
          child: Text(
            colorData['name'] as String,
            style: TextStyle(
              color: _getContrastColor(Color(colorData['color'] as int)),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHairstyleSuggestionCard() {
    final state = ref.watch(dashboardViewModelProvider);
    final hairstyle = state.aiStyleOfDay.hairstyle;
    final title = hairstyle.split('.').first.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.face_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hairstyle Suggestion',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title.isEmpty ? 'Soft layered hair' : title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recommended for your ${state.profileData.faceShape.toLowerCase()} face shape.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: AppColors.textLight, size: 16),
        ],
      ),
    );
  }

  Widget _buildStyleProfileSection(DashboardState state) {
    final profile = state.profileData;
    final favoriteColors = state.aiStyleOfDay.paletteLabels.take(2).join(', ');
    final mostSelected = state.stylePreferenceScores.isEmpty
        ? profile.stylePreferences.first
        : state.stylePreferenceScores.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key;
    final styleScore = (82 + state.preferenceScore).clamp(82, 99);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Style Profile',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildProfileItem('Style: ${profile.styleMood}', Icons.style_rounded),
          const SizedBox(height: 8),
          _buildProfileItem(
            'Body type: ${profile.bodyType}',
            Icons.accessibility_new_rounded,
          ),
          const SizedBox(height: 8),
          _buildProfileItem(
            'Skin tone: ${profile.skinTone}',
            Icons.face_rounded,
          ),
          const SizedBox(height: 8),
          _buildProfileItem(
            'Favorite colors: ${favoriteColors.isEmpty ? 'Neutral tones' : favoriteColors}',
            Icons.palette_rounded,
          ),
          const SizedBox(height: 8),
          _buildProfileItem(
            'Most selected: $mostSelected',
            Icons.checkroom_rounded,
          ),
          const SizedBox(height: 8),
          _buildProfileItem(
            'Style score: $styleScore%',
            Icons.insights_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildOccasionIdeaChips() {
    final occasions = [
      {'label': 'College', 'icon': Icons.school_rounded},
      {'label': 'Office', 'icon': Icons.work_rounded},
      {'label': 'Party', 'icon': Icons.celebration_rounded},
      {'label': 'Travel', 'icon': Icons.flight_takeoff_rounded},
    ];

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: occasions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final occasion = occasions[index];
          final label = occasion['label'] as String;
          return GestureDetector(
            onTap: () async {
              final recommendation = await ref
                  .read(dashboardViewModelProvider.notifier)
                  .generateHomeRecommendation(
                    occasion: label,
                    syncCurrentRecommendation: true,
                  );
              if (!context.mounted) return;
              showAppSnackBar(
                context,
                '${recommendation.occasion} outfit generated',
                isError: false,
              );
            },
            child: Container(
              width: 118,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    occasion['icon'] as IconData,
                    color: AppColors.accent,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _trendingStylesCarousel() {
    final trendingStyles = [
      {'name': 'Minimalist', 'image': 'assets/images/outfit.jpg'},
      {'name': 'Bohemian', 'image': 'assets/images/party.jpg'},
      {'name': 'Streetwear', 'image': 'assets/images/travel.jpg'},
      {'name': 'Classic', 'image': 'assets/images/wedding.jpg'},
    ];

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: trendingStyles.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final style = trendingStyles[index];
          return Container(
            width: 120,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          style['image'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppColors.accentGradient,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.style_rounded,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.26),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    style['name'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _recentlySavedCarousel(DashboardState state) {
    final savedItems = state.wardrobeItems.take(5).toList();

    if (savedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow,
        ),
        child: const Center(
          child: Text(
            'No saved items yet',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: savedItems.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = savedItems[index];
          return Container(
            width: 120,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.checkroom_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 32,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'See all',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.accentLight.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'AI Recommended Outfit',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWhyThisWorks(DashboardRecommendation recommendation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: AppColors.accent),
                const SizedBox(width: 10),
                const Text(
                  'Why This Suits You',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              recommendation.explanation,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            _buildPaletteSection(recommendation),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteSection(dynamic recommendation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.palette_rounded,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Color Palette',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (
              var i = 0;
              i < recommendation.palette.length && i < 4;
              i++
            ) ...[
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(recommendation.palette[i]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      recommendation.paletteLabels.length > i
                          ? recommendation.paletteLabels[i]
                          : '',
                      style: TextStyle(
                        color: _getContrastColor(
                          Color(recommendation.palette[i]),
                        ),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if (i < 3) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? AppColors.textPrimary : Colors.white;
  }

  Widget _buildExplanationCard(dynamic recommendation) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentLight.withValues(alpha: 0.12),
            AppColors.accentLight.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Why This Works',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.explanation,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendedCarousel(DashboardState state) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.homeRecommendations.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final rec = state.homeRecommendations[index];
          return _buildCarouselCard(rec);
        },
      ),
    );
  }

  Widget _buildCarouselCard(DashboardRecommendation rec) {
    return GestureDetector(
      onTap: () => _showRecommendationDetail(rec),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 130,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: rec.imageUrl.isNotEmpty
                        ? Image.network(rec.imageUrl, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.accentLight.withValues(alpha: 0.3),
                            child: const Icon(
                              Icons.style_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rec.category,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.occasion,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rec.mood,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecommendationDetail(DashboardRecommendation rec) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                        ),
                        child: rec.imageUrl.isNotEmpty
                            ? Image.network(rec.imageUrl, fit: BoxFit.cover)
                            : _buildImagePlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      rec.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildTag(rec.occasion, AppColors.accent),
                        _buildTag(rec.category, AppColors.accent),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildRecommendationSection(
                      icon: Icons.style_rounded,
                      title: 'Outfit',
                      content: rec.outfit,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 12),
                    _buildRecommendationSection(
                      icon: Icons.face_rounded,
                      title: 'Hairstyle',
                      content: rec.hairstyle,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 12),
                    _buildPaletteSection(rec),
                    const SizedBox(height: 16),
                    _buildExplanationCard(rec),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.thumb_up_outlined,
                            label: 'Like',
                            onTap: () async {
                              await ref
                                  .read(dashboardViewModelProvider.notifier)
                                  .likeRecommendation(rec);
                              if (!mounted) return;
                              Navigator.pop(context);
                              _goToTab(2, 'Saved to Wardrobe');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.thumb_down_outlined,
                            label: 'Regenerate',
                            onTap: () {
                              ref
                                  .read(dashboardViewModelProvider.notifier)
                                  .selectRecommendation(rec);
                              ref
                                  .read(dashboardViewModelProvider.notifier)
                                  .dislikeCurrentRecommendation();
                              Navigator.pop(context);
                            },
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

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============ AI SYNC TAB ============
  Widget _aiSyncTab(DashboardState state) {
    final hasResults = state.hasCompletedStyleAnalysis;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        Row(
          children: [
            GestureDetector(
              onTap: () => _goToTab(0, 'Back to home'),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.softShadow,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Style Sync',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Analyze your style with AI',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Upload Section
        _buildUploadSection(state),
        const SizedBox(height: 24),

        if (state.isUploading) ...[
          _buildAnalysisLoadingCard(state),
          const SizedBox(height: 24),
        ],

        // Show results only after analysis
        if (hasResults) ...[
          // AI Analysis Section
          _buildAIAnalysisSection(state),
          const SizedBox(height: 24),

          // Recommended Outfit
          _buildRecommendedOutfitSection(state),
          const SizedBox(height: 24),

          // Recommended Hairstyle
          _buildRecommendedHairstyleSection(state),
          const SizedBox(height: 24),

          // Best Colors
          _buildBestColorsSection(state),
          const SizedBox(height: 24),

          // Why This Works
          _buildWhyThisWorksSection(state),
          const SizedBox(height: 24),

          // Action Buttons
          _buildAIActionButtons(state),
        ],
      ],
    );
  }

  Widget _buildUploadSection(DashboardState state) {
    final selectedPath = state.selectedImagePath;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Upload Your Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Image Preview
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.accentLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedPath != null
                    ? AppColors.accent.withValues(alpha: 0.3)
                    : AppColors.divider,
                width: selectedPath != null ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: selectedPath == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 48,
                          color: AppColors.accent.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No image selected',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        buildSelectedImage(
                          selectedPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  size: 48,
                                ),
                              ),
                        ),
                        if (state.uploadProgress > 0)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 6,
                              color: Colors.white.withValues(alpha: 0.9),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: state.uploadProgress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.accentGradient,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Upload Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildUploadButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onPressed: state.isUploading
                        ? null
                        : () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUploadButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onPressed: state.isUploading
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Analyze Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildAnalyzeButton(state),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisSection(DashboardState state) {
    final profile = state.profileData;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAnalysisRow('Body Type', profile.bodyType),
          const SizedBox(height: 12),
          _buildAnalysisRow('Face Shape', profile.faceShape),
          const SizedBox(height: 12),
          _buildAnalysisRow('Skin Tone', profile.skinTone),
          const SizedBox(height: 12),
          _buildAnalysisRow(
            'Style Preference',
            profile.stylePreferences.isEmpty
                ? profile.styleMood
                : profile.stylePreferences.first,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisLoadingCard(DashboardState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              state.aiProcessingMessage.isEmpty
                  ? 'Analyzing your style...'
                  : state.aiProcessingMessage,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedOutfitSection(DashboardState state) {
    final rec = state.currentRecommendation.outfit.isNotEmpty
        ? state.currentRecommendation
        : state.aiStyleOfDay;
    final outfitParts = rec.outfit
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .take(4)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.checkroom_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Recommended Outfit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Outfit Image
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: rec.imageUrl.isNotEmpty
                      ? Image.network(
                          rec.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),
              ],
            ),
          ),
          // Outfit Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag(rec.occasion, AppColors.accent),
                    _buildTag(rec.category, AppColors.accent),
                  ],
                ),
                const SizedBox(height: 12),
                for (final part in outfitParts) ...[
                  Text(
                    part,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactActionButton(
                        icon: Icons.visibility_outlined,
                        label: 'View Details',
                        onTap: () => _showRecommendationDetail(rec),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCompactActionButton(
                        icon: Icons.refresh_rounded,
                        label: 'Generate Another',
                        onTap: () {
                          ref
                              .read(dashboardViewModelProvider.notifier)
                              .dislikeCurrentRecommendation();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedHairstyleSection(DashboardState state) {
    final rec = state.currentRecommendation.outfit.isNotEmpty
        ? state.currentRecommendation
        : state.aiStyleOfDay;
    final hairstyleTitle = rec.hairstyle.split('.').first.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.face_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended Hairstyle',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hairstyleTitle.isEmpty ? 'Soft Layered Hair' : hairstyleTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recommended because your face shape is ${state.profileData.faceShape}.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestColorsSection(DashboardState state) {
    final rec = state.currentRecommendation.outfit.isNotEmpty
        ? state.currentRecommendation
        : state.aiStyleOfDay;
    final colors = rec.palette.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Best Colors',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(colors.length, (index) {
              final color = Color(colors[index]);
              final label = rec.paletteLabels.length > index
                  ? rec.paletteLabels[index]
                  : 'Color';
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.divider),
                      boxShadow: AppColors.softShadow,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyThisWorksSection(DashboardState state) {
    final rec = state.currentRecommendation.outfit.isNotEmpty
        ? state.currentRecommendation
        : state.aiStyleOfDay;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why This Recommendation?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            rec.explanation.isNotEmpty
                ? rec.explanation
                : 'This outfit balances your body proportions and complements your ${state.profileData.skinTone.toLowerCase()} skin tone.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIActionButtons(DashboardState state) {
    return Row(
      children: [
        Expanded(
          child: _buildAIActionButton(
            icon: Icons.thumb_up_rounded,
            label: 'Like',
            onTap: () async {
              await ref
                  .read(dashboardViewModelProvider.notifier)
                  .likeCurrentRecommendation();
              if (!mounted) return;
              _goToTab(2, 'Saved to Wardrobe');
            },
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAIActionButton(
            icon: Icons.thumb_down_rounded,
            label: 'Dislike',
            onTap: () {
              ref
                  .read(dashboardViewModelProvider.notifier)
                  .dislikeCurrentRecommendation();
            },
            isPrimary: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAIActionButton(
            icon: Icons.favorite_rounded,
            label: 'Save to Wardrobe',
            onTap: () async {
              await ref
                  .read(dashboardViewModelProvider.notifier)
                  .saveCurrentRecommendation();
              if (!mounted) return;
              _goToTab(2, 'Saved to Wardrobe');
            },
            isPrimary: false,
          ),
        ),
      ],
    );
  }

  Widget _buildAIActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.accent : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: AppColors.divider),
          boxShadow: isPrimary ? AppColors.buttonShadow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : AppColors.textPrimary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isPrimary ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
        foregroundColor: AppColors.accent,
      ),
    );
  }

  Widget _buildAnalyzeButton(DashboardState state) {
    return Container(
      decoration: BoxDecoration(
        gradient: state.selectedImagePath != null && !state.isUploading
            ? AppColors.accentGradient
            : null,
        color: state.selectedImagePath == null || state.isUploading
            ? AppColors.disabled
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: state.selectedImagePath != null && !state.isUploading
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: state.selectedImagePath != null && !state.isUploading
              ? () async {
                  final success = await ref
                      .read(dashboardViewModelProvider.notifier)
                      .uploadSelectedImage();
                  if (!mounted) return;
                  final message = ref
                      .read(dashboardViewModelProvider)
                      .uploadMessage;
                  if (message != null) {
                    showAppSnackBar(context, message, isError: !success);
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.isUploading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                const SizedBox(width: 10),
                Text(
                  state.isUploading ? 'Analyzing...' : 'Analyze Image',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ WARDROBE TAB ============
  Widget _wardrobeTab(DashboardState state) {
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    final savedLooks =
        state.wardrobeItems.where((entry) => entry.entryType == 'look').toList()
          ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    final filteredLooks = savedLooks.where((item) {
      final filter = state.wardrobeFilter;
      final matchesFilter = filter == 'All' || item.category == filter;
      final query = _wardrobeQuery;
      final matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.outfit.toLowerCase().contains(query) ||
          item.hairstyle.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
    final favoriteItems = savedLooks.where((item) => item.isFavorite).toList();
    final recentlyAdded = savedLooks.take(4).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'My Wardrobe',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _showAddOutfitDialog,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Add Yours'),
            ),
          ],
        ),
        Text(
          'Save AI recommendations, favorite looks, and outfits you create yourself.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _buildSearchField(
          controller: _wardrobeSearchController,
          hintText: 'Search "Black Dress"',
        ),
        const SizedBox(height: 20),
        const Text(
          'Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildCategoryChips(state, notifier),
        const SizedBox(height: 24),
        _buildSectionHeader('Saved Outfits', null),
        const SizedBox(height: 14),
        if (savedLooks.isEmpty)
          _buildEmptyCloset()
        else if (filteredLooks.isEmpty)
          _buildSimplePlaceholder(
            'No outfits match your search or selected category.',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredLooks.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final item = filteredLooks[index];
              return _buildOutfitCard(item);
            },
          ),
        const SizedBox(height: 24),
        _buildSectionHeader('Recently Added', null),
        const SizedBox(height: 14),
        if (recentlyAdded.isEmpty)
          _buildSimplePlaceholder('No recently added outfits yet.')
        else
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentlyAdded.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) =>
                  _buildOutfitCard(recentlyAdded[index]),
            ),
          ),
        const SizedBox(height: 24),
        _buildSectionHeader('Favorite Outfits ❤️', null),
        const SizedBox(height: 14),
        if (favoriteItems.isEmpty)
          _buildSimplePlaceholder('No favorite outfits yet.')
        else
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favoriteItems.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) =>
                  _buildOutfitCard(favoriteItems[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryChips(DashboardState state, dynamic notifier) {
    final categories = {
      'All',
      'Casual',
      'Formal',
      'Party',
      'Smart',
      'Relaxed',
      'Elegant',
      'Bold',
      'Streetwear',
      'Custom Outfit',
      ...state.wardrobeItems
          .where((item) => item.entryType == 'look')
          .map((item) => item.category)
          .where((category) => category.trim().isNotEmpty),
    }.toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((cat) {
        final isSelected = state.wardrobeFilter == cat;
        return GestureDetector(
          onTap: () => notifier.setWardrobeFilter(cat),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? null : Border.all(color: AppColors.divider),
              boxShadow: isSelected
                  ? AppColors.buttonShadow
                  : AppColors.softShadow,
            ),
            child: Text(
              cat,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOutfitCard(WardrobeEntry item) {
    return GestureDetector(
      onTap: () => _showWardrobeDetails(item),
      onLongPress: () => _showDeleteWardrobeConfirmation(item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: item.imageUrl.isEmpty
                            ? AppColors.accentGradient
                            : null,
                      ),
                      child: item.imageUrl.isEmpty
                          ? Center(
                              child: Icon(
                                Icons.checkroom_rounded,
                                color: Colors.white.withValues(alpha: 0.72),
                                size: 36,
                              ),
                            )
                          : _buildWardrobeImage(
                              item.imageUrl,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(dashboardViewModelProvider.notifier)
                            .toggleWardrobeFavorite(item);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: item.isFavorite
                              ? AppColors.error
                              : AppColors.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatSavedDate(item.savedAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.outfit.isEmpty ? item.tag : item.outfit,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCloset() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.checkroom_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No saved outfits yet.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save recommendations from AI Sync or add your own outfit to start building your digital closet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _goToTab(1, 'Opened AI Sync to generate an outfit'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Generate Outfit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  Widget _buildSimplePlaceholder(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textLight,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildWardrobeImage(String source, {required BoxFit fit}) {
    if (source.startsWith('http')) {
      return Image.network(
        source,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }
    return buildSelectedImage(
      source,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
    );
  }

  Future<void> _showDeleteWardrobeConfirmation(WardrobeEntry item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Outfit'),
        content: Text('Remove "${item.title}" from your wardrobe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    ref.read(dashboardViewModelProvider.notifier).removeWardrobeItem(item);
    if (!mounted) return;
    showAppSnackBar(
      context,
      'Outfit removed from your wardrobe.',
      isError: false,
    );
  }

  void _showWardrobeDetails(WardrobeEntry item) {
    final outfitItems = item.outfit
        .split(RegExp(r'[•,]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final paletteLabels = item.paletteLabels.isEmpty
        ? const ['Neutral']
        : item.paletteLabels;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 250,
                  child: item.imageUrl.isEmpty
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.style_rounded,
                              size: 60,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        )
                      : _buildWardrobeImage(item.imageUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMetaChip(item.category),
                  _buildMetaChip('Saved ${_formatSavedDate(item.savedAt)}'),
                  if (item.isFavorite) _buildMetaChip('Favorite'),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Items Included',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...(outfitItems.isEmpty ? [item.title] : outfitItems).map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildOutfitItem(entry, item.category),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recommended Hairstyle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.hairstyle.isEmpty ? 'Soft natural waves' : item.hairstyle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recommended Colors',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: paletteLabels.map(_buildMetaChip).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'AI Explanation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.explanation.isEmpty
                    ? 'A clean, versatile outfit saved in your wardrobe for easy styling.'
                    : item.explanation,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailActionButton(
                      icon: item.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: item.isFavorite ? 'Unfavorite' : 'Favorite',
                      onTap: () {
                        ref
                            .read(dashboardViewModelProvider.notifier)
                            .toggleWardrobeFavorite(item);
                        Navigator.pop(context);
                        showAppSnackBar(
                          context,
                          item.isFavorite
                              ? 'Removed from favorites.'
                              : 'Added to favorites.',
                          isError: false,
                        );
                      },
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove',
                      onTap: () {
                        Navigator.pop(context);
                        _showDeleteWardrobeConfirmation(item);
                      },
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailActionButton(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Wear Today',
                      onTap: () {
                        Navigator.pop(context);
                        showAppSnackBar(
                          context,
                          'Marked "${item.title}" as your look for today.',
                          isError: false,
                        );
                      },
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailActionButton(
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onTap: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text:
                                '${item.title}\n${item.category} outfit\n${item.explanation}',
                          ),
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        showAppSnackBar(
                          context,
                          'Outfit details copied to clipboard.',
                          isError: false,
                        );
                      },
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
        ),
      ),
    );
  }

  String _formatSavedDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showAddOutfitDialog() {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCategory = 'Casual';
    String imagePath = '';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add Your Own Outfit',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.dashboardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imagePath.isEmpty
                        ? const Center(
                            child: Icon(
                              Icons.add_photo_alternate_rounded,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          )
                        : _buildWardrobeImage(imagePath, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                          final path = await ref
                              .read(dashboardViewModelProvider.notifier)
                              .pickWardrobeItemImage(ImageSource.gallery);
                          if (path == null || path.isEmpty) return;
                          setState(() => imagePath = path);
                        },
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                          final path = await ref
                              .read(dashboardViewModelProvider.notifier)
                              .pickWardrobeItemImage(ImageSource.camera);
                          if (path == null || path.isEmpty) return;
                          setState(() => imagePath = path);
                        },
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Outfit name',
                    hintText: 'e.g. My Black Hoodie',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes or items included',
                    hintText: 'White shirt, blue jeans, sneakers',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Category',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                            'Casual',
                            'Formal',
                            'Party',
                            'Office',
                            'Traditional',
                            'Summer',
                            'Winter',
                          ]
                          .map(
                            (cat) => GestureDetector(
                              onTap: () =>
                                  setState(() => selectedCategory = cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedCategory == cat
                                      ? AppColors.primary
                                      : AppColors.dashboardBackground,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: selectedCategory == cat
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          if (isSubmitting) {
                            return;
                          }
                          if (titleController.text.trim().isNotEmpty) {
                            if (imagePath.isEmpty) {
                              showAppSnackBar(
                                context,
                                'Please add a photo of your outfit.',
                              );
                              return;
                            }
                            setState(() => isSubmitting = true);
                            final uploadedImagePath = await ref
                                .read(dashboardViewModelProvider.notifier)
                                .uploadWardrobeItemImage(imagePath);
                            if (!context.mounted) {
                              return;
                            }
                            if (uploadedImagePath == null ||
                                uploadedImagePath.isEmpty) {
                              setState(() => isSubmitting = false);
                              final message = ref
                                      .read(dashboardViewModelProvider)
                                      .uploadMessage ??
                                  'Unable to upload your outfit photo.';
                              showAppSnackBar(
                                context,
                                message,
                                isError: true,
                              );
                              return;
                            }
                            ref
                                .read(dashboardViewModelProvider.notifier)
                                .addCustomOutfit(
                                  title: titleController.text.trim(),
                                  category: selectedCategory,
                                  imagePath: uploadedImagePath,
                                  outfit: noteController.text.trim(),
                                  explanation:
                                      'Manually added to your wardrobe.',
                                );
                            Navigator.pop(context);
                            showAppSnackBar(
                              context,
                              'Outfit added to your wardrobe!',
                              isError: false,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Add Outfit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ DISCOVER TAB ============
  Widget _discoverTab(DashboardState state) {
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    final filteredItems = state.discoverItems.where((item) {
      final matchesFilter =
          item.category.toLowerCase() == state.discoverFilter.toLowerCase();
      final query = _discoverQuery;
      final matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.caption.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '🔍 Discover',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Explore trending fashion, occasion looks, hairstyles, palettes, and fresh inspiration beyond your personal recommendations.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _buildSearchField(
          controller: _discoverSearchController,
          hintText: 'Search "Korean fashion" or "summer outfits"',
        ),
        const SizedBox(height: 20),
        const Text(
          'Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildDiscoverCategoryChips(state, notifier),
        const SizedBox(height: 24),
        _buildSectionHeader('${state.discoverFilter} Outfits', null),
        const SizedBox(height: 14),
        if (filteredItems.isEmpty)
          _buildSimplePlaceholder(
            'No inspiration found for your current search or category.',
          )
        else
          _buildPinterestOutfitsGrid(state, filteredItems),
      ],
    );
  }

  Widget _buildDiscoverCategoryChips(DashboardState state, dynamic notifier) {
    final categories = ['Trending', 'Casual', 'Formal', 'Streetwear', 'Party'];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((cat) {
        final isSelected = state.discoverFilter == cat;
        return GestureDetector(
          onTap: () => notifier.setDiscoverFilter(cat),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? null : Border.all(color: AppColors.divider),
              boxShadow: isSelected
                  ? AppColors.buttonShadow
                  : AppColors.softShadow,
            ),
            child: Text(
              cat,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ignore: unused_element
  Widget _buildTrendingBanner(DiscoverEntry item) {
    return GestureDetector(
      onTap: () => _showDiscoverItemDetails(item),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(gradient: AppColors.accentGradient),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.caption,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 14,
                      ),
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

  Widget _buildPinterestOutfitsGrid(
    DashboardState state,
    List<DiscoverEntry> items,
  ) {
    final leftColumn = <DiscoverEntry>[];
    final rightColumn = <DiscoverEntry>[];
    for (var i = 0; i < items.length; i++) {
      if (i.isEven) {
        leftColumn.add(items[i]);
      } else {
        rightColumn.add(items[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPinterestColumn(state, leftColumn)),
        const SizedBox(width: 14),
        Expanded(child: _buildPinterestColumn(state, rightColumn)),
      ],
    );
  }

  Widget _buildPinterestColumn(
    DashboardState state,
    List<DiscoverEntry> items,
  ) {
    return Column(
      children: items.map((item) {
        final isSaved = state.wardrobeItems.any((entry) => entry.id == item.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildDiscoverCard(item, isSaved: isSaved),
        );
      }).toList(),
    );
  }

  Widget _buildDiscoverCard(DiscoverEntry item, {required bool isSaved}) {
    return GestureDetector(
      onTap: () => _showDiscoverItemDetails(item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: item.height.clamp(170, 260).toDouble(),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.style_rounded,
                              color: Colors.white.withValues(alpha: 0.75),
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () async {
                        if (isSaved) {
                          showAppSnackBar(
                            context,
                            'Already saved to Wardrobe.',
                            isError: false,
                          );
                          return;
                        }
                        await ref
                            .read(dashboardViewModelProvider.notifier)
                            .saveDiscoverItem(item);
                        if (!mounted) return;
                        _goToTab(2, 'Saved to Wardrobe');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSaved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isSaved
                              ? AppColors.error
                              : AppColors.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.caption,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDiscoverItemDetails(DiscoverEntry item) {
    final isSaved = ref
        .read(dashboardViewModelProvider)
        .wardrobeItems
        .any((entry) => entry.id == item.id);
    final occasion = switch (item.category) {
      'Formal' => 'Office',
      'Party' => 'Party',
      'Streetwear' => 'College',
      'Summer' => 'Travel',
      'Winter' => 'Winter Event',
      _ => 'Weekend',
    };
    final hairstyle = switch (item.category) {
      'Formal' => 'Sleek low bun',
      'Party' => 'Soft glam waves',
      'Streetwear' => 'Textured ponytail',
      'Summer' => 'Loose braid',
      'Winter' => 'Smooth blowout',
      _ => 'Soft layered blowout',
    };
    final paletteLabels = switch (item.category) {
      'Formal' => ['Black', 'Ivory', 'Grey'],
      'Party' => ['Berry', 'Black', 'Blush'],
      'Streetwear' => ['Grey', 'Black', 'Olive'],
      'Summer' => ['Blue', 'Beige', 'White'],
      'Winter' => ['Navy', 'Grey', 'White'],
      _ => ['Beige', 'Camel', 'Olive'],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 250,
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMetaChip(item.category),
                  _buildMetaChip(occasion),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.caption,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Suggested Hairstyle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hairstyle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Color Direction',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: paletteLabels.map(_buildMetaChip).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailActionButton(
                      icon: isSaved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: isSaved ? 'Saved' : 'Save to Wardrobe',
                      onTap: () async {
                        if (isSaved) {
                          Navigator.pop(context);
                          return;
                        }
                        await ref
                            .read(dashboardViewModelProvider.notifier)
                            .saveDiscoverItem(item);
                        if (!mounted) return;
                        Navigator.pop(context);
                        _goToTab(2, 'Saved to Wardrobe');
                      },
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailActionButton(
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onTap: () {
                        Navigator.pop(context);
                        showAppSnackBar(
                          context,
                          'Share feature coming soon!',
                          isError: false,
                        );
                      },
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildOccasionLooks() {
    final occasions = [
      {'icon': Icons.school_rounded, 'name': 'College'},
      {'icon': Icons.work_rounded, 'name': 'Office'},
      {'icon': Icons.celebration_rounded, 'name': 'Party'},
      {'icon': Icons.favorite_rounded, 'name': 'Wedding'},
      {'icon': Icons.flight_takeoff_rounded, 'name': 'Travel'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: occasions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final occasion = occasions[index];
        return GestureDetector(
          onTap: () => _goToTab(1, 'Opened AI Sync for ${occasion['name']}'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    occasion['icon'] as IconData,
                    color: AppColors.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  occasion['name'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildTrendingHairstyles() {
    final hairstyles = [
      {
        'name': 'Layered Cut',
        'faces': 'Best for Oval & Round faces',
        'icon': Icons.face_rounded,
      },
      {
        'name': 'Soft Curtain Waves',
        'faces': 'Best for Heart & Oval faces',
        'icon': Icons.face_3_rounded,
      },
      {
        'name': 'Polished Low Bun',
        'faces': 'Best for Square & Oval faces',
        'icon': Icons.auto_fix_high_rounded,
      },
    ];

    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hairstyles.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final hairstyle = hairstyles[index];
          return GestureDetector(
            onTap: () => _showHairstyleDetails(
              hairstyle['name']! as String,
              hairstyle['faces']! as String,
            ),
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          hairstyle['icon']! as IconData,
                          color: Colors.white.withValues(alpha: 0.78),
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hairstyle['name']! as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hairstyle['faces']! as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showHairstyleDetails(String hairstyleName, String faceShapeText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.74,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 210,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Icon(
                    Icons.face_rounded,
                    color: Colors.white.withValues(alpha: 0.76),
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                hairstyleName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                faceShapeText,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Why it works',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This hairstyle balances proportions, keeps the look modern, and pairs well with both casual and polished outfits.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailActionButton(
                      icon: Icons.favorite_border_rounded,
                      label: 'Save',
                      onTap: () {
                        Navigator.pop(context);
                        showAppSnackBar(
                          context,
                          'Hairstyle saved for inspiration!',
                          isError: false,
                        );
                      },
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailActionButton(
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onTap: () {
                        Navigator.pop(context);
                        showAppSnackBar(
                          context,
                          'Share feature coming soon!',
                          isError: false,
                        );
                      },
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutfitItem(String name, String category) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dashboardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.checkroom_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.accent : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: AppColors.divider),
          boxShadow: isPrimary ? AppColors.buttonShadow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : AppColors.textPrimary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildColorInspiration() {
    final palettes = [
      [0xFFE8D5C4, 0xFFD4A574, 0xFF8B7355, 0xFF4A3A34],
      [0xFFE8F4F8, 0xFF87CEEB, 0xFF4682B4, 0xFF1E3A5F],
      [0xFFF5E6E6, 0xFFE8B4B8, 0xFFC75B7A, 0xFF8B3A62],
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: palettes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showColorPaletteDetails(
              'Palette ${index + 1}',
              palettes[index],
            ),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: palettes[index].map((color) {
                          return Expanded(
                            child: Container(
                              height: double.infinity,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: Color(color),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Palette ${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showColorPaletteDetails(String paletteName, List<int> colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Palette Name
                    Text(
                      paletteName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Color Palette Display
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: colors.map((color) {
                          return Expanded(
                            child: Container(
                              height: double.infinity,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Color(color),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    const Text(
                      'Color Harmony',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This color palette creates a harmonious and balanced look. Perfect for creating stylish outfits that work well together.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailActionButton(
                            icon: Icons.favorite_border_rounded,
                            label: 'Save Palette',
                            onTap: () {
                              Navigator.pop(context);
                              showAppSnackBar(
                                context,
                                'Palette saved!',
                                isError: false,
                              );
                            },
                            isPrimary: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailActionButton(
                            icon: Icons.share_rounded,
                            label: 'Share',
                            onTap: () {
                              Navigator.pop(context);
                              showAppSnackBar(
                                context,
                                'Share feature coming soon!',
                                isError: false,
                              );
                            },
                            isPrimary: false,
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

  // ignore: unused_element
  Widget _buildFashionTips() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fashion Tips',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pair neutral colors with one accent color.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ref
        .read(dashboardViewModelProvider.notifier)
        .pickImage(source);
    if (!mounted || !picked) return;
    final message = ref.read(dashboardViewModelProvider).uploadMessage;
    if (message != null) {
      showAppSnackBar(context, message, isError: false);
    }
  }

  void _goToTab(int index, String message) {
    ref.read(dashboardViewModelProvider.notifier).setIndex(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    showAppSnackBar(context, message, isError: false);
  }

  void _openChatBot() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChatBotSheet(),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab({required this.silhouetteProfile});

  final SilhouetteProfile? silhouetteProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(authSessionViewModelProvider);
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final user = sessionState.user;
    final profileData = dashboardState.profileData;
    final fallbackName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName
        : 'Sristika Puri';
    final displayName = profileData.displayName.isNotEmpty
        ? profileData.displayName
        : fallbackName;
    final email = profileData.email.isNotEmpty
        ? profileData.email
        : (user?.email ?? 'sristika@email.com');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final savedLooks = dashboardState.wardrobeItems
        .where((item) => item.entryType == 'look')
        .length;
    final favoriteLooks = dashboardState.wardrobeItems
        .where((item) => item.entryType == 'look' && item.isFavorite)
        .length;
    final aiAnalyses = dashboardState.hasCompletedStyleAnalysis ? 1 : 0;
    final favoriteColors = dashboardState.aiStyleOfDay.paletteLabels
        .take(3)
        .toList();
    final favoriteCategories = profileData.stylePreferences.take(3).toList();
    final completionItems = [
      displayName,
      email,
      profileData.bodyType,
      profileData.skinTone,
      profileData.faceShape,
      profileData.styleMood,
    ];
    final completionPercent =
        ((completionItems.where((value) => value.trim().isNotEmpty).length /
                    completionItems.length) *
                100)
            .round();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '👤 Profile',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Manage your personal details, style preferences, activity, and support settings from one place.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        showAppSnackBar(
                          context,
                          'Profile photo uses your account initial for now.',
                          isError: false,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          boxShadow: AppColors.buttonShadow,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showEditProfileModal(
                  context,
                  ref,
                  profileData,
                  displayName,
                  email,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.buttonShadow,
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: '📈 Profile Completion',
          icon: Icons.verified_user_outlined,
          children: [
            Text(
              'Complete your profile to improve future recommendations.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: completionPercent / 100,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: AppColors.dashboardBackground,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
            const SizedBox(height: 10),
            Text(
              '$completionPercent% complete',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: '✨ My Style Profile',
          icon: Icons.style_rounded,
          children: [
            _buildProfileStat(
              'Body Type',
              profileData.bodyType,
              Icons.straighten_rounded,
            ),
            const Divider(height: 20),
            _buildProfileStat(
              'Skin Tone',
              profileData.skinTone,
              Icons.palette_rounded,
            ),
            const Divider(height: 20),
            _buildProfileStat(
              'Face Shape',
              profileData.faceShape,
              Icons.face_rounded,
            ),
            const Divider(height: 20),
            _buildProfileStat(
              'Style',
              profileData.styleMood,
              Icons.auto_awesome_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: '⚙️ Preferences',
          icon: Icons.settings_rounded,
          children: [
            _buildSettingsRow(
              Icons.dark_mode_outlined,
              'Theme',
              profileData.themePreference,
            ),
            const Divider(height: 20),
            _buildSettingsRow(
              Icons.notifications_outlined,
              'Notifications',
              profileData.notificationsEnabled ? 'On' : 'Off',
            ),
            const Divider(height: 20),
            _buildSettingsRow(
              Icons.language_outlined,
              'Language',
              profileData.language,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: '📊 My Activity',
          icon: Icons.analytics_rounded,
          children: [
            _buildActivityRow(
              Icons.bookmark_rounded,
              'Saved Outfits',
              '$savedLooks',
            ),
            const Divider(height: 20),
            _buildActivityRow(
              Icons.favorite_rounded,
              'Favorite Looks',
              '$favoriteLooks',
            ),
            const Divider(height: 20),
            _buildActivityRow(
              Icons.psychology_rounded,
              'AI Analyses',
              '$aiAnalyses',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: '🧾 Saved Preferences',
          icon: Icons.favorite_outline_rounded,
          children: [
            _buildProfileStat(
              'Favorite Colors',
              favoriteColors.isEmpty
                  ? 'Neutral tones'
                  : favoriteColors.join(', '),
              Icons.palette_outlined,
            ),
            const Divider(height: 20),
            _buildProfileStat(
              'Favorite Categories',
              favoriteCategories.isEmpty
                  ? 'Casual Chic'
                  : favoriteCategories.join(', '),
              Icons.sell_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'ℹ️ Support',
          icon: Icons.help_outline_rounded,
          children: [
            _buildSupportRow(context, Icons.help_center_rounded, 'Help Center'),
            const Divider(height: 20),
            _buildSupportRow(context, Icons.quiz_outlined, 'FAQ'),
            const Divider(height: 20),
            _buildSupportRow(
              context,
              Icons.support_agent_rounded,
              'Contact Support',
            ),
            const Divider(height: 20),
            _buildSupportRow(
              context,
              Icons.privacy_tip_outlined,
              'Privacy Policy',
            ),
            const Divider(height: 20),
            _buildSupportRow(
              context,
              Icons.description_outlined,
              'Terms & Conditions',
            ),
            const Divider(height: 20),
            _buildSupportRow(
              context,
              Icons.info_outline_rounded,
              'About FashioME',
            ),
          ],
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => _logout(context, ref),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error),
              boxShadow: AppColors.softShadow,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                SizedBox(width: 8),
                Text(
                  '🚪 Logout',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditProfileModal(
    BuildContext context,
    WidgetRef ref,
    DashboardProfileData profileData,
    String currentName,
    String currentEmail,
  ) {
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);
    String selectedBodyType = profileData.bodyType.isEmpty
        ? 'Rectangle'
        : profileData.bodyType;
    String selectedSkinTone = profileData.skinTone.isEmpty
        ? 'Warm'
        : profileData.skinTone;
    String selectedFaceShape = profileData.faceShape.isEmpty
        ? 'Oval'
        : profileData.faceShape;
    String selectedStyle = profileData.styleMood.isEmpty
        ? 'Casual Chic'
        : profileData.styleMood;
    String selectedTheme = profileData.themePreference.isEmpty
        ? 'System'
        : profileData.themePreference;
    String selectedLanguage = profileData.language.isEmpty
        ? 'English'
        : profileData.language;
    bool notificationsEnabled = profileData.notificationsEnabled;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (modalContext, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.55,
          maxChildSize: 0.96,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInputLabel('Full Name'),
                _buildInputField(
                  controller: nameController,
                  hintText: 'Enter your name',
                ),
                const SizedBox(height: 16),
                _buildInputLabel('Email'),
                _buildInputField(
                  controller: emailController,
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildInputLabel('Body Type'),
                _buildDropdownField(
                  value: selectedBodyType,
                  items: const ['Rectangle', 'Pear', 'Hourglass', 'Balanced'],
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => selectedBodyType = value);
                  },
                ),
                const SizedBox(height: 16),
                _buildInputLabel('Skin Tone'),
                _buildDropdownField(
                  value: selectedSkinTone,
                  items: const ['Warm', 'Cool', 'Neutral'],
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => selectedSkinTone = value);
                  },
                ),
                const SizedBox(height: 16),
                _buildInputLabel('Face Shape'),
                _buildDropdownField(
                  value: selectedFaceShape,
                  items: const ['Oval', 'Round', 'Square', 'Heart'],
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => selectedFaceShape = value);
                  },
                ),
                const SizedBox(height: 16),
                _buildInputLabel('Style Preference'),
                _buildDropdownField(
                  value: selectedStyle,
                  items: const [
                    'Casual Chic',
                    'Minimal',
                    'Streetwear',
                    'Formal',
                    'Traditional',
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => selectedStyle = value);
                  },
                ),
                const SizedBox(height: 16),
                _buildInputLabel('Theme'),
                _buildDropdownField(
                  value: selectedTheme,
                  items: const ['Light', 'Dark', 'System'],
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => selectedTheme = value);
                  },
                ),
                const SizedBox(height: 16),
                _buildInputLabel('Language'),
                _buildDropdownField(
                  value: selectedLanguage,
                  items: const ['English', 'Nepali'],
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => selectedLanguage = value);
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    notificationsEnabled
                        ? 'Outfit reminders and recommendation updates are on'
                        : 'Notifications are currently off',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: notificationsEnabled,
                  activeThumbColor: AppColors.accent,
                  onChanged: (value) {
                    setModalState(() => notificationsEnabled = value);
                  },
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final updatedProfile = profileData.copyWith(
                      displayName: nameController.text.trim().isEmpty
                          ? currentName
                          : nameController.text.trim(),
                      email: emailController.text.trim().isEmpty
                          ? currentEmail
                          : emailController.text.trim(),
                      bodyType: selectedBodyType,
                      skinTone: selectedSkinTone,
                      faceShape: selectedFaceShape,
                      styleMood: selectedStyle,
                      themePreference: selectedTheme,
                      language: selectedLanguage,
                      notificationsEnabled: notificationsEnabled,
                      stylePreferences: [
                        selectedStyle,
                        selectedBodyType,
                        selectedSkinTone,
                      ],
                    );
                    await ref
                        .read(dashboardViewModelProvider.notifier)
                        .updateProfileData(updatedProfile);
                    if (!context.mounted) return;
                    Navigator.of(sheetContext).pop();
                    showAppSnackBar(
                      context,
                      'Preferences saved. Recommendations updated.',
                      isError: false,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppColors.buttonShadow,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.of(sheetContext).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.dashboardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textLight),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.dashboardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: items.contains(value) ? value : items.first,
        decoration: const InputDecoration(border: InputBorder.none),
        items: items
            .map(
              (item) =>
                  DropdownMenuItem<String>(value: item, child: Text(item)),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActivityRow(IconData icon, String title, String count) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSupportRow(BuildContext context, IconData icon, String title) {
    return GestureDetector(
      onTap: () {
        showAppSnackBar(context, '$title page coming soon.', isError: false);
      },
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.textLight,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (shouldLogout != true) {
      return;
    }

    final success = await ref
        .read(authSessionViewModelProvider.notifier)
        .logout();
    if (!context.mounted) return;
    if (success) {
      showAppSnackBar(context, 'Signed out successfully.', isError: false);
      AppRoutes.pushAndRemoveUntil(context, const LoginPage());
    } else {
      final message = ref.read(authSessionViewModelProvider).errorMessage;
      if (message != null) {
        showAppSnackBar(context, message);
      }
    }
  }
}

// ============ CHAT BOT SHEET ============
class _ChatBotSheet extends ConsumerStatefulWidget {
  const _ChatBotSheet();

  @override
  ConsumerState<_ChatBotSheet> createState() => _ChatBotSheetState();
}

class _ChatBotSheetState extends ConsumerState<_ChatBotSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final chatMessages = dashboardState.chatMessages;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Style Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ask for styling advice...',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  chatMessages.length + (dashboardState.isChatTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatMessages.length &&
                    dashboardState.isChatTyping) {
                  return _buildTypingIndicator();
                }
                final message = chatMessages[index];
                return _buildChatBubble(message);
              },
            ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask for outfit advice...',
                        hintStyle: TextStyle(color: AppColors.textLight),
                        filled: true,
                        fillColor: AppColors.dashboardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
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

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(dashboardViewModelProvider.notifier).sendChatMessage(text);
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accent : AppColors.dashboardBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.dashboardBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypingDot(0),
            const SizedBox(width: 4),
            _buildTypingDot(1),
            const SizedBox(width: 4),
            _buildTypingDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
