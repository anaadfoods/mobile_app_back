import '../entities/product_entity.dart';
import '../repositories/products_repository.dart';

class GetFeaturedProductsUseCase {
  final ProductsRepository _repository;

  const GetFeaturedProductsUseCase(this._repository);

  Future<List<ProductEntity>> call() {
    return _repository.getFeaturedProducts();
  }
}
