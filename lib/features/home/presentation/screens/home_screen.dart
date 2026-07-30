import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/common_widgets/subscription_table.dart';
import 'package:grocery_app/common_widgets/subscription_card.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:grocery_app/features/products/presentation/cubit/product_cubit.dart';
import 'package:grocery_app/features/products/presentation/cubit/product_state.dart';
import 'package:grocery_app/features/home/domain/entities/community_entity.dart';
import 'package:grocery_app/models/product_model.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/top_curosel.dart';
import '../widgets/home_search_dropdown.dart';
import '../widgets/home_communities_section.dart';
import '../widgets/home_community_card.dart';
import '../widgets/all_products_list.dart';
import '../widgets/home_header_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ValueNotifier<List<Product>> _searchResultsNotifier =
      ValueNotifier<List<Product>>([]);
  final ValueNotifier<bool> _isSearchingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isSearchActiveNotifier =
      ValueNotifier<bool>(false);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  final ValueNotifier<Color?> _bgColorNotifier = ValueNotifier<Color?>(null);

  late AnimationController _headerController;
  late AnimationController _contentController;
  late Animation<double> _headerFade;
  late Animation<double> _headerScale;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    context.read<HomeCubit>().loadHomeData();
    context.read<ProductCubit>().loadHomePageData();
  }

  void _initAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _headerScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });

    _focusNode.addListener(_updateSearchActive);
    _isSearchingNotifier.addListener(_updateSearchActive);
    _searchResultsNotifier.addListener(_updateSearchActive);
  }

  void _updateSearchActive() {
    _isSearchActiveNotifier.value = _isSearchingNotifier.value ||
        (_searchResultsNotifier.value.isNotEmpty && _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_updateSearchActive);
    _isSearchingNotifier.removeListener(_updateSearchActive);
    _searchResultsNotifier.removeListener(_updateSearchActive);
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _headerController.dispose();
    _contentController.dispose();
    _bgColorNotifier.dispose();
    _searchResultsNotifier.dispose();
    _isSearchingNotifier.dispose();
    _isSearchActiveNotifier.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      _searchResultsNotifier.value = [];
      _isSearchingNotifier.value = false;
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _isSearchingNotifier.value = true;
      final productState = context.read<ProductCubit>().state;
      if (productState is ProductSuccess) {
        final queryLower = query.toLowerCase();
        final results = productState.featuredProducts
            .map((e) => Product.fromEntity(e))
            .where((p) =>
                p.productName.toLowerCase().contains(queryLower) ||
                p.productCategory.toLowerCase().contains(queryLower))
            .toList();
        _searchResultsNotifier.value = results;
      } else {
        _searchResultsNotifier.value = [];
      }
      _isSearchingNotifier.value = false;
    });
  }

  Widget _heading(
    BuildContext context,
    String title,
    String? all,
    VoidCallback? onPressed,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (all != null && onPressed != null)
            GestureDetector(
              onTap: onPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.harvestAmber
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  all,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isDark ? Colors.green : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _subscriptionSection(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: SubscriptionTable(),
    );
  }

  Widget padded(Widget widget) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: widget,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<HomeCubit>().loadHomeData();
            context.read<ProductCubit>().loadHomePageData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _headerFade,
                  child: ScaleTransition(
                    scale: _headerScale,
                    child: ValueListenableBuilder<Color?>(
                      valueListenable: _bgColorNotifier,
                      builder: (context, dynamicColor, _) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: _isSearchingNotifier,
                          builder: (context, isSearching, _) {
                            return HomeHeaderWidget(
                              dynamicColor: dynamicColor,
                              searchController: _searchController,
                              focusNode: _focusNode,
                              onSearchChanged: _performSearch,
                              onSearchClear: () {
                                _searchController.clear();
                                _searchResultsNotifier.value = [];
                              },
                              isSearching: isSearching,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _contentFade,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isSearchActiveNotifier,
                    builder: (context, isSearchActive, child) {
                      if (isSearchActive) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: _isSearchingNotifier,
                          builder: (context, isSearching, child) {
                            if (isSearching) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.0),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              );
                            }
                            return ValueListenableBuilder<List<Product>>(
                              valueListenable: _searchResultsNotifier,
                              builder: (context, searchResults, child) {
                                return HomeSearchDropdown(
                                  searchResults: searchResults,
                                  onProductTap: (product) {
                                    _focusNode.unfocus();
                                    context.push('/product/${product.id}');
                                  },
                                );
                              },
                            );
                          },
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          padded(
                            TopCurosel(
                              onColorChanged: (color) {
                                _bgColorNotifier.value = color;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          const AllProductsList(),
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, authState) {
                              if (authState is! Authenticated) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  padded(
                                    const SubscriptionCarousel(),
                                  ),
                                ],
                              );
                            },
                          ),
                          _heading(
                            context,
                            "Subscription Plans",
                            "",
                            () {},
                          ),
                          _subscriptionSection(context),
                          const SizedBox(height: 4),
                          BlocBuilder<HomeCubit, HomeState>(
                            builder: (context, homeState) {
                              final communities = (homeState is HomeSuccess)
                                  ? homeState.communities
                                  : <CommunityEntity>[];
                              return HomeCommunitiesSection(
                                communities: communities,
                                buildCard: (context, community, index) =>
                                    AnimatedCommunityCard(
                                  community: community,
                                  index: index,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 80),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
