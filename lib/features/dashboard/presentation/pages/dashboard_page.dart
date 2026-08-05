import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/extensions/context_extensions.dart';
import 'package:fashio_me/features/dashboard/presentation/pages/ai_stylist_tab.dart';
import 'package:fashio_me/features/dashboard/presentation/pages/discover_tab.dart';
import 'package:fashio_me/features/dashboard/presentation/pages/home_tab.dart';
import 'package:fashio_me/features/dashboard/presentation/pages/profile_tab.dart';
import 'package:fashio_me/features/dashboard/presentation/pages/wardrobe_tab.dart';
import 'package:fashio_me/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_bottom_nav_bar.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_dark_text_field.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_palette.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_sheet_action.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_top_bar.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_top_icon_button.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _selectedEvent = 'Wedding';
  String _selectedSource = 'My Wardrobe';
  String _selectedWeather = 'Summer / Hot';
  String _selectedVibe = 'Minimalist';

  static const _events = [
    ('Wedding', Icons.favorite_outline),
    ('Party', Icons.celebration_outlined),
    ('Formal', Icons.workspace_premium_outlined),
    ('Casual', Icons.weekend_outlined),
    ('Date Night', Icons.local_fire_department_outlined),
    ('Office', Icons.work_outline),
    ('Festival', Icons.auto_awesome_outlined),
    ('Travel', Icons.flight_takeoff_outlined),
    ('Gala', Icons.star_border_outlined),
    ('Street Style', Icons.checkroom_outlined),
    ('Beach', Icons.beach_access_outlined),
    ('Sangeet', Icons.music_note_outlined),
    ('Black Tie', Icons.dry_cleaning_outlined),
    ('Brunch', Icons.local_cafe_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final titles = [
      strings.navHome,
      strings.navAiStylist,
      strings.navMyWardrobe,
      strings.navDiscoverTrends,
      strings.navMyProfile,
    ];
    final state = ref.watch(dashboardViewModelProvider);
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    final pages = [
      HomeTab(
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
      AiStylistTab(
        state: state,
        selectedEvent: _selectedEvent,
        selectedSource: _selectedSource,
        selectedWeather: _selectedWeather,
        selectedVibe: _selectedVibe,
        events: _events,
        onEventChanged: (value) => setState(() => _selectedEvent = value),
        onSourceChanged: (value) async {
          setState(() => _selectedSource = value);
          if (value == 'New Inspiration') {
            await notifier.generateHomeRecommendation(
              occasion:
                  '$_selectedEvent in $_selectedWeather with a $_selectedVibe vibe',
              syncCurrentRecommendation: true,
              source: value,
            );
          }
        },
        onWeatherChanged: (value) => setState(() => _selectedWeather = value),
        onVibeChanged: (value) => setState(() => _selectedVibe = value),
      ),
      WardrobeTab(state: state, onAddItem: () => _showAddItemSheet(context)),
      DiscoverTab(state: state),
      ProfileTab(state: state),
    ];

    return Scaffold(
      backgroundColor: DashboardPalette.background,
      body: Container(
        decoration: const BoxDecoration(color: DashboardPalette.background),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  DashboardTopBar(
                    title: titles[state.currentIndex],
                    onLeadingTap: _showMenuSheet,
                    onSearchTap: () => _showSearchSheet(),
                    onTrailingTap: () => state.currentIndex == 4
                        ? showDashboardNotificationsSheet(context, ref)
                        : notifier.setIndex(4),
                    trailingIcon: state.currentIndex == 4
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNavBar(
        currentIndex: state.currentIndex,
        onTap: notifier.setIndex,
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: DashboardPalette.card,
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showMenuSheet() {
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                Text(
                  context.strings.menuTitle,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 22,
                    fontFamily: AppFonts.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.home_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(context.strings.navHome),
                  onTap: () {
                    Navigator.pop(context);
                    notifier.setIndex(0);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.auto_awesome_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(context.strings.navAiStylist),
                  onTap: () {
                    Navigator.pop(context);
                    notifier.setIndex(1);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.checkroom_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(context.strings.navMyWardrobe),
                  onTap: () {
                    Navigator.pop(context);
                    notifier.setIndex(2);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(context.strings.navShopCatalog),
                  onTap: () {
                    Navigator.pop(context);
                    notifier.setIndex(3);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.explore_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(context.strings.navDiscoverTrends),
                  onTap: () {
                    Navigator.pop(context);
                    notifier.setIndex(3);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(context.strings.navMyOrders),
                  onTap: () {
                    Navigator.pop(context);
                    AppRoutes.toOrderHistory(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.star_outline,
                    color: AppColors.primary,
                  ),
                  title: Text(context.strings.navMyReviews),
                  onTap: () {
                    Navigator.pop(context);
                    AppRoutes.toMyReviews(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(context.strings.navStyleArchive),
                  onTap: () {
                    Navigator.pop(context);
                    AppRoutes.toStyleArchive(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                  ),
                  title: Text(context.strings.navMyProfile),
                  onTap: () {
                    Navigator.pop(context);
                    notifier.setIndex(3);
                  },
                ),
              ],
            ),
          ),
        );
      },
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
            context.viewInsetsBottom + 18,
          ),
          child: Row(
            children: [
              Expanded(
                child: DashboardDarkTextField(
                  controller: controller,
                  label: 'Search',
                ),
              ),
              const SizedBox(width: 8),
              DashboardTopIconButton(
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
            DashboardSheetAction(
              icon: Icons.photo_camera_outlined,
              title: 'Camera',
              onTap: () {
                Navigator.pop(context);
                _addWardrobeItemFromImage(ImageSource.camera);
              },
            ),
            DashboardSheetAction(
              icon: Icons.upload_outlined,
              title: 'Upload Image',
              onTap: () {
                Navigator.pop(context);
                _addWardrobeItemFromImage(ImageSource.gallery);
              },
            ),
            DashboardSheetAction(
              icon: Icons.edit_note_outlined,
              title: 'Add Manually',
              onTap: () {
                Navigator.pop(context);
                _showManualWardrobeItemSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showManualWardrobeItemSheet() async {
    final titleController = TextEditingController();
    final categoryController = TextEditingController();
    final notifier = ref.read(dashboardViewModelProvider.notifier);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Wardrobe Item',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DashboardDarkTextField(
              controller: titleController,
              label: 'Item name',
            ),
            const SizedBox(height: 12),
            DashboardDarkTextField(
              controller: categoryController,
              label: 'Category (e.g. Tops, Shoes)',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final category = categoryController.text.trim();
                  if (title.isEmpty || category.isEmpty) {
                    _showSnack('Enter an item name and category.');
                    return;
                  }
                  await notifier.addWardrobeItem(title, category);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    categoryController.dispose();
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
