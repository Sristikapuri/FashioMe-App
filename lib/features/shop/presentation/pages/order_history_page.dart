import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/extensions/context_extensions.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_order.dart';
import 'package:fashio_me/features/shop/presentation/pages/order_detail_page.dart';
import 'package:fashio_me/features/shop/presentation/providers/shop_providers.dart';

class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  bool _loading = true;
  String _error = '';
  List<ShopOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await ref
          .read(shopViewModelProvider.notifier)
          .fetchMyOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load order history.';
        _loading = false;
      });
    }
  }

  Future<void> _cancelOrder(ShopOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep order')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Cancel order')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(shopViewModelProvider.notifier).cancelOrder(order.id);
      await _loadOrders();
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to cancel this order.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.orderHistory),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (_error.isNotEmpty) ...[
                    Text(
                      _error,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_orders.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: Text(strings.noOrders)),
                    )
                  else
                    ..._orders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => AppRoutes.push(
                            context,
                            OrderDetailPage(orderId: order.id),
                          ),
                          child: _OrderCard(
                            order: order,
                            onCancel: () => _cancelOrder(order),
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onCancel});

  final ShopOrder order;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final total = order.total;
    final subtotal = order.subtotal;
    final status = order.status;
    final items = order.items;
    final orderId = order.id;
    final shortId = orderId.length > 6 ? orderId.substring(0, 6) : orderId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Order #$shortId',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(status.toUpperCase()),
            ],
          ),
          const SizedBox(height: 8),
          Text('Items: ${items.length}'),
          const SizedBox(height: 8),
          if (items.isNotEmpty) _OrderItemThumbnails(items: items),
          const SizedBox(height: 8),
          if (items.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map((item) => _Chip(label: '${item.name} x${item.quantity}'))
                  .toList(),
            ),
          const SizedBox(height: 4),
          Text('Subtotal: \$${subtotal.toStringAsFixed(2)}'),
          Text(
            'Total: \$${total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (status == 'pending' || status == 'paid') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel order'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderItemThumbnails extends StatelessWidget {
  const _OrderItemThumbnails({required this.items});

  final List<ShopOrderItem> items;

  @override
  Widget build(BuildContext context) {
    const maxThumbnails = 5;
    final shown = items.take(maxThumbnails).toList();
    final overflow = items.length - shown.length;

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          ...shown.map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: (item.imageUrl == null || item.imageUrl!.isEmpty)
                      ? Container(
                          color: AppColors.surfaceMuted,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.surfaceMuted,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
          if (overflow > 0)
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                '+$overflow',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
