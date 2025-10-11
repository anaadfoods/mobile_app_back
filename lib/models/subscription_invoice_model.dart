import 'dart:convert';

// Helper function to easily parse the full JSON string
ApiResponse apiResponseFromJson(String str) => ApiResponse.fromJson(json.decode(str));

/// Represents the main API response structure.
class ApiResponse {
    final bool success;
    final int subscriptionId;
    final List<Invoice> invoices;
    final int totalInvoices;

    ApiResponse({
        required this.success,
        required this.subscriptionId,
        required this.invoices,
        required this.totalInvoices,
    });

    /// Creates an ApiResponse instance from a JSON map.
    factory ApiResponse.fromJson(Map<String, dynamic> json) {
        // Cast the 'invoices' list from the JSON and map each item
        // to an Invoice object using the Invoice.fromJson factory.
        var invoiceList = json['invoices'] as List;
        List<Invoice> invoices = invoiceList.map((i) => Invoice.fromJson(i)).toList();

        return ApiResponse(
            success: json["success"],
            subscriptionId: json["subscription_id"],
            invoices: invoices,
            totalInvoices: json["total_invoices"],
        );
    }
}

/// Represents a single invoice object.
class Invoice {
    final int id;
    final String odooInvoiceNumber;
    final String s3Url;
    final String displayName;

    Invoice({
        required this.id,
        required this.odooInvoiceNumber,
        required this.s3Url,
        required this.displayName,
    });

    /// Creates an Invoice instance from a JSON map.
    factory Invoice.fromJson(Map<String, dynamic> json) {
        return Invoice(
            id: json["id"],
            odooInvoiceNumber: json["odoo_invoice_number"],
            s3Url: json["s3_url"],
            displayName: json["display_name"],
        );
    }
}