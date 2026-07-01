import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/widgets/selected_image.dart';
import 'package:fashio_me/features/auth/presentation/pages/login_page.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_session_providers.dart';
import 'package:fashio_me/features/dashboard/presentation/pages/profile_update_page.dart';
import 'package:fashio_me/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:fashio_me/features/shop/presentation/pages/shop_page.dart';
import 'package:fashio_me/features/shop/presentation/pages/order_history_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _selectedEvent = 'Wedding';
  String _selectedSource = 'My Wardrobe';

  static const _events = [
    ('Wedding', Icons.favorite_outline),
    ('Party', Icons.celebration_outlined),
    ('Formal', Icons.workspace_premium_outlined),
    ('Casual', Icons.weekend_outlined),
    ('Date Night', Icons.local_fire_department_outlined),
    ('Office', Icons.work_outline),
    ('Festival', Icons.auto_awesome_outlined),
    ('Travel', Icons.flight_takeoff_outlined),
  ];

  static const _titles = [
    'Home',
    'AI Stylist',
    'My Wardrobe',
    'Shop',
    'Discover',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardViewModelProvider);
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    final pages = [
      _HomeTab(
        state: state,
        selectedEvent: _selectedEvent,
        events: _events,
        onEventTap: (value) async {
          setState(() => _selectedEvent = value);
          await notifier.generateHomeRecommendation(
            occasion: value,
            syncCurrentRecommendation: true,
          );
        },
      ),
      _AiStylistTab(
        state: state,
        selectedEvent: _selectedEvent,
        selectedSource: _selectedSource,
        events: _events,
        onEventChanged: (value) => setState(() => _selectedEvent = value),
        onSourceChanged: (value) => setState(() => _selectedSource = value),
      ),
      _WardrobeTab(state: state, onAddItem: () => _showAddItemSheet(context)),
      const ShopPage(),
      _DiscoverTab(state: state),
      _ProfileTab(state: state),
    ];

    return Scaffold(
      backgroundColor: _DashboardPalette.background,
      body: Container(
        decoration: const BoxDecoration(color: _DashboardPalette.background),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _TopBar(
                    title: _titles[state.currentIndex],
                    onLeadingTap: () => _showSnack('Menu coming soon'),
                    onSearchTap: () => _showSearchSheet(),
                    onTrailingTap: () => state.currentIndex == 5
                        ? _showSnack('Notifications coming soon')
                        : notifier.setIndex(5),
                    trailingIcon: state.currentIndex == 5
                        ? Icons.notifications_none_rounded
                        : Icons.tune_rounded,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.cardBackground,
                      onRefresh: () async {
                        await notifier.generateFreshHomeRecommendation();
                      },
                      child: pages[state.currentIndex],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 18,
                bottom: 96,
                child: _AssistantButton(onTap: () => notifier.setIndex(1)),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: state.currentIndex,
        onTap: notifier.setIndex,
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _DashboardPalette.card,
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _showSearchSheet() async {
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    final controller = TextEditingController(
      text: ref.read(dashboardViewModelProvider).searchQuery,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: Row(
            children: [
              Expanded(
                child: _DarkTextField(controller: controller, label: 'Search'),
              ),
              const SizedBox(width: 8),
              _TopIconButton(
                icon: Icons.search_rounded,
                onTap: () {
                  Navigator.pop(context);
                  notifier.searchDashboard(controller.text);
                },
              ),
            ],
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<void> _showAddItemSheet(BuildContext context) async {
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetAction(
              icon: Icons.photo_camera_outlined,
              title: 'Camera',
              onTap: () {
                Navigator.pop(context);
                _addWardrobeItemFromImage(ImageSource.camera);
              },
            ),
            _SheetAction(
              icon: Icons.upload_outlined,
              title: 'Upload Image',
              onTap: () {
                Navigator.pop(context);
                _addWardrobeItemFromImage(ImageSource.gallery);
              },
            ),
            _SheetAction(
              icon: Icons.edit_note_outlined,
              title: 'Add Manually',
              onTap: () {
                Navigator.pop(context);
                notifier.addWardrobeItem('Manual wardrobe item', 'Casual');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addWardrobeItemFromImage(ImageSource source) async {
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    final path = await notifier.pickWardrobeItemImage(source);
    if (!mounted) {
      return;
    }

    if (path == null) {
      _showSnack('No image selected.');
      return;
    }

    final uploadedPath = await notifier.uploadWardrobeItemImage(path);
    if (!mounted) {
      return;
    }

    final added = await notifier.addWardrobeItem(
      source == ImageSource.camera ? 'Captured wardrobe item' : 'Uploaded item',
      source == ImageSource.camera ? 'Tops' : 'Clothes',
      imagePath: uploadedPath ?? path,
    );

    if (!mounted) {
      return;
    }

    _showSnack(
      added
          ? 'Image uploaded and added to your wardrobe.'
          : 'Image saved locally. Upload will sync when backend is ready.',
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab({
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
    final firstName = _firstName(state.profileData.displayName);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 140),
      children: [
        _HeroBanner(
          title: 'Good Morning,\n$firstName',
          subtitle:
              'Your AI stylist has fresh outfit ideas, color picks, and closet inspiration ready for today.',
          badgeText: 'AI Stylist',
          onTap: () => notifier.setIndex(1),
        ),
        const SizedBox(height: 20),
        _SearchBar(
          initialValue: state.searchQuery,
          onSubmitted: notifier.searchDashboard,
        ),
        const SizedBox(height: 20),
        _SectionTitle(
          title: 'Browse by Occasion',
          actionLabel: 'View All',
          onAction: () => notifier.setIndex(1),
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
            return _OccasionCard(
              label: item.$1,
              icon: item.$2,
              isSelected: selectedEvent == item.$1,
              onTap: () => onEventTap(item.$1),
            );
          },
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Today\'s Style Suggestion',
          actionLabel: 'New',
          onAction: () {
            notifier.generateFreshHomeRecommendation();
          },
        ),
        _FeaturedRecommendationCard(
          item: state.aiStyleOfDay,
          isLoading: state.isUploading,
          onPrimaryTap: () {
            notifier.generateHomeRecommendation(
              occasion: selectedEvent,
              syncCurrentRecommendation: true,
            );
            notifier.setIndex(1);
          },
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'AI Recommended For You',
          actionLabel: 'View All',
          onAction: () => notifier.setIndex(4),
        ),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.homeRecommendations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: 122,
              child: _MiniLookCard(
                item: state.homeRecommendations[index],
                onTap: () => notifier.selectRecommendation(
                  state.homeRecommendations[index],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Seasonal Inspiration'),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _SeasonCard(
                title: 'Summer\nVibes',
                imagePath: 'assets/images/weekend.jpg',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _SeasonCard(
                title: 'Monsoon\nChic',
                imagePath: 'assets/images/travel.jpg',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _SeasonCard(
                title: 'Winter\nLayers',
                imagePath: 'assets/images/outfit.jpg',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _SeasonCard(
                title: 'Festive\nLooks',
                imagePath: 'assets/images/wedding.jpg',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _InfoStrip(
          icon: Icons.auto_awesome_rounded,
          title: 'AI Assistant',
          subtitle: 'Your smart styling companion',
          onTap: () => notifier.setIndex(1),
        ),
      ],
    );
  }
}

class _AiStylistTab extends ConsumerStatefulWidget {
  const _AiStylistTab({
    required this.state,
    required this.selectedEvent,
    required this.selectedSource,
    required this.events,
    required this.onEventChanged,
    required this.onSourceChanged,
  });

  final DashboardState state;
  final String selectedEvent;
  final String selectedSource;
  final List<(String, IconData)> events;
  final ValueChanged<String> onEventChanged;
  final ValueChanged<String> onSourceChanged;

  @override
  ConsumerState<_AiStylistTab> createState() => _AiStylistTabState();
}

class _AiStylistTabState extends ConsumerState<_AiStylistTab> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }

    _messageController.clear();
    await ref
        .read(dashboardViewModelProvider.notifier)
        .sendChatMessage(message, source: widget.selectedSource);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    final visibleMessages = state.chatMessages.length > 6
        ? state.chatMessages.sublist(state.chatMessages.length - 6)
        : state.chatMessages;
    final quickPrompts = [
      'What should I wear for ${widget.selectedEvent}?',
      'Suggest colors for my skin tone',
      'Which hairstyle fits this look?',
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 140),
      children: [
        _LuxuryCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: _DashboardPalette.softGold,
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: _DashboardPalette.background,
                      child: Text(
                        _initials(state.profileData.displayName),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontFamily: AppFonts.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Style Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: AppFonts.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _DataPill(
                              label: 'Body Shape',
                              value: state.profileData.bodyType,
                            ),
                            _DataPill(
                              label: 'Skin Tone',
                              value: state.profileData.skinTone,
                            ),
                            _DataPill(
                              label: 'Face',
                              value: state.profileData.faceShape,
                            ),
                            _DataPill(
                              label: 'Style',
                              value: state.profileData.styleMood,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: _DashboardPalette.outline),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ConfidenceCard(
                      score: state.preferenceScore == 0
                          ? 92
                          : 92 + (state.preferenceScore % 6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SmallInfoPanel(
                      title: 'View Details',
                      subtitle:
                          'Your profile is personalized for recommendations.',
                      icon: Icons.visibility_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Select Occasion'),
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.events.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = widget.events[index];
              return _FilterChip(
                label: item.$1,
                selected: widget.selectedEvent == item.$1,
                onTap: () => widget.onEventChanged(item.$1),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Generate New Look'),
        const SizedBox(height: 12),
        Row(
          children: ['My Wardrobe', 'New Inspiration'].map((source) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: source == 'My Wardrobe' ? 8 : 0,
                ),
                child: _SourceCard(
                  label: source,
                  icon: source == 'My Wardrobe'
                      ? Icons.checkroom_outlined
                      : Icons.auto_awesome_outlined,
                  selected: widget.selectedSource == source,
                  onTap: () => widget.onSourceChanged(source),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionPanel(
                icon: Icons.photo_camera_outlined,
                label: 'Camera',
                onTap: () => notifier.pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionPanel(
                icon: Icons.upload_outlined,
                label: 'Upload Image',
                onTap: () => notifier.pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),
        if (state.selectedImagePath != null) ...[
          const SizedBox(height: 14),
          _ImagePreview(path: state.selectedImagePath!),
        ],
        const SizedBox(height: 14),
        _PrimaryLuxuryButton(
          label: state.isUploading
              ? state.aiProcessingMessage
              : (state.selectedImagePath != null
                    ? 'Analyze Uploaded Photo  ✦'
                    : 'Generate Outfit  ✦'),
          onTap: state.isUploading
              ? null
              : () async {
                  if (state.selectedImagePath != null) {
                    await notifier.uploadSelectedImage(
                      occasion: widget.selectedEvent,
                      source: widget.selectedSource,
                    );
                    return;
                  }

                  await notifier.generateHomeRecommendation(
                    occasion: widget.selectedEvent,
                    syncCurrentRecommendation: true,
                    source: widget.selectedSource,
                  );
                },
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Recent AI Looks',
          actionLabel: 'View All',
          onAction: () => notifier.setIndex(4),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.homeRecommendations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: 118,
              child: _MiniLookCard(
                item: state.homeRecommendations[index],
                onTap: () => notifier.selectRecommendation(
                  state.homeRecommendations[index],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'AI Assistant'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickPrompts
              .map(
                (prompt) => ActionChip(
                  backgroundColor: _DashboardPalette.cardAlt,
                  side: const BorderSide(color: _DashboardPalette.outline),
                  label: Text(
                    prompt,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  onPressed: () => notifier.sendChatMessage(
                    prompt,
                    source: widget.selectedSource,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _LuxuryCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ask for outfits, colors, styling, or hairstyle advice.',
                style: TextStyle(
                  color: _DashboardPalette.mutedText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              ...visibleMessages.map(
                (message) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ChatBubble(message: message),
                ),
              ),
              if (state.isChatTyping)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _DashboardPalette.cardAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'AI stylist is typing...',
                    style: TextStyle(
                      color: _DashboardPalette.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitMessage(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ask your AI stylist...',
                        hintStyle: const TextStyle(
                          color: _DashboardPalette.mutedText,
                        ),
                        filled: true,
                        fillColor: _DashboardPalette.cardAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _DashboardPalette.outline,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _DashboardPalette.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _DashboardPalette.gold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 52,
                    width: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: state.isChatTyping ? null : _submitMessage,
                      child: const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final background = message.isUser
        ? _DashboardPalette.softGold.withValues(alpha: 0.18)
        : _DashboardPalette.cardAlt;
    final borderColor = message.isUser
        ? _DashboardPalette.gold.withValues(alpha: 0.35)
        : _DashboardPalette.outline;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _WardrobeTab extends ConsumerWidget {
  const _WardrobeTab({required this.state, required this.onAddItem});

  final DashboardState state;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    final filters = [
      'All',
      'Tops',
      'Bottoms',
      'Dresses',
      'Shoes',
      'Accessories',
    ];
    final items = state.wardrobeItems.where((item) {
      if (state.wardrobeFilter == 'All') return true;
      return item.category.toLowerCase().contains(
        state.wardrobeFilter.toLowerCase(),
      );
    }).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 140),
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = filters[index];
              return _FilterChip(
                label: filter,
                selected: filter == state.wardrobeFilter,
                onTap: () => notifier.setWardrobeFilter(filter),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _StatTile(value: '${state.wardrobeItems.length}', label: 'Items'),
            _StatTile(
              value:
                  '${state.wardrobeItems.where((e) => e.entryType == 'look').length}',
              label: 'Outfits',
            ),
            _StatTile(
              value: '${state.wardrobeItems.where((e) => e.isFavorite).length}',
              label: 'Favorites',
            ),
            _StatTile(
              value:
                  '${state.wardrobeItems.where((e) => e.tag.toLowerCase().contains('recent')).length + 8}',
              label: 'Recently Worn',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'My Collection',
          actionLabel: 'View All',
          onAction: () =>
              _showLocalSnack(context, 'Collection view expanded soon'),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _SmallInfoPanel(
            title: 'Closet is empty',
            subtitle:
                'Add tops, bottoms, shoes, and accessories to build your wardrobe.',
            icon: Icons.checkroom_outlined,
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) => _ClosetCard(
              item: items[index],
              onFavorite: () => notifier.toggleWardrobeFavorite(items[index]),
              onEdit: () =>
                  _showEditWardrobeItemSheet(context, ref, items[index]),
              onDelete: () => notifier.removeWardrobeItem(items[index]),
            ),
          ),
        const SizedBox(height: 24),
        _InfoStrip(
          icon: Icons.weekend_outlined,
          title: 'Closet',
          subtitle: 'Organize and manage your entire closet in one place.',
          onTap: () => _showLocalSnack(context, 'Closet organizer coming soon'),
        ),
        const SizedBox(height: 14),
        _LuxuryCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Add Your Items',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: AppFonts.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Build your digital wardrobe by adding your own clothing items.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _DashboardPalette.mutedText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ActionPanel(
                      icon: Icons.photo_camera_outlined,
                      label: 'Camera',
                      onTap: onAddItem,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionPanel(
                      icon: Icons.upload_outlined,
                      label: 'Upload Image',
                      onTap: onAddItem,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: _DashboardPalette.outline),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onAddItem,
                  icon: const Icon(Icons.edit_note_outlined),
                  label: const Text('Add Manually'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLocalSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _DashboardPalette.card,
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showEditWardrobeItemSheet(
    BuildContext context,
    WidgetRef ref,
    WardrobeEntry item,
  ) {
    final titleController = TextEditingController(text: item.title);
    final categoryController = TextEditingController(text: item.category);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _DashboardPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Wardrobe Item',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: AppFonts.bold,
                ),
              ),
              const SizedBox(height: 14),
              _DarkTextField(controller: titleController, label: 'Title'),
              const SizedBox(height: 12),
              _DarkTextField(controller: categoryController, label: 'Category'),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final category = categoryController.text.trim();
                    if (title.isEmpty || category.isEmpty) {
                      return;
                    }

                    await ref
                        .read(dashboardViewModelProvider.notifier)
                        .updateWardrobeItem(
                          item,
                          title: title,
                          category: category,
                        );
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      titleController.dispose();
      categoryController.dispose();
    });
  }
}

class _DiscoverTab extends ConsumerWidget {
  const _DiscoverTab({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final trendingItems = [
      dailyFallback,
      ...visibleItems.where((item) => item.id != dailyFallback.id),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 140),
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = filters[index];
              return _FilterChip(
                label: filter,
                selected: filter == state.discoverFilter,
                onTap: () => notifier.setDiscoverFilter(filter),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Trending Looks',
          actionLabel: 'View All',
          onAction: () => _showDiscoverSnack(context),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: trendingItems.length > 5 ? 5 : trendingItems.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: 118,
              child: _DiscoverLookCard(
                item: trendingItems[index],
                onTap: () => notifier.saveDiscoverItem(trendingItems[index]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Color Inspiration',
          actionLabel: 'View All',
          onAction: () => _showDiscoverSnack(context),
        ),
        const SizedBox(height: 12),
        _LuxuryCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: state.currentRecommendation.palette
                .map((color) => _ColorDot(color: Color(color)))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Style Guides',
          actionLabel: 'View All',
          onAction: () => _showDiscoverSnack(context),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 178,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _GuideCard(
                title: 'How to Dress for Your Body Shape',
                imagePath: 'assets/images/party.jpg',
              ),
              SizedBox(width: 12),
              _GuideCard(
                title: 'Perfect Colors for Your Skin Tone',
                imagePath: 'assets/images/brunch.jpg',
              ),
              SizedBox(width: 12),
              _GuideCard(
                title: 'Occasion Based Outfit Guide',
                imagePath: 'assets/images/wedding.jpg',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Fashion Tips & Articles',
          actionLabel: 'View All',
          onAction: () => _showDiscoverSnack(context),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 178,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _GuideCard(
                title: '10 Style Tips Every Man Should Know',
                imagePath: 'assets/images/outfit.jpg',
              ),
              SizedBox(width: 12),
              _GuideCard(
                title: 'Effortless Women Style Guide',
                imagePath: 'assets/images/brunch.jpg',
              ),
              SizedBox(width: 12),
              _GuideCard(
                title: 'Layering Like a Pro',
                imagePath: 'assets/images/travel.jpg',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDiscoverSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: _DashboardPalette.card,
        content: Text(
          'More discover content coming soon',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileCompletion = _calculateProfileCompletion(state);
    
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 140),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.4),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: _DashboardPalette.cardAlt,
                  child: Text(
                    _initials(state.profileData.displayName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontFamily: AppFonts.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                state.profileData.displayName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontFamily: AppFonts.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.profileData.email.isEmpty
                    ? 'Style is a way to show who you are'
                    : 'Style is a way to show who you are\nwithout speaking.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _ProfileCompletionCard(completion: profileCompletion),
        const SizedBox(height: 24),
        _StatsRow(state: state),
        const SizedBox(height: 24),
        _StylePreferencesCard(state: state),
        const SizedBox(height: 24),
        _ProfileMenu(
          title: 'Edit Profile',
          subtitle: 'Update your personal information and photo',
          icon: Icons.edit_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileUpdatePage()),
            );
          },
        ),
        _ProfileMenu(
          title: 'My Silhouette',
          subtitle:
              '${state.profileData.bodyType} body & ${state.profileData.faceShape} analysis',
          icon: Icons.accessibility_new_outlined,
        ),
        _ProfileMenu(
          title: 'Style Preferences',
          subtitle: state.profileData.stylePreferences.join(', '),
          icon: Icons.tune_outlined,
        ),
        const _ProfileMenu(
          title: 'Saved Looks',
          subtitle: 'Your favorite AI-generated looks',
          icon: Icons.favorite_border,
        ),
        _ProfileMenu(
          title: 'Measurements',
          subtitle: '${state.profileData.skinTone} tone and body stats',
          icon: Icons.straighten_outlined,
        ),
        _ProfileMenu(
          title: 'My Orders',
          subtitle: 'Your saved custom items',
          icon: Icons.receipt_long_outlined,
          onTap: () => AppRoutes.push(context, const OrderHistoryPage()),
        ),
        const _ProfileMenu(
          title: 'Closet',
          subtitle: 'Manage your closet & categories',
          icon: Icons.checkroom_outlined,
        ),
        const _ProfileMenu(
          title: 'Settings',
          subtitle: 'Notifications & privacy',
          icon: Icons.settings_outlined,
        ),
        const _ProfileMenu(
          title: 'Notifications',
          subtitle: 'Manage alert preferences',
          icon: Icons.notifications_none_rounded,
        ),
        const _ProfileMenu(
          title: 'Help & Support',
          subtitle: 'Get quick help',
          icon: Icons.help_outline,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () async {
              final didLogout = await ref
                  .read(authSessionViewModelProvider.notifier)
                  .logout();
              if (!context.mounted || !didLogout) {
                return;
              }
              AppRoutes.pushReplacement(context, const LoginPage());
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Sign Out',
              style: TextStyle(fontFamily: AppFonts.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateProfileCompletion(DashboardState state) {
    int completedFields = 0;
    int totalFields = 6;
    
    if (state.profileData.displayName.isNotEmpty) completedFields++;
    if (state.profileData.email.isNotEmpty) completedFields++;
    if (state.profileData.bodyType.isNotEmpty) completedFields++;
    if (state.profileData.skinTone.isNotEmpty) completedFields++;
    if (state.profileData.stylePreferences.isNotEmpty) completedFields++;
    if (state.profileData.faceShape.isNotEmpty) completedFields++;
    
    return completedFields / totalFields;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onLeadingTap,
    required this.onSearchTap,
    required this.onTrailingTap,
    required this.trailingIcon,
  });

  final String title;
  final VoidCallback onLeadingTap;
  final VoidCallback onSearchTap;
  final VoidCallback onTrailingTap;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 12),
      child: Row(
        children: [
          _TopIconButton(icon: Icons.menu_rounded, onTap: onLeadingTap),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 28,
                fontFamily: AppFonts.bold,
              ),
            ),
          ),
          _TopIconButton(icon: Icons.search_rounded, onTap: onSearchTap),
          const SizedBox(width: 8),
          _TopIconButton(icon: trailingIcon, onTap: onTrailingTap),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _LuxuryCard(
      padding: EdgeInsets.zero,
      child: Container(
        constraints: const BoxConstraints(minHeight: 188),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: AppColors.primaryGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              right: 18,
              top: 18,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.36),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: _DashboardPalette.softGold.withValues(alpha: 0.16),
                      border: Border.all(
                        color: _DashboardPalette.softGold.withValues(
                          alpha: 0.34,
                        ),
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: _DashboardPalette.gold,
                        fontSize: 11,
                        fontFamily: AppFonts.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      height: 1.08,
                      fontFamily: AppFonts.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: onTap,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Elevate style',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: AppFonts.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.initialValue, required this.onSubmitted});

  final String initialValue;
  final ValueChanged<String> onSubmitted;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _SearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DashboardPalette.outline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSubmitted,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search styles, occasions, looks...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: _DashboardPalette.gold,
              size: 20,
            ),
            onPressed: () => widget.onSubmitted(_controller.text),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              height: 1.05,
              fontFamily: AppFonts.bold,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontFamily: AppFonts.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _OccasionCard extends StatelessWidget {
  const _OccasionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : _DashboardPalette.outline,
          ),
          boxShadow: AppColors.softShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.primaryDark,
              size: 24,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primaryDark,
                    fontSize: 12,
                    height: 1.15,
                    fontFamily: AppFonts.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedRecommendationCard extends StatelessWidget {
  const _FeaturedRecommendationCard({
    required this.item,
    required this.onPrimaryTap,
    required this.isLoading,
  });

  final DashboardRecommendation item;
  final VoidCallback onPrimaryTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return _LuxuryCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: AppFonts.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.outfit,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _DashboardPalette.mutedText,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: AppColors.primary,
                ),
                child: Text(
                  isLoading ? 'Loading' : 'New',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: AppFonts.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _NetworkImage(url: item.imageUrl, height: 220),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PrimaryLuxuryButton(
                  label: 'View Look',
                  onTap: onPrimaryTap,
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              _PaletteSwatches(colors: item.palette),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniLookCard extends StatelessWidget {
  const _MiniLookCard({required this.item, required this.onTap});

  final DashboardRecommendation item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: _LuxuryCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _NetworkImage(url: item.imageUrl, height: 104),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.2,
                fontFamily: AppFonts.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonCard extends StatelessWidget {
  const _SeasonCard({required this.title, required this.imagePath});

  final String title;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return _LuxuryCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 96,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.2,
                  fontFamily: AppFonts.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: _LuxuryCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _DashboardPalette.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _DashboardPalette.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: AppFonts.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _DashboardPalette.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceCard extends StatelessWidget {
  const _ConfidenceCard({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return _LuxuryCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 86,
            width: 86,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 7,
                  backgroundColor: AppColors.cardBackground.withValues(
                    alpha: 0.08,
                  ),
                  color: _DashboardPalette.gold,
                ),
                Center(
                  child: Text(
                    '$score%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: AppFonts.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Style Confidence',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: AppFonts.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Great! Your profile is well optimized for personalized recommendations.',
            style: TextStyle(
              color: _DashboardPalette.mutedText,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : _DashboardPalette.outline,
          ),
          boxShadow: AppColors.softShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : AppColors.primaryDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.primaryDark,
                  fontSize: 13,
                  fontFamily: AppFonts.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: _DashboardPalette.outline),
        backgroundColor: _DashboardPalette.card,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return _LuxuryCard(
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
                  color: _DashboardPalette.cardAlt,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: _DashboardPalette.mutedText,
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

class _PrimaryLuxuryButton extends StatelessWidget {
  const _PrimaryLuxuryButton({
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

class _SmallInfoPanel extends StatelessWidget {
  const _SmallInfoPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _LuxuryCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _DashboardPalette.gold),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: AppFonts.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: _DashboardPalette.mutedText,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : _DashboardPalette.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.primaryDark,
            fontSize: 12,
            fontFamily: AppFonts.bold,
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _LuxuryCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontFamily: AppFonts.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _DashboardPalette.mutedText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClosetCard extends StatelessWidget {
  const _ClosetCard({
    required this.item,
    required this.onFavorite,
    required this.onEdit,
    required this.onDelete,
  });

  final WardrobeEntry item;
  final VoidCallback onFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _LuxuryCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox.expand(
                    child: buildSelectedImage(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: _DashboardPalette.cardAlt,
                        child: const Icon(
                          Icons.checkroom_outlined,
                          color: _DashboardPalette.mutedText,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _DashboardPalette.gold,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 6,
                  top: 6,
                  child: Row(
                    children: [
                      _MiniIconButton(icon: Icons.edit_outlined, onTap: onEdit),
                      const SizedBox(width: 6),
                      _MiniIconButton(
                        icon: Icons.delete_outline,
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.category,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: AppFonts.bold,
            ),
          ),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _DashboardPalette.mutedText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverLookCard extends StatelessWidget {
  const _DiscoverLookCard({required this.item, required this.onTap});

  final DiscoverEntry item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: _LuxuryCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _NetworkImage(
                  url: item.imageUrl,
                  height: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: AppFonts.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.title, required this.imagePath});

  final String title;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return _LuxuryCard(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                imagePath,
                height: 112,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.35,
                fontFamily: AppFonts.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
            boxShadow: AppColors.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _DashboardPalette.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _DashboardPalette.gold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontFamily: AppFonts.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: _DashboardPalette.mutedText,
              ),
          ],
        ),
      ),
    ),
  );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_filled, 'Home'),
      (Icons.auto_awesome_rounded, 'AI Stylist'),
      (Icons.checkroom_rounded, 'Wardrobe'),
      (Icons.storefront_rounded, 'Shop'),
      (Icons.travel_explore_rounded, 'Discover'),
      (Icons.person_rounded, 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBarBackground,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F820000),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = index == currentIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: selected
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.34),
                        )
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.$1,
                        color: selected
                            ? AppColors.primaryDark
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$2,
                        style: TextStyle(
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                          fontSize: 10,
                          fontFamily: selected
                              ? AppFonts.bold
                              : AppFonts.regular,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AssistantButton extends StatelessWidget {
  const _AssistantButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.accentGradient,
          border: Border.all(color: _DashboardPalette.gold, width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
            SizedBox(height: 2),
            Text(
              'AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: AppFonts.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _DashboardPalette.outline),
        ),
        child: Icon(icon, color: AppColors.primaryDark, size: 20),
      ),
    );
  }
}

class _LuxuryCard extends StatelessWidget {
  const _LuxuryCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _DashboardPalette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18820000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontFamily: AppFonts.bold,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: _DashboardPalette.mutedText,
      ),
    );
  }
}

class _PaletteSwatches extends StatelessWidget {
  const _PaletteSwatches({required this.colors});

  final List<int> colors;

  @override
  Widget build(BuildContext context) {
    final displayColors = colors.take(3).map((e) => Color(e)).toList();
    return Row(
      children: displayColors
          .map(
            (color) => Container(
              margin: const EdgeInsets.only(left: 6),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DataPill extends StatelessWidget {
  const _DataPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _DashboardPalette.outline),
      ),
      child: Text(
        '$label  $value',
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

class _ProfileCompletionCard extends StatelessWidget {
  const _ProfileCompletionCard({required this.completion});

  final double completion;

  @override
  Widget build(BuildContext context) {
    final percentage = (completion * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Completion',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: AppFonts.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: AppFonts.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completion,
              backgroundColor: AppColors.cardBackground,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            completion < 0.5 
                ? 'Complete your profile for better recommendations'
                : completion < 1.0
                    ? 'Almost there! Add more details'
                    : 'Profile complete! Great job!',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Saved Looks',
            value: '${state.homeRecommendations.length}',
            icon: Icons.favorite_outline,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Style Score',
            value: '88%',
            icon: Icons.star_outline,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Wardrobe',
            value: '${state.wardrobeItems.length}',
            icon: Icons.checkroom_outlined,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBackground.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontFamily: AppFonts.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StylePreferencesCard extends StatelessWidget {
  const _StylePreferencesCard({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBackground.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Style Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: AppFonts.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.profileData.stylePreferences.isEmpty)
            Text(
              'No style preferences set yet',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.profileData.stylePreferences.map((preference) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    preference,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontFamily: AppFonts.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _FallbackAssetImage(height: height);
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: buildSelectedImage(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _FallbackAssetImage(height: height),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        width: 28,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 15),
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  const _DarkTextField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.profileAccent),
        filled: true,
        fillColor: AppColors.cardBackground,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _DashboardPalette.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _FallbackAssetImage extends StatelessWidget {
  const _FallbackAssetImage({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/outfit.jpg',
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}

abstract final class _DashboardPalette {
  static const background = AppColors.background;
  static const card = AppColors.premiumInk;
  static const cardAlt = AppColors.primary;
  static const outline = AppColors.divider;
  static const gold = AppColors.accent;
  static const softGold = AppColors.accentLight;
  static const mutedText = Color(0xFFEBD0D0);
}

String _firstName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Alex';
  return trimmed.split(' ').first;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) return 'AM';
  return parts.map((part) => part[0].toUpperCase()).join();
}
