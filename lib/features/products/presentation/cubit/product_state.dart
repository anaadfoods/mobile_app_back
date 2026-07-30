import 'package:equatable/equatable.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
export '../../domain/entities/category_entity.dart';
export '../../domain/entities/product_entity.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductSuccess extends ProductState {
  final List<CategoryEntity> categories;
  final List<ProductEntity> featuredProducts;
  final List<ProductEntity> bestsellerProducts;
  final List<ProductEntity> productsForCategory;
  final ProductEntity? selectedProduct;

  const ProductSuccess({
    this.categories = const [],
    this.featuredProducts = const [],
    this.bestsellerProducts = const [],
    this.productsForCategory = const [],
    this.selectedProduct,
  });

  ProductSuccess copyWith({
    List<CategoryEntity>? categories,
    List<ProductEntity>? featuredProducts,
    List<ProductEntity>? bestsellerProducts,
    List<ProductEntity>? productsForCategory,
    ProductEntity? selectedProduct,
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
  List<Object?> get props => [
        categories,
        featuredProducts,
        bestsellerProducts,
        productsForCategory,
        selectedProduct,
      ];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}
