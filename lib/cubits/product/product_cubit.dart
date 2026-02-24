import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/repositories/product_repository.dart';
import 'package:grocery_app/cubits/product/product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _productRepository;

  ProductCubit({required ProductRepository productRepository})
    : _productRepository = productRepository,
      super(ProductInitial());

  /// Fetches all essential data for the home screen in parallel.
  Future<void> loadHomePageData() async {
    try {
      emit(ProductLoading());

      // Fetch all required data concurrently for faster loading
      final results = await Future.wait([
        _productRepository.fetchCategories(),
        _productRepository.fetchFeaturedProducts(),
        _productRepository.fetchBestsellerProducts(),
      ]);

      // Sort all fetched lists so isActive = true comes first
      void sortProductsByActive(List<Product> list) {
        list.sort((a, b) {
          if (a.isActive && !b.isActive) return -1;
          if (!a.isActive && b.isActive) return 1;
          return 0; // maintain original order otherwise if both are active or both inactive
        });
      }

      final featured = results[1] as List<Product>;
      final bestseller = results[2] as List<Product>;
      sortProductsByActive(featured);
      sortProductsByActive(bestseller);

      // The results list will contain the outcomes in the order they were called.
      emit(
        ProductSuccess(
          categories: results[0] as List<Category>,
          featuredProducts: featured,
          bestsellerProducts: bestseller,
        ),
      );
    } on ProductException catch (e) {
      emit(ProductError(e.message));
    } catch (e) {
      emit(const ProductError('An unexpected error occurred.'));
    }
  }

  /// Fetches products for a specific category.
  Future<void> fetchProductsByCategory(String categoryName) async {
    // Preserve the existing state data while loading new category-specific products
    final currentState = state;
    ProductSuccess? previousSuccessState;
    if (currentState is ProductSuccess) {
      previousSuccessState = currentState;
    }

    emit(ProductLoading()); // Or a more specific loading state if needed

    try {
      final products = await _productRepository.fetchProductsByCategory(
        categoryName,
      );

      // Sort the list so isActive = true comes first
      products.sort((a, b) {
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        return 0;
      });

      // If we had a previous success state, use copyWith to update it.
      // Otherwise, create a new success state.
      if (previousSuccessState != null) {
        emit(previousSuccessState.copyWith(productsForCategory: products));
      } else {
        emit(ProductSuccess(productsForCategory: products));
      }
    } on ProductException catch (e) {
      emit(ProductError(e.message));
    }
  }
}
