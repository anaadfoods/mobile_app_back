import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/product_image_model.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/screens/checkout/checkout_screen.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/services/order_service.dart';
import 'package:grocery_app/screens/help/help_screen.dart';
import 'package:order_tracker/order_tracker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  bool _isCancelling = false;
  late Order _currentOrder;

  List<TextDto> orderList = [
    TextDto("Your order has been placed", "Fri, 25th Mar '22 - 10:47pm"),
    TextDto("Seller ha processed your order", "Sun, 27th Mar '22 - 10:19am"),
    TextDto(
      "Your item has been picked up by courier partner.",
      "Tue, 29th Mar '22 - 5:00pm",
    ),
  ];

  List<TextDto> shippedList = [
    TextDto("Your order has been shipped", ""),
    TextDto("Your item has been received in the nearest hub to you.", null),
  ];

  List<TextDto> outOfDeliveryList = [];

  List<TextDto> deliveredList = [];

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    print('Order ID: ${_currentOrder.id}');
    print('Order Number: ${_currentOrder.orderNumber}');
    print('Products Count: ${_currentOrder.products.length}');
    _currentOrder.products.forEach((product) {
      print('Product: ${product.productName}');
      print('Product Details: ${product.productDetails?.productName}');
      print('Quantity: ${product.quantity}');
      print('Price: ${product.price}');
      print('Total: ${product.total}');
    });
  }

  void _copyOrderNumber() async {
    await Clipboard.setData(ClipboardData(text: _currentOrder.orderNumber));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order number copied to clipboard'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToHelp() {
    _copyOrderNumber();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => HelpScreen(orderNumber: _currentOrder.orderNumber),
      ),
    );
  }

  Future<void> _cancelOrder() async {
    try {
      setState(() {
        _isCancelling = true;
      });

      final success = await _orderService.cancelOrder(
        _currentOrder.orderNumber,
      );

      if (mounted) {
        if (success) {
          setState(() {
            _currentOrder = _currentOrder.copyWith(status: "CANCELLED");
            _isCancelling = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order cancelled successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Return updated order status to previous screen
          Navigator.pop(context, _currentOrder);
        } else {
          setState(() {
            _isCancelling = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel order'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildActionButton() {
    if (_currentOrder.status == "CANCELLED") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(Icons.help_outline),
          label: Text('Need Help?'),
          onPressed: _navigateToHelp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    } else if (_currentOrder.status == "DELIVERED") {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.shopping_cart),
                  label: Text('Buy Again'),
                  onPressed: _handleBuyAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.rate_review),
                  label: Text('Give Review'),
                  onPressed: _handleGiveReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.help_outline),
              label: Text('Need Help?'),
              onPressed: _navigateToHelp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );
    } else if (_currentOrder.canBeCancelled) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isCancelling ? null : _cancelOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          child:
              _isCancelling
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Cancel Order'),
        ),
      );
    }
    return SizedBox.shrink();
  }

  void _handleBuyAgain() async {
    try {
      final authService = AuthService();
      final token = await authService.getAccessToken();

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please login to proceed with purchase'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Login',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ),
        );
        return;
      }

      // Get the first product from the order
      final firstProduct = _currentOrder.products.firstWhere(
        (product) => product.productDetails != null,
        orElse:
            () => OrderProduct(
              id: 0,
              productName: '',
              quantity: 0,
              price: '0',
              image: null,
              productDetails: null,
            ),
      );

      if (firstProduct.productDetails != null) {
        // Convert ProductDetails to Product
        final productToBuy = Product(
          id: firstProduct.productDetails!.id,
          sku: firstProduct.productDetails!.sku,
          weight: firstProduct.productDetails!.weight,
          weightUnit: firstProduct.productDetails!.weightUnit,
          price: double.parse(firstProduct.productDetails!.price),
          discountPercentage: double.parse(
            firstProduct.productDetails!.discountPercentage,
          ),
          finalPrice: double.parse(firstProduct.productDetails!.finalPrice),
          isInStock: firstProduct.productDetails!.isInStock,
          isActive: firstProduct.productDetails!.isActive,
          productName: firstProduct.productDetails!.productName,
          productDescription: firstProduct.productDetails!.productDescription,
          productCategory: firstProduct.productDetails!.productCategory,
          productImages: firstProduct.productDetails!.productImages,
        );

        // Convert to ProductVariant for checkout
        final productVariant = productToBuy.toProductVariant();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CheckoutScreen(
                  singleProduct: productVariant,
                  quantity: firstProduct.quantity,
                  deliveryCharges:
                      0.0, // Default delivery charges for buy again
                ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No products available to purchase'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Buy again error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to proceed with purchase'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleGiveReview() {
    // TODO: Implement review functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Review functionality coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${_currentOrder.orderNumber}"),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            tooltip: 'Download Invoice',
            onPressed: () async {
              // Download a random file as a placeholder
              final url =
                  'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
              final response = await http.get(Uri.parse(url));
              final dir = await getTemporaryDirectory();
              final file = File(
                '${dir.path}/invoice_${_currentOrder.orderNumber}.pdf',
              );
              await file.writeAsBytes(response.bodyBytes);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invoice downloaded to ${file.path}')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderInfoCard(),
              SizedBox(height: 12),
              _buildProductsCard(),
              if (_currentOrder.shippingDetails != null) ...[
                SizedBox(height: 12),
                _buildShippingDetailsCard(),
              ],
              SizedBox(height: 16),
              _buildActionButton(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: Icon(Icons.message),
        onPressed: () async {
          final user = await AuthService().currentUser;
          final phone = '91XXXXXXXXXX'; // Replace with your WhatsApp number
          final message = Uri.encodeComponent(
            'Order Support Request\n' +
                'User: ${user?.firstName ?? ''} ${user?.lastName ?? ''}\n' +
                'Phone: ${user?.phoneNumber ?? ''}\n' +
                'Order Number: ${_currentOrder.orderNumber}\n' +
                'Order Status: ${_currentOrder.status}\n' +
                'Total: ${_currentOrder.total}',
          );
          final url = 'https://wa.me/$phone?text=$message';
          if (await canLaunch(url)) {
            await launch(url);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Could not open WhatsApp')));
          }
        },
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(3),
              child: OrderTracker(
                status: Status.shipped,
                activeColor: Colors.green,
                inActiveColor: Colors.grey[300],
                orderTitleAndDateList: orderList,
                shippedTitleAndDateList: shippedList,
                  outOfDeliveryTitleAndDateList: outOfDeliveryList,
                // deliveredTitleAndDateList: ,
              ),
            ),

            Text(
              "Order Information",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 12),
            _buildDetailRow("Order Number", _currentOrder.orderNumber),
            SizedBox(height: 6),
            _buildDetailRow(
              "Date",
              _currentOrder.createdAt.toLocal().toString().split(" ")[0],
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Status",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      _currentOrder.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentOrder.status,
                    style: TextStyle(
                      color: _getStatusColor(_currentOrder.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Payment Status",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(
                      _currentOrder.paymentStatus,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentOrder.paymentStatus,
                    style: TextStyle(
                      color: _getPaymentStatusColor(
                        _currentOrder.paymentStatus,
                      ),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Expected Delivery Date",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(
                      _currentOrder.paymentStatus,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_currentOrder.expectedDeliveryDate ?? ''),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  "Products",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ..._currentOrder.products
                .map(
                  (product) => GestureDetector(
                    onTap: () {
                      if (product.productDetails != null) {
                        // Convert ProductDetails to Product
                        final productToShow = Product(
                          id: product.productDetails!.id,
                          productName: product.productDetails!.productName,
                          productCategory:
                              product.productDetails!.productCategory ?? '',
                          price: double.parse(product.price),
                          finalPrice: double.parse(product.price),
                          sku: product.productDetails!.sku ?? '',
                          discountPercentage: 0,
                          isInStock: true,
                          isActive: true,
                          productDescription: '',
                          weight: product.productDetails!.weight,
                          weightUnit: product.productDetails!.weightUnit,
                          productImages:
                              product.image != null
                                  ? [
                                    ProductImage(
                                      image: product.image!,
                                      altText:
                                          product.productDetails!.productName,
                                    ),
                                  ]
                                  : [],
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ProductDetailsScreen(
                                  product: productToShow,
                                ),
                          ),
                        );
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[100],
                                ),
                                child:
                                    product.image != null
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            product.image!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Icon(
                                                Icons.image,
                                                color: Colors.grey[400],
                                              );
                                            },
                                          ),
                                        )
                                        : Icon(
                                          Icons.image,
                                          color: Colors.grey[400],
                                        ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.productDetails?.productName ?? "",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2),
                                    if (product.productDetails != null) ...[
                                      Text(
                                        '${product.productDetails!.weight} ${product.productDetails!.weightUnit}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                    ],
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Qty: ${product.quantity}',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        if (product.discount != null &&
                                            product.discount != "0.00") ...[
                                          SizedBox(width: 6),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green[50],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Save ₹${product.discount}',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${product.price}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  if (product.total != null) ...[
                                    SizedBox(height: 2),
                                    Text(
                                      'Total: ₹${product.total}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (product != _currentOrder.products.last)
                          Divider(height: 16),
                      ],
                    ),
                  ),
                )
                .toList(),
            Divider(height: 24),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildPriceRow(
                    "Subtotal",
                    "₹${_calculateSubtotal()}",
                    isBold: false,
                  ),
                  SizedBox(height: 8),
                  _buildPriceRow(
                    "Anaad Discount",
                    "- ₹${_calculateDiscount()}",
                    isBold: false,
                    isDiscount: true,
                  ),
                  SizedBox(height: 8),
                  _buildPriceRow(
                    "GST (5%)",
                    "₹${_calculateGST()}",
                    isBold: false,
                  ),
                  SizedBox(height: 8),
                  _buildPriceRow(
                    "Delivery Charges",
                    "₹${_currentOrder.deliveryCharges ?? '0.00'}",
                    isBold: false,
                  ),
                  Divider(height: 16),
                  _buildPriceRow(
                    "Total Amount",
                    "₹${_currentOrder.total}",
                    isBold: true,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingDetailsCard() {
    final details = _currentOrder.shippingDetails!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Shipping Details",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 12),
            _buildDetailRow("Address", details.address),
            SizedBox(height: 6),
            _buildDetailRow("City", details.city),
            SizedBox(height: 6),
            _buildDetailRow("State", details.state),
            SizedBox(height: 6),
            _buildDetailRow("PIN Code", details.pincode),
            SizedBox(height: 6),
            _buildDetailRow("Phone", details.phone),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "DELIVERED":
        return Colors.green;
      case "PLACED":
        return Colors.orange;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case "PAID":
        return Colors.green;
      case "PENDING":
        return Colors.orange;
      case "FAILED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _calculateSubtotal() {
    double subtotal = 0;
    for (var product in _currentOrder.products) {
      subtotal += double.parse(product.price) * product.quantity;
    }
    return subtotal.toStringAsFixed(2);
  }

  String _calculateDiscount() {
    double subtotal = double.parse(_calculateSubtotal());
    double total = double.parse(_currentOrder.total);
    double discount = subtotal - total;
    return discount.toStringAsFixed(2);
  }

  String _calculateGST() {
    double subtotal = double.parse(_calculateSubtotal());
    double gst = subtotal * 0.05; // 5% GST
    return gst.toStringAsFixed(2);
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color:
                isDiscount
                    ? Colors.green[700]
                    : isTotal
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
