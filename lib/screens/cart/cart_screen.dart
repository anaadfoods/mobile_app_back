import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/screens/checkout/checkout_screen.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/screens/address/address_selection_screen.dart';
import 'package:grocery_app/services/cart_service.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/widgets/chart_item_widget.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  CartModel? _cart;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cart = await _cartService.getCart();
      if (!mounted) return;

      setState(() {
        _cart = cart;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double getTotalAmount() {
    if (_cart == null || _cart!.items.isEmpty) {
      return 0.0;
    }
    return _cart!.items.fold(
      0.0,
      (sum, item) =>
          sum + (item.productVariant.finalPrice * item.quantity),
    );
  }

  void _onQuantityChanged(int productVariantId, int newQuantity) async {
    final itemIndex = _cart!.items.indexWhere(
      (item) => item.productVariant.id == productVariantId,
    );
    if (itemIndex == -1) return;

    final item = _cart!.items[itemIndex];
    final oldQuantity = item.quantity;

    setState(() {
      _cart!.items[itemIndex] = item.copyWith(quantity: newQuantity);
    });

    try {
      await _cartService.updateCartItem(productVariantId, newQuantity);
    } catch (e) {
      if (mounted) {
        setState(() {
          _cart!.items[itemIndex] = item.copyWith(quantity: oldQuantity);
        });
        SnackBarHelper.showError(context, 'Failed to update item. Please try again.');
      }
    }
  }

  // --- 👇 NEW OPTIMISTIC REMOVE FUNCTION ---
  void _onRemoveItem(int productVariantId) async {
    final itemIndex =
        _cart!.items.indexWhere((i) => i.productVariant.id == productVariantId);
    if (itemIndex == -1) return;

    final removedItem = _cart!.items[itemIndex];

    setState(() {
      _cart!.items.removeAt(itemIndex);
    });

    try {
      await _cartService.removeFromCart(productVariantId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _cart!.items.insert(itemIndex, removedItem);
        });
        SnackBarHelper.showError(context, 'Failed to remove item. Please try again.');
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 86, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Cart is empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Looks like you haven\'t added anything to your cart yet.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Start Shopping', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Login to see or add to cart",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Login', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCart,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              itemCount: _cart!.items.length,
              itemBuilder: (context, index) {
                final item = _cart!.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        final product = await CategoryService.fetchProductById(
                            item.productVariant.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailsScreen(product: product),
                          ),
                        );
                      },
                      child: ChartItemWidget(
                        item: item,
                        onQuantityChanged: (quantity) {
                          _onQuantityChanged(
                            item.productVariant.id,
                            quantity,
                          );
                        },
                        // --- 👇 UPDATED ONREMOVE CALLBACK ---
                        onRemove: () {
                          _onRemoveItem(item.productVariant.id);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_cart != null && !_cart!.isEmpty) _buildCheckoutSection(),
      ],
    );
  }

  Widget _buildCheckoutSection() {
     return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Items:',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                Text(
                  '${_cart!.totalItems}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${getTotalAmount().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddressSelectionScreen(cart: _cart),
                    ),
                  );

                  if (result != null && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutScreen(
                          cart: result['cart'],
                          singleProduct: result['singleProduct'],
                          price: result['price'],
                          quantity: result['quantity'],
                          isSubscription: result['isSubscription'] ?? false,
                          selectedPlan: result['selectedPlan'],
                          shippingDetails: result['shippingDetails'],
                          deliveryCharges: result['deliveryCharges'] ?? 0.0,
                          expectedDeliveryDate: result['expectedDeliveryDate'] ?? '',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bottonBackgroundColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Cart', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: (_cart == null || _cart!.isEmpty) ? null : () async {
              setState(() => _isLoading = true);
              await _cartService.clearCart();
              await _loadCart();
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _cart == null || _cart!.isEmpty
                  ? _buildEmptyState()
                  : _buildCartList(),
    );
  }
}