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

// ---------------------------------------------------------------------------
// Section enum
// ---------------------------------------------------------------------------
enum _WardrobeSection { items, outfits, favourites, recentlyWorn }

extension _WardrobeSectionX on _WardrobeSection {
  String get label {
    switch (this) {
      case _WardrobeSection.items:
        return 'Items';
      case _WardrobeSection.outfits:
        return 'Outfits';
      case _WardrobeSection.favourites:
        return 'Favourites';
      case _WardrobeSection.recentlyWorn:
        return 'Recently Worn';
    }
  }

  IconData get icon {
    switch (this) {
      case _WardrobeSection.items:
        return Icons.checkroom_outlined;
      case _WardrobeSection.outfits:
        return Icons.auto_awesome_outlined;
      case _WardrobeSection.favourites:
        return Icons.favorite_border_rounded;
      case _WardrobeSection.recentlyWorn:
        return Icons.history_rounded;
    }
  }

  IconData get iconFilled {
    switch (this) {
      case _WardrobeSection.items:
        return Icons.checkroom;
      case _WardrobeSection.outfits:
        return Icons.auto_awesome;
      case _WardrobeSection.favourites:
        return Icons.favorite_rounded;
      case _WardrobeSection.recentlyWorn:
        return Icons.history_rounded;
    }
  }

  String emptyTitle(String filter) {
    switch (this) {
      case _WardrobeSection.items:
        return filter == 'All'
            ? 'No clothing items yet'
            : 'No $filter items yet';
      case _WardrobeSection.outfits:
        return 'No saved outfits yet';
      case _WardrobeSection.favourites:
        return 'No favourites yet';
      case _WardrobeSection.recentlyWorn:
        return 'Nothing recently worn';
    }
  }

  String emptySubtitle(String filter) {
    switch (this) {
      case _WardrobeSection.items:
        return 'Add your clothing pieces using the camera or upload option below.';
      case _WardrobeSection.outfits:
        return 'Save AI-generated looks from the AI Stylist tab to see them here.';
      case _WardrobeSection.favourites:
        return 'Tap the ♥ on any item or outfit to add it to your favourites.';
      case _WardrobeSection.recentlyWorn:
        return 'Items will appear here as you add or wear them.';
    }
  }
}

// ---------------------------------------------------------------------------
// Main Widget
// ---------------------------------------------------------------------------
class WardrobeTab extends ConsumerStatefulWidget {
  const WardrobeTab({
    super.key,
    required this.state,
    required this.onAddItem,
  });

  final DashboardState state;
  final VoidCallback onAddItem;

  @override
  ConsumerState<WardrobeTab> createState() => _WardrobeTabState();
}

class _WardrobeTabState extends ConsumerState<WardrobeTab> {
  _WardrobeSection _activeSection = _WardrobeSection.items;

  // ---------------------------------------------------------------------------
  // Filtered lists
  // ---------------------------------------------------------------------------
  List<WardrobeEntry> get _itemsList => widget.state.wardrobeItems
      .where((e) => e.entryType != 'look')
      .toList();

  List<WardrobeEntry> get _outfitsList => widget.state.wardrobeItems
      .where((e) => e.entryType == 'look')
      .toList();

  List<WardrobeEntry> get _favouritesList =>
      widget.state.wardrobeItems.where((e) => e.isFavorite).toList();

  List<WardrobeEntry> get _recentlyWornList {
    final sorted = [...widget.state.wardrobeItems]
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return sorted.take(15).toList();
  }

  List<WardrobeEntry> _filterByCategory(List<WardrobeEntry> source) {
    if (widget.state.wardrobeFilter == 'All') return source;
    if (widget.state.wardrobeFilter == 'Other') {
      const known = ['tops', 'bottoms', 'dresses', 'shoes', 'accessories'];
      return source
          .where(
            (e) => !known.any(
              (cat) => e.category.toLowerCase().contains(cat),
            ),
          )
          .toList();
    }
    return source
        .where(
          (e) => e.category.toLowerCase().contains(
            widget.state.wardrobeFilter.toLowerCase(),
          ),
        )
        .toList();
  }

  List<WardrobeEntry> get _activeItems {
    switch (_activeSection) {
      case _WardrobeSection.items:
        return _filterByCategory(_itemsList);
      case _WardrobeSection.outfits:
        return _filterByCategory(_outfitsList);
      case _WardrobeSection.favourites:
        // No category filter for favourites — show all favourites
        return _favouritesList;
      case _WardrobeSection.recentlyWorn:
        // No category filter for recently worn — show chronologically
        return _recentlyWornList;
    }
  }

