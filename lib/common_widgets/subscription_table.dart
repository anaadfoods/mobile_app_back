import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/routes/app_routes.dart';

class SubscriptionTable extends StatefulWidget {
  final Function(SubscriptionPlan)? onPlanSelected;
  const SubscriptionTable({super.key, this.onPlanSelected});

  @override
  _SubscriptionTableState createState() => _SubscriptionTableState();
}

class _SubscriptionTableState extends State<SubscriptionTable>
    with TickerProviderStateMixin {
  final SubscriptionService _subscriptionService = getIt<SubscriptionService>();
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  String? _error;
  static List<SubscriptionPlan>? _cachedPlans;
  static final Map<int, List<SubscriptionPlanProduct>> _cachedPlanProducts = {};
  final Map<int, List<SubscriptionPlanProduct>> _planProducts = {};
  final Map<int, bool> _loadingProducts = {};
  int _currentIndex = 0;

  late PageController _pageController;
  late AnimationController _pulseController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    // viewportFraction 0.65 shows ~3 cards (center + partial sides)
    // initialPage 1000 for infinite scroll illusion
    _pageController = PageController(viewportFraction: 0.65, initialPage: 1000);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _plans.isEmpty) return;
      // For infinite scroll, just go to next page
      final currentPage = _pageController.page?.round() ?? 1000;
      _pageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  bool _hasLoadedData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedData) {
      _hasLoadedData = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_cachedPlans != null && _cachedPlans!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _plans = List<SubscriptionPlan>.from(_cachedPlans!)
            ..sort((a, b) => a.id.compareTo(b.id));
          _isLoading = false;
        });
      }
      for (var plan in _cachedPlans!) {
        _loadPlanProducts(plan.id);
      }
    } else {
      await _loadSubscriptionPlans();
    }
  }

  Future<void> _loadSubscriptionPlans() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final result = await _subscriptionService.getSubscriptionPlans();
      if (mounted) {
        if (result['success']) {
          setState(() {
            _plans = List<SubscriptionPlan>.from(result['data'] as List<SubscriptionPlan>)
              ..sort((a, b) => a.id.compareTo(b.id));
            _cachedPlans = _plans;
            _isLoading = false;
          });
          for (var plan in _plans) {
            _loadPlanProducts(plan.id);
          }
        } else {
          setState(() {
            _error = result['message'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPlanProducts(int planId) async {
    if (_cachedPlanProducts.containsKey(planId)) {
      if (mounted) {
        setState(() {
          _planProducts[planId] = _cachedPlanProducts[planId]!;
        });
      }
      return;
    }
    if (_loadingProducts[planId] == true) return;

    if (mounted) {
      setState(() {
        _loadingProducts[planId] = true;
      });
    }

    try {
      final result = await _subscriptionService.getSubscriptionPlanProducts(
        planId,
      );
      if (mounted) {
        if (result['success']) {
          final response = result['data'] as SubscriptionPlanProductsResponse;
          setState(() {
            _planProducts[planId] = response.products;
            _cachedPlanProducts[planId] = response.products;
          });
        } else {
          if (result['requiresLogin'] == true) {
            context.pushNamed(AppRoute.login.name);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingProducts[planId] = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    _cachedPlans = null;
    _cachedPlanProducts.clear();
    await _loadSubscriptionPlans();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _pulseController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return _buildLoadingState(isDark);
    }
    if (_error != null) {
      return _buildErrorState(theme);
    }
    if (_plans.isEmpty) {
      return const SizedBox.shrink();
    }

    // Taller cards for more rectangular look
    final cardHeight = (size.height * 0.48).clamp(340.0, 440.0);

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: GestureDetector(
            onPanDown: (_) => _stopAutoScroll(),
            onPanEnd: (_) => _startAutoScroll(),
            child: PageView.builder(
              controller: _pageController,
              itemCount: null, // Infinite scroll
              onPageChanged: (index) {
                setState(() => _currentIndex = index % _plans.length);
              },
              itemBuilder: (context, index) {
                final actualIndex = index % _plans.length;
                final plan = _plans[actualIndex];
                final isActive = actualIndex == _currentIndex;

                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double scale = 1.0;
                    double opacity = 1.0;

                    if (_pageController.position.haveDimensions) {
                      final page = _pageController.page ?? 1000.0;
                      final diff = (page - index).abs();
                      // Center card = full size, side cards smaller
                      scale = (1 - (diff * 0.12)).clamp(0.8, 1.0);
                      opacity = (1 - (diff * 0.3)).clamp(0.5, 1.0);
                    }

                    return Center(
                      child: Transform.scale(scale: scale, child: child),
                    );
                  },
                  child: _buildPlanCard(plan, isActive, theme, isDark),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Page indicators
        _buildPageIndicators(isDark),
      ],
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.deepSoilGreen,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loading plans...',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 40,
            color: const Color(0xFF8B7355), // Warm mocha - friendly
          ),
          const SizedBox(height: 12),
          Text(
            "Couldn't load subscription plans",
            style: TextStyle(
              color: const Color(0xFF8B7355),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Text(
          //   "Check your connection and try again 📶",
          //   style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          //   textAlign: TextAlign.center,
          // ),
          const SizedBox(height: 8),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 24),
          //   child: Text(
          //     "🌾 Beejamrutham (cow-based seed treatment) improves germination by 20%!",
          //     style: TextStyle(
          //       color: Colors.green.shade700,
          //       fontSize: 11,
          //       fontStyle: FontStyle.italic,
          //     ),
          //     textAlign: TextAlign.center,
          //   ),
          // ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadSubscriptionPlans,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators(bool isDark) {
    final bestValIdx =
        _plans.isEmpty ? -1 : _plans.indexWhere((p) => p.durationMonths == 12);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_plans.length, (index) {
        final isActive = index == _currentIndex;
        final isBest = index == bestValIdx;
        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color:
                  isActive
                      ? (isBest
                          ? const Color(0xFFD4AF37)
                          : AppColors.deepSoilGreen)
                      : (isDark ? Colors.white24 : Colors.black12),
              boxShadow:
                  isActive
                      ? [
                        BoxShadow(
                          color:
                              isBest
                                  ? const Color(0xFFD4AF37).withOpacity(0.6)
                                  : AppColors.deepSoilGreen.withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                      : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPlanCard(
    SubscriptionPlan plan,
    bool isActive,
    ThemeData theme,
    bool isDark,
  ) {
    final cardColors = _getCardColors(plan, isDark, isActive);
    final isBestValue = plan.durationMonths == 12;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showSubscriptionPopup(
          context: context,
          allPlans: _plans,
          initialPlan: plan,
          allProducts: _planProducts,
          loadingProductsState: _loadingProducts,
          loadProductsCallback: _loadPlanProducts,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: cardColors.gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: cardColors.shadow.withOpacity(isActive ? 0.55 : 0.25),
              blurRadius: isActive ? 32 : 18,
              offset: const Offset(0, 10),
              spreadRadius: isActive ? 4 : 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Card Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Duration badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(
                                    cardColors.goldAccent ? 0.12 : 0.18,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      cardColors.goldAccent
                                          ? Border.all(
                                            color: const Color(0xFFD4AF37),
                                            width: 1,
                                          )
                                          : Border.all(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 1,
                                          ),
                                ),
                                child: Text(
                                  '${plan.durationMonths} MONTHS',
                                  style: TextStyle(
                                    color:
                                        cardColors.goldAccent
                                            ? const Color(0xFFFFE082)
                                            : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Plan name
                              Text(
                                plan.name.toUpperCase(),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19,
                                  letterSpacing: 0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Premium icon container
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            gradient:
                                cardColors.goldAccent
                                    ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFD4AF37),
                                        Color(0xFFB8860B),
                                      ],
                                    )
                                    : LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.28),
                                        Colors.white.withOpacity(0.12),
                                      ],
                                    ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  cardColors.goldAccent
                                      ? const Color(0xFFFFE082)
                                      : Colors.white.withOpacity(0.3),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    cardColors.goldAccent
                                        ? const Color(
                                          0xFFD4AF37,
                                        ).withOpacity(0.5)
                                        : Colors.white.withOpacity(0.12),
                                blurRadius: cardColors.goldAccent ? 14 : 6,
                                spreadRadius: cardColors.goldAccent ? 1 : 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            cardColors.icon,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Description
                    Text(
                      plan.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Stats panel (no blur)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              cardColors.goldAccent
                                  ? const Color(0xFFD4AF37).withOpacity(0.4)
                                  : Colors.white.withOpacity(0.22),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat(
                            '${plan.totalDiscountPercentage}%',
                            'Savings',
                            cardColors.goldAccent,
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.white.withOpacity(0.22),
                          ),
                          _buildStat(
                            plan.allowsInstallments ? 'Yes' : 'No',
                            'EMI',
                            cardColors.goldAccent,
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.white.withOpacity(0.22),
                          ),
                          _buildStat(
                            '${plan.durationMonths}',
                            'Months',
                            cardColors.goldAccent,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CTA Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient:
                            cardColors.goldAccent
                                ? const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFFD4AF37),
                                    Color(0xFFEACB55),
                                    Color(0xFFD4AF37),
                                  ],
                                )
                                : null,
                        color: cardColors.goldAccent ? null : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                cardColors.goldAccent
                                    ? const Color(0xFFD4AF37).withOpacity(0.55)
                                    : Colors.black.withOpacity(0.12),
                            blurRadius: cardColors.goldAccent ? 18 : 8,
                            offset: const Offset(0, 3),
                            spreadRadius: cardColors.goldAccent ? 1 : 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Explore Plan',
                            style: TextStyle(
                              color:
                                  cardColors.goldAccent
                                      ? const Color(0xFF1A3010)
                                      : cardColors.gradient[0],
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color:
                                cardColors.goldAccent
                                    ? const Color(0xFF1A3010)
                                    : cardColors.gradient[0],
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Best Value floating banner
              if (isBestValue)
                Positioned(
                  top: 0,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66D4AF37),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.charcoal,
                          size: 11,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'BEST VALUE',
                          style: TextStyle(
                            color: AppColors.charcoal,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
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

  Widget _buildStat(String value, String label, bool goldAccent) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  _CardColors _getCardColors(
    SubscriptionPlan plan,
    bool isDark,
    bool isActive,
  ) {
    final isOneYear = plan.durationMonths == 12;

    if (isActive) {
      return _CardColors(
        gradient: [AppColors.deepSoilGreen, AppColors.deepSoilGreen],
        shadow: AppColors.deepSoilGreen,
        icon: Icons.eco_rounded,
        goldAccent: isOneYear,
      );
    } else {
      return _CardColors(
        gradient: [AppColors.rawEarth, AppColors.rawEarth],
        shadow: AppColors.rawEarth,
        icon: Icons.spa_rounded,
        goldAccent: isOneYear,
      );
    }
  }
}

class _CardColors {
  final List<Color> gradient;
  final Color shadow;
  final IconData icon;
  final bool goldAccent;

  _CardColors({
    required this.gradient,
    required this.shadow,
    required this.icon,
    this.goldAccent = false,
  });
}

// ================= POPUP DIALOG (Kept intact) =================

void showSubscriptionPopup({
  required BuildContext context,
  required List<SubscriptionPlan> allPlans,
  required SubscriptionPlan initialPlan,
  required Map<int, List<SubscriptionPlanProduct>> allProducts,
  required Map<int, bool> loadingProductsState,
  required Future<void> Function(int) loadProductsCallback,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Subscription Details',
    barrierColor: Colors.black.withOpacity(0.6),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) {
      return Stack(
        children: [
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        Theme.of(context).brightness == Brightness.dark
                            ? [
                              AppColors.darkSurface,
                              AppColors.darkSurfaceElevated,
                            ]
                            : [AppColors.parchment, AppColors.parchment],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: _SubscriptionPopupContent(
                    allPlans: allPlans,
                    initialPlan: initialPlan,
                    allProducts: allProducts,
                    loadingProductsState: loadingProductsState,
                    loadProductsCallback: loadProductsCallback,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: child,
        ),
      );
    },
  );
}

class _SubscriptionPopupContent extends StatefulWidget {
  final List<SubscriptionPlan> allPlans;
  final SubscriptionPlan initialPlan;
  final Map<int, List<SubscriptionPlanProduct>> allProducts;
  final Map<int, bool> loadingProductsState;
  final Future<void> Function(int) loadProductsCallback;

  const _SubscriptionPopupContent({
    required this.allPlans,
    required this.initialPlan,
    required this.allProducts,
    required this.loadingProductsState,
    required this.loadProductsCallback,
  });

  @override
  State<_SubscriptionPopupContent> createState() =>
      _SubscriptionPopupContentState();
}

class _SubscriptionPopupContentState extends State<_SubscriptionPopupContent> {
  late SubscriptionPlan _selectedPlan;
  String? _selectedProduct;
  late PageController _pageController;
  final ScrollController _scrollController = ScrollController();
  bool _isDropdownOpen = false;
  late List<SubscriptionPlan> _sortedPlans;

  @override
  void initState() {
    super.initState();
    _sortedPlans = List<SubscriptionPlan>.from(widget.allPlans)
      ..sort((a, b) => a.id.compareTo(b.id));
    _selectedPlan = widget.initialPlan;
    final initialIndex = _sortedPlans.indexOf(widget.initialPlan);
    _pageController = PageController(
      initialPage: initialIndex != -1 ? initialIndex : 0,
    );
    _loadProductsForPlan(_selectedPlan.id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProductsForPlan(int planId) async {
    if (!widget.allProducts.containsKey(planId) &&
        widget.loadingProductsState[planId] != true) {
      await widget.loadProductsCallback(planId);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.parchment : AppColors.charcoal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Close button
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, right: 12),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: textColor, size: 20),
              ),
            ),
          ),
        ),

        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _sortedPlans.length,
            onPageChanged: (index) {
              setState(() {
                _selectedPlan = _sortedPlans[index];
                _selectedProduct = null;
                _isDropdownOpen = false;
              });
              _loadProductsForPlan(_selectedPlan.id);
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(0);
              }
            },
            itemBuilder: (context, index) {
              final plan = _sortedPlans[index];
              final currentProducts = widget.allProducts[plan.id] ?? [];
              final areProductsLoading =
                  widget.loadingProductsState[plan.id] == true;

              return Column(
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      thickness: 3,
                      radius: const Radius.circular(4),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(24, 0, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan.name,
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        plan.description,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: textColor.withOpacity(0.85),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: textColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.eco_rounded,
                                    color: Color(0xFF2E7D32),
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Info cards
                            _buildInfoCard(
                              Icons.calendar_month_rounded,
                              'Duration',
                              '${plan.durationMonths} Months',
                              textColor,
                            ),
                            const SizedBox(height: 10),
                            _buildInfoCard(
                              Icons.payment_rounded,
                              'Installments',
                              plan.allowsInstallments
                                  ? 'Available'
                                  : 'Not Available',
                              textColor,
                            ),
                            const SizedBox(height: 10),
                            _buildInfoCard(
                              Icons.local_offer_rounded,
                              'Total Savings',
                              '${plan.totalDiscountPercentage}% Off',
                              textColor,
                            ),
                            const SizedBox(height: 10),
                            _buildInfoCard(
                              Icons.verified_rounded,
                              'Plan Type',
                              plan.isOneTimeOnly ? 'One-Time' : 'Recurring',
                              textColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Product selector
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      border: Border(
                        top: BorderSide(color: textColor.withOpacity(0.1)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 14,
                              decoration: BoxDecoration(
                                color: textColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Choose a Product',
                              style: TextStyle(
                                color: textColor.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Tap-to-expand selector bar
                        GestureDetector(
                          onTap: () {
                            if (areProductsLoading || currentProducts.isEmpty) {
                              return;
                            }
                            setState(() => _isDropdownOpen = !_isDropdownOpen);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    _isDropdownOpen
                                        ? textColor.withOpacity(0.6)
                                        : textColor.withOpacity(0.25),
                                width: 1.5,
                              ),
                              color:
                                  _isDropdownOpen
                                      ? textColor.withOpacity(0.18)
                                      : textColor.withOpacity(0.08),
                            ),
                            child: Column(
                              children: [
                                // Header row
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        color: textColor.withOpacity(0.8),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child:
                                            areProductsLoading
                                                ? Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: textColor,
                                                            strokeWidth: 2,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      'Loading products…',
                                                      style: TextStyle(
                                                        color: textColor
                                                            .withOpacity(0.6),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                                : Text(
                                                  _selectedProduct ??
                                                      (currentProducts.isEmpty
                                                          ? 'No products available'
                                                          : 'Tap to choose a product'),
                                                  style: TextStyle(
                                                    color:
                                                        _selectedProduct != null
                                                            ? textColor
                                                            : textColor
                                                                .withOpacity(
                                                                  0.6,
                                                                ),
                                                    fontSize: 14,
                                                    fontWeight:
                                                        _selectedProduct != null
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                  ),
                                                ),
                                      ),
                                      if (!areProductsLoading &&
                                          currentProducts.isNotEmpty)
                                        AnimatedRotation(
                                          turns: _isDropdownOpen ? 0.5 : 0,
                                          duration: const Duration(
                                            milliseconds: 250,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          child: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: textColor,
                                            size: 22,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Expandable product list
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  child:
                                      _isDropdownOpen
                                          ? ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  bottom: Radius.circular(13),
                                                ),
                                            child: Column(
                                              children: [
                                                Container(
                                                  height: 1,
                                                  color: textColor.withOpacity(
                                                    0.15,
                                                  ),
                                                ),
                                                ...currentProducts.asMap().entries.map((
                                                  entry,
                                                ) {
                                                  final i = entry.key;
                                                  final p = entry.value;
                                                  final isLast =
                                                      i ==
                                                      currentProducts.length -
                                                          1;
                                                  final isChosen =
                                                      _selectedProduct ==
                                                      p.productName;

                                                  return TweenAnimationBuilder<
                                                    double
                                                  >(
                                                    tween: Tween(
                                                      begin: 0,
                                                      end: 1,
                                                    ),
                                                    duration: Duration(
                                                      milliseconds:
                                                          200 + (i * 60),
                                                    ),
                                                    curve: Curves.easeOut,
                                                    builder: (
                                                      ctx,
                                                      value,
                                                      child,
                                                    ) {
                                                      return Transform.translate(
                                                        offset: Offset(
                                                          0,
                                                          (1 - value) * 10,
                                                        ),
                                                        child: Opacity(
                                                          opacity: value.clamp(
                                                            0,
                                                            1,
                                                          ),
                                                          child: child,
                                                        ),
                                                      );
                                                    },
                                                    child: GestureDetector(
                                                      onTap: () async {
                                                        HapticFeedback.selectionClick();
                                                        setState(() {
                                                          _selectedProduct =
                                                              p.productName;
                                                          _isDropdownOpen =
                                                              false;
                                                        });
                                                        try {
                                                          final product =
                                                              await CategoryService.fetchProductById(
                                                                p.productId,
                                                              );
                                                          if (!context
                                                              .mounted) {
                                                            return;
                                                          }
                                                          Navigator.push(
                                                            context,
                                                            AnimatedTransitions.fadeScale(
                                                              ProductDetailsScreen(
                                                                product:
                                                                    product,
                                                                autoOpenSubscription:
                                                                    true,
                                                                initialPlanId:
                                                                    _selectedPlan
                                                                        .id,
                                                              ),
                                                            ),
                                                          );
                                                        } catch (e) {
                                                          if (!context
                                                              .mounted) {
                                                            return;
                                                          }
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Failed to load product details.',
                                                              ),
                                                              backgroundColor:
                                                                  Colors.red,
                                                              duration:
                                                                  Duration(
                                                                    seconds: 2,
                                                                  ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      child: AnimatedContainer(
                                                        duration:
                                                            const Duration(
                                                              milliseconds: 200,
                                                            ),
                                                        color:
                                                            isChosen
                                                                ? textColor
                                                                    .withOpacity(
                                                                      0.18,
                                                                    )
                                                                : Colors
                                                                    .transparent,
                                                        child: Column(
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical:
                                                                        13,
                                                                  ),
                                                              child: Row(
                                                                children: [
                                                                  AnimatedContainer(
                                                                    duration: const Duration(
                                                                      milliseconds:
                                                                          200,
                                                                    ),
                                                                    width: 8,
                                                                    height: 8,
                                                                    decoration: BoxDecoration(
                                                                      shape:
                                                                          BoxShape
                                                                              .circle,
                                                                      color:
                                                                          isChosen
                                                                              ? textColor
                                                                              : textColor.withOpacity(
                                                                                0.3,
                                                                              ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 12,
                                                                  ),
                                                                  Expanded(
                                                                    child: Text(
                                                                      p.productName,
                                                                      style: TextStyle(
                                                                        color: textColor.withOpacity(
                                                                          isChosen
                                                                              ? 1.0
                                                                              : 0.85,
                                                                        ),
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            isChosen
                                                                                ? FontWeight.w700
                                                                                : FontWeight.w400,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  if (isChosen)
                                                                    const Icon(
                                                                      Icons
                                                                          .check_circle_rounded,
                                                                      color:
                                                                          Colors
                                                                              .white,
                                                                      size: 18,
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                            if (!isLast)
                                                              Container(
                                                                height: 1,
                                                                margin:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          16,
                                                                    ),
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                      0.08,
                                                                    ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                          )
                                          : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String label,
    String value,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: textColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
