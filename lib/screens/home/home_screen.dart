import "dart:math" as math;
import "dart:ui";

import "package:go_router/go_router.dart";
import "package:grocery_app/common_widgets/global_import.dart";
import "package:grocery_app/routes/app_routes.dart";
import "package:grocery_app/common_widgets/subscription_table.dart";
import "package:grocery_app/screens/home/home_community_card.dart";
import "package:grocery_app/screens/home/home_featured_products.dart";
import "package:grocery_app/screens/home/home_search_bar.dart";
import "package:grocery_app/screens/home/home_search_dropdown.dart";
import "package:grocery_app/screens/home/home_category_showcase.dart";
import "package:grocery_app/screens/home/home_communities_section.dart";
import "package:grocery_app/screens/home/all_products_list.dart";

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
    context.push('/product/${item.id}');
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
                  child: Opacity(opacity: _headerFade.value, child: child),
                );
              },
              child: Stack(
                children: [
                  // Dynamic color header background with blur effect
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
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
                                filter: ImageFilter.blur(
                                  sigmaX: 20,
                                  sigmaY: 20,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        _dynamicBgColor!.withValues(alpha: 0.7),
                                        _dynamicBgColor!.withValues(alpha: 0.5),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
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

                                  return GestureDetector(
                                    onTap: () {
                                      final dashboardState =
                                          context
                                              .findAncestorStateOfType<
                                                DashboardScreenState
                                              >();
                                      dashboardState?.switchToTab(5);
                                    },
                                    child: Row(
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
                                                color: theme.colorScheme.primary
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 20,
                                            backgroundColor: theme.cardColor,
                                            backgroundImage:
                                                profilePicture != null &&
                                                        profilePicture
                                                            .isNotEmpty
                                                    ? NetworkImage(
                                                      profilePicture,
                                                    )
                                                    : null,
                                            child:
                                                profilePicture == null ||
                                                        profilePicture.isEmpty
                                                    ? Text(
                                                      name[0].toUpperCase(),
                                                      style: textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                theme
                                                                    .colorScheme
                                                                    .primary,
                                                          ),
                                                    )
                                                    : null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Greeting Text Column
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Time-based greeting with icon
                                              Row(
                                                children: [
                                                  TweenAnimationBuilder<double>(
                                                    tween: Tween(
                                                      begin: 0.0,
                                                      end: 1.0,
                                                    ),
                                                    duration: const Duration(
                                                      milliseconds: 800,
                                                    ),
                                                    builder: (
                                                      context,
                                                      value,
                                                      child,
                                                    ) {
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
                                                    style: textTheme.bodySmall
                                                        ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .onPrimary
                                                              .withValues(
                                                                alpha: 0.8,
                                                              ),
                                                          fontWeight:
                                                              FontWeight.w500,
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
                                                      style: textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            color:
                                                                theme
                                                                    .colorScheme
                                                                    .onPrimary,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            letterSpacing: 0.2,
                                                          ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  // Animated waving hand
                                                  TweenAnimationBuilder<double>(
                                                    tween: Tween(
                                                      begin: 0.0,
                                                      end: 1.0,
                                                    ),
                                                    duration: const Duration(
                                                      milliseconds: 1500,
                                                    ),
                                                    builder: (
                                                      context,
                                                      value,
                                                      child,
                                                    ) {
                                                      final wave = math.sin(
                                                        value * 2 * math.pi,
                                                      );
                                                      return Transform.rotate(
                                                        angle:
                                                            0.2 *
                                                            (1 + wave * 0.3),
                                                        child:
                                                            Transform.translate(
                                                              offset: Offset(
                                                                0,
                                                                -2.0 *
                                                                    wave.abs(),
                                                              ),
                                                              child: const Text(
                                                                "👋",
                                                                style:
                                                                    TextStyle(
                                                                      fontSize:
                                                                          18,
                                                                    ),
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
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Modern Animated Notification Bell
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildModernIconButton(
                                  icon: Icons.dangerous,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    context.push('/${AppRoute.panchang.path}');
                                  },
                                  theme: theme,
                                  hasBadge: false,
                                ),
                                const SizedBox(width: 8),
                                _buildModernIconButton(
                                  icon: Icons.notifications_rounded,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    context.push(AppRoute.notifications.path);
                                  },
                                  theme: theme,
                                  hasBadge: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      HomeSearchBar(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onChanged: _performSearch,
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                        isSearching: _isSearching,
                      ),
                      const SizedBox(height: 20), // Bottom padding for header
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
                    HomeSearchDropdown(
                      searchResults: _searchResults,
                      onProductTap:
                          (product) => _onProductClicked(context, product),
                    )
                  else ...[
                    padded(
                      TopCurosel(
                        onColorChanged: (color) {
                          setState(() {
                            _dynamicBgColor = color;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const AllProductsList(),
                    padded(const SubscriptionCarousel()),
                    _heading(context, "Subscription Plans", "", () {}),
                    _subscriptionSection(context),
                    padded(const HomeCategoryShowcase()),
                    _buildFeaturedProducts(),
                    const SizedBox(height: 4),
                    HomeCommunitiesSection(
                      communitiesFuture: _communitiesFuture,
                      buildCard: _buildCommunityCard,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    bool hasBadge = false,
  }) {
    Widget content = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.2 * value),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Transform.rotate(
            angle: math.sin(value * math.pi * 2) * 0.1,
            child: Icon(icon, color: theme.colorScheme.onPrimary, size: 24),
          ),
        );
      },
    );

    if (hasBadge) {
      content = NotificationBadgeWidget(child: content);
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: content,
    );
  }

  Widget _buildFeaturedProducts() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return const FeaturedProductsSkeleton();
        }
        if (state is ProductError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 40,
                    color: const Color(0xFF8B7355), // Warm mocha
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Couldn't load products right now",
                    style: TextStyle(
                      color: const Color(0xFF8B7355),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Check your connection and try again 🔄",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "🌿 Crops grown with cow-based manure have 40% more nutrients!",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
                () => context.pushNamed(
                  AppRoute.featuredProducts.name,
                  extra: featuredProducts,
                ),
              ),
              // Horizontal scrolling featured products
              SizedBox(
                height: 290,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: featuredProducts.length.clamp(0, 6),
                  itemBuilder: (context, index) {
                    final product = featuredProducts[index];
                    return FeaturedProductCard(
                      product: product,
                      index: index,
                      isDark: isDark,
                      onTap: () => _onProductClicked(context, product),
                    );
                  },
                ),
              ),
            ],
          );
        }
        return const FeaturedProductsSkeleton();
      },
    );
  }

  // _buildFeaturedProductCard extracted to home_featured_products.dart
  // _buildFeaturedProductsSkeleton extracted to home_featured_products.dart

  Widget _subscriptionSection(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: SubscriptionTable(),
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
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

  Widget _buildCommunityCard(
    BuildContext context,
    Community community,
    int index,
  ) {
    // Delegate to the enhanced card widget
    return AnimatedCommunityCard(community: community, index: index);
  }
}
