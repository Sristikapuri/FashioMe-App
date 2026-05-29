import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../view_models/dashboard_view_model.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {

  static const _imageParams = 'auto=format&fit=crop&w=400&q=80';

  static const _occasions = [
    (
      'https://images.unsplash.com/photo-1519741497674-611481863552?$_imageParams',
      'WEDDING',
    ),
    (
      'https://images.unsplash.com/photo-1507679799987-c73779587ccf?$_imageParams',
      'OFFICE',
    ),
    (
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?$_imageParams',
      'PARTY',
    ),
    (
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?$_imageParams',
      'DATE NIGHT',
    ),
    (
      'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?$_imageParams',
      'BRUNCH',
    ),
    (
      'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?$_imageParams',
      'FESTIVAL',
    ),
    (
      'https://images.unsplash.com/photo-1596783438789-94786a309b84?$_imageParams',
      'COCKTAIL',
    ),
    (
      'https://images.unsplash.com/photo-1488085068365-99befe983387?$_imageParams',
      'TRAVEL',
    ),
    (
      'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?$_imageParams',
      'CASUAL',
    ),
  ];

  static const _paletteColors = [
    Color(0xFF7B0000),
    Color(0xFF8B6B00),
    Color(0xFFF8F2F0),
    Color(0xFFDFC1B8),
    Color(0xFF3F4630),
    Color(0xFFF1D0C8),
  ];

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final screens = [
      _homeTab(),
      const _PlaceholderTab(label: 'AI Sync'),
      const _PlaceholderTab(label: 'Closet'),
      const _PlaceholderTab(label: 'Advisor'),
      const _PlaceholderTab(label: 'Me'),
    ];

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.dashboardBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primaryDark),
          onPressed: () {},
        ),
        title: Text(
          'FashioMe',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryDark,
                fontSize: 24,
                fontFamily: AppFonts.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_outline,
              size: 22,
              color: AppColors.primaryDark,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: screens[dashboardState.currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: dashboardState.currentIndex,
        onTap: (index) =>
            ref.read(dashboardViewModelProvider.notifier).setIndex(index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.navBarBackground,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.navUnselected,
        iconSize: 24,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'AI SYNC',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom_outlined),
            label: 'CLOSET',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sentiment_satisfied_alt_outlined),
            label: 'ADVISOR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'ME',
          ),
        ],
      ),
    );
  }

  Widget _homeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's Curation",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                'VIEW ALL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.accent,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _banner(),
          const SizedBox(height: 35),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Your Seasonal Palette',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'DEEP AUTUMN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _seasonalPaletteCard(),
          const SizedBox(height: 35),
          Text(
            'Personalized Hairstyles',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _imageCard(
                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?$_imageParams',
                  'TEXTURED PIXIE',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _imageCard(
                  'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?$_imageParams',
                  'SOFT LAYERS',
                ),
              ),
            ],
          ),
          const SizedBox(height: 35),
          Text(
            'Explore Occasions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            child: Row(
              children: [
                for (var i = 0; i < _occasions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  _circleCard(_occasions[i].$1, _occasions[i].$2),
                ],
              ],
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Discover your AI fashion recommendations daily ✨',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _banner() {
    return SizedBox(
      width: double.infinity,
      child: Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?$_imageParams',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.65),
              Colors.transparent,
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Fusion Edit',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
            const Spacer(),
            Text(
              'Velvet Heritage\nMeets Urban Edge',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.15,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Combining classical embroidery with modern silhouettes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _seasonalPaletteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E0D8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            child: Row(
              children: [
                for (var i = 0; i < _paletteColors.length; i++) ...[
                  if (i > 0) const SizedBox(width: 18),
                  PaletteColor(color: _paletteColors[i], index: i),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: _paletteColors,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkImage({
    required String url,
    required double width,
    required double height,
    required double radius,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.grey.shade500,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _imageCard(String image, String title) {
    return Column(
      children: [
        _networkImage(
          url: image,
          width: double.infinity,
          height: 200,
          radius: 18,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
                letterSpacing: 1,
              ),
        ),
      ],
    );
  }

  Widget _circleCard(String image, String title) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          _networkImage(
            url: image,
            width: 96,
            height: 96,
            radius: 20,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 0.8,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primaryDark.withValues(alpha: 0.4),
            ),
      ),
    );
  }
}

class PaletteColor extends StatelessWidget {
  const PaletteColor({
    super.key,
    required this.color,
    this.index = 0,
  });

  final Color color;
  final int index;

  bool get _isLight => color.computeLuminance() > 0.82;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: _isLight
                  ? const Color(0xFFD4C4BC)
                  : Colors.white.withValues(alpha: 0.35),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == 0 ? AppColors.primaryDark : Colors.transparent,
          ),
        ),
      ],
    );
  }
}
