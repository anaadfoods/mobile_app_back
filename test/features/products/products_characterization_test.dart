import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/products/domain/failures/product_failure.dart';
import 'package:grocery_app/features/products/domain/repositories/products_repository.dart';
import 'package:grocery_app/features/products/domain/usecases/get_categories_use_case.dart';
import 'package:grocery_app/features/products/domain/usecases/get_featured_products_use_case.dart';
import 'package:grocery_app/features/products/domain/usecases/get_bestseller_products_use_case.dart';
import 'package:grocery_app/features/products/domain/usecases/get_products_by_category_use_case.dart';
import 'package:grocery_app/features/products/domain/usecases/get_product_by_id_use_case.dart';
import 'package:grocery_app/features/products/domain/usecases/search_products_use_case.dart';
import 'package:grocery_app/features/products/presentation/cubit/product_cubit.dart';
import 'package:grocery_app/features/products/presentation/cubit/product_state.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/product_model.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}

void main() {
  late MockProductsRepository mockRepository;
  late ProductCubit productCubit;
  late CategoryEntity testCategory;
  late ProductEntity testProduct;

  setUp(() {
    mockRepository = MockProductsRepository();
    testCategory = const CategoryEntity(
      id: 1,
      name: 'Organic Fruits',
      description: 'Fresh organic fruits',
      image: 'fruits.png',
      isActive: true,
      productsCount: 10,
    );
    testProduct = const ProductEntity(
      id: 101,
      sku: 'FRUIT-101',
      weight: '500',
      weightUnit: 'g',
      price: 150.0,
      discountPercentage: 10.0,
      finalPrice: 135.0,
      isInStock: true,
      isActive: true,
      productName: 'Organic Apples',
      productDescription: 'Sweet organic apples',
      productCategory: 'Organic Fruits',
      productImages: [],
    );

    registerFallbackValue('Organic Fruits');
    registerFallbackValue(101);
  });

  tearDown(() {
    productCubit.close();
  });

  ProductCubit createCubit() {
    return ProductCubit(
      getCategoriesUseCase: GetCategoriesUseCase(mockRepository),
      getFeaturedProductsUseCase: GetFeaturedProductsUseCase(mockRepository),
      getBestsellerProductsUseCase: GetBestsellerProductsUseCase(mockRepository),
      getProductsByCategoryUseCase: GetProductsByCategoryUseCase(mockRepository),
      getProductByIdUseCase: GetProductByIdUseCase(mockRepository),
      searchProductsUseCase: SearchProductsUseCase(mockRepository),
    );
  }

  test('loadHomePageData fetches categories, featured, and bestseller in parallel', () async {
    when(() => mockRepository.getCategories()).thenAnswer((_) async => [testCategory]);
    when(() => mockRepository.getFeaturedProducts()).thenAnswer((_) async => [testProduct]);
    when(() => mockRepository.getBestsellerProducts()).thenAnswer((_) async => [testProduct]);

    productCubit = createCubit();
    final states = <ProductState>[];
    final subscription = productCubit.stream.listen(states.add);

    await productCubit.loadHomePageData();
    await Future.delayed(Duration.zero);

    expect(states.length, 2);
    expect(states[0], isA<ProductLoading>());
    expect(states[1], isA<ProductSuccess>());
    
    final success = states[1] as ProductSuccess;
    expect(success.categories.length, 1);
    expect(success.featuredProducts.length, 1);
    expect(success.bestsellerProducts.length, 1);

    await subscription.cancel();
  });

  test('fetchProductsByCategory fetches category products and copies state values', () async {
    when(() => mockRepository.getCategories()).thenAnswer((_) async => [testCategory]);
    when(() => mockRepository.getFeaturedProducts()).thenAnswer((_) async => [testProduct]);
    when(() => mockRepository.getBestsellerProducts()).thenAnswer((_) async => [testProduct]);
    when(() => mockRepository.getProductsByCategory(any())).thenAnswer((_) async => [testProduct]);

    productCubit = createCubit();
    
    // Setup initial success state
    await productCubit.loadHomePageData();
    await Future.delayed(Duration.zero);

    final states = <ProductState>[];
    final subscription = productCubit.stream.listen(states.add);

    await productCubit.fetchProductsByCategory('Organic Fruits');
    await Future.delayed(Duration.zero);

    expect(states.length, 2);
    expect(states[0], isA<ProductLoading>());
    expect(states[1], isA<ProductSuccess>());

    final success = states[1] as ProductSuccess;
    expect(success.productsForCategory.length, 1);
    // Verify that featured/bestseller data was copied and preserved
    expect(success.categories.length, 1);
    expect(success.featuredProducts.length, 1);

    await subscription.cancel();
  });
}
