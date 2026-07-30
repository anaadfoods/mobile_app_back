import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/products/domain/entities/category_entity.dart';
import 'package:grocery_app/features/products/domain/entities/product_entity.dart';
import 'package:grocery_app/features/products/domain/repositories/products_repository.dart';
import 'package:grocery_app/features/products/domain/usecases/get_categories_use_case.dart';
import 'package:grocery_app/features/products/domain/usecases/get_featured_products_use_case.dart';
import 'package:grocery_app/features/products/domain/usecases/get_bestseller_products_use_case.dart';
import 'package:grocery_app/features/products/domain/usecases/get_products_by_category_use_case.dart';
import 'package:grocery_app/features/products/domain/usecases/get_product_by_id_use_case.dart';
import 'package:grocery_app/features/products/domain/usecases/search_products_use_case.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}

void main() {
  late MockProductsRepository mockRepository;
  late CategoryEntity testCategory;
  late ProductEntity testProduct;

  setUp(() {
    mockRepository = MockProductsRepository();
    testCategory = const CategoryEntity(
      id: 1,
      name: 'Organic Fruits',
      description: 'Description',
      image: 'image.png',
      isActive: true,
      productsCount: 5,
    );
    testProduct = const ProductEntity(
      id: 101,
      sku: 'SKU',
      weight: '1',
      weightUnit: 'kg',
      price: 100.0,
      discountPercentage: 0.0,
      finalPrice: 100.0,
      isInStock: true,
      isActive: true,
      productName: 'Product',
      productDescription: 'Desc',
      productCategory: 'Category',
      productImages: [],
    );
  });

  test('GetCategoriesUseCase calls getCategories on repository', () async {
    when(() => mockRepository.getCategories()).thenAnswer((_) async => [testCategory]);
    final useCase = GetCategoriesUseCase(mockRepository);

    final result = await useCase();
    expect(result, [testCategory]);
    verify(() => mockRepository.getCategories()).called(1);
  });

  test('GetFeaturedProductsUseCase calls getFeaturedProducts on repository', () async {
    when(() => mockRepository.getFeaturedProducts()).thenAnswer((_) async => [testProduct]);
    final useCase = GetFeaturedProductsUseCase(mockRepository);

    final result = await useCase();
    expect(result, [testProduct]);
    verify(() => mockRepository.getFeaturedProducts()).called(1);
  });

  test('GetBestsellerProductsUseCase calls getBestsellerProducts on repository', () async {
    when(() => mockRepository.getBestsellerProducts()).thenAnswer((_) async => [testProduct]);
    final useCase = GetBestsellerProductsUseCase(mockRepository);

    final result = await useCase();
    expect(result, [testProduct]);
    verify(() => mockRepository.getBestsellerProducts()).called(1);
  });

  test('GetProductsByCategoryUseCase calls getProductsByCategory on repository', () async {
    when(() => mockRepository.getProductsByCategory('Fruit')).thenAnswer((_) async => [testProduct]);
    final useCase = GetProductsByCategoryUseCase(mockRepository);

    final result = await useCase('Fruit');
    expect(result, [testProduct]);
    verify(() => mockRepository.getProductsByCategory('Fruit')).called(1);
  });

  test('GetProductByIdUseCase calls getProductById on repository', () async {
    when(() => mockRepository.getProductById(101)).thenAnswer((_) async => testProduct);
    final useCase = GetProductByIdUseCase(mockRepository);

    final result = await useCase(101);
    expect(result, testProduct);
    verify(() => mockRepository.getProductById(101)).called(1);
  });

  test('SearchProductsUseCase calls searchProducts on repository', () async {
    when(() => mockRepository.searchProducts('Apple')).thenAnswer((_) async => [testProduct]);
    final useCase = SearchProductsUseCase(mockRepository);

    final result = await useCase('Apple');
    expect(result, [testProduct]);
    verify(() => mockRepository.searchProducts('Apple')).called(1);
  });
}
