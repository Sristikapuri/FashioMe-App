import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/features/review/presentation/widgets/reviews_section.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_item.dart';
import 'package:fashio_me/features/shop/presentation/providers/shop_providers.dart';

class ShopDetailPage extends ConsumerWidget {
  const ShopDetailPage({super.key, required this.itemId});

  final String itemId;

  Future<void> _addToBag(WidgetRef ref, ShopItem item) async {
    await ref.read(shopViewModelProvider.notifier).addToBag(item);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('Product Details'),
      ),
      body: FutureBuilder<ShopItem>(
        future: ref.read(shopViewModelProvider.notifier).fetchItem(itemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load product details.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }

          final item = snapshot.data;
          if (item == null) {
            return const Center(child: Text('Product not found.'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.surfaceMuted,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(label: item.category),
                  _Chip(label: item.color),
                  _Chip(label: item.size),
                  _Chip(label: item.status),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (item.discountedPrice != null)
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                        fontSize: 16,
                      ),
                    ),
                  if (item.discountedPrice != null) const SizedBox(width: 10),
                  Text(
                    '\$${item.salePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.discountedPrice != null
                    ? 'You save \$${item.savings.toStringAsFixed(2)} on this item.'
                    : '${item.stock} in stock',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              Text(
                item.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await _addToBag(ref, item);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.name} added to bag'),
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'Open bag',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add to bag'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back to shop'),
              ),
              const SizedBox(height: 28),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 16),
              ReviewsSection(clotheId: item.id),
            ],
          );
        },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
