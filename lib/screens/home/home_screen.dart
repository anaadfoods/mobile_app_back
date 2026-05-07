import "dart:math" as math;
import "dart:ui" as ui;
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
import 'package:grocery_app/screens/innovations/panchang/panchang_home_screen.dart';
import 'package:grocery_app/screens/innovations/solar_system_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Product> _searchResults = [];
  bool _isSearching = false;
  bool _isNavigatingToFeatured = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  // Dynamic color from carousel images — isolated via ValueNotifier
  final ValueNotifier<Color?> _bgColorNotifier = ValueNotifier<Color?>(null);

  // Animation controllers for soothing entrance effects
  late AnimationController _headerController;
  late AnimationController _contentController;
  late Animation<double> _headerFade;
  late Animation<double> _headerScale;
  late Animation<double> _contentFade;

  // Cached future for communities to prevent re-fetching on rebuild
  late Future<List<Community>> _communitiesFuture;

  // Cached greeting (computed once, doesn't change during session)
  late final int _greetingHour;
  late final String _greetingText;
  late final String _greetingEmoji;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initGreeting();
    // Cache the communities future so it doesn't re-fetch on every rebuild
    _communitiesFuture = CommunityService.fetchCommunities();
  }

  void _initGreeting() {
    _greetingHour = DateTime.now().hour;
    if (_greetingHour < 12) {
      _greetingText = 'Good Morning';
      _greetingEmoji = '🌅';
    } else if (_greetingHour < 17) {
      _greetingText = 'Good Afternoon';
      _greetingEmoji = '☀️';
    } else {
      _greetingText = 'Good Evening';
      _greetingEmoji = '🌙';
    }
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
    _bgColorNotifier.dispose();
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
    final screenWidth = MediaQuery.sizeOf(context).width;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        // physics: const BouncingScrollPhysics(
        //   parent: AlwaysScrollableScrollPhysics(),
        // ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated Header Section
            AnimatedBuilder(
              animation: _headerController,
              builder: (context, child) {
                return Transform.scale(scale: _headerScale.value, child: child);
              },
              child: FadeTransition(
                opacity: _headerFade,
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
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.deepSoilGreen,
                                  Color(0xFF3D6B28),
                                ],
                              ),
                            ),
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
                            top: MediaQuery.paddingOf(context).top + 12,
                            bottom: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Modern Welcome Section with Avatar
                              const AnaadLogoMark(
                                size: 42,
                                logoSize: 30,
                                backgroundOpacity: 0.18,
                                showShadow: false,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: BlocBuilder<AuthCubit, AuthState>(
                                  buildWhen: (prev, curr) => prev != curr,
                                  builder: (context, state) {
                                    String name = "User";
                                    String? profilePicture;
                                    if (state is Authenticated) {
                                      name =
                                          state.user.firstName[0]
                                              .toUpperCase() +
                                          state.user.firstName.substring(1);
                                      profilePicture =
                                          state.user.profilePicture;
                                    }

                                    return GestureDetector(
                                      onTap: () {
                                        context.go(AppRoute.profile.path);
                                      },
                                      child: Row(
                                        children: [
                                          // Animated Avatar with glow
                                          // Container(
                                          //   padding: const EdgeInsets.all(2),
                                          //   decoration: BoxDecoration(
                                          //     shape: BoxShape.circle,
                                          //     gradient: LinearGradient(
                                          //       colors: [
                                          //         theme.colorScheme.primary,
                                          //         theme.colorScheme.secondary,
                                          //       ],
                                          //     ),
                                          //     boxShadow: [
                                          //       BoxShadow(
                                          //         color: theme
                                          //             .colorScheme
                                          //             .primary
                                          //             .withValues(alpha: 0.4),
                                          //         blurRadius: 8,
                                          //         spreadRadius: 1,
                                          //       ),
                                          //     ],
                                          //   ),
                                          //   child: CircleAvatar(
                                          //     radius: 20,
                                          //     backgroundColor: theme.cardColor,
                                          //     // backgroundImage:
                                          //     //     profilePicture != null &&
                                          //     //             profilePicture
                                          //     //                 .isNotEmpty
                                          //     //         ? CachedNetworkImageProvider(
                                          //     //           profilePicture,
                                          //     //         )
                                          //     //         : null,
                                          //     child:
                                          //         profilePicture == null ||
                                          //                 profilePicture.isEmpty
                                          //             ? Text(
                                          //               name[0].toUpperCase(),
                                          //               style: textTheme
                                          //                   .titleMedium
                                          //                   ?.copyWith(
                                          //                     fontWeight:
                                          //                         FontWeight
                                          //                             .bold,
                                          //                     color:
                                          //                         theme
                                          //                             .colorScheme
                                          //                             .primary,
                                          //                   ),
                                          //             )
                                          //             : null,
                                          //   ),
                                          // ),
                                          const SizedBox(width: 12),
                                          // Greeting Text Column
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Time-based greeting with live emoji at end
                                                Row(
                                                  children: [
                                                    Text(
                                                      _greetingText,
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
                                                    const SizedBox(width: 5),
                                                    // Animated greeting emoji
                                                    RepaintBoundary(
                                                      child:
                                                          _AnimatedGreetingEmoji(
                                                            emoji:
                                                                _greetingEmoji,
                                                            hour: _greetingHour,
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
                                                                  FontWeight
                                                                      .bold,
                                                              letterSpacing:
                                                                  0.2,
                                                            ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    // Waving hand emoji
                                                    const RepaintBoundary(
                                                      child: _WavingHandEmoji(),
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
                                  _PanchangChakraButton(
                                    theme: theme,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      context.push(AppRoute.panchang.path);
                                    },
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
            ),

            const SizedBox(height: 10),

            // Animated Content Section
            FadeTransition(
              opacity: _contentFade,
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
                      RepaintBoundary(
                        child: TopCurosel(
                          onColorChanged: (color) {
                            _bgColorNotifier.value = color;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const RepaintBoundary(child: AllProductsList()),
                    padded(
                      const RepaintBoundary(child: SubscriptionCarousel()),
                    ),
                    _heading(context, "Subscription Plans", "", () {}),
                    RepaintBoundary(child: _subscriptionSection(context)),
                    padded(
                      const RepaintBoundary(child: HomeCategoryShowcase()),
                    ),
                    RepaintBoundary(child: _buildFeaturedProducts()),
                    const SizedBox(height: 4),
                    RepaintBoundary(
                      child: HomeCommunitiesSection(
                        communitiesFuture: _communitiesFuture,
                        buildCard: _buildCommunityCard,
                      ),
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
    Widget? customChild,
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
            child:
                customChild ??
                Icon(icon, color: theme.colorScheme.onPrimary, size: 24),
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

  Future<void> _onSeeAllFeatured(List<Product> products) async {
    HapticFeedback.lightImpact();
    if (_isNavigatingToFeatured) return;
    setState(() => _isNavigatingToFeatured = true);
    await Future.delayed(const Duration(milliseconds: 80));
    if (mounted) {
      context.pushNamed(AppRoute.featuredProducts.name, extra: products);
    }
    if (mounted) setState(() => _isNavigatingToFeatured = false);
  }

  Widget _buildFeaturedProducts() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<ProductCubit, ProductState>(
      buildWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
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
                    "Check your connection and try again ðŸ”„",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ðŸŒ¿ Crops grown with cow-based manure have 40% more nutrients!",
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
              Padding(
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
                      'Featured Products',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _onSeeAllFeatured(featuredProducts),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppColors.spacingM,
                          vertical: AppColors.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppColors.radiusRound,
                          ),
                        ),
                        child:
                            _isNavigatingToFeatured
                                ? SizedBox(
                                  width: 58,
                                  height: 16,
                                  child: ShimmerLoading(
                                    isLoading: true,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                )
                                : Text(
                                  'See All →',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              // Horizontal scrolling featured products
              SizedBox(
                height: 290,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  addAutomaticKeepAlives: false,
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

// â”€â”€â”€ Live Mini Solar System button for Panchang â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// --- Standalone animated greeting emoji (isolated repaint) -----------------

class _AnimatedGreetingEmoji extends StatefulWidget {
  final String emoji;
  final int hour;
  const _AnimatedGreetingEmoji({required this.emoji, required this.hour});

  @override
  State<_AnimatedGreetingEmoji> createState() => _AnimatedGreetingEmojiState();
}

class _AnimatedGreetingEmojiState extends State<_AnimatedGreetingEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value * 2 * math.pi;
        double scale;
        double angle;
        final h = widget.hour;
        if (h < 12) {
          scale = 1.0 + 0.12 * math.sin(t * 1.6);
          angle = 0.08 * math.sin(t * 0.8);
        } else if (h < 17) {
          scale = 1.0 + 0.08 * math.sin(t * 1.2);
          angle = _ctrl.value * math.pi * 2 * 0.25;
        } else {
          scale = 1.0 + 0.07 * math.sin(t * 0.9);
          angle = 0.12 * math.sin(t * 0.5);
        }
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: scale,
            child: Text(widget.emoji, style: const TextStyle(fontSize: 14)),
          ),
        );
      },
    );
  }
}

// --- Standalone waving hand emoji (isolated repaint) ------------------------

class _WavingHandEmoji extends StatefulWidget {
  const _WavingHandEmoji();

  @override
  State<_WavingHandEmoji> createState() => _WavingHandEmojiState();
}

class _WavingHandEmojiState extends State<_WavingHandEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final wave = math.sin(_ctrl.value * math.pi);
        return Transform.rotate(
          angle: 0.28 * wave,
          child: Transform.translate(
            offset: Offset(0, -2.5 * wave.abs()),
            child: const Text('👋', style: TextStyle(fontSize: 18)),
          ),
        );
      },
    );
  }
}

class _PanchangChakraButton extends StatefulWidget {
  final ThemeData theme;
  final VoidCallback onTap;
  const _PanchangChakraButton({required this.theme, required this.onTap});

  @override
  State<_PanchangChakraButton> createState() => _PanchangChakraButtonState();
}

class _PanchangChakraButtonState extends State<_PanchangChakraButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final Stopwatch _sw;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch()..start();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _showSolarSystemPopup(BuildContext context) {
    HapticFeedback.heavyImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Solar System',
      barrierColor: Colors.black.withOpacity(0.75),
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (ctx, _, __) => const _SolarPopupContent(),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        // Scale from 0.4 â†’ 1.0 with elastic overshoot
        final scale = Tween<double>(begin: 0.4, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        );
        // Fade 0 â†’ 1 with a quicker ease
        final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
          ),
        );
        return FadeTransition(
          opacity: opacity,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onLongPress: () => _showSolarSystemPopup(context),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.theme.colorScheme.onPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.theme.colorScheme.onPrimary.withValues(
                  alpha: 0.1,
                ),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFCA28).withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _ticker,
              builder: (context, _) {
                final t = _sw.elapsed.inMilliseconds / 1000.0;
                return CustomPaint(
                  size: const Size(24, 24),
                  painter: _MiniSolarPainter(t: t),
                );
              },
            ),
          ),
          // Pulsing "hold" hint overlaid below the container
          Positioned(
            bottom: -13,
            child: AnimatedBuilder(
              animation: _ticker,
              builder: (context, _) {
                final t = _sw.elapsed.inMilliseconds / 1000.0;
                final pulse = 0.35 + 0.35 * math.sin(t * 1.1).abs();
                return Text(
                  'hold',
                  style: TextStyle(
                    color: const Color(0xFFFFCA28).withOpacity(pulse),
                    fontSize: 7,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.5,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Planets: [orbitFraction, periodSec, startAngle, colorARGB]
const _miniPlanets = [
  [0.22, 4.8, 0.70, 0xFFA8A8A8], // Mercury â€” grey
  [0.40, 10.0, 2.40, 0xFFE8C060], // Venus   â€” gold
  [0.60, 20.0, 4.90, 0xFF42A5F5], // Earth   â€” blue
  [0.82, 38.0, 1.10, 0xFFEF5350], // Mars    â€” red
];

class _MiniSolarPainter extends CustomPainter {
  final double t;
  const _MiniSolarPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final max = cx * 0.96;

    // â”€â”€ Background disc â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    canvas.drawCircle(
      Offset(cx, cy),
      max,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFF0D1B2A), Color(0xFF030810)],
          radius: 1.0,
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: max)),
    );

    // â”€â”€ Orbit rings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    for (final p in _miniPlanets) {
      final orbitR = (p[0] as double) * max;
      canvas.drawCircle(
        Offset(cx, cy),
        orbitR,
        Paint()
          ..color = Colors.white.withOpacity(0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.35,
      );
    }

    // â”€â”€ Sun â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final sunR = max * 0.18;
    // Corona glow
    canvas.drawCircle(
      Offset(cx, cy),
      sunR * 2.0,
      Paint()
        ..color = const Color(0xFFFFCA28).withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Body
    canvas.drawCircle(
      Offset(cx, cy),
      sunR,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xFFFFFDE7),
            Color(0xFFFFCA28),
            Color(0xFFFF8F00),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: sunR)),
    );

    // â”€â”€ Planets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    for (final p in _miniPlanets) {
      final orbitR = (p[0] as double) * max;
      final period = p[1] as double;
      final start = p[2] as double;
      final color = Color(p[3] as int);
      final pr = 0.9 + orbitR * 0.055; // planet dot radius

      final angle = (t / period) * 2 * math.pi + start;
      final px = cx + orbitR * math.cos(angle);
      final py = cy + orbitR * math.sin(angle);

      // Tiny glow
      canvas.drawCircle(
        Offset(px, py),
        pr * 2.2,
        Paint()
          ..color = color.withOpacity(0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      // Planet dot
      canvas.drawCircle(Offset(px, py), pr, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_MiniSolarPainter old) => old.t != t;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  Solar System Popup â€” 3D Perspective Version
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// 3D perspective constants for popup
const double _popupTilt = 0.38;
const double _popupDepthScale = 0.28;
const double _popupDepthBright = 0.25;

class _SolarPopupContent extends StatefulWidget {
  const _SolarPopupContent();

  @override
  State<_SolarPopupContent> createState() => _SolarPopupContentState();
}

class _SolarPopupContentState extends State<_SolarPopupContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final Stopwatch _sw;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch()..start();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size;
    final w = sw.width * 0.92;
    final h = sw.height * 0.90;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF0A1628), Color(0xFF030810)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFFFFCA28).withOpacity(0.22),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFCA28).withOpacity(0.10),
                blurRadius: 40,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.75),
                blurRadius: 60,
                spreadRadius: 8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Live 3D solar system (full canvas)
                AnimatedBuilder(
                  animation: _ticker,
                  builder: (context, _) {
                    final t = _sw.elapsed.inMilliseconds / 1000.0;
                    return CustomPaint(
                      painter: _RealisticPopupPainter(t: t),
                      child: const SizedBox.expand(),
                    );
                  },
                ),

                // Gradient veil over bottom portion
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: h * 0.42,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF030810).withOpacity(0.75),
                          const Color(0xFF020608).withOpacity(0.97),
                        ],
                        stops: const [0.0, 0.40, 1.0],
                      ),
                    ),
                  ),
                ),

                // Content overlay
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Decorative divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: const Color(
                                  0xFFFFCA28,
                                ).withOpacity(0.25),
                                thickness: 0.5,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                '\u2726',
                                style: TextStyle(
                                  color: const Color(
                                    0xFFFFCA28,
                                  ).withOpacity(0.60),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: const Color(
                                  0xFFFFCA28,
                                ).withOpacity(0.25),
                                thickness: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Headline
                        const Text(
                          'FOOD MOVES WITH THE COSMOS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFFFCA28),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.2,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Body
                        Text(
                          'Every seed sprouts with the Sun. Every harvest '
                          'follows the Moon. For thousands of years, the '
                          'Panchang \u2014 the ancient almanac of cosmic cycles \u2014 '
                          'guided when to sow, when to reap, and when to eat.\n\n'
                          'Anaad Foods honours this wisdom. We source and '
                          'deliver food in alignment with nature\u2019s rhythms, '
                          'so every grain, every vegetable, every drop of '
                          'goodness reaches you at its peak \u2014 the way the '
                          'universe intended.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.68),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w300,
                            height: 1.65,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Coming Soon badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFCA28).withOpacity(0.50),
                              width: 1,
                            ),
                            color: const Color(0xFFFFCA28).withOpacity(0.08),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: const Color(
                                  0xFFFFCA28,
                                ).withOpacity(0.80),
                                size: 13,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'COSMIC FOOD CALENDAR  \u00b7  COMING SOON',
                                style: TextStyle(
                                  color: const Color(
                                    0xFFFFCA28,
                                  ).withOpacity(0.80),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Close button
                Positioned(
                  top: 10,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.20),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ),
                ),

                // Anaad Foods wordmark top-centre
                Positioned(
                  top: 14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'A N A A D  F O O D S',
                      style: TextStyle(
                        color: const Color(0xFFFFCA28).withOpacity(0.45),
                        fontSize: 9,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 3.5,
                      ),
                    ),
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  3D popup painter (matches full-screen 3D quality)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// Planet data for popup
class _PPlanet {
  final String name;
  final Color color, colorDark;
  final double radius, orbit, period, start;
  final bool hasRings;
  final Color? atmosphere;
  final List<List<double>>? bands;

