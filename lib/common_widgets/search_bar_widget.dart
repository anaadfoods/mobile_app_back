import 'package:grocery_app/core/theme/app_colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/theme.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:http/http.dart' as http;

class ProductSearchBar extends StatefulWidget {
  const ProductSearchBar({super.key});

  @override
  _ProductSearchBarState createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<ProductSearchBar> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  /// Call API
  Future<void> _searchProducts(String query) async {
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _errorMessage = "Please enter at least 3 characters.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/products/variants/search/?q=$query',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() => _searchResults = data);
      } else {
        setState(() => _errorMessage = "Failed to load results");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 🔍 Search Bar
        Container(
          height: 50,
          margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
          ),
          child: TextField(
            controller: _controller,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: "Search products...",
              prefixIcon: Icon(
                Icons.search,
                color:
                    theme.inputDecorationTheme.prefixIconColor ??
                    theme.iconTheme.color,
              ),
            ).applyDefaults(theme.inputDecorationTheme),
            onChanged: (query) {
              _searchProducts(query);
            },
            onSubmitted: (query) {
              _searchProducts(query);
            },
          ),
        ),

        // ⏳ Loading
        if (_isLoading)
          const Padding(
            padding: AppSpacing.paddingLg,
            child: CircularProgressIndicator(),
          ),

        // ⚠️ Error message
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              _errorMessage,
              style: TextStyle(color: AppColors.rawEarth, fontSize: 14),
            ),
          ),

        // 📦 Results List
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return ListTile(
                title: Text(product['product_name']),
                subtitle: Text("₹${product['final_price']}"),
                trailing: Text(
                  product['is_in_stock'] ? 'In stock' : 'Out of stock',
                  style: TextStyle(
                    color:
                        product['is_in_stock']
                            ? AppColors.deepSoilGreen
                            : AppColors.rawEarth,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
