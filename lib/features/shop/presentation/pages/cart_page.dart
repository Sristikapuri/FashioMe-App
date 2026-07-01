import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/features/shop/data/datasources/shop_remote_datasource.dart';
import 'package:fashio_me/features/shop/data/models/shop_item_model.dart';
import 'package:fashio_me/features/shop/presentation/pages/order_history_page.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  final TextEditingController _addressController = TextEditingController();
  bool _loading = true;
  bool _placingOrder = false;
  String _error = '';
  Map<String, int> _bag = {};
  List<ShopItemModel> _catalog = [];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    try {
      final remote = ref.read(shopRemoteDataSourceProvider);
      final bag = await remote.fetchCartItems();
      final catalog = await remote.fetchShopItems(limit: 100);
      if (!mounted) return;
      setState(() {
        _bag = bag;
        _catalog = catalog;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load cart.';
        _loading = false;
      });
    }
  }

  Future<void> _persistCart(Map<String, int> nextBag) async {
    setState(() {
      _bag = nextBag;
    });

    try {
      await ref.read(shopRemoteDataSourceProvider).saveCartItems(nextBag);
      if (!mounted) return;
      setState(() {
        _error = '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Saved locally, but backend sync failed.';
      });
    }
  }

  Future<void> _placeOrder() async {
    final shippingAddress = _addressController.text.trim();
    if (shippingAddress.isEmpty) {
      setState(() {
        _error = 'Please enter a shipping address.';
      });
      return;
    }

    setState(() {
      _placingOrder = true;
      _error = '';
    });

    try {
      await ref
          .read(shopRemoteDataSourceProvider)
          .placeOrder(shippingAddress: shippingAddress);
      await _persistCart({});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully.')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to place order.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _placingOrder = false;
        });
      }
    }
  }

  ShopItemModel? _findItem(String id) {
    for (final item in _catalog) {
      if (item.id == id) return item;
    }
    return null;
  }

  double get _subtotal {
    return _bag.entries.fold<double>(0, (sum, entry) {
      final item = _findItem(entry.key);
      if (item == null) return sum;
      return sum + (item.salePrice * entry.value);
    });
  }

  double get _tax => _subtotal * 0.05;
  double get _total => _subtotal + _tax;

  void _changeQty(String id, int quantity) {
    final nextBag = Map<String, int>.from(_bag);
    if (quantity <= 0) {
      nextBag.remove(id);
    } else {
      nextBag[id] = quantity;
    }
    _persistCart(nextBag);
  }

  void _removeItem(String id) => _changeQty(id, 0);

  @override
  Widget build(BuildContext context) {
    final entries = _bag.entries.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCart,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (_error.isNotEmpty) ...[
                    Text(
                      _error,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Shipping address',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: Text('Your cart is empty.')),
                    )
                  else
                    ...entries.map((entry) {
                      final item = _findItem(entry.key);
                      if (item == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CartCard(
                          item: item,
                          quantity: entry.value,
                          onIncrease: () =>
                              _changeQty(item.id, entry.value + 1),
                          onDecrease: () =>
                              _changeQty(item.id, entry.value - 1),
                          onRemove: () => _removeItem(item.id),
                          onTap: () => AppRoutes.push(
                            context,
                            CartDetailStubPage(itemId: item.id),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE7B8B8)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Subtotal',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const Spacer(),
                            Text(
                              '\$${_subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Tax',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const Spacer(),
                            Text(
                              '\$${_tax.toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: entries.isEmpty || _placingOrder
                                ? null
                                : _placeOrder,
                            child: Text(
                              _placingOrder
                                  ? 'Placing order...'
                                  : 'Place order',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              AppRoutes.push(context, const OrderHistoryPage()),
                          child: const Text('View order history'),
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

class _CartCard extends StatelessWidget {
  const _CartCard({
    required this.item,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onTap,
  });

  final ShopItemModel item;
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7B8B8)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                item.imageUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFF7F7F7),
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.category} • ${item.color}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${item.salePrice.toStringAsFixed(2)} each',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 170;
                      return Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          IconButton(
                            onPressed: onDecrease,
                            icon: const Icon(Icons.remove_circle_outline),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 32,
                              height: 32,
                            ),
                          ),
                          Text(
                            '$quantity',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          IconButton(
                            onPressed: onIncrease,
                            icon: const Icon(Icons.add_circle_outline),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 32,
                              height: 32,
                            ),
                          ),
                          if (compact)
                            TextButton(
                              onPressed: onRemove,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Remove'),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: TextButton(
                                onPressed: onRemove,
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Remove'),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 72),
              child: Text(
                '\$${(item.salePrice * quantity).toStringAsFixed(2)}',
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartDetailStubPage extends StatelessWidget {
  const CartDetailStubPage({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart Item')),
      body: Center(child: Text('Item ID: $itemId')),
    );
  }
}
