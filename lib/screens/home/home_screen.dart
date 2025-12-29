import "dart:math" as math;
import "dart:ui";

import "package:grocery_app/common_widgets/global_import.dart";
import "package:grocery_app/screens/RFP/contract_farming_screen.dart";
import "package:grocery_app/screens/featured_products_screen.dart";
import "package:grocery_app/widgets/subscription_table.dart";
import "package:grocery_app/helpers/color_extractor.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Product> _searchResults = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  // Dynamic color from carousel images
  Color? _dynamicBgColor;

  // Animation controllers for soothing entrance effects
  late AnimationController _headerController;
  late AnimationController _contentController;
  late Animation<double> _headerFade;
  late Animation<double> _headerScale;
  late Animation<double> _contentFade;

  // Cached future for communities to prevent re-fetching on rebuild
  late Future<List<Community>> _communitiesFuture;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // Cache the communities future so it doesn't re-fetch on every rebuild
    _communitiesFuture = CommunityService.fetchCommunities();
  }

  void _initAnimations() {
    // Header entrance animation - gentle scale and fade
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

    // Content stagger animation
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    // Start animations with slight delay for smoothness
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _headerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

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
            // Animated Header Section
            AnimatedBuilder(
              animation: _headerController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _headerScale.value,
                  child: Opacity(
                    opacity: _headerFade.value,
                    child: child,
                  ),
                );
              },
              child: Stack(
                children: [
                  // Dynamic color header background with blur effect
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    height: MediaQuery.of(context).size.height * 0.15,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Base image
                          Image.asset(
                            "assets/images/OnBoarding/background_home.png",
                            fit: BoxFit.cover,
                          ),
                          // Dynamic color overlay with blur
                          if (_dynamicBgColor != null)
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      _dynamicBgColor!.withOpacity(0.7),
                                      _dynamicBgColor!.withOpacity(0.5),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: screenWidth * 0.05,
                          right: screenWidth * 0.05,
                          top: MediaQuery.of(context).padding.top + 12,
                          bottom: 12,
                        ),
                        child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Modern Welcome Section with Avatar
                          Expanded(
                            child: BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, state) {
                                String name = "User";
                                String? profilePicture;
                                if (state is Authenticated) {
                                  name =
                                      state.user.firstName[0].toUpperCase() +
                                      state.user.firstName.substring(1);
                                  profilePicture = state.user.profilePicture;
                                }
                                
                                // Time-based greeting
                                final hour = DateTime.now().hour;
                                String greeting;
                                IconData greetingIcon;
                                Color iconColor;
                                
                                if (hour < 12) {
                                  greeting = "Good Morning";
                                  greetingIcon = Icons.wb_sunny_rounded;
                                  iconColor = Colors.amber;
                                } else if (hour < 17) {
                                  greeting = "Good Afternoon";
                                  greetingIcon = Icons.wb_sunny_outlined;
                                  iconColor = Colors.orange;
                                } else {
                                  greeting = "Good Evening";
                                  greetingIcon = Icons.nightlight_round;
                                  iconColor = Colors.indigo.shade300;
                                }
                                
                                return Row(
                                  children: [
                                    // Animated Avatar with glow
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.colorScheme.primary,
                                            theme.colorScheme.secondary,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.primary.withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: theme.cardColor,
                                        backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                                            ? NetworkImage(profilePicture)
                                            : null,
                                        child: profilePicture == null || profilePicture.isEmpty
                                            ? Text(
                                                name[0].toUpperCase(),
                                                style: textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.primary,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Greeting Text Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Time-based greeting with icon
                                          Row(
                                            children: [
                                              TweenAnimationBuilder<double>(
                                                tween: Tween(begin: 0.0, end: 1.0),
                                                duration: const Duration(milliseconds: 800),
                                                builder: (context, value, child) {
                                                  return Transform.rotate(
                                                    angle: value * 0.1,
                                                    child: Opacity(
                                                      opacity: value,
                                                      child: Icon(
                                                        greetingIcon,
                                                        size: 16,
                                                        color: iconColor,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                greeting,
                                                style: textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          // Name with wave animation
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  name,
                                                  style: textTheme.titleMedium?.copyWith(
                                                    color: theme.colorScheme.onPrimary,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.2,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // Animated waving hand
                                              TweenAnimationBuilder<double>(
                                                tween: Tween(begin: 0.0, end: 1.0),
                                                duration: const Duration(milliseconds: 1500),
                                                builder: (context, value, child) {
                                                  final wave = math.sin(value * 2 * math.pi);
                                                  return Transform.rotate(
                                                    angle: 0.2 * (1 + wave * 0.3),
                                                    child: Transform.translate(
                                                      offset: Offset(0, -2.0 * wave.abs()),
                                                      child: const Text(
                                                        "👋",
                                                        style: TextStyle(fontSize: 18),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          // Modern Animated Notification Bell
                          _buildModernNotificationBell(context, theme),
                        ],
                      ),
                    ),
                    _searchBar(context),
                  ],
                ),
              ],
            ),
            ),

            const SizedBox(height: 10),

            // Animated Content Section
            AnimatedBuilder(
              animation: _contentController,
              builder: (context, child) {
                return Opacity(
                  opacity: _contentFade.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _contentFade.value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isSearching)
                    const Center(child: CircularProgressIndicator())
                  else if (_searchResults.isNotEmpty && _focusNode.hasFocus)
                    _buildSearchDropdown(context)
                  else ...[
                    padded(TopCurosel(
                      onColorChanged: (color) {
                        setState(() {
                          _dynamicBgColor = color;
                        });
                      },
                    )),
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
          ],
        ),
      ),
    );
  }

  Widget _buildModernNotificationBell(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
        );
      },
      child: NotificationBadgeWidget(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.onPrimary.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2 * value),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: math.sin(value * math.pi * 2) * 0.1,
                child: Icon(
                  Icons.notifications_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 24,
                ),
              ),
            );
          },
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppColors.radiusRound),
          border: Border.all(
            color: _focusNode.hasFocus 
                ? colorScheme.primary.withOpacity(0.5)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
            width: _focusNode.hasFocus ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _focusNode.hasFocus
                  ? colorScheme.primary.withOpacity(0.15)
                  : theme.shadowColor.withOpacity(AppColors.shadowOpacityMedium),
              blurRadius: _focusNode.hasFocus ? 16 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: theme.textTheme.bodyLarge,
          onTap: () => setState(() {}), // Trigger rebuild for focus animation
          decoration: InputDecoration(
            hintText: "Search products...",
            hintStyle: TextStyle(color: theme.hintColor),
            prefixIcon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.search, 
                color: _focusNode.hasFocus 
                    ? colorScheme.primary 
                    : colorScheme.primary.withOpacity(0.7),
              ),
            ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            return const SizedBox.shrink();
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
                    FeaturedProductsScreen(products: featuredProducts),
                  ),
                ),
              ),
              // Horizontal scrolling featured products
              SizedBox(
                height: 260,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: featuredProducts.length.clamp(0, 6),
                  itemBuilder: (context, index) {
                    final product = featuredProducts[index];
                    return _buildFeaturedProductCard(product, index, isDark);
                  },
                ),
              ),
            ],
          );
        }
        return _buildFeaturedProductsSkeleton(context);
      },
    );
  }

  Widget _buildFeaturedProductCard(Product product, int index, bool isDark) {
    final theme = Theme.of(context);
    final hasDiscount = product.discountPercentage > 0;

    // Dummy food gradients
    final gradients = [
      [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
      [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
      [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
      [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
      [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)],
      [const Color(0xFFFFFDE7), const Color(0xFFFFF9C4)],
    ];
    final icons = [
      Icons.bakery_dining_rounded,
      Icons.rice_bowl_rounded,
      Icons.local_pizza_rounded,
      Icons.icecream_rounded,
      Icons.egg_alt_rounded,
      Icons.breakfast_dining_rounded,
    ];
    final iconColors = [
      const Color(0xFFE65100),
      const Color(0xFF2E7D32),
      const Color(0xFFD32F2F),
      const Color(0xFF7B1FA2),
      const Color(0xFFF9A825),
      const Color(0xFF795548),
    ];

    return GestureDetector(
      onTap: product.isInStock ? () => _onProductClicked(context, product) : null,
      child: Opacity(
        opacity: product.isInStock ? 1.0 : 0.5,
        child: Container(
          width: 165,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradients[index % gradients.length],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: product.productImages.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: product.productImages[0].image,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Center(
                                  child: Icon(
                                    icons[index % icons.length],
                                    size: 48,
                                    color: iconColors[index % iconColors.length].withOpacity(0.6),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Center(
                                  child: Icon(
                                    icons[index % icons.length],
                                    size: 48,
                                    color: iconColors[index % iconColors.length].withOpacity(0.6),
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  icons[index % icons.length],
                                  size: 48,
                                  color: iconColors[index % iconColors.length].withOpacity(0.6),
                                ),
                              ),
                      ),
                    ),
                    // Discount badge
                    if (hasDiscount)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${product.discountPercentage.toInt()}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Details section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.weight} ${product.weightUnit}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            '₹${product.finalPrice.toStringAsFixed(0)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 4),
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: theme.hintColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedProductsSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        padded(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerLoading(
                isLoading: true,
                child: Skeleton(width: 160, height: 22),
              ),
              ShimmerLoading(
                isLoading: true,
                child: Skeleton(width: 70, height: 22),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) {
              return ShimmerLoading(
                isLoading: true,
                child: Container(
                  width: 165,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Skeleton(width: double.infinity, height: 16),
                              const SizedBox(height: 8),
                              Skeleton(width: 60, height: 12),
                              const Spacer(),
                              Skeleton(width: 80, height: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _subscriptionSection(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      height: (screenHeight * 0.58).clamp(400.0, 500.0),
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
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.85),
            isDark 
                ? theme.colorScheme.primary.withOpacity(0.7)
                : Colors.green.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Background Elements
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 30,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 80,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.25),
              ),
            ),
          ),
          
          // Main Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Rejuvenating Earth",
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            "Nourishing Lives",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Shop by Category",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                        Icons.grass_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _categoryCard(
                        context,
                        "Fresh Vegetables",
                        "assets/images/natural_veggies.png",
                        const ExploreScreen(),
                        Icons.spa_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return _TappableCard(
      onTap: () => Navigator.push(
        context,
        AnimatedTransitions.slideFromRight(screen),
      ),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrow indicator
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.colorScheme.primary,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunities() {
    return FutureBuilder<List<Community>>(
      future: _communitiesFuture,
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
    // Delegate to the enhanced card widget
    return _AnimatedCommunityCard(
      community: community,
      index: index,
    );
  }
}

/// Step 2: Community Card with press animation + shimmer effect
class _AnimatedCommunityCard extends StatefulWidget {
  final Community community;
  final int index;

  const _AnimatedCommunityCard({
    required this.community,
    required this.index,
  });

  @override
  State<_AnimatedCommunityCard> createState() => _AnimatedCommunityCardState();
}

class _AnimatedCommunityCardState extends State<_AnimatedCommunityCard>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  
  // Shimmer animation
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  
  // Floating particles animation
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    
    // Shimmer sweep
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    
    // Floating particles - slow gentle movement
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final community = widget.community;
    final index = widget.index;

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
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          AnimatedTransitions.fadeScale(
            CommunityDetailScreen(community: community),
          ),
        );
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 180,
          margin: const EdgeInsets.symmetric(
            vertical: AppColors.spacingS,
            horizontal: AppColors.spacingL,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusXL),
            boxShadow: [
              BoxShadow(
                color: (isEvenCard ? Colors.green : Colors.brown)
                    .withOpacity(_isPressed ? 0.15 : 0.25),
                blurRadius: _isPressed ? 8 : 16,
                offset: Offset(0, _isPressed ? 4 : 8),
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

                // Shimmer Effect Overlay
                AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.08),
                            Colors.transparent,
                          ],
                          stops: [
                            (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                            _shimmerAnimation.value.clamp(0.0, 1.0),
                            (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Floating Decorative Dots
                AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, _) {
                    final accentColor = isEvenCard 
                        ? const Color(0xFF69F0AE) 
                        : const Color(0xFFFFAB91);
                    return Stack(
                      children: [
                        // Dot 1 - top right
                        Positioned(
                          top: 50 + (_floatAnimation.value * 8),
                          right: 25,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withOpacity(0.6),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Dot 2 - middle right
                        Positioned(
                          top: 90 + (_floatAnimation.value * -6),
                          right: 40,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withOpacity(0.5),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Dot 3 - lower right
                        Positioned(
                          top: 130 + (_floatAnimation.value * 5),
                          right: 20,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withOpacity(0.4),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.25),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(AppColors.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Coming Soon Badge - Glassmorphism Style
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isEvenCard 
                                      ? const Color(0xFF69F0AE) 
                                      : const Color(0xFFFFAB91))
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: (isEvenCard 
                                        ? const Color(0xFF69F0AE) 
                                        : const Color(0xFFFFAB91))
                                        .withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Coming Soon",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

                      // Learn More Button - Glassmorphism Style
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Explore",
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

// Reusable tappable card with subtle press animation
class _TappableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TappableCard({
    required this.child,
    required this.onTap,
  });

  @override
  State<_TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<_TappableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.identity()
            ..translate(0.0, _isPressed ? 2.0 : 0.0),
          child: widget.child,
        ),
      ),
    );
  }
}
