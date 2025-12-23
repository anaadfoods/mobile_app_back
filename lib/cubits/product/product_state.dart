import 'package:equatable/equatable.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

// A single success state to hold all catalog data.
// This is scalable and prevents data loss on new fetches.
class ProductSuccess extends ProductState {
  final List<Category> categories;
  final List<Product> featuredProducts;
  final List<Product> bestsellerProducts;
  final List<Product> productsForCategory; // For when a user selects a category
  final Product? selectedProduct; // For the product detail view

  const ProductSuccess({
    this.categories = const [],
    this.featuredProducts = const [],
    this.bestsellerProducts = const [],
    this.productsForCategory = const [],
    this.selectedProduct,
  });

  // copyWith allows us to update parts of the state without boilerplate
  ProductSuccess copyWith({
    List<Category>? categories,
    List<Product>? featuredProducts,
    List<Product>? bestsellerProducts,
    List<Product>? productsForCategory,
    Product? selectedProduct,
  }) {
    return ProductSuccess(
      categories: categories ?? this.categories,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      bestsellerProducts: bestsellerProducts ?? this.bestsellerProducts,
      productsForCategory: productsForCategory ?? this.productsForCategory,
      selectedProduct: selectedProduct ?? this.selectedProduct,
    );
  }

  @override
  List<Object> get props => [
        categories,
        featuredProducts,
        bestsellerProducts,
        productsForCategory,
        selectedProduct ?? Object(), // Handle nullable object
      ];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object> get props => [message];
}