  int _countFor(_WardrobeSection s) {
    switch (s) {
      case _WardrobeSection.items:
        return _itemsList.length;
      case _WardrobeSection.outfits:
        return _outfitsList.length;
      case _WardrobeSection.favourites:
        return _favouritesList.length;
      case _WardrobeSection.recentlyWorn:
        return _recentlyWornList.length;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    final filters = ['All', 'Tops', 'Bottoms', 'Dresses', 'Shoes', 'Accessories'];
    final showCategoryFilter = _activeSection == _WardrobeSection.items ||
        _activeSection == _WardrobeSection.outfits;
    final displayItems = _activeItems;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
      children: [
        // ── Section Tab Selector ──────────────────────────────────────────
        _WardrobeSectionBar(
          active: _activeSection,
          counts: {for (final s in _WardrobeSection.values) s: _countFor(s)},
          onSelect: (s) => setState(() => _activeSection = s),
        ),
        const SizedBox(height: 16),

        // ── Category Filter chips (only for Items & Outfits) ─────────────
        if (showCategoryFilter) ...[
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = filters[i];
                return DashboardFilterChip(
                  label: f,
                  selected: f == widget.state.wardrobeFilter,
                  onTap: () => notifier.setWardrobeFilter(f),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Section title ─────────────────────────────────────────────────
        DashboardSectionTitle(
          title: _sectionTitle,
          actionLabel: displayItems.isEmpty ? null : 'View All',
          onAction: displayItems.isEmpty
              ? null
              : () => _showFullView(context, displayItems),
        ),
        const SizedBox(height: 12),

        // ── Grid or empty state ───────────────────────────────────────────
        if (displayItems.isEmpty)
          _WardrobeEmptyState(
            section: _activeSection,
            filter: widget.state.wardrobeFilter,
            onAddItem: onAddItem,
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) => DashboardClosetCard(
              item: displayItems[index],
              onFavorite: () =>
                  notifier.toggleWardrobeFavorite(displayItems[index]),
              onEdit: () =>
                  _showEditSheet(context, ref, displayItems[index]),
              onDelete: () =>
                  notifier.removeWardrobeItem(displayItems[index]),
            ),
          ),

        const SizedBox(height: 24),

        // ── Closet Organiser strip ────────────────────────────────────────
        DashboardInfoStrip(
          icon: Icons.weekend_outlined,
          title: 'Closet Organizer',
          subtitle: 'Browse and filter all your clothes by category.',
          onTap: () => _showClosetOrganizerSheet(context, widget.state, ref),
        ),
        const SizedBox(height: 14),

        // ── Add Items card ────────────────────────────────────────────────
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

  String get _sectionTitle {
    final count = _activeItems.length;
    switch (_activeSection) {
      case _WardrobeSection.items:
        return 'Clothing Items ($count)';
      case _WardrobeSection.outfits:
        return 'Saved Outfits ($count)';
      case _WardrobeSection.favourites:
        return 'Favourites ($count)';
      case _WardrobeSection.recentlyWorn:
        return 'Recently Worn ($count)';
    }
  }

  VoidCallback get onAddItem => widget.onAddItem;

  void _showFullView(BuildContext context, List<WardrobeEntry> items) {
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        height: context.screenHeight * 0.85,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _sectionTitle,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 18,
                    fontFamily: AppFonts.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
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
                  onFavorite: () =>
                      notifier.toggleWardrobeFavorite(items[index]),
                  onEdit: () =>
                      _showEditSheet(context, ref, items[index]),
                  onDelete: () =>
                      notifier.removeWardrobeItem(items[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, WardrobeEntry item) {
    final titleController = TextEditingController(text: item.title);
    final categoryController = TextEditingController(text: item.category);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DashboardPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
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
            DashboardDarkTextField(
                controller: categoryController, label: 'Category'),
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
                  if (title.isEmpty || category.isEmpty) return;
                  await ref
                      .read(dashboardViewModelProvider.notifier)
                      .updateWardrobeItem(item,
                          title: title, category: category);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      titleController.dispose();
      categoryController.dispose();
    });
  }
}

// ---------------------------------------------------------------------------
// Section Tab Bar Widget
// ---------------------------------------------------------------------------
class _WardrobeSectionBar extends StatelessWidget {
  const _WardrobeSectionBar({
    required this.active,
    required this.counts,
    required this.onSelect,
  });

  final _WardrobeSection active;
  final Map<_WardrobeSection, int> counts;
  final ValueChanged<_WardrobeSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: _WardrobeSection.values
            .map((s) => Expanded(child: _SectionTabButton(
                  section: s,
                  count: counts[s] ?? 0,
                  isActive: s == active,
                  onTap: () => onSelect(s),
                )))
            .toList(),
      ),
    );
  }
}

class _SectionTabButton extends StatelessWidget {
  const _SectionTabButton({
    required this.section,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final _WardrobeSection section;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isActive ? AppColors.buttonShadow : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? section.iconFilled : section.icon,
              size: 18,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              section.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontFamily: AppFonts.bold,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: AppFonts.bold,
                  color: isActive ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State Widget
// ---------------------------------------------------------------------------
class _WardrobeEmptyState extends StatelessWidget {
  const _WardrobeEmptyState({
    required this.section,
    required this.filter,
    required this.onAddItem,
  });

  final _WardrobeSection section;
  final String filter;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.surfaceSoft, AppColors.navBarBackground],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: Icon(
              section.iconFilled,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            section.emptyTitle(filter),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontFamily: AppFonts.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.emptySubtitle(filter),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (section == _WardrobeSection.items ||
              section == _WardrobeSection.recentlyWorn) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onAddItem,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Add First Item',
                style: TextStyle(fontFamily: AppFonts.bold, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Closet Organiser sheet (unchanged logic, preserved from original)
// ---------------------------------------------------------------------------
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
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => ConstrainedBox(
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
                            (c) => i.category.toLowerCase().contains(c),
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
                            horizontal: 12, vertical: 4),
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
      ),
    ),
  );
}
