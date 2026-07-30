import 'package:flutter/material.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/widgets/selected_image.dart';
import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_luxury_card.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_network_image.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_palette.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_palette_swatches.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_primary_luxury_button.dart';

class DashboardFeaturedRecommendationCard extends StatelessWidget {
  const DashboardFeaturedRecommendationCard({super.key, 
    required this.item,
    required this.onPrimaryTap,
    required this.onAddProduct,
    required this.isLoading,
    this.primaryLabel = 'View Look',
  });

  final DashboardRecommendation item;
  final VoidCallback onPrimaryTap;
  final Future<void> Function(MatchedShopProduct product) onAddProduct;
  final bool isLoading;
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    return DashboardLuxuryCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: AppFonts.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.outfit,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DashboardPalette.mutedText,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: AppColors.primary,
                ),
                child: Text(
                  isLoading ? 'Loading' : 'New',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: AppFonts.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (item.wardrobeItemsUsed.isNotEmpty ||
              item.missingItemsToBuy.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.wardrobeItemsUsed.isNotEmpty)
                  DashboardRecommendationMetaChip(
                    label:
                        'From wardrobe: ${item.wardrobeItemsUsed.join(', ')}',
                  ),
                if (item.missingItemsToBuy.isNotEmpty)
                  DashboardRecommendationMetaChip(
                    label: 'Shop: ${item.missingItemsToBuy.join(', ')}',
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (item.matchedProducts.isNotEmpty) ...[
            const Text(
              'Shop pieces matched to this look',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: AppFonts.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...item.matchedProducts
                .take(4)
                .map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DashboardMatchedProductTile(
                      product: product,
                      onAdd: () => onAddProduct(product),
                    ),
                  ),
                ),
            const SizedBox(height: 4),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: DashboardNetworkImage(url: item.imageUrl, height: 220),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DashboardPrimaryLuxuryButton(
                  label: primaryLabel,
                  onTap: onPrimaryTap,
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              DashboardPaletteSwatches(colors: item.palette),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardMatchedProductTile extends StatelessWidget {
  const DashboardMatchedProductTile({super.key, required this.product, required this.onAdd});

  final MatchedShopProduct product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DashboardPalette.cardAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardPalette.outline),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: buildSelectedImage(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: DashboardPalette.outline,
                  child: Icon(
                    Icons.checkroom_outlined,
                    color: DashboardPalette.mutedText,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: AppFonts.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.matchReason.isEmpty
                      ? '${product.color} • ${product.size}'
                      : product.matchReason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashboardPalette.mutedText,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Rs ${product.salePrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: DashboardPalette.gold,
                    fontSize: 11,
                    fontFamily: AppFonts.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: product.stock > 0 ? onAdd : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: DashboardPalette.gold,
              side: const BorderSide(color: DashboardPalette.gold),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class DashboardRecommendationMetaChip extends StatelessWidget {
  const DashboardRecommendationMetaChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: DashboardPalette.cardAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DashboardPalette.outline),
      ),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: DashboardPalette.mutedText,
          fontSize: 11,
        ),
      ),
    );
  }
}
