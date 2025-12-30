import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

class SubscriptionTable extends StatefulWidget {
  final Function(SubscriptionPlan)? onPlanSelected;
  const SubscriptionTable({super.key, this.onPlanSelected});

  @override
  _SubscriptionTableState createState() => _SubscriptionTableState();
}

class _SubscriptionTableState extends State<SubscriptionTable>
    with SingleTickerProviderStateMixin {
  final SubscriptionService _subscriptionService = SubscriptionService();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_cachedPlans != null && _cachedPlans!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _plans = _cachedPlans!;
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
            _plans = result['data'] as List<SubscriptionPlan>;
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
      final result = await _subscriptionService.getSubscriptionPlanProducts(planId);
      if (mounted) {
        if (result['success']) {
          final response = result['data'] as SubscriptionPlanProductsResponse;
          setState(() {
            _planProducts[planId] = response.products;
            _cachedPlanProducts[planId] = response.products;
          });
        } else {
          if (result['requiresLogin'] == true) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
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
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: child,
                        ),
                      ),
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
              color: AppColors.primaryColor,
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
          Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Failed to load',
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_plans.length, (index) {
        final isActive = index == _currentIndex;
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
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive
                  ? AppColors.primaryColor
                  : (isDark ? Colors.white24 : Colors.black12),
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
    // Card colors based on plan type
    final cardColors = _getCardColors(plan, isDark);

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
              color: cardColors.shadow.withOpacity(isActive ? 0.4 : 0.2),
              blurRadius: isActive ? 24 : 16,
              offset: const Offset(0, 8),
              spreadRadius: isActive ? 2 : 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
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
                              // Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${plan.durationMonths} MONTHS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Plan name
                              Text(
                                plan.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            cardColors.icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Text(
                      plan.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Stats row
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat(
                            '${plan.totalDiscountPercentage}%',
                            'Savings',
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          _buildStat(
                            plan.allowsInstallments ? 'Yes' : 'No',
                            'EMI',
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          _buildStat(
                            '${plan.durationMonths}',
                            'Months',
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Explore Plan',
                            style: TextStyle(
                              color: cardColors.gradient[0],
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: cardColors.gradient[0],
                            size: 18,
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

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  _CardColors _getCardColors(SubscriptionPlan plan, bool isDark) {
    // Assign different gradients based on plan index
    final index = _plans.indexOf(plan);
    switch (index % 4) {
      case 0:
        return _CardColors(
          gradient: [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
          shadow: const Color(0xFF2E7D32),
          icon: Icons.eco_rounded,
        );
      case 1:
        return _CardColors(
          gradient: [const Color(0xFF1565C0), const Color(0xFF0D47A1)],
          shadow: const Color(0xFF1565C0),
          icon: Icons.water_drop_rounded,
        );
      case 2:
        return _CardColors(
          gradient: [const Color(0xFFE65100), const Color(0xFFBF360C)],
          shadow: const Color(0xFFE65100),
          icon: Icons.local_fire_department_rounded,
        );
      case 3:
      default:
        return _CardColors(
          gradient: [const Color(0xFF6A1B9A), const Color(0xFF4A148C)],
          shadow: const Color(0xFF6A1B9A),
          icon: Icons.auto_awesome_rounded,
        );
    }
  }
}

class _CardColors {
  final List<Color> gradient;
  final Color shadow;
  final IconData icon;

  _CardColors({
    required this.gradient,
    required this.shadow,
    required this.icon,
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
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.transparent),
            ),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
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

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.initialPlan;
    _loadProductsForPlan(_selectedPlan.id);
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
    final currentProducts = widget.allProducts[_selectedPlan.id] ?? [];
    final areProductsLoading =
        widget.loadingProductsState[_selectedPlan.id] == true;

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
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),

        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPlan.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedPlan.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.85),
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
                        color: Colors.white,
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
                  '${_selectedPlan.durationMonths} Months',
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  Icons.payment_rounded,
                  'Installments',
                  _selectedPlan.allowsInstallments ? 'Available' : 'Not Available',
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  Icons.local_offer_rounded,
                  'Total Savings',
                  '${_selectedPlan.totalDiscountPercentage}% Off',
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  Icons.verified_rounded,
                  'Plan Type',
                  _selectedPlan.isOneTimeOnly ? 'One-Time' : 'Recurring',
                ),
              ],
            ),
          ),
        ),

        // Product selector
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Product',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  color: Colors.white.withOpacity(0.1),
                ),
                child: areProductsLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedProduct,
                          dropdownColor: const Color(0xFF2E7D32),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                          ),
                          hint: Text(
                            currentProducts.isEmpty
                                ? 'No products available'
                                : 'Choose a product',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          items: currentProducts.map((p) {
                            return DropdownMenuItem<String>(
                              value: p.productName,
                              child: Text(
                                p.productName,
                                style: const TextStyle(color: Colors.white),
                              ),
                              onTap: () async {
                                final product =
                                    await CategoryService.fetchProductById(
                                  p.productId,
                                );
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  AnimatedTransitions.fadeScale(
                                    ProductDetailsScreen(product: product),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                          onChanged: currentProducts.isEmpty
                              ? null
                              : (val) {
                                  setState(() {
                                    _selectedProduct = val;
                                  });
                                },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
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
