import '../entities/product_entity.dart';
import '../repositories/products_repository.dart';

class GetBestsellerProductsUseCase {
  final ProductsRepository _repository;

  const GetBestsellerProductsUseCase(this._repository);

  Future<List<ProductEntity>> call() {
    return _repository.getBestsellerProducts();
  }
}
