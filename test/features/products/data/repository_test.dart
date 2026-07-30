import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/products/data/datasources/products_remote_data_source.dart';
import 'package:grocery_app/features/products/data/repositories/products_repository_impl.dart';
import 'package:grocery_app/features/products/domain/failures/product_failure.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/product_model.dart';

class MockProductsRemoteDataSource extends Mock implements ProductsRemoteDataSource {}

void main() {
  late MockProductsRemoteDataSource mockRemoteDataSource;
  late ProductsRepositoryImpl repository;
  late Category testCategoryDto;
  late Product testProductDto;

  setUp(() {
    mockRemoteDataSource = MockProductsRemoteDataSource();
    repository = ProductsRepositoryImpl(mockRemoteDataSource);

    testCategoryDto = Category(
      id: 1,
      name: 'Veggies',
      description: 'Fresh Veggies',
      image: 'veg.png',
      isActive: true,
      productsCount: 12,
    );

    testProductDto = Product(
      id: 101,
      sku: 'SKU-VEG',
      weight: '250',
      weightUnit: 'g',
      price: 50.0,
      discountPercentage: 0.0,
      finalPrice: 50.0,
      isInStock: true,
      isActive: true,
      productName: 'Spinach',
      productDescription: 'Organic Spinach',
      productCategory: 'Veggies',
      productImages: const [],
    );
  });

  test('getCategories maps DTOs to entities correctly', () async {
    when(() => mockRemoteDataSource.fetchCategories()).thenAnswer((_) async => [testCategoryDto]);

    final result = await repository.getCategories();
    expect(result.length, 1);
    expect(result[0].name, 'Veggies');
    expect(result[0].productsCount, 12);
  });

  test('getFeaturedProducts maps DTOs to entities and sorts by active first', () async {
    final inactiveProduct = Product(
      id: 102,
      sku: 'SKU-VEG-2',
      weight: '250',
      weightUnit: 'g',
      price: 50.0,
      discountPercentage: 0.0,
      finalPrice: 50.0,
      isInStock: true,
      isActive: false, // Inactive product
      productName: 'Old Spinach',
      productDescription: 'Old Spinach',
      productCategory: 'Veggies',
      productImages: const [],
    );

    // Return inactive first from remote
    when(() => mockRemoteDataSource.fetchFeaturedProducts()).thenAnswer((_) async => [inactiveProduct, testProductDto]);

    final result = await repository.getFeaturedProducts();
    expect(result.length, 2);
    // Active one (testProductDto ID 101) must be sorted first
    expect(result[0].id, 101);
    expect(result[1].id, 102);
  });

  test('getProductById maps to entity or throws failure on exception', () async {
    when(() => mockRemoteDataSource.fetchProductById(101)).thenAnswer((_) async => testProductDto);

    final result = await repository.getProductById(101);
    expect(result.id, 101);
    expect(result.productName, 'Spinach');

    // Test error mapping
    when(() => mockRemoteDataSource.fetchProductById(999)).thenThrow(Exception('Not Found 404'));
    expect(
      () => repository.getProductById(999),
      throwsA(isA<ProductFailure>().having((f) => f.type, 'type', ProductFailureType.notFound)),
    );
  });
}
