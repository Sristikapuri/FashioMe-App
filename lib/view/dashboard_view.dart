import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
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
        automaticallyImplyLeading: false,
        centerTitle: true,
        titleSpacing: 16,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.menu, color: AppColors.primaryDark),
            Text(
              'FashioMe',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 24,
                    fontFamily: AppFonts.bold,
                  ),
            ),
            const Icon(
              Icons.person_outline,
              size: 18,
              color: AppColors.primaryDark,
            ),
          ],
        ),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Curation",
                style: Theme.of(context).textTheme.titleLarge,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  PaletteColor(color: Color(0xff7B0000)),
                  SizedBox(width: 12),
                  PaletteColor(color: Color(0xff8B6B00)),
                  SizedBox(width: 12),
                  PaletteColor(color: Color(0xffF8F2F0)),
                  SizedBox(width: 12),
                  PaletteColor(color: Color(0xffDFC1B8)),
                  SizedBox(width: 12),
                  PaletteColor(color: Color(0xff3F4630)),
                  SizedBox(width: 12),
                  PaletteColor(color: Color(0xffF1D0C8)),
                ],
              ),
            ),
          ),
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
                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
                  'TEXTURED PIXIE',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _imageCard(
                  'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df',
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
            child: Row(
              children: [
                _circleCard(
                  'https://images.unsplash.com/photo-1519741497674-611481863552',
                  'WEDDING',
                ),
                const SizedBox(width: 14),
                _circleCard(
                  'https://images.unsplash.com/photo-1507679799987-c73779587ccf',
                  'OFFICE',
                ),
                const SizedBox(width: 14),
                _circleCard(
                  'https://images.unsplash.com/photo-1514525253161-7a46d19cd819',
                  'PARTY',
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Discover your AI fashion recommendations daily ✨',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _banner() {
    return Container(
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
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1529139574466-a303027c1d8b',
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
    );
  }

  Widget _imageCard(String image, String title) {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            image: DecorationImage(
              image: NetworkImage(image),
              fit: BoxFit.cover,
            ),
          ),
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
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            image: DecorationImage(
              image: NetworkImage(image),
              fit: BoxFit.cover,
            ),
          ),
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
  const PaletteColor({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
