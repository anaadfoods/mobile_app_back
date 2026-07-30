import 'package:grocery_app/features/products/data/datasources/products_remote_data_source.dart';
import 'package:grocery_app/features/products/domain/entities/category_entity.dart';
import 'package:grocery_app/features/products/domain/entities/product_entity.dart';
import 'package:grocery_app/features/products/domain/failures/product_failure.dart';
import 'package:grocery_app/features/products/domain/repositories/products_repository.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/product_image_model.dart';
import 'package:grocery_app/models/product_model.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsRemoteDataSource _remoteDataSource;

  const ProductsRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<CategoryEntity>> getCategories() async {
    try {
      final DTOs = await _remoteDataSource.fetchCategories();
      return DTOs.map((dto) => dto.toDomain()).toList();
    } catch (e) {
      throw ProductFailure(
        type: ProductFailureType.network,
        message: _getErrorMessage(e, 'Could not fetch product categories.'),
      );
    }
  }

  @override
  Future<List<ProductEntity>> getFeaturedProducts() async {
    try {
      final DTOs = await _remoteDataSource.fetchFeaturedProducts();
      final entities = DTOs.map((dto) => dto.toDomain()).toList();
      _sortProductsByActive(entities);
      return entities;
    } catch (e) {
      throw ProductFailure(
        type: ProductFailureType.network,
        message: _getErrorMessage(e, 'Could not fetch featured products.'),
      );
    }
  }

  @override
  Future<List<ProductEntity>> getBestsellerProducts() async {
    try {
      final DTOs = await _remoteDataSource.fetchBestsellerProducts();
      final entities = DTOs.map((dto) => dto.toDomain()).toList();
      _sortProductsByActive(entities);
      return entities;
    } catch (e) {
      throw ProductFailure(
        type: ProductFailureType.network,
        message: _getErrorMessage(e, 'Could not fetch bestseller products.'),
      );
    }
  }

  @override
  Future<List<ProductEntity>> getProductsByCategory(String categoryName) async {
    try {
      final DTOs = await _remoteDataSource.fetchProductsByCategory(categoryName);
      final entities = DTOs.map((dto) => dto.toDomain()).toList();
      _sortProductsByActive(entities);
      return entities;
    } catch (e) {
      throw ProductFailure(
        type: ProductFailureType.network,
        message: _getErrorMessage(e, 'Could not fetch products for "$categoryName".'),
      );
    }
  }

  @override
  Future<ProductEntity> getProductById(int id) async {
    try {
      final dto = await _remoteDataSource.fetchProductById(id);
      return dto.toDomain();
    } catch (e) {
      throw ProductFailure(
        type: ProductFailureType.notFound,
        message: _getErrorMessage(e, 'Could not fetch product details.'),
      );
    }
  }

  @override
  Future<List<ProductEntity>> searchProducts(String query) async {
    try {
      final DTOs = await _remoteDataSource.searchProducts(query);
      final entities = DTOs.map((dto) => dto.toDomain()).toList();
      _sortProductsByActive(entities);
      return entities;
    } catch (e) {
      throw ProductFailure(
        type: ProductFailureType.network,
        message: _getErrorMessage(e, 'Error searching products.'),
      );
    }
  }

  void _sortProductsByActive(List<ProductEntity> products) {
    products.sort((a, b) {
      if (a.isActive && !b.isActive) return -1;
      if (!a.isActive && b.isActive) return 1;
      return 0;
    });
  }

  String _getErrorMessage(dynamic e, String defaultMsg) {
    final s = e.toString().toLowerCase();
    
    if (s.contains('socketexception') ||
        s.contains('connection refused') ||
        s.contains('network is unreachable') ||
        s.contains('timed out') ||
        s.contains('timeout') ||
        s.contains('clientexception') ||
        s.contains('500') || 
        s.contains('502') || 
        s.contains('503') || 
        s.contains('server error') || 
        s.contains('internal') ||
        s.contains('dioexception')) {
      return "Sorry, we are not available right now. Please try again later.";
    }
    
    if (s.contains('404') || s.contains('not found')) {
      return "Couldn't find what you're looking for.";
    }
    
    final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(e.toString());
    if (match != null) {
      return match.group(1)!;
    }
    
    return "Sorry, we are not available right now. Please try again later.";
  }
}

extension CategoryMapper on Category {
  CategoryEntity toDomain() {
    return CategoryEntity(
      id: id,
      name: name,
      description: description,
      image: image,
      isActive: isActive,
      productsCount: productsCount,
    );
  }
}

extension ProductImageMapper on ProductImage {
  ProductImageEntity toDomain() {
    return ProductImageEntity(
      image: image,
      altText: altText,
    );
  }
}

extension ProductMapper on Product {
  ProductEntity toDomain() {
    return ProductEntity(
      id: id,
      sku: sku,
      weight: weight,
      weightUnit: weightUnit,
      price: price,
      discountPercentage: discountPercentage,
      finalPrice: finalPrice,
      isInStock: isInStock,
      isActive: isActive,
      productName: productName,
      productDescription: productDescription,
      productCategory: productCategory,
      productImages: productImages.map((img) => img.toDomain()).toList(),
      cropCycleId: cropCycleId,
    );
  }
}
