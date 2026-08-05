import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
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

  /// Shows an embedded Stripe CardField inside a Flutter dialog so that
  /// keyboard focus is handled by Flutter — eliminating the native Android
  /// PaymentSheet focus bug where the card-number field won't accept input.
  Future<bool> _payWithStripe({
    required String orderId,
    required double totalAmount,
    required String name,
    required String email,
  }) async {
    final notifier = ref.read(shopViewModelProvider.notifier);

    // 1. Create a PaymentIntent on the backend.
    final intentData = await notifier.createStripePaymentIntent(
      amount: totalAmount,
      orderId: orderId,
    );
    final clientSecret = intentData['clientSecret']!;

    // 2. Show the embedded card dialog (Flutter-rendered, not native sheet).
    if (!mounted) return false;
    final paid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _StripeCardDialog(
        clientSecret: clientSecret,
        amount: totalAmount,
        name: name,
        email: email,
      ),
    );
    if (paid != true) return false;

    // 3. Verify with backend.
    final verified = await notifier.verifyStripePayment(orderId: orderId);
    return verified;
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

      if (_paymentMethod == 'stripe') {
        bool success = false;
        try {
          success = await _payWithStripe(
            orderId: orderId,
            totalAmount: totalAmount,
            name: name,
            email: email,
          );
        } on StripeException catch (e) {
          if (!mounted) return;
          // User cancelled — inform them the order is pending.
          notifier.setError(
            'Order $orderId was created and is awaiting Stripe payment. '
            'You can check its status from order history. '
            '(${e.error.localizedMessage ?? e.error.code.name})',
          );
          return;
        }
        if (!success) {
          if (!mounted) return;
          notifier.setError(
            'Order $orderId was created but payment could not be confirmed. '
            'You can check its status from order history.',
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
          _paymentMethod == 'stripe'
                ? 'Your payment was confirmed via Stripe and your order is being processed.'
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
                                  label: const Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.credit_card, size: 14),
                                        SizedBox(width: 4),
                                        Text('Stripe'),
                                      ],
                                    ),
                                  ),
                                  selected: _paymentMethod == 'stripe',
                                  selectedColor: const Color(0xFF635BFF),
                                  labelStyle: TextStyle(
                                    color: _paymentMethod == 'stripe'
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _paymentMethod = 'stripe';
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
                                  : _paymentMethod == 'stripe'
                                  ? 'Pay with Stripe'
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
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => Container(
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

/// Flutter-native card payment dialog using Stripe's [CardField] widget.
/// Because this runs entirely inside Flutter's widget tree, keyboard events
/// are dispatched by Flutter itself — avoiding the native Android
/// PaymentSheet bug where the card-number field silently ignores input.
class _StripeCardDialog extends StatefulWidget {
  const _StripeCardDialog({
    required this.clientSecret,
    required this.amount,
    required this.name,
    required this.email,
  });

  final String clientSecret;
  final double amount;
  final String name;
  final String email;

  @override
  State<_StripeCardDialog> createState() => _StripeCardDialogState();
}

class _StripeCardDialogState extends State<_StripeCardDialog> {
  CardFieldInputDetails? _cardDetails;
  bool _paying = false;
  String? _error;

  Future<void> _pay() async {
    if (_cardDetails == null || !(_cardDetails!.complete)) {
      setState(() => _error = 'Please enter complete card details.');
      return;
    }
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: widget.clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              name: widget.name,
              email: widget.email,
            ),
          ),
        ),
      );
      if (!mounted) return;
      if (result.status == PaymentIntentsStatus.Succeeded) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _paying = false;
          _error = 'Payment failed. Status: ${result.status.name}';
        });
      }
    } on StripeException catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = e.error.localizedMessage ?? e.error.code.name;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountDisplay =
        'NPR ${widget.amount.toStringAsFixed(2)}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.credit_card,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pay with Card',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        amountDisplay,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _paying ? null : () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Stripe CardField ────────────────────────────────────────
            const Text(
              'Card Details',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            CardField(
              autofocus: true,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              onCardChanged: (details) {
                setState(() => _cardDetails = details);
              },
            ),

            // ── Error message ───────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Pay button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _paying ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _paying
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        'Pay $amountDisplay',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '🔒 Secured by Stripe',
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

