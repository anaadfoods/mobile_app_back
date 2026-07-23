import 'dart:math' as math;
import "package:grocery_app/common_widgets/global_import.dart";
import "package:grocery_app/common_widgets/select_state.dart";
import "package:http/http.dart" as http;

enum OrderType { self, other }

class AddressSelectionScreen extends StatefulWidget {
  final CartModel? cart;
  final Product? singleProduct;
  final String? paymentType;
  final double? price;
  final int? quantity;
  final bool isSubscription;
  final int? selectedPlan;
  final UserModel? user = getIt<TokenService>().currentUser;

  AddressSelectionScreen({
    super.key,
    this.cart,
    this.price,
    this.singleProduct,
    this.quantity,
    this.isSubscription = false,
    this.selectedPlan,
    this.paymentType,
  }) : assert(cart != null || (singleProduct != null && quantity != null));

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _deliveryDetails;
  Map<String, String>? _savedAddress;
  String? _missingPhoneError;

  OrderType _orderType = OrderType.self;
  String _selectedAddressType = 'new';

  // Animation Controllers
  late AnimationController _headerController;
  late AnimationController _contentController;
  late AnimationController _particleController;

  late Animation<double> _headerSlide;
  late Animation<double> _headerFade;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _pincodeController.addListener(_onPincodeChanged);
    _loadSavedAddress();
    if (widget.user != null) {
      _nameController.text =
          "${widget.user!.firstName} ${widget.user!.lastName}".trim();
    }
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

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _headerSlide = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.removeListener(_onPincodeChanged);
    _pincodeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _headerController.dispose();
    _contentController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _onPincodeChanged() {
    final pincode = _pincodeController.text.trim();
    if (pincode.length == 6 && RegExp(r'^\d{6}$').hasMatch(pincode)) {
      _calculateDeliveryCharges(pincode);
    } else {
      setState(() {
        _deliveryDetails = null;
        _error = null;
      });
    }
  }

  void _loadSavedAddress() {
    final user = widget.user;
    if (user != null &&
        (user.address?.isNotEmpty ?? false) &&
        (user.city?.isNotEmpty ?? false) &&
        (user.state?.isNotEmpty ?? false) &&
        (user.pincode?.isNotEmpty ?? false)) {
      _savedAddress = {
        'address': user.address!,
        'city': user.city!,
        'state': user.state!,
        'pincode': user.pincode!,
        'phone': user.phoneNumber,
        'name': "${user.firstName} ${user.lastName}".trim(),
      };
      _selectedAddressType = 'saved';
      _selectAddress(_savedAddress!);
    } else {
      _selectedAddressType = 'new';
      _clearAddressForm();
      if (user != null) {
        _nameController.text = "${user.firstName} ${user.lastName}".trim();
      }
    }
    setState(() {});
  }

