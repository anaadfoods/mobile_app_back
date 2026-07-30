import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_categories_use_case.dart';
import '../../domain/usecases/get_featured_products_use_case.dart';
import '../../domain/usecases/get_bestseller_products_use_case.dart';
import '../../domain/usecases/get_products_by_category_use_case.dart';
import '../../domain/usecases/get_product_by_id_use_case.dart';
import '../../domain/usecases/search_products_use_case.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final GetCategoriesUseCase _getCategoriesUseCase;
  final GetFeaturedProductsUseCase _getFeaturedProductsUseCase;
  final GetBestsellerProductsUseCase _getBestsellerProductsUseCase;
  final GetProductsByCategoryUseCase _getProductsByCategoryUseCase;
  final GetProductByIdUseCase _getProductByIdUseCase;
  final SearchProductsUseCase _searchProductsUseCase;

  ProductCubit({
    required GetCategoriesUseCase getCategoriesUseCase,
    required GetFeaturedProductsUseCase getFeaturedProductsUseCase,
    required GetBestsellerProductsUseCase getBestsellerProductsUseCase,
    required GetProductsByCategoryUseCase getProductsByCategoryUseCase,
    required GetProductByIdUseCase getProductByIdUseCase,
    required SearchProductsUseCase searchProductsUseCase,
  })  : _getCategoriesUseCase = getCategoriesUseCase,
        _getFeaturedProductsUseCase = getFeaturedProductsUseCase,
        _getBestsellerProductsUseCase = getBestsellerProductsUseCase,
        _getProductsByCategoryUseCase = getProductsByCategoryUseCase,
        _getProductByIdUseCase = getProductByIdUseCase,
        _searchProductsUseCase = searchProductsUseCase,
        super(ProductInitial());

  Future<void> loadHomePageData() async {
    try {
      emit(ProductLoading());

      final results = await Future.wait([
        _getCategoriesUseCase(),
        _getFeaturedProductsUseCase(),
        _getBestsellerProductsUseCase(),
      ]);

      emit(
        ProductSuccess(
          categories: results[0] as List<CategoryEntity>,
          featuredProducts: results[1] as List<ProductEntity>,
          bestsellerProducts: results[2] as List<ProductEntity>,
        ),
      );
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> fetchProductsByCategory(String categoryName) async {
    final currentState = state;
    ProductSuccess? previousSuccessState;
    if (currentState is ProductSuccess) {
      previousSuccessState = currentState;
    }

    emit(ProductLoading());

    try {
      final products = await _getProductsByCategoryUseCase(categoryName);

      if (previousSuccessState != null) {
        emit(previousSuccessState.copyWith(productsForCategory: products));
      } else {
        emit(ProductSuccess(productsForCategory: products));
      }
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}
