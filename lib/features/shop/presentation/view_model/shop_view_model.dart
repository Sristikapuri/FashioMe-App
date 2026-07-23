import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_item.dart';
import 'package:fashio_me/features/shop/domain/repositories/shop_repository.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_order.dart';
import 'package:fashio_me/features/shop/presentation/state/shop_state.dart';
import 'package:fashio_me/features/shop/presentation/providers/shop_repository_providers.dart';

class ShopViewModel extends Notifier<ShopState> {
  late final IShopRepository _repository;
  Future<void>? _loadTask;

  @override
  ShopState build() {
    _repository = ref.read(shopRepositoryProvider);
    Future.microtask(load);
    return const ShopState();
  }

  Future<void> load({bool force = false}) {
    if (!force && _loadTask != null) return _loadTask!;

    final task = _load();
    _loadTask = task;
    task.whenComplete(() {
      if (identical(_loadTask, task)) _loadTask = null;
    });
    return task;
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    var items = state.items;
    var bag = state.bag;
    String? loadError;

    try {
      items = await _repository.fetchShopItems(limit: 100);
    } catch (_) {
      loadError = 'Unable to load products. Pull down to try again.';
    }

    try {
      final cartSnapshot = await _repository.fetchCartItems();
      bag = cartSnapshot.bag;
      final bagProducts = cartSnapshot.items;
      if (bagProducts.isNotEmpty) {
        final mergedItems = <ShopItem>[
          ...items,
          for (final item in bagProducts)
            if (!items.any((existing) => existing.id == item.id)) item,
        ];
        items = mergedItems;
      }
    } catch (_) {
      loadError ??= 'Products loaded, but your bag could not be synced.';
    }

    state = state.copyWith(
      items: items,
      bag: bag,
      isLoading: false,
      errorMessage: loadError,
      clearError: loadError == null,
    );

    if (items.isEmpty && loadError == null) {
      state = state.copyWith(
        errorMessage: 'No products are available right now. Pull to refresh.',
      );
    }
  }

  Future<void> refresh() => load(force: true);

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setGender(String gender) {
    state = state.copyWith(selectedGender: gender);
  }

  void setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  Future<void> addToBag(ShopItem item) {
    return changeQuantity(item.id, (state.bag[item.id] ?? 0) + 1);
  }

  Future<bool> addToBagById(String id) async {
    var item = state.itemById(id);
    if (item == null) {
      try {
        item = await _repository.fetchShopItemById(id);
        state = state.copyWith(
          items: [
            ...state.items.where((existing) => existing.id != item!.id),
            item,
          ],
          clearError: true,
        );
      } catch (_) {
        state = state.copyWith(
          errorMessage: 'This matching product is unavailable right now.',
        );
        return false;
      }
    }

    await addToBag(item);
    return true;
  }

  Future<void> changeQuantity(String id, int quantity) async {
    final nextBag = Map<String, int>.from(state.bag);
    if (quantity <= 0) {
      nextBag.remove(id);
    } else {
      nextBag[id] = quantity;
    }

    state = state.copyWith(bag: nextBag, isSyncingCart: true, clearError: true);
    try {
      await _repository.saveCartItems(nextBag);
      state = state.copyWith(isSyncingCart: false);
    } catch (_) {
      state = state.copyWith(
        isSyncingCart: false,
        errorMessage: 'Cart changes are saved locally but could not sync.',
      );
    }
  }

  Future<void> clearBag() async {
    state = state.copyWith(
      bag: const {},
      isSyncingCart: true,
      clearError: true,
    );
    try {
      await _repository.saveCartItems(const {});
      state = state.copyWith(isSyncingCart: false);
    } catch (_) {
      state = state.copyWith(
        isSyncingCart: false,
        errorMessage: 'Order placed, but the cart could not be cleared.',
      );
    }
  }

  Future<String> placeOrder({
    required String shippingAddress,
    required String customerName,
    required String customerEmail,
    required String phone,
    required String city,
    required String postalCode,
    required String paymentMethod,
  }) {
    return _repository.placeOrder(
      shippingAddress: shippingAddress,
      customerName: customerName,
      customerEmail: customerEmail,
      phone: phone,
      city: city,
      postalCode: postalCode,
      paymentMethod: paymentMethod,
    );
  }

  Future<String> getEsewaPaymentUrl({
    required double amount,
    required String orderId,
    required String productCode,
  }) {
    return _repository.getEsewaPaymentUrl(
      amount: amount,
      orderId: orderId,
      productCode: productCode,
    );
  }

  Future<bool> verifyEsewaPayment({
    required double amount,
    required String orderId,
    required String productCode,
  }) {
    return _repository.verifyEsewaPayment(
      amount: amount,
      orderId: orderId,
      productCode: productCode,
    );
  }

  Future<ShopItem> fetchItem(String id) => _repository.fetchShopItemById(id);

  Future<List<ShopOrder>> fetchMyOrders() => _repository.fetchMyOrders();
}
