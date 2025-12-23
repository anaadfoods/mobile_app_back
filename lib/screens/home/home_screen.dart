import "package:grocery_app/common_widgets/global_import.dart";
import "package:grocery_app/screens/RFP/contract_farming_screen.dart";
import "package:grocery_app/widgets/subscription_table.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _searchResults = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      try {
        List<Product> results = await CategoryService().searchProducts(query);
        setState(() => _searchResults = results);
      } catch (e) {
        debugPrint("Search error: $e");
      } finally {
        setState(() => _isSearching = false);
      }
    });
  }

  void _onProductClicked(BuildContext context, Product item) {
    _focusNode.unfocus();
    Navigator.push(
      context,
      AnimatedTransitions.fadeScale(ProductDetailsScreen(product: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    child: Image.asset(
                      "assets/images/OnBoarding/background_home.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, state) {
                              String name = "User";
                              if (state is Authenticated) {
                                name =
                                    state.user.firstName[0].toUpperCase() +
                                    state.user.firstName.substring(1);
                              }
                              return Text(
                                "Welcome $name 👋",
                                style: textTheme.displaySmall?.copyWith(
                                  fontSize: 18,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.notifications_outlined,
                              color: theme.colorScheme.onPrimary,
                            ),
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const NotificationsScreen(),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    _searchBar(context),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (_isSearching)
              const Center(child: CircularProgressIndicator())
            else if (_searchResults.isNotEmpty && _focusNode.hasFocus)
              _buildSearchDropdown(context)
            else ...[
              padded(const TopCurosel()),
              padded(const SubscriptionCarousel()),
              _heading(context, "Subscription Plans", "", () {}),
              _subscriptionSection(context),
              padded(_buildCategoryShowcase(context)),
              _buildFeaturedProducts(),
              const SizedBox(height: 4),
              _buildCommunities(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppColors.radiusRound),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(
                AppColors.shadowOpacityMedium,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: "Search products...",
            hintStyle: TextStyle(color: theme.hintColor),
            prefixIcon: Icon(Icons.search, color: colorScheme.primary),
            suffixIcon:
                _isSearching
                    ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                    : (_searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.close, color: theme.hintColor),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                        : null),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppColors.spacingL,
              vertical: AppColors.spacingM,
            ),
          ),
          onChanged: (value) => _performSearch(value.trim()),
        ),
      ),
    );
  }

  Widget _buildSearchDropdown(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
      ),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(12),
        color: theme.cardColor,
        child: ListView.separated(
          itemCount: _searchResults.length,
          shrinkWrap: true,
          separatorBuilder:
              (_, __) => Divider(height: 1, color: theme.dividerColor),
          itemBuilder: (context, index) {
            final product = _searchResults[index];
            return ListTile(
              title: Text(
                product.productName,
                style: theme.textTheme.bodyLarge,
              ),
              subtitle: Text(
                "₹${product.finalPrice.toString()}",
                style: theme.textTheme.bodyMedium,
              ),
              onTap: () => _onProductClicked(context, product),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return _buildFeaturedProductsSkeleton(context);
        }
        if (state is ProductError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Error: ${state.message}",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }
        if (state is ProductSuccess) {
          final featuredProducts = state.featuredProducts;
          if (featuredProducts.isEmpty) {
            return const Center(child: Text("No featured products found"));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heading(
                context,
                "Featured Products",
                "See All →",
                () => Navigator.push(
                  context,
                  AnimatedTransitions.slideFromRight(
                    CategoryItemsScreen(
                      name: "Featured Products",
                      allProducts: featuredProducts,
                    ),
                  ),
                ),
              ),
              ListView.builder(
                itemCount: featuredProducts.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final product = featuredProducts[index];
                  return Opacity(
                    opacity: product.isInStock ? 1.0 : 0.5,
                    child: GroceryItemCardWidget(
                      item: product,
                      heroSuffix: "home_screen",
                      onTap:
                          product.isInStock
                              ? () => _onProductClicked(context, product)
                              : null,
                    ),
                  );
                },
              ),
            ],
          );
        }
        return _buildFeaturedProductsSkeleton(context);
      },
    );
  }

  Widget _buildFeaturedProductsSkeleton(BuildContext context) {
    return ShimmerLoading(
      isLoading: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          padded(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Skeleton(width: 180, height: 24),
                Skeleton(width: 80, height: 24),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Skeleton(width: 80, height: 80),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Skeleton(width: double.infinity, height: 20),
                        SizedBox(height: 8),
                        Skeleton(width: 100, height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _subscriptionSection(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      height: (screenHeight * 0.50).clamp(350.0, 400.0),
      child: const SubscriptionTable(),
    );
  }

  Widget _heading(
    BuildContext context,
    String title,
    String? all,
    VoidCallback? onPressed,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppColors.spacingL,
        AppColors.spacingM,
        AppColors.spacingL,
        AppColors.spacingS,
      ),
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
                  horizontal: AppColors.spacingM,
                  vertical: AppColors.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppColors.radiusRound),
                ),
                child: Text(
                  all,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget padded(Widget widget) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppColors.spacingM),
    child: widget,
  );

  Widget _buildCategoryShowcase(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Rejuvenating Earth\nNourishing Lives",
            style: theme.textTheme.displayMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Our Categories you can shop from–",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _categoryCard(
                  context,
                  "Natural Farming",
                  "assets/images/natural_farming.png",
                  const CombinedScreen(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _categoryCard(
                  context,
                  "Naturally Grown Vegetables",
                  "assets/images/natural_veggies.png",
                  const ExploreScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(
    BuildContext context,
    String title,
    String imagePath,
    Widget screen,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            AnimatedTransitions.slideFromRight(screen),
          ),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunities() {
    return FutureBuilder<List<Community>>(
      future: CommunityService.fetchCommunities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(AppColors.spacingXL),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(AppColors.spacingL),
            child: Center(
              child: Text(
                "Error loading communities",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final communities = snapshot.data!;

        return Column(
          children: [
            // _heading(context, "Join Our Community", null, null),
            const SizedBox(height: AppColors.spacingS),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: communities.length,
              itemBuilder: (context, index) {
                final community = communities[index];
                return _buildCommunityCard(context, community, index);
              },
            ),
            const SizedBox(height: AppColors.spacingL),
          ],
        );
      },
    );
  }

  Widget _buildCommunityCard(
    BuildContext context,
    Community community,
    int index,
  ) {
    final theme = Theme.of(context);

    // Alternate between green and brown gradients for variety
    final isEvenCard = index % 2 == 0;
    final gradientColors =
        isEvenCard
            ? [
              const Color(0xFF2E7D32).withOpacity(0.85), // Forest green
              const Color(0xFF1B5E20).withOpacity(0.7),
            ]
            : [
              const Color(0xFF5D4037).withOpacity(0.9), // Brown
              const Color(0xFF3E2723).withOpacity(0.75),
            ];

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            AnimatedTransitions.fadeScale(
              CommunityDetailScreen(community: community),
            ),
          ),
      child: Container(
        height: 180,
        margin: const EdgeInsets.symmetric(
          vertical: AppColors.spacingS,
          horizontal: AppColors.spacingL,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppColors.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppColors.radiusXL),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Image.network(
                community.image,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color:
                          isEvenCard
                              ? Colors.green.shade800
                              : Colors.brown.shade800,
                      child: const Icon(
                        Icons.eco,
                        size: 60,
                        color: Colors.white24,
                      ),
                    ),
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(AppColors.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Coming Soon Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppColors.spacingXS,
                        horizontal: AppColors.spacingM,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusRound,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Coming Soon",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppColors.spacingXS),
                          const Icon(Icons.eco, size: 14, color: Colors.white),
                        ],
                      ),
                    ),

                    // Community Name
                    Text(
                      community.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Learn More Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppColors.spacingL,
                        vertical: AppColors.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(
                          AppColors.radiusRound,
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Learn More",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppColors.spacingXS),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
