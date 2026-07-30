import 'package:equatable/equatable.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_item.dart';

class ShopState extends Equatable {
  const ShopState({
    this.items = const [],
    this.bag = const {},
    this.selectedCategory = 'All',
    this.selectedGender = 'all',
    this.searchQuery = '',
    this.isLoading = true,
    this.errorMessage,
    this.isSyncingCart = false,
    this.showLowStockOnly = false,
    this.wishlistIds = const {},
  });

  /// Items at or below this stock count are considered "low stock".
  static const int lowStockThreshold = 5;

  final List<ShopItem> items;
  final Map<String, int> bag;
  final String selectedCategory;
  final String selectedGender;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;
  final bool isSyncingCart;
  final bool showLowStockOnly;
  final Set<String> wishlistIds;

  ShopState copyWith({
    List<ShopItem>? items,
    Map<String, int>? bag,
    String? selectedCategory,
    String? selectedGender,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isSyncingCart,
    bool? showLowStockOnly,
    Set<String>? wishlistIds,
  }) {
    return ShopState(
      items: items ?? this.items,
      bag: bag ?? this.bag,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedGender: selectedGender ?? this.selectedGender,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSyncingCart: isSyncingCart ?? this.isSyncingCart,
      showLowStockOnly: showLowStockOnly ?? this.showLowStockOnly,
      wishlistIds: wishlistIds ?? this.wishlistIds,
    );
  }

  List<ShopItem> get featuredDeals => items
      .where((item) => item.discountedPrice != null)
      .take(3)
      .toList(growable: false);

  List<ShopItem> get filteredItems {
    final query = searchQuery.trim().toLowerCase();
    final category = selectedCategory.trim().toLowerCase();
    return items
        .where((item) {
          if (showLowStockOnly && item.stock > lowStockThreshold) {
            return false;
          }
          if (category != 'all' &&
              item.category.trim().toLowerCase() != category) {
            return false;
          }
          if (selectedGender != 'all') {
            final itemGender = (item.gender ?? 'unisex').toLowerCase();
            if (itemGender != 'unisex' && itemGender != selectedGender) {
              return false;
            }
          }
          return query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query) ||
              item.category.toLowerCase().contains(query) ||
              item.color.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  ShopItem? itemById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<(ShopItem, int)> get bagItems => bag.entries
      .map((entry) {
        final item = itemById(entry.key);
        return item == null ? null : (item, entry.value);
      })
      .whereType<(ShopItem, int)>()
      .toList(growable: false);

  double get subtotal => bag.entries.fold<double>(0, (sum, entry) {
    final item = itemById(entry.key);
    return item == null ? sum : sum + item.salePrice * entry.value;
  });

  double get discounts => bag.entries.fold<double>(0, (sum, entry) {
    final item = itemById(entry.key);
    return item == null ? sum : sum + item.savings * entry.value;
  });

  double get tax => subtotal * 0.05;
  double get total => subtotal + tax;
  int get itemCount => bag.values.fold(0, (sum, quantity) => sum + quantity);

  @override
  List<Object?> get props => [
    items,
    bag,
    selectedCategory,
    selectedGender,
    searchQuery,
    isLoading,
    errorMessage,
    isSyncingCart,
    showLowStockOnly,
    wishlistIds,
  ];
}