  Future<void> _calculateDeliveryCharges(String pincode) async {
    if (pincode.length != 6) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Build items list - either single product or all cart items
      final List<Map<String, dynamic>> items;

      if (widget.singleProduct != null) {
        // Single product purchase
        items = [
          {'product_variant_id': widget.singleProduct!.id},
        ];
      } else if (widget.cart != null && widget.cart!.items.isNotEmpty) {
        // Cart with multiple products - map all items
        items =
            widget.cart!.items
                .map((item) => {'product_variant_id': item.productVariant.id})
                .toList();
      } else {
        throw Exception(
          'No product variant found to calculate delivery charges.',
        );
      }

      final Map<String, dynamic> requestPayload = {
        'delivery_pincode': pincode,
        'items': items,
        'is_subscription_checkout': widget.isSubscription,
      };

      if (widget.isSubscription && widget.selectedPlan != null) {
        requestPayload['plan_id'] = widget.selectedPlan;
      }

      final body = jsonEncode(requestPayload);

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/core/delivery/calculate-charges/'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        setState(() {
          _deliveryDetails = jsonDecode(response.body) as Map<String, dynamic>?;
          _error = null;
        });
      } else {
        final errorBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : null;
        throw Exception(
          (errorBody is Map && errorBody['error'] != null)
              ? errorBody['error']
              : 'Failed to calculate delivery charges',
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _deliveryDetails = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      } else {
        _isLoading = false;
      }
    }
  }

  void _selectAddress(Map<String, String> address) {
    setState(() {
      _addressController.text = address['address'] ?? '';
      _cityController.text = address['city'] ?? '';
      _stateController.text = address['state'] ?? '';
      _pincodeController.text = address['pincode'] ?? '';
      _phoneController.text = address['phone'] ?? '';
      if (address.containsKey('name')) {
        _nameController.text = address['name'] ?? '';
      }
    });

    final pincode = (address['pincode'] ?? '').trim();
    if (pincode.length == 6 && RegExp(r'^\d{6}$').hasMatch(pincode)) {
      _calculateDeliveryCharges(pincode);
    } else {
      setState(() {
        _deliveryDetails = null;
      });
    }
  }

  void _clearAddressForm() {
    _formKey.currentState?.reset();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _pincodeController.clear();
    _phoneController.clear();
    _nameController.clear();
    setState(() {
      _deliveryDetails = null;
      _error = null;
    });
  }

  Future<bool> _updateUserAddress(Map<String, String> addressDetails) async {
    setState(() => _isLoading = true);

    // Use AuthCubit to update address - this emits state changes that
    // all screens listening to the cubit can react to
    final success = await context.read<AuthCubit>().updateUserAddress(
      addressDetails,
    );

    if (!mounted) return success;
    setState(() => _isLoading = false);

    if (!success && mounted) {
      SnackBarHelper.showInfo(
        context,
        'Proceeding with checkout using this address (not saved to profile).',
      );
    } else if (success && mounted) {
      SnackBarHelper.showSuccess(context, 'Address saved to your profile!');
    }
    return success;
  }

  void _onContinuePressed() async {
    HapticFeedback.mediumImpact();

    if ((_orderType == OrderType.other ||
            (_orderType == OrderType.self && _selectedAddressType == 'new')) &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_orderType == OrderType.self && _selectedAddressType == 'saved') {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        setState(() {
          _missingPhoneError = 'Phone number is required';
        });
        return;
      } else if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
        setState(() {
          _missingPhoneError = 'Phone number must be exactly 10 digits';
        });
        return;
      } else {
        setState(() {
          _missingPhoneError = null;
        });
      }
    }

    if (_deliveryDetails == null) {
      SnackBarHelper.showError(
        context,
        'Please enter a valid pincode to check delivery.',
      );
      return;
    }

    final shippingDetails = {
      'address': _addressController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'pincode': _pincodeController.text,
      'phone': _phoneController.text,
      'name': _nameController.text,
    };

    if (_orderType == OrderType.self && _selectedAddressType == 'new') {
      await _updateUserAddress(shippingDetails);
    }

    _navigateToCheckout(shippingDetails);
  }

  String _getDefaultDeliveryDate() {
    final defaultDate = DateTime.now().add(const Duration(days: 3));
    return '${defaultDate.year}-${defaultDate.month.toString().padLeft(2, '0')}-${defaultDate.day.toString().padLeft(2, '0')}';
  }

  String _formatDeliveryDate(String? date) {
    if (date == null || date.isEmpty) {
      return _getDefaultDeliveryDate();
    }

    try {
      // Normalize separators
      String normalizedDate = date.replaceAll('/', '-');
      List<String> parts = normalizedDate.split('-');

      if (parts.length == 3) {
        String day, month, year;

        // Check if format is YYYY-MM-DD (year is first)
        if (parts[0].length == 4) {
          year = parts[0];
          month = parts[1];
          day = parts[2];
        } else {
          // Assume DD-MM-YYYY
          day = parts[0];
          month = parts[1];
          year = parts[2];
        }

        // Handle time part if present in the last segment (e.g. "2026 10:00")
        if (year.contains(' ')) {
          year = year.split(' ')[0];
        }
        if (day.contains(' ')) {
          // In case of YYYY-MM-DD HH:MM where day is last
          day = day.split(' ')[0];
        }

        // Fix 2-digit years (e.g. "32" -> "2032")
        // Also fix "0032" if it was already parsed incorrectly previously
        int yearInt = int.tryParse(year) ?? DateTime.now().year;
        if (yearInt < 100) {
          yearInt += 2000;
        }
        year = yearInt.toString();

        // Pad day and month
        day = day.padLeft(2, '0');
        month = month.padLeft(2, '0');

        return '$year-$month-$day';
      }
    } catch (e) {
      // Fallback to default if parsing totally fails
    }

    return _getDefaultDeliveryDate();
  }

  void _navigateToCheckout(Map<String, String> shippingDetails) {
    double codCharge = 0.0;
    double prepaidCharge = 0.0;

    final charges = _deliveryDetails?['delivery_charges'];
    if (charges is Map) {
      codCharge = double.tryParse(charges['cod']?.toString() ?? '0') ?? 0.0;
      prepaidCharge =
          double.tryParse(charges['prepaid']?.toString() ?? '0') ?? 0.0;
    } else if (charges != null) {
      codCharge = double.tryParse(charges.toString()) ?? 0.0;
      prepaidCharge = codCharge;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CheckoutScreen(
              cart: widget.cart,
              singleProduct: widget.singleProduct,
              price: widget.price,
              quantity: widget.quantity,
              isSubscription: widget.isSubscription,
              selectedPlan: widget.selectedPlan,
              shippingDetails: shippingDetails,
              codDeliveryCharge: codCharge,
              prepaidDeliveryCharge: prepaidCharge,
              expectedDeliveryDate: _formatDeliveryDate(
                _deliveryDetails?['expected_delivery_date'],
              ),
              paymentType: widget.paymentType,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Animated Header
              _buildAnimatedHeader(theme, isDark),

              // Content
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _contentController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - _contentFade.value)),
                      child: Opacity(opacity: _contentFade.value, child: child),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildOrderTypeSelector(theme),
                        const SizedBox(height: 20),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child:
                              _orderType == OrderType.self
                                  ? Column(
                                    key: const ValueKey('self'),
                                    children: [
                                      if (_savedAddress != null) ...[
                                        _buildSavedAddressCard(theme, isDark),
                                        if (_selectedAddressType == 'saved' &&
                                            (_savedAddress!['phone'] == null ||
                                                _savedAddress!['phone']!
                                                    .isEmpty)) ...[
                                          const SizedBox(height: 16),
                                          _buildMissingPhoneField(
                                            theme,
                                            isDark,
                                          ),
                                        ],
                                      ],
                                      _buildNewAddressOption(
                                        theme,
                                        isDark,
                                        isForSelf: true,
                                      ),
                                      if (_selectedAddressType == 'new')
                                        _buildNewAddressForm(
                                          theme,
                                          isDark,
                                          isForSelf: true,
                                        ),
                                    ],
                                  )
                                  : Column(
                                    key: const ValueKey('other'),
                                    children: [
                                      _buildNewAddressForm(
                                        theme,
                                        isDark,
                                        isForSelf: false,
                                      ),
                                    ],
                                  ),
                        ),
                        if (_error != null) _buildErrorMessage(theme),
                        if (_deliveryDetails != null)
                          _buildDeliveryDetailsCard(theme, isDark),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Continue Button
          _buildBottomButton(theme, isDark),

          // Loading Overlay
          if (_isLoading) _buildLoadingOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _headerController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _headerSlide.value),
            child: Opacity(opacity: _headerFade.value, child: child),
          );
        },
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.harvestAmber,
                AppColors.harvestAmber.withValues(alpha: 0.85),
                isDark
                    ? AppColors.harvestAmber.withValues(alpha: 0.7)
                    : AppColors.harvestAmber,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.harvestAmber.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.parchment.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: -40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.parchment.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // Header Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      // Title Row
                      Row(
                        children: [
                          // Back button
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.parchment,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.maybePop(context),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Delivery Address",
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: AppColors.parchment,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Where should we deliver your order?",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.parchment.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.parchment.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.amberWarnBg,
                              size: 24,
                            ),
                          ),
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

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.parchment.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.harvestAmber, size: 22),
        ),
      ),
    );
  }

  Widget _buildOrderTypeSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: _buildOrderTypeButton(
              theme,
              OrderType.self,
              'For Myself',
              Icons.person_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildOrderTypeButton(
              theme,
              OrderType.other,
              'For Someone Else',
              Icons.card_giftcard_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeButton(
    ThemeData theme,
    OrderType type,
    String label,
    IconData icon,
  ) {
    final isSelected = _orderType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _orderType = type;
          if (_orderType == OrderType.self) {
            _loadSavedAddress();
          } else {
            _selectedAddressType = 'new';
            _clearAddressForm();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.harvestAmber : AppColors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.parchment : AppColors.harvestAmber,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.parchment : theme.hintColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedAddressCard(ThemeData theme, bool isDark) {
    if (_savedAddress == null) return const SizedBox.shrink();

    final isSelected = _selectedAddressType == 'saved';
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedAddressType = 'saved';
          if (_savedAddress != null) _selectAddress(_savedAddress!);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.harvestAmber
                    : isDark
                    ? AppColors.charcoal87
                    : AppColors.parchment,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
                      ? AppColors.harvestAmber.withValues(alpha: 0.15)
                      : theme.shadowColor.withValues(alpha: 0.06),
              blurRadius: isSelected ? 16 : 8,
              offset: Offset(0, isSelected ? 6 : 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Selection Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? AppColors.harvestAmber : AppColors.transparent,
                border: Border.all(
                  color:
                      isSelected
                          ? AppColors.harvestAmber
                          : theme.hintColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? const Icon(
                        Icons.check,
                        color: AppColors.parchment,
                        size: 16,
                      )
                      : null,
            ),
            const SizedBox(width: 16),
            // Address Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.harvestAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.home_rounded,
                color: AppColors.harvestAmber,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Address Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Saved Address',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.harvestAmber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Default',
                          style: TextStyle(
                            color: AppColors.harvestAmber,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_savedAddress!['address']}, ${_savedAddress!['city']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_savedAddress!['state']} - ${_savedAddress!['pincode']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewAddressOption(
    ThemeData theme,
    bool isDark, {
    required bool isForSelf,
  }) {
    final isSelected = _selectedAddressType == 'new';
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedAddressType = 'new';
          _clearAddressForm();
          if (isForSelf && widget.user != null) {
            _nameController.text =
                "${widget.user!.firstName} ${widget.user!.lastName}".trim();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.harvestAmber
                    : isDark
                    ? AppColors.charcoal87
                    : AppColors.parchment,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
                      ? AppColors.harvestAmber.withValues(alpha: 0.15)
                      : theme.shadowColor.withValues(alpha: 0.06),
              blurRadius: isSelected ? 16 : 8,
              offset: Offset(0, isSelected ? 6 : 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Selection Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? AppColors.harvestAmber : AppColors.transparent,
                border: Border.all(
                  color:
                      isSelected
                          ? AppColors.harvestAmber
                          : theme.hintColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? const Icon(
                        Icons.check,
                        color: AppColors.parchment,
                        size: 16,
                      )
                      : null,
            ),
            const SizedBox(width: 16),
            // Add Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.harvestAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add_location_alt_rounded,
                color: AppColors.harvestAmber,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Label
            Expanded(
              child: Text(
                isForSelf ? 'Add & Save New Address' : 'Add New Address',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: theme.hintColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingPhoneField(ThemeData theme, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.harvestAmber, width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We need your phone number',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.harvestAmber,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (v) {
              setState(() {
                if (v.trim().isEmpty) {
                  _missingPhoneError = 'Phone number is required';
                } else if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) {
                  _missingPhoneError = 'Phone number must be exactly 10 digits';
                } else {
                  _missingPhoneError = null;
                }
              });
            },
            decoration: InputDecoration(
              errorText: _missingPhoneError,
              hintText: 'Enter 10-digit phone number',
              prefixIcon: const Icon(
                Icons.phone_rounded,
                color: AppColors.harvestAmber,
              ),
              filled: true,
              fillColor:
                  isDark
                      ? AppColors.parchment.withValues(alpha: 0.05)
                      : AppColors.parchment,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.6),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.harvestAmber,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 1.5,
                ),
              ),
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewAddressForm(
    ThemeData theme,
    bool isDark, {
    bool isForSelf = true,
  }) {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_location_alt_rounded,
                  color: AppColors.harvestAmber,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isForSelf ? 'New Address' : "Recipient's Address",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildModernInput(
              theme,
              isDark,
              controller: _nameController,
              label: isForSelf ? 'Full Name' : "Recipient's Name",
              hint:
                  isForSelf
                      ? 'Enter your full name'
                      : "Enter recipient's full name",
              icon: Icons.person_outline_rounded,
              validator:
                  (v) =>
                      v == null || v.trim().isEmpty
                          ? (isForSelf
                              ? 'Name is required'
                              : "Recipient's name is required")
                          : null,
            ),
            const SizedBox(height: 16),
            _buildModernInput(
              theme,
              isDark,
              controller: _addressController,
              label: isForSelf ? 'Full Address' : "Recipient's Address",
              hint:
                  isForSelf
                      ? 'House No, Street, Landmark'
                      : "Recipient's House No, Street, Landmark",
              icon: Icons.home_work_rounded,
              validator:
                  (v) =>
                      v == null || v.trim().isEmpty
                          ? (isForSelf
                              ? 'Address is required'
                              : "Recipient's address is required")
                          : null,
            ),
            const SizedBox(height: 16),
            SelectState(
              key: const ValueKey('address_select_state'),
              onCountryChanged: (_) {},
              onStateChanged:
                  (v) => setState(() => _stateController.text = v ?? ''),
              onCityChanged:
                  (v) => setState(() => _cityController.text = v ?? ''),
              initialState:
                  _stateController.text.isNotEmpty
                      ? _stateController.text
                      : null,
              initialCity:
                  _cityController.text.isNotEmpty ? _cityController.text : null,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _buildModernInput(
              theme,
              isDark,
              controller: _pincodeController,
              label: 'Pincode',
              hint: '6 digits',
              icon: Icons.pin_drop_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                  return 'Pincode must be exactly 6 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildModernInput(
              theme,
              isDark,
              controller: _phoneController,
              label: isForSelf ? 'Phone Number' : "Recipient's Phone Number",
              hint:
                  isForSelf
                      ? '10 digit mobile number'
                      : "10 digit mobile number of recipient",
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) {
                  return 'Phone number must be exactly 10 digits';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                FocusScope.of(context).unfocus();
                _onContinuePressed();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInput(
    ThemeData theme,
    bool isDark, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, color: AppColors.harvestAmber, size: 22),
            filled: true,
            fillColor: isDark ? AppColors.charcoal : AppColors.parchment,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.charcoal87 : AppColors.parchment,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.harvestAmber, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.colorScheme.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDetailsCard(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.harvestAmber.withValues(alpha: 0.1),
            AppColors.harvestAmber.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.harvestAmber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.harvestAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.harvestAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Delivery Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildDeliveryChargesItem(theme)),
              Container(
                width: 1,
                height: 50,
                color: AppColors.harvestAmber.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildDeliveryInfoItem(
                  theme,
                  Icons.calendar_month_rounded,
                  'Expected Delivery',
                  ApiConfig.showExpectedDeliveryDate
                      ? (_deliveryDetails?['expected_delivery_date'] ?? 'N/A')
                      : ApiConfig.alternativeDeliveryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoItem(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppColors.harvestAmber, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.harvestAmber,
            fontSize: 12, // Reduced size
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }

  Widget _buildDeliveryChargesItem(ThemeData theme) {
    final charges = _deliveryDetails?['delivery_charges'];
    String codCharge = '0';
    String prepaidCharge = '0';

    if (charges is Map) {
      codCharge = (charges['cod'] ?? 0).toString();
      prepaidCharge = (charges['prepaid'] ?? 0).toString();
    } else if (charges != null) {
      // Fallback if it's a single value
      codCharge = charges.toString();
      prepaidCharge = charges.toString();
    }

    return Column(
      children: [
        Icon(Icons.payments_rounded, color: AppColors.harvestAmber, size: 24),
        const SizedBox(height: 8),
        Text(
          'Delivery Charges',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'COD: ₹$codCharge',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.harvestAmber,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          'Prepaid: ₹$prepaidCharge',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.harvestAmber,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomButton(ThemeData theme, bool isDark) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : AppColors.parchment,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onContinuePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.harvestAmber,
                foregroundColor: AppColors.parchment,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedAddressType == 'new'
                        ? 'Save Address & Continue'
                        : 'Continue to Checkout',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.parchment.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme) {
    return Container(
      color: AppColors.charcoal.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.harvestAmber),
              const SizedBox(height: 16),
              Text('Processing...', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
