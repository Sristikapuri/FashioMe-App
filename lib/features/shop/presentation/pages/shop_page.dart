import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/features/shop/data/datasources/shop_remote_datasource.dart';
import 'package:fashio_me/features/shop/data/models/shop_item_model.dart';
import 'package:fashio_me/features/shop/presentation/pages/cart_page.dart';
import 'package:fashio_me/features/shop/presentation/pages/shop_detail_page.dart';

class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = const [
    'All',
    'tops',
    'bottoms',
    'shoes',
    'accessories',
  ];
  String _selectedCategory = 'All';
  List<ShopItemModel> _items = [];
  Map<String, int> _bag = {};
  bool _loading = true;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadBag();
    _fetchItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBag() async {
    try {
      final remote = ref.read(shopRemoteDataSourceProvider);
      final bag = await remote.fetchCartItems();
      if (!mounted) return;
      setState(() {
        _bag = bag;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Unable to sync cart with the backend.';
      });
    }
  }

  Future<void> _saveBag() async {
    try {
      await ref.read(shopRemoteDataSourceProvider).saveCartItems(_bag);
      if (!mounted) return;
      setState(() {
        _message = '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Cart changes could not be synced with the backend.';
      });
    }
  }

  Future<void> _fetchItems() async {
    try {
      final remote = ref.read(shopRemoteDataSourceProvider);
      final items = await remote.fetchShopItems(limit: 48);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = 'Failed to load shop items.';
      });
    }
  }

  List<ShopItemModel> get _featuredDeals =>
      _items.where((item) => item.discountedPrice != null).take(3).toList();

  List<ShopItemModel> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      if (_selectedCategory != 'All' && item.category != _selectedCategory)
        return false;
      if (query.isNotEmpty && !item.name.toLowerCase().contains(query))
        return false;
      return true;
    }).toList();
  }

  double get _subtotal {
    return _bag.entries.fold<double>(0, (sum, entry) {
      final item = _items.where((i) => i.id == entry.key).toList();
      if (item.isEmpty) return sum;
      return sum + (item.first.salePrice * entry.value);
    });
  }

  double get _discounts {
    return _bag.entries.fold<double>(0, (sum, entry) {
      final item = _items.where((i) => i.id == entry.key).toList();
      if (item.isEmpty) return sum;
      return sum + (item.first.savings * entry.value);
    });
  }

  double get _tax => (_subtotal * 0.05);
  double get _total => _subtotal + _tax;

  void _addToBag(ShopItemModel item) {
    setState(() {
      _bag[item.id] = (_bag[item.id] ?? 0) + 1;
    });
    _saveBag();
  }

  void _changeQty(String id, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _bag.remove(id);
      } else {
        _bag[id] = quantity;
      }
    });
    _saveBag();
  }

  @override
  Widget build(BuildContext context) {
    final bagItems = _bag.entries
        .map((entry) {
          final item = _items.where((i) => i.id == entry.key).toList();
          if (item.isEmpty) return null;
          return (item.first, entry.value);
        })
        .whereType<(ShopItemModel, int)>()
        .toList();

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
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  if (_message.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      _message,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search products',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE7B8B8)),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, index) {
                  final category = _categories[index];
                  final selected = category == _selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = category),
                    selectedColor: AppColors.primary.withValues(alpha: 0.16),
                    labelStyle: TextStyle(
                      color: selected ? AppColors.primaryDark : Colors.black87,
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchItems,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        children: [
                          if (_featuredDeals.isNotEmpty) ...[
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
                                itemCount: _featuredDeals.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (_, index) {
                                  final item = _featuredDeals[index];
                                  return _FeaturedCard(
                                    item: item,
                                    onAdd: () => _addToBag(item),
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
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredItems.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.68,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemBuilder: (_, index) {
                              final item = _filteredItems[index];
                              return _ProductCard(
                                item: item,
                                onAdd: () => _addToBag(item),
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
        itemCount: bagItems.fold<int>(0, (sum, entry) => sum + entry.$2),
        subtotal: _subtotal,
        savings: _discounts,
        total: _total,
        bagItems: bagItems,
        onChangeQty: _changeQty,
        onViewCart: () => AppRoutes.push(context, const CartPage()),
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

  final ShopItemModel item;
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7B8B8)),
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
                    color: const Color(0xFFF7F7F7),
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
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                    color: Colors.grey.shade600,
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

  final ShopItemModel item;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7B8B8)),
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
                    color: const Color(0xFFF7F7F7),
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  if (item.discountedPrice != null) ...[
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
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
  final List<(ShopItemModel, int)> bagItems;
  final void Function(String id, int quantity) onChangeQty;
  final VoidCallback onViewCart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7B8B8))),
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
                      color: const Color(0xFFFFF7F7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7B8B8)),
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
                                style: TextStyle(
                                  color: Colors.grey.shade700,
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
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(width: 12),
              Text(
                'Savings: \$${savings.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade700),
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
