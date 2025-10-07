import 'package:flutter/material.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/models/payment_status_model.dart';

class OrderAcceptedScreen extends StatelessWidget {
  final OrderModel? order;
  final PaymentStatus? paymentStatus;
  final bool? isSubscription;

  const OrderAcceptedScreen({
    super.key,
    this.order,
    this.paymentStatus,
    this.isSubscription,
  });

  @override
  Widget build(BuildContext context) {
    // Determine which data source to use
    final orderNumber =
        order?.orderNumber ?? paymentStatus?.orderNumber ?? 'N/A';
    final totalAmount =
        order?.total ?? paymentStatus?.amount.toString() ?? 'N/A';

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
            SizedBox(height: 24),
            Text(
              'Order Placed Successfully!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Order Number: $orderNumber',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            if (paymentStatus?.transactionId != null &&
                paymentStatus!.transactionId.isNotEmpty)...[
              SizedBox(height: 8),
              Text(
                'Transaction id : ${paymentStatus?.transactionId} ',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
            SizedBox(height: 8),
            Text(
              'Total Amount: ₹$totalAmount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 32),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue Shopping',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
