import '../entities/product_entity.dart';
import '../repositories/products_repository.dart';

class SearchProductsUseCase {
  final ProductsRepository _repository;

  const SearchProductsUseCase(this._repository);

  Future<List<ProductEntity>> call(String query) {
    return _repository.searchProducts(query);
  }
}
