import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:grocery_app/features/cart/presentation/cubit/cart_state.dart';
import 'package:grocery_app/features/favorites/domain/usecases/get_favorites_use_case.dart';
import 'package:grocery_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:grocery_app/features/favorites/presentation/cubit/favorites_state.dart';
import 'package:grocery_app/features/favorites/presentation/widgets/favorite_item_card.dart';
import 'package:grocery_app/features/favorites/presentation/widgets/favorite_empty_state.dart';
import 'package:grocery_app/features/favorites/presentation/widgets/favorite_error_state.dart';
import 'package:grocery_app/features/products/domain/usecases/get_product_by_id_use_case.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/product_image_model.dart';
import 'package:grocery_app/routes/app_routes.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/common_widgets/animated_screen_header.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen>
    with TickerProviderStateMixin {
  final GetProductByIdUseCase _getProductByIdUseCase = getIt<GetProductByIdUseCase>();

  late AnimationController _headerController;
  late AnimationController _contentController;
  late AnimationController _pulseController;

  late Animation<double> _contentFade;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    context.read<FavoritesCubit>().loadFavorites();
  }

  void _initAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Product _createProductFromFavorite(FavoriteEntity favorite) {
    return Product(
      id: favorite.productId,
      sku: '',
      weight: favorite.weight,
      weightUnit: '',
      price: double.tryParse(favorite.price) ?? 0.0,
      discountPercentage: 0.0,
      finalPrice: double.tryParse(favorite.price) ?? 0.0,
      isInStock: true,
      isActive: true,
      productName: favorite.name,
      productDescription: '',
      productCategory: favorite.productCategory,
      productImages: [
        ProductImage(image: favorite.image, altText: favorite.name),
      ],
    );
  }

  void _handleQuantityChanged(FavoriteEntity favorite, int newQuantity) {
    HapticFeedback.selectionClick();
    final cubit = context.read<CartCubit>();
    final currentQty = _getQuantity(favorite.productId);

    if (newQuantity > 0 && currentQty == 0) {
      cubit.addItem(_createProductFromFavorite(favorite), newQuantity);
    } else if (newQuantity == 0) {
      cubit.removeItem(favorite.productId);
    } else {
      cubit.updateItem(favorite.productId, newQuantity);
    }
  }

  int _getQuantity(int productId) {
    final state = context.read<CartCubit>().state;
    if (state is CartSuccess) {
      final item = state.cart.items.firstWhereOrNull(
        (item) => item.productVariant.id == productId,
      );
      return item?.quantity ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is Authenticated) {
                context.read<FavoritesCubit>().loadFavorites();
              } else if (state is Unauthenticated) {
                context.read<FavoritesCubit>().clearFavoritesState();
              }
            },
          ),
          BlocListener<FavoritesCubit, FavoritesState>(
            listener: (context, state) {
              if (state is FavoritesError) {
                SnackBarHelper.showError(context, state.message);
              }
            },
          ),
        ],
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, cartState) {
            CartModel? cart;
            if (cartState is CartSuccess) {
              cart = cartState.cart;
            }

            return BlocBuilder<FavoritesCubit, FavoritesState>(
              builder: (context, favState) {
                if (favState is FavoritesSuccess) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) _contentController.forward();
                  });
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: AnimatedScreenHeader(
                        title: "My Favorites",
                        subtitle: favState is FavoritesSuccess
                            ? "${favState.favorites.length} saved items"
                            : "Your favorite picks",
                        showBack: false,
                        hasParticles: true,
                        animationController: _headerController,
                        actions: [
                          const Icon(
                            Icons.favorite_rounded,
                            color: AppColors.harvestAmber,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    if (favState is FavoritesLoading)
                      const SliverFillRemaining(
                        child: LoadingStateWidget(
                          itemHeight: 112,
                          borderRadius: 20,
                        ),
                      )
                    else if (favState is FavoritesError)
                      SliverFillRemaining(
                        child: _buildErrorState(theme, favState.message),
                      )
                    else if (favState is FavoritesSuccess &&
                        favState.favorites.isEmpty)
                      SliverFillRemaining(
                        child: _buildEmptyState(theme, isDark),
                      )
                    else if (favState is FavoritesSuccess)
                      SliverToBoxAdapter(
                        child: AnimatedBuilder(
                          animation: _contentController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - _contentFade.value)),
                              child: Opacity(
                                opacity: _contentFade.value,
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatsRow(theme, isDark, cart, favState.favorites.length),
                                const SizedBox(height: 20),
                                ...List.generate(favState.favorites.length, (index) {
                                  final favItem = favState.favorites[index];
                                  final qty = _getQuantity(favItem.productId);

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: Duration(
                                      milliseconds: 400 + (index * 80),
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 30 * (1 - value)),
                                        child: Opacity(opacity: value, child: child),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: FavoriteItemCard(
                                        favorite: favItem,
                                        quantity: qty,
                                        isDark: isDark,
                                        isProcessing: false,
                                        isBeingRemoved: false,
                                        onRemove: () {
                                          HapticFeedback.mediumImpact();
                                          context.read<FavoritesCubit>().toggleFavorite(favItem.productId);
                                        },
                                        onTap: () async {
                                          HapticFeedback.lightImpact();
                                          try {
                                            final productEntity = await _getProductByIdUseCase(favItem.productId);
                                            if (!mounted) return;
                                            context.pushNamed(
                                              AppRoute.productDetails.name,
                                              pathParameters: {'id': productEntity.id.toString()},
                                              extra: productEntity,
                                            );
                                          } catch (e) {
                                            if (!mounted) return;
                                            SnackBarHelper.showError(context, 'Could not view product details');
                                          }
                                        },
                                        onQuantityChanged: (newQty) {
                                          _handleQuantityChanged(favItem, newQty);
                                        },
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }



  Widget _buildStatsRow(ThemeData theme, bool isDark, CartModel? cart, int favoritesCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark_rounded, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '$favoritesCount Items Saved',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (cart != null && cart.totalItems > 0)
            Row(
              children: [
                Icon(Icons.shopping_bag_rounded, size: 18, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  '${cart.totalItems} Items in Cart',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String errorMessage) {
    return FavoriteErrorState(
      errorMessage: errorMessage,
      onRetry: () => context.read<FavoritesCubit>().loadFavorites(),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return FavoriteEmptyState(pulseAnimation: _pulseAnimation);
  }
}