  const _PPlanet({
    required this.name,
    required this.color,
    required this.colorDark,
    required this.radius,
    required this.orbit,
    required this.period,
    required this.start,
    this.hasRings = false,
    this.atmosphere,
    this.bands,
  });
}

const _pPlanets = <_PPlanet>[
  _PPlanet(
    name: 'Mercury',
    color: Color(0xFFB0ACA6),
    colorDark: Color(0xFF5A5652),
    radius: 2.6,
    orbit: 0.105,
    period: 4.8,
    start: 0.7,
  ),
  _PPlanet(
    name: 'Venus',
    color: Color(0xFFE8C876),
    colorDark: Color(0xFF8A6F32),
    radius: 3.6,
    orbit: 0.160,
    period: 7.8,
    start: 2.4,
    atmosphere: Color(0xFFFFF3C4),
  ),
  _PPlanet(
    name: 'Earth',
    color: Color(0xFF4DA6FF),
    colorDark: Color(0xFF1A4070),
    radius: 4.0,
    orbit: 0.218,
    period: 12.0,
    start: 4.9,
    atmosphere: Color(0xFF80D0FF),
  ),
  _PPlanet(
    name: 'Mars',
    color: Color(0xFFE06040),
    colorDark: Color(0xFF6D2A1A),
    radius: 3.2,
    orbit: 0.278,
    period: 20.0,
    start: 1.1,
  ),
  _PPlanet(
    name: 'Jupiter',
    color: Color(0xFFD4A96A),
    colorDark: Color(0xFF6A5030),
    radius: 7.5,
    orbit: 0.400,
    period: 36.0,
    start: 3.5,
    bands: [
      [0xFFC8906A, -0.35, 0.20],
      [0xFFE8C890, 0.0, 0.15],
      [0xFFB07848, 0.30, 0.22],
    ],
  ),
  _PPlanet(
    name: 'Saturn',
    color: Color(0xFFEAD5A0),
    colorDark: Color(0xFF806838),
    radius: 6.2,
    orbit: 0.520,
    period: 58.0,
    start: 5.6,
    hasRings: true,
  ),
  _PPlanet(
    name: 'Uranus',
    color: Color(0xFF80DEEA),
    colorDark: Color(0xFF2A6070),
    radius: 5.0,
    orbit: 0.680,
    period: 82.0,
    start: 0.2,
    atmosphere: Color(0xFFA0F0F8),
  ),
  _PPlanet(
    name: 'Neptune',
    color: Color(0xFF5C6BC0),
    colorDark: Color(0xFF283060),
    radius: 4.6,
    orbit: 0.840,
    period: 118.0,
    start: 2.8,
    atmosphere: Color(0xFF8090E0),
  ),
];

