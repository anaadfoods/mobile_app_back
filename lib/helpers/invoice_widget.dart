import 'package:flutter/material.dart';
import 'package:grocery_app/models/subscription_invoice_model.dart';
import 'package:grocery_app/styles/colors.dart';
// Make sure to import your Invoice model

class InvoiceTrackerWidget extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<Invoice> invoices;
  final Function(Invoice) onInvoiceTap;

  const InvoiceTrackerWidget({
    super.key,
    required this.isLoading,
    this.error,
    required this.invoices,
    required this.onInvoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invoices',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          _buildContent(),
        ],
      ),
    );
  }

  /// Builds the content based on the current state (loading, error, empty, or data)
  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Text(
            'No invoices available yet. or may be error occured while fetching',
            style: const TextStyle(color:Colors.black),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (invoices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Text('No invoices available yet.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        final isLastItem = index == invoices.length - 1;
        return _buildInvoiceItem(invoice, isLastItem: isLastItem);
      },
    );
  }

  /// Builds a single row in the invoice tracker list
  Widget _buildInvoiceItem(Invoice invoice, {required bool isLastItem}) {
    return InkWell(
      onTap: () => onInvoiceTap(invoice),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // This column builds the icon and the vertical connecting line
            Column(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryColor, // Green color from image
                  child: Icon(Icons.receipt_long, color: Colors.white, size: 18),
                ),
                if (!isLastItem)
                  Container(
                    height: 60, // Adjust height between items
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // This column holds the title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invoice.odooInvoiceNumber,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Trailing download icon
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(Icons.download_for_offline, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}