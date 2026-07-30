import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/extensions/context_extensions.dart';
import 'package:fashio_me/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_action_panel.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_closet_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_dark_text_field.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_filter_chip.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_info_strip.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_luxury_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_palette.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_section_title.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_small_info_panel.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_stat_tile.dart';

class WardrobeTab extends ConsumerWidget {
  const WardrobeTab({super.key, required this.state, required this.onAddItem});

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
      if (state.wardrobeFilter == 'Other') {
        const knownCategories = [
          'tops',
          'bottoms',
          'dresses',
          'shoes',
          'accessories',
        ];
        return !knownCategories.any(
          (category) => item.category.toLowerCase().contains(category),
        );
      }
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
              return DashboardFilterChip(
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
            DashboardStatTile(value: '${state.wardrobeItems.length}', label: 'Items'),
            DashboardStatTile(
              value:
                  '${state.wardrobeItems.where((e) => e.entryType == 'look').length}',
              label: 'Outfits',
            ),
            DashboardStatTile(
              value: '${state.wardrobeItems.where((e) => e.isFavorite).length}',
              label: 'Favorites',
            ),
            DashboardStatTile(
              value:
                  '${state.wardrobeItems.where((e) => e.tag.toLowerCase().contains('recent')).length + 8}',
              label: 'Recently Worn',
            ),
          ],
        ),
        const SizedBox(height: 24),
        DashboardSectionTitle(
          title: 'My Collection',
          actionLabel: 'View All',
          onAction: () => _showFullCollectionView(
            context,
            ref,
            state,
            onEdit: (item) => _showEditWardrobeItemSheet(context, ref, item),
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardSmallInfoPanel(
                title: 'Closet is empty',
                subtitle:
                    'Add tops, bottoms, shoes, and accessories to build your wardrobe.',
                icon: Icons.checkroom_outlined,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add),
                label: const Text('Add your first item'),
              ),
            ],
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
            itemBuilder: (context, index) => DashboardClosetCard(
              item: items[index],
              onFavorite: () => notifier.toggleWardrobeFavorite(items[index]),
              onEdit: () =>
                  _showEditWardrobeItemSheet(context, ref, items[index]),
              onDelete: () => notifier.removeWardrobeItem(items[index]),
            ),
          ),
        const SizedBox(height: 24),
        DashboardInfoStrip(
          icon: Icons.weekend_outlined,
          title: 'Closet Organizer',
          subtitle: 'Organize and manage your entire closet by category.',
          onTap: () => _showClosetOrganizerSheet(context, state, ref),
        ),
        const SizedBox(height: 14),
        DashboardLuxuryCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Add Your Items',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontFamily: AppFonts.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Build your digital wardrobe by adding your own clothing items.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DashboardPalette.mutedText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DashboardActionPanel(
                      icon: Icons.photo_camera_outlined,
                      label: 'Camera',
                      onTap: onAddItem,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DashboardActionPanel(
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
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: DashboardPalette.outline),
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
      backgroundColor: DashboardPalette.card,
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
              DashboardDarkTextField(controller: titleController, label: 'Title'),
              const SizedBox(height: 12),
              DashboardDarkTextField(controller: categoryController, label: 'Category'),
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

void _showFullCollectionView(
  BuildContext context,
  WidgetRef ref,
  DashboardState state,
  {required void Function(WardrobeEntry item) onEdit}
) {
  final items = state.wardrobeItems;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Container(
        height: context.screenHeight * 0.8,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Full Wardrobe Collection (${items.length})',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 20,
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
              child: items.isEmpty
                  ? const Center(child: Text('Your wardrobe is empty.'))
                  : GridView.builder(
                      itemCount: items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.68,
                          ),
                      itemBuilder: (context, index) => DashboardClosetCard(
                        item: items[index],
                        onFavorite: () => ref
                            .read(dashboardViewModelProvider.notifier)
                            .toggleWardrobeFavorite(items[index]),
                        onEdit: () => onEdit(items[index]),
                        onDelete: () => ref
                            .read(dashboardViewModelProvider.notifier)
                            .removeWardrobeItem(items[index]),
                      ),
                    ),
            ),
          ],
        ),
      );
    },
  );
}

void _showClosetOrganizerSheet(
  BuildContext context,
  DashboardState state,
  WidgetRef ref,
) {
  final categories = [
    'All',
    'Tops',
    'Bottoms',
    'Dresses',
    'Shoes',
    'Accessories',
    'Other',
  ];
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Closet Organizer & Category Breakdown',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 20,
                fontFamily: AppFonts.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categories.map((cat) {
              final count = cat == 'All'
                  ? state.wardrobeItems.length
                  : cat == 'Other'
                  ? state.wardrobeItems.where((i) {
                      const known = [
                        'tops',
                        'bottoms',
                        'dresses',
                        'shoes',
                        'accessories',
                      ];
                      return !known.any(
                        (category) => i.category.toLowerCase().contains(category),
                      );
                    }).length
                  : state.wardrobeItems
                        .where(
                          (i) => i.category.toLowerCase().contains(
                            cat.toLowerCase(),
                          ),
                        )
                        .length;
              final selected = state.wardrobeFilter == cat;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  ref
                      .read(dashboardViewModelProvider.notifier)
                      .setWardrobeFilter(cat);
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.checkroom_outlined,
                        color: selected
                            ? AppColors.primary
                            : AppColors.primaryDark,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        cat,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count items',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
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
                  'Close Organizer',
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