// Computed 3D position for z-sorting
class _PPos {
  final int idx;
  final Offset screen;
  final double z, angle, scale, bright;
  const _PPos(
    this.idx,
    this.screen,
    this.z,
    this.angle,
    this.scale,
    this.bright,
  );
}

// --- Pre-computed star/asteroid data for the solar popup ------------------
// Fixed seeds (77/31) - positions are invariant; computed once at app startup.
class _StarDot {
  final double xf, yf, r, baseOp, freq, phase;
  final bool twinkles;
  final Color tint;
  const _StarDot(
    this.xf,
    this.yf,
    this.r,
    this.baseOp,
    this.twinkles,
    this.freq,
    this.phase,
    this.tint,
  );
}

class _BrightStar {
  final double xf, yf, r, baseOp, freq, phase;
  final Color tint;
  const _BrightStar(
    this.xf,
    this.yf,
    this.r,
    this.baseOp,
    this.freq,
    this.phase,
    this.tint,
  );
}

class _BeltDot {
  final double baseAngle, rFrac, dotBase, opBase;
  const _BeltDot(this.baseAngle, this.rFrac, this.dotBase, this.opBase);
}

class _PopupStarData {
  final List<_StarDot> layer1;
  final List<_BrightStar> layer2;
  final List<_BrightStar> layer3;
  final List<_BeltDot> belt;
  _PopupStarData(this.layer1, this.layer2, this.layer3, this.belt);
}

