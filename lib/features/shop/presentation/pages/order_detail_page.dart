import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_order.dart';
import 'package:fashio_me/features/shop/presentation/providers/shop_providers.dart';

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'shipped':
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<ShopOrder>(
        future: ref.read(shopViewModelProvider.notifier).fetchOrderById(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load order details.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }

          final order = snapshot.data!;
          final shortId = order.id.length > 8
              ? order.id.substring(order.id.length - 8)
              : order.id;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #$shortId',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(order.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: _statusColor(order.status),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (order.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Placed on ${_formatDate(order.createdAt)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Items',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ...order.items.map((item) => _OrderItemTile(item: item)),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Payment Summary',
                children: [
                  _SummaryRow('Subtotal', '\$${order.subtotal.toStringAsFixed(2)}'),
                  if (order.tax != null)
                    _SummaryRow('Tax', '\$${order.tax!.toStringAsFixed(2)}'),
                  _SummaryRow(
                    'Total',
                    '\$${order.total.toStringAsFixed(2)}',
                    emphasize: true,
                  ),
                  if (order.paymentMethod != null &&
                      order.paymentMethod!.isNotEmpty)
                    _SummaryRow('Payment Method', order.paymentMethod!.toUpperCase()),
                  if (order.esewaTransactionId != null &&
                      order.esewaTransactionId!.isNotEmpty)
                    _SummaryRow('eSewa Transaction', order.esewaTransactionId!),
                  if (order.esewaRefId != null && order.esewaRefId!.isNotEmpty)
                    _SummaryRow('eSewa Reference', order.esewaRefId!),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Shipping Details',
                children: [
                  if (order.customerName != null && order.customerName!.isNotEmpty)
                    _SummaryRow('Name', order.customerName!),
                  if (order.customerEmail != null && order.customerEmail!.isNotEmpty)
                    _SummaryRow('Email', order.customerEmail!),
                  if (order.phone != null && order.phone!.isNotEmpty)
                    _SummaryRow('Phone', order.phone!),
                  if (order.shippingAddress != null && order.shippingAddress!.isNotEmpty)
                    _SummaryRow('Address', order.shippingAddress!),
                  if (order.city != null && order.city!.isNotEmpty)
                    _SummaryRow('City', order.city!),
                  if (order.postalCode != null && order.postalCode!.isNotEmpty)
                    _SummaryRow('Postal Code', order.postalCode!),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final ShopOrderItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: (item.imageUrl == null || item.imageUrl!.isEmpty)
                  ? Container(
                      color: AppColors.surfaceMuted,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    )
                  : Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.surfaceMuted,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
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
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (item.category != null || item.size != null || item.color != null)
                  Text(
                    [item.category, item.size, item.color]
                        .where((v) => v != null && v.isNotEmpty)
                        .join(' • '),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                Text(
                  'Qty: ${item.quantity}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (item.price != null)
            Text(
              '\$${(item.price! * item.quantity).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
