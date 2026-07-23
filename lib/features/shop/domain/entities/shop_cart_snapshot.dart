import 'package:fashio_me/features/shop/domain/entities/shop_item.dart';

class ShopCartSnapshot {
  const ShopCartSnapshot({this.bag = const {}, this.items = const []});

  final Map<String, int> bag;
  final List<ShopItem> items;
}