final _popupStarData = () {
  const tints = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFFFE8C8),
    Color(0xFFC8D8FF),
    Color(0xFFFFCCCC),
    Color(0xFFD0F0FF),
    Color(0xFFFFF0B0),
  ];
  final rng = math.Random(77);
  // Layer 1 - 180 tiny stars (mirrors exact RNG sequence in original paint())
  final l1 = List<_StarDot>.generate(180, (_) {
    final xf = rng.nextDouble();
    final yf = rng.nextDouble();
    final r = rng.nextDouble() * 0.7 + 0.15;
    final op = rng.nextDouble() * 0.35 + 0.08;
    final tw = rng.nextBool();
    final freq = tw ? rng.nextDouble() * 2.0 + 0.3 : 0.0;
    final phase = tw ? rng.nextDouble() * 6.28 : 0.0;
    return _StarDot(
      xf,
      yf,
      r,
      op,
      tw,
      freq,
      phase,
      tints[rng.nextInt(tints.length)],
    );
  });
  // Layer 2 - 40 medium glowing stars (continues same RNG from layer 1)
  final l2 = List<_BrightStar>.generate(40, (_) {
    final xf = rng.nextDouble();
    final yf = rng.nextDouble();
    final r = rng.nextDouble() * 1.0 + 0.8;
    final op = rng.nextDouble() * 0.40 + 0.25;
    final freq = rng.nextDouble() * 1.8 + 0.4;
    final phase = rng.nextDouble() * 6.28;
    return _BrightStar(
      xf,
      yf,
      r,
      op,
      freq,
      phase,
      tints[rng.nextInt(tints.length)],
    );
  });
  // Layer 3 - 12 bright cross-flare stars (continues same RNG)
  final l3 = List<_BrightStar>.generate(12, (_) {
    final xf = rng.nextDouble();
    final yf = rng.nextDouble();
    final r = rng.nextDouble() * 0.8 + 1.2;
    final op = rng.nextDouble() * 0.30 + 0.45;
    final freq = rng.nextDouble() * 2.5 + 0.5;
    final phase = rng.nextDouble() * 6.28;
    return _BrightStar(
      xf,
      yf,
      r,
      op,
      freq,
      phase,
      tints[rng.nextInt(tints.length)],
    );
  });
  // Asteroid belt - independent seed 31
  final arng = math.Random(31);
  final belt = List<_BeltDot>.generate(
    55,
    (_) => _BeltDot(
      arng.nextDouble() * math.pi * 2,
      0.340 + (arng.nextDouble() - 0.5) * 0.032,
      arng.nextDouble() * 0.7 + 0.15,
      arng.nextDouble() * 0.10 + 0.03,
    ),
  );
  return _PopupStarData(l1, l2, l3, belt);
}();

