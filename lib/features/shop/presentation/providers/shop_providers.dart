import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/features/shop/presentation/state/shop_state.dart';
import 'package:fashio_me/features/shop/presentation/view_model/shop_view_model.dart';
export 'shop_repository_providers.dart';

final shopViewModelProvider = NotifierProvider<ShopViewModel, ShopState>(
  ShopViewModel.new,
);
