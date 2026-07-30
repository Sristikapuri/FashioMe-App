import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/extensions/context_extensions.dart';
import 'package:fashio_me/core/services/deep_link/deep_link_service.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_item.dart';
import 'package:fashio_me/features/shop/presentation/pages/order_history_page.dart';
import 'package:fashio_me/features/shop/presentation/pages/shop_detail_page.dart';
import 'package:fashio_me/features/shop/presentation/providers/shop_providers.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  String _paymentMethod = 'cod';
  bool _placingOrder = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<bool?> _openEsewaAndCheckStatus({
    required String orderId,
    required double totalAmount,
    required String paymentUrl,
  }) async {
    final launched = await launchUrl(
      Uri.parse(paymentUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw StateError('Could not open the eSewa payment page.');
    }
    if (!mounted) return null;

    final verifying = ValueNotifier<bool>(false);
    final dialogError = ValueNotifier<String>('');
    // Guards against a deep link arriving after the dialog already closed
    // (e.g. "Not now" was tapped, then a delayed callback fires) from
    // popping the wrong route — CartPage itself, not the dialog.
    var dialogOpen = true;

    Future<void> runVerification() async {
      if (!dialogOpen || !mounted || verifying.value) return;
      verifying.value = true;
      dialogError.value = '';
      try {
        final success = await ref
            .read(shopViewModelProvider.notifier)
            .verifyEsewaPayment(
              amount: totalAmount,
              orderId: orderId,
              productCode: 'EPAYTEST',
            );
        if (!dialogOpen || !mounted) return;
        if (success) {
          dialogOpen = false;
          Navigator.of(context).pop(true);
        } else {
          verifying.value = false;
          dialogError.value =
              'Payment is not complete yet. Finish eSewa payment and try again.';
        }
      } catch (e) {
        if (!dialogOpen || !mounted) return;
        verifying.value = false;
        dialogError.value = 'Verification failed: ${e.toString()}';
      }
    }

    final deepLinkService = ref.read(deepLinkServiceProvider);
    deepLinkService.start();
    final linkSubscription = deepLinkService.linkStream.listen((uri) {
      if (uri.host != 'esewa-payment') return;
      final linkOrderId = uri.queryParameters['orderId'];
      if (linkOrderId != null && linkOrderId != orderId) return;

      final status = uri.queryParameters['status'];
      if (status == 'success') {
        runVerification();
      } else if (status == 'failed' && dialogOpen && mounted) {
        dialogOpen = false;
        Navigator.of(context).pop(false);
      }
    });

    try {
      return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AnimatedBuilder(
            animation: Listenable.merge([verifying, dialogError]),
            builder: (dialogContext, _) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF60BB46),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'e',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'eSewa Gateway',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID: $orderId',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Amount: \$${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF60BB46),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (dialogError.value.isNotEmpty) ...[
                      Text(
                        dialogError.value,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (verifying.value)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFF60BB46),
                            ),
                          ),
                        ),
                      )
                    else
                      const Text(
                        "Complete the payment in the eSewa page that opened. "
                        "We'll detect it automatically — or check manually below.",
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                  ],
                ),
                actions: [
                  if (!verifying.value) ...[
                    TextButton(
                      onPressed: () {
                        dialogOpen = false;
                        Navigator.of(dialogContext).pop(false);
                      },
                      child: const Text(
                        'Not now',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        await launchUrl(
                          Uri.parse(paymentUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: const Text('Open eSewa'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60BB46),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: runVerification,
                      child: const Text('Check payment'),
                    ),
                  ],
                ],
              );
            },
          );
        },
      );
    } finally {
      dialogOpen = false;
      await linkSubscription.cancel();
      deepLinkService.stop();
      verifying.dispose();
      dialogError.dispose();
    }
  }

  Future<void> _placeOrder() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();
    final postalCode = _postalCodeController.text.trim();
    final address = _addressController.text.trim();
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        city.isEmpty ||
        postalCode.isEmpty ||
        address.isEmpty) {
      ref
          .read(shopViewModelProvider.notifier)
          .setError('Please fill out all checkout fields.');
      return;
    }

    if (!emailPattern.hasMatch(email)) {
      ref
          .read(shopViewModelProvider.notifier)
          .setError('Please enter a valid email address.');
      return;
    }

    setState(() {
      _placingOrder = true;
    });

    final shopState = ref.read(shopViewModelProvider);
    final notifier = ref.read(shopViewModelProvider.notifier);
    final totalAmount = shopState.total;
    final shippingAddress = '$address, $city, $postalCode';

    try {
      final orderId = await notifier.placeOrder(
        shippingAddress: shippingAddress,
        customerName: name,
        customerEmail: email,
        phone: phone,
        city: city,
        postalCode: postalCode,
        paymentMethod: _paymentMethod,
      );

      if (_paymentMethod == 'esewa') {
        final paymentUrl = await notifier.getEsewaPaymentUrl(
          amount: totalAmount,
          orderId: orderId,
          productCode: 'EPAYTEST',
        );

        final success = await _openEsewaAndCheckStatus(
          orderId: orderId,
          totalAmount: totalAmount,
          paymentUrl: paymentUrl,
        );
        if (success != true) {
          if (!mounted) return;
          notifier.setError(
            'Order $orderId was created and is awaiting eSewa payment. You can check its status from order history.',
          );
          return;
        }
      }

      await notifier.clearBag();
      if (!mounted) return;
      final viewOrders = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Order successful'),
          content: Text(
            _paymentMethod == 'esewa'
                ? 'Your payment was confirmed and your order is being processed.'
                : 'Your order was placed successfully and is being processed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Continue Shopping'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('View Order History'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      if (viewOrders == true && mounted) {
        AppRoutes.push(context, const OrderHistoryPage());
      }
    } catch (e) {
      if (!mounted) return;
      notifier.setError('Failed to place order: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _placingOrder = false;
        });
      }
    }
  }

  void _changeQty(String id, int quantity) {
    ref.read(shopViewModelProvider.notifier).changeQuantity(id, quantity);
  }

  void _removeItem(String id) => _changeQty(id, 0);

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopViewModelProvider);
    final entries = shopState.bagItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: shopState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: ref.read(shopViewModelProvider.notifier).refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (shopState.errorMessage != null) ...[
                    Text(
                      shopState.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: Text('Your cart is empty.')),
                    )
                  else ...[
                    ...entries.map((entry) {
                      final item = entry.$1;
                      final quantity = entry.$2;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CartCard(
                          item: item,
                          quantity: quantity,
                          onIncrease: () => _changeQty(item.id, quantity + 1),
                          onDecrease: () => _changeQty(item.id, quantity - 1),
                          onRemove: () => _removeItem(item.id),
                          onTap: () => AppRoutes.push(
                            context,
                            ShopDetailPage(itemId: item.id),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Checkout Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _cityController,
                                  decoration: const InputDecoration(
                                    labelText: 'City',
                                    filled: true,
                                    fillColor: Colors.transparent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _postalCodeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Postal Code',
                                    filled: true,
                                    fillColor: Colors.transparent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Street Address',
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('COD')),
                                  selected: _paymentMethod == 'cod',
                                  selectedColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    color: _paymentMethod == 'cod'
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _paymentMethod = 'cod';
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('eSewa')),
                                  selected: _paymentMethod == 'esewa',
                                  selectedColor: const Color(0xFF60BB46),
                                  labelStyle: TextStyle(
                                    color: _paymentMethod == 'esewa'
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _paymentMethod = 'esewa';
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.divider),
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
                              '\$${shopState.subtotal.toStringAsFixed(2)}',
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
                              'Tax (5%)',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '\$${shopState.tax.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
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
                                  ? 'Processing...'
                                  : _paymentMethod == 'esewa'
                                  ? 'Pay with eSewa'
                                  : 'Place Order (COD)',
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

  final ShopItem item;
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
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
                  color: AppColors.surfaceMuted,
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
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${item.salePrice.toStringAsFixed(2)} each',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
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