class _RealisticPopupPainter extends CustomPainter {
  final double t;
  const _RealisticPopupPainter({required this.t});

  _PPos _project(int idx, Offset center, double maxOrbit) {
    final p = _pPlanets[idx];
    final orbitR = p.orbit * maxOrbit;
    final angle = (t / p.period) * 2 * math.pi + p.start;
    final sx = center.dx + orbitR * math.cos(angle);
    final sy = center.dy + orbitR * math.sin(angle) * _popupTilt;
    final zN = math.sin(angle);
    final scale = 1.0 + zN * _popupDepthScale;
    final bright = 1.0 + zN * _popupDepthBright;
    return _PPos(idx, Offset(sx, sy), zN, angle, scale, bright);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.38; // shifted up so system fills top portion
    final center = Offset(cx, cy);
    final maxOrbit = cx * 0.96; // use full width instead of min(cx,cy)

    // â”€â”€ Background â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          maxOrbit * 1.2,
          const [
            Color(0xFF0C1424),
            Color(0xFF060C16),
            Color(0xFF020408),
            Color(0xFF000000),
          ],
          const [0.0, 0.35, 0.65, 1.0],
        ),
    );
    canvas.drawCircle(
      center,
      maxOrbit * 0.40,
      Paint()
        ..color = const Color(0xFFFF8F00).withOpacity(0.018)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, maxOrbit * 0.30),
    );

    // ── Distant galaxies / nebula clouds ─────────────────────
    // Spiral galaxy blob (upper-left)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.12, size.height * 0.08),
        width: 38,
        height: 16,
      ),
      Paint()
        ..color = const Color(0xFF8090D0).withOpacity(0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.12, size.height * 0.08),
        width: 18,
        height: 8,
      ),
      Paint()
        ..color = const Color(0xFFB0C0F0).withOpacity(0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Warm galaxy (upper-right corner)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.88, size.height * 0.12),
        width: 28,
        height: 10,
      ),
      Paint()
        ..color = const Color(0xFFD0A060).withOpacity(0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.88, size.height * 0.12),
        width: 12,
        height: 5,
      ),
      Paint()
        ..color = const Color(0xFFF0D098).withOpacity(0.09)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Blue nebula cloud (left side)
    canvas.drawCircle(
      Offset(size.width * 0.06, size.height * 0.35),
      size.width * 0.10,
      Paint()
        ..color = const Color(0xFF2A3880).withOpacity(0.08)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.08),
    );

    // Warm nebula cloud (right side, faint)
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.48),
      size.width * 0.08,
      Paint()
        ..color = const Color(0xFF4A2020).withOpacity(0.06)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.07),
    );

    // Tiny galaxy cluster (centre-top)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.55, size.height * 0.04),
        width: 20,
        height: 8,
      ),
      Paint()
        ..color = const Color(0xFFA0A8E0).withOpacity(0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // ── Star field (multi-layer for depth) ───────────────────
    // -- Star field (multi-layer for depth) - uses pre-computed data ---------
    final _sw = size.width;
    final _sh = size.height;
    // Layer 1: Dense tiny stars
    for (final s in _popupStarData.layer1) {
      final twinkle =
          s.twinkles ? (0.5 + 0.5 * math.sin(t * s.freq + s.phase)) : 1.0;
      canvas.drawCircle(
        Offset(s.xf * _sw, s.yf * _sh),
        s.r,
        Paint()
          ..color = s.tint.withOpacity((s.baseOp * twinkle).clamp(0.03, 0.50)),
      );
    }

    // Layer 2: Medium stars with glow
    for (final s in _popupStarData.layer2) {
      final twinkle = 0.5 + 0.5 * math.sin(t * s.freq + s.phase);
      final op = (s.baseOp * twinkle).clamp(0.05, 0.70);
      canvas.drawCircle(
        Offset(s.xf * _sw, s.yf * _sh),
        s.r * 2.5,
        Paint()
          ..color = s.tint.withOpacity(op * 0.12)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.r * 2),
      );
      canvas.drawCircle(
        Offset(s.xf * _sw, s.yf * _sh),
        s.r,
        Paint()..color = s.tint.withOpacity(op),
      );
    }

    // Layer 3: Bright points with cross-flares
    for (final s in _popupStarData.layer3) {
      final twinkle = 0.4 + 0.6 * math.sin(t * s.freq + s.phase);
      final op = (s.baseOp * twinkle).clamp(0.08, 0.85);
      final pos = Offset(s.xf * _sw, s.yf * _sh);
      canvas.drawCircle(
        pos,
        s.r * 3.5,
        Paint()
          ..color = s.tint.withOpacity(op * 0.08)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.r * 3),
      );
      canvas.drawCircle(pos, s.r, Paint()..color = s.tint.withOpacity(op));
      if (op > 0.40) {
        final fl =
            Paint()
              ..color = s.tint.withOpacity(op * 0.22)
              ..strokeWidth = 0.4
              ..strokeCap = StrokeCap.round;
        final len = s.r * 3.5;
        canvas.drawLine(pos - Offset(len, 0), pos + Offset(len, 0), fl);
        canvas.drawLine(pos - Offset(0, len), pos + Offset(0, len), fl);
      }
    }

    final gridPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.3;
    for (int i = 1; i <= 10; i++) {
      final r = maxOrbit * (i / 10.0) * 1.02;
      final opacity = (0.022 * (1.0 - i / 12.0)).clamp(0.0, 1.0);
      gridPaint.color = Colors.white.withOpacity(opacity);
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: r * 2,
          height: r * 2 * _popupTilt,
        ),
        gridPaint,
      );
    }
    final radialPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.010)
          ..strokeWidth = 0.3;
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final far = maxOrbit * 1.02;
      canvas.drawLine(
        center,
        Offset(
          center.dx + far * math.cos(angle),
          center.dy + far * math.sin(angle) * _popupTilt,
        ),
        radialPaint,
      );
    }

    // â”€â”€ Elliptical orbit paths â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    for (final p in _pPlanets) {
      final r = p.orbit * maxOrbit;
      final rect = Rect.fromCenter(
        center: center,
        width: r * 2,
        height: r * 2 * _popupTilt,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..color = Colors.white.withOpacity(0.045)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // â”€â”€ Asteroid belt (3D) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // -- Asteroid belt (3D) - uses pre-computed data -------------------------
    for (final a in _popupStarData.belt) {
      final angle = a.baseAngle + t * 0.008;
      final rOff = a.rFrac * maxOrbit;
      final zN = math.sin(angle);
      final depthOp = (0.5 + zN * 0.5).clamp(0.15, 1.0);
      canvas.drawCircle(
        Offset(
          cx + rOff * math.cos(angle),
          cy + rOff * math.sin(angle) * _popupTilt,
        ),
        a.dotBase * (1.0 + zN * 0.15),
        Paint()
          ..color = Colors.white.withOpacity(
            (a.opBase * depthOp).clamp(0.0, 1.0),
          ),
      );
    }

    final positions = <_PPos>[];
    for (int i = 0; i < _pPlanets.length; i++) {
      positions.add(_project(i, center, maxOrbit));
    }
    positions.sort((a, b) => a.z.compareTo(b.z));

    final sunR = maxOrbit * 0.060;
    final behind = positions.where((p) => p.z < -0.05).toList();
    final front = positions.where((p) => p.z >= -0.05).toList();

    for (final pp in behind) {
      _drawOrbitTrail(canvas, center, pp, maxOrbit);
      _drawFullPlanet(canvas, pp, center, sunR, size);
    }
    _drawSun(canvas, center, sunR);
    for (final pp in front) {
      _drawOrbitTrail(canvas, center, pp, maxOrbit);
      _drawFullPlanet(canvas, pp, center, sunR, size);
    }

    _drawMoon(canvas, center, maxOrbit);
  }

  void _drawSun(Canvas canvas, Offset c, double r) {
    final pulse = 1.0 + 0.03 * math.sin(t * 2.2);
    final pulse2 = 1.0 + 0.05 * math.sin(t * 1.4 + 1.0);
    canvas.drawCircle(
      c,
      r * 5.0 * pulse2,
      Paint()
        ..color = const Color(0xFFFF6D00).withOpacity(0.012)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
    for (int i = 0; i < 6; i++) {
      final rayAngle = i * math.pi / 3 + t * 0.05;
      final rayLen = r * (3.0 + 0.6 * math.sin(t * 1.8 + i));
      final dx = math.cos(rayAngle);
      final dy = math.sin(rayAngle);
      canvas.drawLine(
        Offset(c.dx + r * 0.6 * dx, c.dy + r * 0.6 * dy),
        Offset(c.dx + rayLen * dx, c.dy + rayLen * dy),
        Paint()
          ..color = const Color(0xFFFFCC02).withOpacity(0.035)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    for (int i = 5; i >= 1; i--) {
      canvas.drawCircle(
        c,
        r * (1.0 + i * 0.50) * pulse,
        Paint()
          ..color = const Color(0xFFFF9800).withOpacity(0.025 * i)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0 + i * 3),
      );
    }
    canvas.drawCircle(
      c,
      r * 1.45,
      Paint()
        ..color = const Color(0xFFFFCC02).withOpacity(0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r,
          const [
            Color(0xFFFFFFE8),
            Color(0xFFFFF176),
            Color(0xFFFFCA28),
            Color(0xFFFF8F00),
            Color(0xFFE65100),
          ],
          const [0.0, 0.25, 0.55, 0.82, 1.0],
        ),
    );
    final spotA = t * 0.3;
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    canvas.drawCircle(
      Offset(
        c.dx + r * 0.35 * math.cos(spotA),
        c.dy + r * 0.15 * math.sin(spotA),
      ),
      r * 0.10,
      Paint()..color = const Color(0xFFCC7700).withOpacity(0.32),
    );
    canvas.restore();
  }

  void _drawOrbitTrail(
    Canvas canvas,
    Offset center,
    _PPos pp,
    double maxOrbit,
  ) {
    final p = _pPlanets[pp.idx];
    final r = p.orbit * maxOrbit;
    const sweep = 0.50;
    final rect = Rect.fromCenter(
      center: center,
      width: r * 2,
      height: r * 2 * _popupTilt,
    );
    canvas.drawArc(
      rect,
      pp.angle - sweep,
      sweep,
      false,
      Paint()
        ..color = p.color.withOpacity(0.10 * pp.bright.clamp(0.5, 1.5))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * pp.scale
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawArc(
      rect,
      pp.angle - sweep * 0.5,
      sweep * 0.5,
      false,
      Paint()
        ..color = p.color.withOpacity(0.20 * pp.bright.clamp(0.5, 1.5))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * pp.scale
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawFullPlanet(
    Canvas canvas,
    _PPos pp,
    Offset sunCenter,
    double sunR,
    Size size,
  ) {
    final p = _pPlanets[pp.idx];
    final r = p.radius * pp.scale;
    final pos = pp.screen;
    final bright = pp.bright.clamp(0.6, 1.4);

    final toSun = sunCenter - pos;
    final dist = toSun.distance.clamp(1.0, double.infinity);
    final ld = Offset(toSun.dx / dist, toSun.dy / dist);

    // Shadow on orbital plane
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx + 1.5, pos.dy + r * 0.6),
        width: r * 2.0,
        height: r * 0.4,
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.12 * bright)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.7),
    );

    if (p.atmosphere != null) {
      canvas.drawCircle(
        pos + ld * r * 0.12,
        r * 1.5,
        Paint()
          ..color = p.atmosphere!.withOpacity(0.08 * bright)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6),
      );
    }

    canvas.drawCircle(
      pos,
      r * 2.0,
      Paint()
        ..color = p.color.withOpacity(0.12 * bright)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8),
    );

    if (p.hasRings) _drawRing(canvas, pos, r, false);

    final litColor = Color.lerp(p.color, Colors.white, (bright - 1.0) * 0.15)!;
    final darkColor =
        Color.lerp(p.colorDark, Colors.black, (1.0 - bright) * 0.08)!;
    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..shader = ui.Gradient.linear(pos + ld * r, pos - ld * r, [
          litColor,
          darkColor,
        ]),
    );

    if (p.bands != null) {
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: pos, radius: r)));
      for (final b in p.bands!) {
        final by = pos.dy + r * b[1];
        final bh = r * b[2];
        canvas.drawRect(
          Rect.fromLTWH(pos.dx - r, by - bh / 2, r * 2, bh),
          Paint()..color = Color(b[0].toInt()).withOpacity(0.50 * bright),
        );
      }
      canvas.restore();
    }

    canvas.drawCircle(
      pos + ld * r * 0.28,
      r * 0.35,
      Paint()
        ..shader = ui.Gradient.radial(pos + ld * r * 0.28, r * 0.35, [
          Colors.white.withOpacity(0.40 * bright),
          Colors.white.withOpacity(0.0),
        ]),
    );

    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..color = Colors.white.withOpacity(0.06 * bright)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    if (p.hasRings) {
      _drawRing(canvas, pos, r, true);
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: pos, radius: r)));
      canvas.drawRect(
        Rect.fromCenter(
          center: pos + Offset(0, r * 0.08),
          width: r * 5,
          height: r * 0.25,
        ),
        Paint()..color = Colors.black.withOpacity(0.10),
      );
      canvas.restore();
    }

    // Label
    final opacity = (0.60 * bright).clamp(0.3, 0.85);
    final tp = TextPainter(
      text: TextSpan(
        text: p.name,
        style: TextStyle(
          color: Colors.white.withOpacity(opacity),
          fontSize: 7.5 * (0.8 + bright * 0.2).clamp(0.8, 1.1),
          letterSpacing: 0.8,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final lx = (pos.dx - tp.width / 2).clamp(3.0, size.width - tp.width - 3);
    final ly = (pos.dy + r + 4.0).clamp(3.0, size.height - tp.height - 3);
    canvas.drawRect(
      Rect.fromLTWH(lx - 2, ly - 1, tp.width + 4, tp.height + 2),
      Paint()
        ..color = p.color.withOpacity(0.08 * bright)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    tp.paint(canvas, Offset(lx, ly));
  }

  void _drawRing(Canvas canvas, Offset pos, double r, bool front) {
    void arc(double th, Color c, double mul) {
      final rect = Rect.fromCenter(
        center: pos,
        width: r * 2.5 * mul * 2,
        height: r * 0.55 * mul * 2,
      );
      canvas.drawArc(
        rect,
        front ? 0 : math.pi,
        math.pi,
        false,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = th,
      );
    }

    arc(3.0, const Color(0xFFD4B896).withOpacity(0.55), 1.0);
    arc(1.2, Colors.transparent, 0.88);
    arc(1.8, const Color(0xFFBDA882).withOpacity(0.38), 0.80);
    arc(0.8, const Color(0xFFE8D0B0).withOpacity(0.15), 1.18);
  }

  void _drawMoon(Canvas canvas, Offset center, double maxOrbit) {
    const i = 2;
    final ep = _pPlanets[i];
    final eOrbit = ep.orbit * maxOrbit;
    final eAngle = (t / ep.period) * 2 * math.pi + ep.start;
    final ex = center.dx + eOrbit * math.cos(eAngle);
    final ey = center.dy + eOrbit * math.sin(eAngle) * _popupTilt;
    final earthPos = Offset(ex, ey);
    final moonOrbit = eOrbit * 0.22;
    final moonAngle = (t / 2.5) * 2 * math.pi;
    final mx = ex + moonOrbit * math.cos(moonAngle);
    final my = ey + moonOrbit * math.sin(moonAngle) * _popupTilt;
    final moonPos = Offset(mx, my);
    canvas.drawOval(
      Rect.fromCenter(
        center: earthPos,
        width: moonOrbit * 2,
        height: moonOrbit * 2 * _popupTilt,
      ),
      Paint()
        ..color = Colors.white.withOpacity(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.3,
    );
    canvas.drawCircle(
      moonPos,
      3.0,
      Paint()
        ..color = const Color(0xFFCFD8DC).withOpacity(0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final toSun = center - moonPos;
    final dist = toSun.distance.clamp(1.0, double.infinity);
    final ld = Offset(toSun.dx / dist, toSun.dy / dist);
    canvas.drawCircle(
      moonPos,
      1.5,
      Paint()
        ..shader = ui.Gradient.linear(
          moonPos + ld * 1.5,
          moonPos - ld * 1.5,
          const [Color(0xFFE0E4E8), Color(0xFF606868)],
        ),
    );
  }

  @override
  bool shouldRepaint(_RealisticPopupPainter old) => old.t != t;
}
