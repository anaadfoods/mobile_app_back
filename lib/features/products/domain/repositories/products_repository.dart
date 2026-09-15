import '../entities/category_entity.dart';
import '../entities/product_entity.dart';

abstract class ProductsRepository {
  Future<List<CategoryEntity>> getCategories();
  Future<List<ProductEntity>> getFeaturedProducts();
  Future<List<ProductEntity>> getBestsellerProducts();
  Future<List<ProductEntity>> getProductsByCategory(String categoryName);
  Future<ProductEntity> getProductById(int id);
  Future<List<ProductEntity>> searchProducts(String query);
}
