import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/features/shop/presentation/pages/shop_detail_page.dart';
import 'package:fashio_me/features/shop/presentation/providers/shop_providers.dart';

class WishlistPage extends ConsumerWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopViewModelProvider);
    final items = state.items
        .where((item) => state.wishlistIds.contains(item.id))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const Center(
              child: Text(
                'Your wishlist is empty.\nTap the heart on a product to save it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  onTap: () => AppRoutes.push(
                    context,
                    ShopDetailPage(itemId: item.id),
                  ),
                  tileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.image),
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Text('\$${item.salePrice.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    tooltip: 'Remove from wishlist',
                    icon: const Icon(Icons.favorite, color: AppColors.primary),
                    onPressed: () => ref
                        .read(shopViewModelProvider.notifier)
                        .toggleWishlist(item.id),
                  ),
                );
              },
            ),
    );
  }
}
