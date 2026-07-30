import '../entities/product_entity.dart';
import '../repositories/products_repository.dart';

class GetProductsByCategoryUseCase {
  final ProductsRepository _repository;

  const GetProductsByCategoryUseCase(this._repository);

  Future<List<ProductEntity>> call(String categoryName) {
    return _repository.getProductsByCategory(categoryName);
  }
}
