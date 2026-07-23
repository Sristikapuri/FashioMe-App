import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_session_providers.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_item.dart';
import 'package:fashio_me/features/shop/presentation/pages/cart_page.dart';
import 'package:fashio_me/features/shop/presentation/pages/shop_detail_page.dart';
import 'package:fashio_me/features/shop/presentation/providers/shop_providers.dart';

class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  final TextEditingController _searchController = TextEditingController();
  static const List<String> _categories = [
    'All',
    'tops',
    'bottoms',
    'dresses',
    'party-wear',
    'gown',
    'formal-wear',
    'streetwear',
    'traditional',
    'outerwear',
    'activewear',
    'shirts',
    'pants',
    'skirts',
    'sweaters',
    'shoes',
    'accessories',
  ];
  static const List<(String, String)> _genderFilters = [
    ('All', 'all'),
    ('Female', 'female'),
    ('Male', 'male'),
  ];
  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(authSessionViewModelProvider).user;
    final userGender = currentUser?.gender?.toLowerCase();
    if (userGender == 'female' || userGender == 'male') {
      ref.read(shopViewModelProvider.notifier).setGender(userGender!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopViewModelProvider);
    final notifier = ref.read(shopViewModelProvider.notifier);
    final bagItems = state.bagItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shop',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Browse curated fashion items and add them to your bag.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: notifier.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _genderFilters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final filter = _genderFilters[index];
                        final selected = filter.$2 == state.selectedGender;
                        return ChoiceChip(
                          label: Text(filter.$1),
                          selected: selected,
                          onSelected: (_) => notifier.setGender(filter.$2),
                          selectedColor: AppColors.primary.withValues(
                            alpha: 0.16,
                          ),
                          labelStyle: TextStyle(
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, index) {
                  final category = _categories[index];
                  final selected = category == state.selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) => notifier.setCategory(category),
                    selectedColor: AppColors.primary.withValues(alpha: 0.16),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemCount: _categories.length,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: notifier.refresh,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        children: [
                          if (state.featuredDeals.isNotEmpty) ...[
                            const Text(
                              'Featured Deals',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 180,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: state.featuredDeals.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (_, index) {
                                  final item = state.featuredDeals[index];
                                  return _FeaturedCard(
                                    item: item,
                                    onAdd: () => notifier.addToBag(item),
                                    onTap: () => AppRoutes.push(
                                      context,
                                      ShopDetailPage(itemId: item.id),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 22),
                          ],
                          const Text(
                            'All Products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (state.filteredItems.isEmpty)
                            _EmptyShopState(
                              hasError: state.errorMessage != null,
                              onRefresh: notifier.refresh,
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.filteredItems.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.68,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemBuilder: (_, index) {
                                final item = state.filteredItems[index];
                                return _ProductCard(
                                  item: item,
                                  onAdd: () => notifier.addToBag(item),
                                  onTap: () => AppRoutes.push(
                                    context,
                                    ShopDetailPage(itemId: item.id),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BagBar(
        itemCount: state.itemCount,
        subtotal: state.subtotal,
        savings: state.discounts,
        total: state.total,
        bagItems: bagItems,
        onChangeQty: notifier.changeQuantity,
        onViewCart: () => AppRoutes.push(context, const CartPage()),
      ),
    );
  }
}

class _EmptyShopState extends StatelessWidget {
  const _EmptyShopState({required this.hasError, required this.onRefresh});

  final bool hasError;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            hasError ? Icons.cloud_off_outlined : Icons.inventory_2_outlined,
            size: 42,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            hasError ? 'Shop is temporarily unavailable' : 'No products found',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            hasError
                ? 'Check your connection and try again.'
                : 'Try another search or category.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (hasError) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.item,
    required this.onAdd,
    required this.onTap,
  });

  final ShopItem item;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  item.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.surfaceMuted,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.category} • ${item.color}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  item.discountedPrice != null
                      ? '\$${item.price.toStringAsFixed(2)}'
                      : '\$${item.salePrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    decoration: item.discountedPrice != null
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${item.salePrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAdd,
                child: const Text('Add to bag'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.onAdd,
    required this.onTap,
  });

  final ShopItem item;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  item.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.surfaceMuted,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (item.discountedPrice != null) ...[
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      '\$${item.salePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ] else
                    Text(
                      '\$${item.salePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAdd,
                      child: const Text('Add to bag'),
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

class _BagBar extends StatelessWidget {
  const _BagBar({
    required this.itemCount,
    required this.subtotal,
    required this.savings,
    required this.total,
    required this.bagItems,
    required this.onChangeQty,
    required this.onViewCart,
  });

  final int itemCount;
  final double subtotal;
  final double savings;
  final double total;
  final List<(ShopItem, int)> bagItems;
  final void Function(String id, int quantity) onChangeQty;
  final VoidCallback onViewCart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$itemCount items',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: Text(
                  '\$${total.toStringAsFixed(2)}',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (bagItems.isNotEmpty)
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: bagItems.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final item = bagItems[index];
                  return Container(
                    width: 240,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            item.$1.imageUrl,
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.$1.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '\$${(item.$1.salePrice * item.$2).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 2,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        onChangeQty(item.$1.id, item.$2 - 1),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 30,
                                      height: 30,
                                    ),
                                  ),
                                  Text('${item.$2}'),
                                  IconButton(
                                    onPressed: () =>
                                        onChangeQty(item.$1.id, item.$2 + 1),
                                    icon: const Icon(Icons.add_circle_outline),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 30,
                                      height: 30,
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
                },
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Subtotal: \$${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Text(
                'Savings: \$${savings.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              TextButton(onPressed: onViewCart, child: const Text('View cart')),
            ],
          ),
        ],
      ),
    );
  }
}
