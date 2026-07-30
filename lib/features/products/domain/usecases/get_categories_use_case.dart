import '../entities/category_entity.dart';
import '../repositories/products_repository.dart';

class GetCategoriesUseCase {
  final ProductsRepository _repository;

  const GetCategoriesUseCase(this._repository);

  Future<List<CategoryEntity>> call() {
    return _repository.getCategories();
  }
}
