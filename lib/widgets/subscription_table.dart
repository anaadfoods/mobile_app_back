import 'dart:ui';
import 'package:grocery_app/common_widgets/global_import.dart';

class SubscriptionTable extends StatefulWidget {
  final Function(SubscriptionPlan)? onPlanSelected;
  const SubscriptionTable({super.key, this.onPlanSelected});

  @override
  _SubscriptionTableState createState() => _SubscriptionTableState();
}

class _SubscriptionTableState extends State<SubscriptionTable> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  String? _error;
  static List<SubscriptionPlan>? _cachedPlans;
  static final Map<int, List<SubscriptionPlanProduct>> _cachedPlanProducts = {};
  final Map<int, List<SubscriptionPlanProduct>> _planProducts = {};
  final Map<int, bool> _loadingProducts = {};
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    // Moved _loadData to didChangeDependencies
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          } else {
            SnackBarHelper.showError(
              context,
              result['message'] ?? 'Failed to load products',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error loading products: $e');
      }
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // Responsive Carousel Height based on screen size
    // Small phones: 55% of height, larger screens: 50%
    final isCompactHeight = size.height < 700;
    final heightFraction = isCompactHeight ? 0.55 : 0.50;
    final double carouselHeight = (size.height * heightFraction).clamp(
      380.0,
      580.0,
    );

    if (_isLoading) {
      return Center(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: AppColors.animMedium),
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null) {
      return _buildErrorState(theme);
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: CarouselSlider.builder(
        itemCount: _plans.length,
        itemBuilder: (context, index, realIndex) {
          final plan = _plans[index];
          final isSelected = (index == _currentIndex);
          return _buildPlanCard(
            plan,
            context,
            isSelected: isSelected,
            theme: theme,
          );
        },
        options: CarouselOptions(
          height: carouselHeight,
          viewportFraction:
              size.width < 400 ? 0.92 : 0.85, // Fuller width on small screens
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 5),
          enlargeCenterPage: true,
          enlargeFactor:
              size.width < 400
                  ? 0.15
                  : 0.18, // Smaller enlarge on compact screens
          enableInfiniteScroll: true,
          initialPage: 1,
          onPageChanged: (index, reason) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _error ?? 'An error occurred',
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSubscriptionPlans,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    SubscriptionPlan plan,
    BuildContext context, {
    required bool isSelected,
    required ThemeData theme,
  }) {
    final textTheme = theme.textTheme;
    final size = MediaQuery.of(context).size;

    // Multi-tier responsive breakpoints
    final isExtraSmall = size.width < 320;
    final isSmallScreen = size.width < 380;
    final isCompactHeight = size.height < 700;

    // Dynamic spacing based on screen size
    final basePadding = isExtraSmall ? 12.0 : (isSmallScreen ? 16.0 : 20.0);
    final verticalMargin =
        isCompactHeight ? size.height * 0.01 : size.height * 0.012;

    // Design Tokens based on Mockups
    final backgroundColor =
        isSelected
            ? const Color(0xFF355E3B)
            : Colors.white; // Hunter Green vs White
    final primaryTextColor = isSelected ? Colors.white : Colors.black;
    final secondaryTextColor =
        isSelected
            ? Colors.white.withOpacity(0.8)
            : Colors.black.withOpacity(0.6);
    final borderColor =
        isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2);
    final buttonBorderColor = isSelected ? Colors.white : Colors.black;
    final buttonTextColor = isSelected ? Colors.white : Colors.black;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 4 : 8,
        vertical: verticalMargin,
      ),
      padding: EdgeInsets.all(basePadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Title + Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.name,
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        isExtraSmall
                                            ? 16
                                            : (isSmallScreen ? 18 : null),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: isSmallScreen ? 4 : 8),
                                Text(
                                  plan.description,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: secondaryTextColor,
                                    height: 1.3,
                                    fontSize:
                                        isExtraSmall
                                            ? 10
                                            : (isSmallScreen ? 11 : 12),
                                  ),
                                  maxLines: isCompactHeight ? 2 : 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius:
                                isExtraSmall ? 20 : (isSmallScreen ? 22 : 26),
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.eco_rounded,
                              color: const Color(0xFF355E3B),
                              size:
                                  isExtraSmall ? 20 : (isSmallScreen ? 22 : 28),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isCompactHeight ? 12 : 20),

                      // Action Button "Know More ->"
                      OutlinedButton(
                        onPressed: () {
                          showSubscriptionPopup(
                            context: context,
                            allPlans: _plans,
                            initialPlan: plan,
                            allProducts: _planProducts,
                            loadingProductsState: _loadingProducts,
                            loadProductsCallback: _loadPlanProducts,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: buttonBorderColor),
                          foregroundColor: buttonTextColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: isSmallScreen ? 8 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Know More",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: isSmallScreen ? 14 : 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Divider (now part of the scrollable flow)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isCompactHeight ? 12 : 16,
                    ),
                    child: Divider(color: secondaryTextColor.withOpacity(0.2)),
                  ),

                  // Details Section
                  Column(
                    children: [
                      _StyledInfoRow(
                        icon: Icons.check_circle,
                        label: "Duration",
                        value: "${plan.durationMonths} Months",
                        textColor: primaryTextColor,
                        pillColor:
                            isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                        isSmallScreen: isSmallScreen,
                        isExtraSmall: isExtraSmall,
                      ),
                      SizedBox(height: isCompactHeight ? 6 : 10),
                      _StyledInfoRow(
                        icon: Icons.check_circle,
                        label: "Installments",
                        value: plan.allowsInstallments ? "Yes" : "No",
                        textColor: primaryTextColor,
                        pillColor:
                            isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                        isSmallScreen: isSmallScreen,
                        isExtraSmall: isExtraSmall,
                      ),
                      SizedBox(height: isCompactHeight ? 6 : 10),
                      _StyledInfoRow(
                        icon: Icons.check_circle,
                        label: "Savings",
                        value: "${plan.totalDiscountPercentage}% off",
                        textColor: primaryTextColor,
                        pillColor:
                            isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                        isSmallScreen: isSmallScreen,
                        isExtraSmall: isExtraSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StyledInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textColor;
  final Color pillColor;
  final bool isSmallScreen;
  final bool isExtraSmall;

  const _StyledInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
    required this.pillColor,
    this.isSmallScreen = false,
    this.isExtraSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isExtraSmall ? 14.0 : (isSmallScreen ? 16.0 : 18.0);
    final labelFontSize = isExtraSmall ? 11.0 : (isSmallScreen ? 12.0 : 14.0);
    final pillPaddingH = isExtraSmall ? 8.0 : (isSmallScreen ? 10.0 : 14.0);
    final pillPaddingV = isExtraSmall ? 4.0 : (isSmallScreen ? 5.0 : 7.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isExtraSmall ? 1 : (isSmallScreen ? 2 : 4),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: iconSize),
          SizedBox(width: isExtraSmall ? 6 : (isSmallScreen ? 8 : 12)),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: labelFontSize,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: AppColors.animFast),
            padding: EdgeInsets.symmetric(
              horizontal: pillPaddingH,
              vertical: pillPaddingV,
            ),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: textColor.withOpacity(0.1), width: 1),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: isExtraSmall ? 10 : 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) {
      return Stack(
        children: [
          // Blurred Background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Centered Dialog
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF355E3B), // Match the card Green
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
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
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProducts = widget.allProducts[_selectedPlan.id] ?? [];
    final areProductsLoading =
        widget.loadingProductsState[_selectedPlan.id] == true;

    // We use a Column with [Flexible] for the scrollable area
    // This allows the modal to shrink-wrap content but scroll if it exceeds constraints.
    return Column(
      mainAxisSize: MainAxisSize.min, // Shrink to fit content
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPlan.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold, // Headline
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedPlan.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: const Icon(
                        Icons.eco_rounded,
                        color: Color(0xFF355E3B),
                        size: 36,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 20),

                _StyledInfoRow(
                  icon: Icons.check_circle,
                  label: "Duration",
                  value: "${_selectedPlan.durationMonths} Months",
                  textColor: Colors.white,
                  pillColor: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(height: 12),
                _StyledInfoRow(
                  icon: Icons.check_circle,
                  label: "Allows Installments",
                  value: _selectedPlan.allowsInstallments ? "Yes" : "No",
                  textColor: Colors.white,
                  pillColor: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(height: 12),
                _StyledInfoRow(
                  icon: Icons.check_circle,
                  label: "One-Time Allowance",
                  value: _selectedPlan.isOneTimeOnly ? "Yes" : "No",
                  textColor: Colors.white,
                  pillColor: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(height: 12),
                _StyledInfoRow(
                  icon: Icons.check_circle,
                  label: "Savings",
                  value:
                      "${_selectedPlan.totalDiscountPercentage}% Discount 🔥",
                  textColor: Colors.white,
                  pillColor: Colors.white.withOpacity(0.2),
                ),
              ],
            ),
          ),
        ),

        // Product Selector Pinned to Bottom
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(
              0xFF2C4E31,
            ), // Slightly darker green for footer area
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
              color: Colors.transparent,
            ),
            child:
                areProductsLoading
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
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
                        dropdownColor: const Color(0xFF355E3B),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                        hint: Text(
                          currentProducts.isEmpty
                              ? "No products available"
                              : "Select Product",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        items:
                            currentProducts.map((p) {
                              return DropdownMenuItem<String>(
                                value: p.productName,
                                child: Text(
                                  p.productName,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onTap: () async {
                                  // Navigate to product details
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
                        onChanged:
                            currentProducts.isEmpty
                                ? null
                                : (val) {
                                  setState(() {
                                    _selectedProduct = val;
                                  });
                                },
                      ),
                    ),
          ),
        ),
      ],
    );
  }
}
