import '../entities/product_entity.dart';
import '../repositories/products_repository.dart';

class GetProductByIdUseCase {
  final ProductsRepository _repository;

  const GetProductByIdUseCase(this._repository);

  Future<ProductEntity> call(int id) {
    return _repository.getProductById(id);
  }
}
