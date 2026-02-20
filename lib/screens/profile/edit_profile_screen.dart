import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/common_widgets/select_state.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel userProfile;
  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  File? _selectedImage;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _shimmerController;
  late AnimationController _avatarBorderController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Subscription for address changes
  StreamSubscription<UserModel?>? _addressSubscription;

  @override
  void initState() {
    super.initState();
    _initTextControllers();
    _initAnimations();
    _listenToAddressChanges();
  }

  /// Listen for address updates from other parts of the app
  void _listenToAddressChanges() {
    // Listen to the stream for backwards compatibility
    _addressSubscription = AuthService.addressChanges.listen((user) {
      _updateAddressFields(user);
    });
  }

  /// Updates form fields with the user's address data
  void _updateAddressFields(UserModel? user) {
    if (user != null && mounted) {
      setState(() {
        _addressController.text = user.address ?? '';
        _cityController.text = user.city ?? '';
        _stateController.text = user.state ?? '';
        _pincodeController.text = user.pincode ?? '';
        _phoneController.text = user.phoneNumber;
      });
    }
  }

  void _initTextControllers() {
    // Prefer the latest user data from AuthService (in case address was updated)
    final user = AuthService().currentUser ?? widget.userProfile;

    _firstNameController = TextEditingController(text: user.firstName ?? "");
    _lastNameController = TextEditingController(text: user.lastName ?? "");
    _usernameController = TextEditingController(text: user.username ?? "");
    _emailController = TextEditingController(text: user.email);
    _phoneController = TextEditingController(text: user.phoneNumber);
    _addressController = TextEditingController(text: user.address ?? '');
    _cityController = TextEditingController(text: user.city ?? '');
    _stateController = TextEditingController(text: user.state ?? '');
    _pincodeController = TextEditingController(text: user.pincode ?? '');
  }

  void _initAnimations() {
    // Main entrance animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Shimmer animation for header
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _shimmerController.repeat();

    // Avatar border rotation
    _avatarBorderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _avatarBorderController.repeat();

    _animationController.forward();
  }

  @override
  void dispose() {
    _addressSubscription?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _animationController.dispose();
    _shimmerController.dispose();
    _avatarBorderController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  // Calculate profile completion percentage
  double _calculateProfileCompletion() {
    int filledFields = 0;
    int totalFields = 9;

    if (_firstNameController.text.isNotEmpty) filledFields++;
    if (_lastNameController.text.isNotEmpty) filledFields++;
    if (_usernameController.text.isNotEmpty) filledFields++;
    if (_emailController.text.isNotEmpty) filledFields++;
    if (_phoneController.text.isNotEmpty) filledFields++;
    if (_addressController.text.isNotEmpty) filledFields++;
    if (_cityController.text.isNotEmpty) filledFields++;
    if (_stateController.text.isNotEmpty) filledFields++;
    if (_pincodeController.text.isNotEmpty) filledFields++;

    return filledFields / totalFields;
  }

  Color _getCompletionColor(double completion) {
    if (completion >= 0.9) return Colors.green;
    if (completion >= 0.6) return Colors.amber;
    return Colors.orange;
  }

  Future<void> _pickImage() async {
    _triggerHaptic();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.hintColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Choose Photo',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a source for your profile picture',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Camera Option
                    _buildImageSourceOption(
                      context: context,
                      theme: theme,
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: colorScheme.primary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickFromSource(ImageSource.camera);
                      },
                    ),
                    // Gallery Option
                    _buildImageSourceOption(
                      context: context,
                      theme: theme,
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _pickFromSource(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildImageSourceOption({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromSource(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Error picking image: $e');
    }
  }

  Future<void> _updateProfile() async {
    _triggerHaptic();
    setState(() => _isLoading = true);
    try {
      final updatedProfile = widget.userProfile.copyWith(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        username: _usernameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        pincode: _pincodeController.text,
        city: _cityController.text,
        state: _stateController.text,
      );

      // Use AuthCubit to update profile - this updates both backend and state
      await context.read<AuthCubit>().updateUserProfile(
        updatedData: updatedProfile,
        imageFile: _selectedImage,
      );

      if (!mounted) return;

      // Check if update was successful by checking cubit state
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthProfileUpdateSuccess) {
        HapticFeedback.mediumImpact();
        SnackBarHelper.showSuccess(context, authState.message);
        Navigator.pop(context, true);
      } else if (authState is AuthError) {
        SnackBarHelper.showError(context, authState.message);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'An error occurred while updating profile',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    String userHandle = widget.userProfile.username ?? "edit_profile";

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // React to address updates from the cubit
        if (state is AuthAddressUpdated) {
          _updateAddressFields(state.user);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          extendBodyBehindAppBar: true,
          extendBody: true,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Animated Header with Avatar
                _buildAnimatedHeader(theme, colorScheme, size, userHandle),
                const SizedBox(height: 60),
                // Profile Completion Card
                _buildProfileCompletionCard(theme, colorScheme),
                const SizedBox(height: 20),
                // Form Content
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Personal Info Section
                          _buildSectionCard(
                            theme: theme,
                            title: 'Personal Information',
                            icon: Icons.person_outline_rounded,
                            accentColor: theme.colorScheme.primary,
                            delay: 0,
                            children: [
                              _buildModernTextField(
                                theme: theme,
                                label: 'First Name',
                                controller: _firstNameController,
                                accentColor: theme.colorScheme.primary,
                              ),
                              _buildModernTextField(
                                theme: theme,
                                label: 'Last Name',
                                controller: _lastNameController,
                                accentColor: theme.colorScheme.primary,
                              ),
                              _buildModernTextField(
                                theme: theme,
                                label: 'Username',
                                controller: _usernameController,
                                accentColor: theme.colorScheme.primary,
                                isLast: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Contact Info Section
                          _buildSectionCard(
                            theme: theme,
                            title: 'Contact Information',
                            icon: Icons.contact_mail_outlined,
                            accentColor: theme.colorScheme.primary,
                            delay: 1,
                            children: [
                              _buildModernTextField(
                                theme: theme,
                                label: 'Email',
                                controller: _emailController,
                                accentColor: theme.colorScheme.primary,
                                readOnly: true,
                              ),
                              _buildModernTextField(
                                theme: theme,
                                label: 'Phone Number',
                                controller: _phoneController,
                                accentColor: theme.colorScheme.primary,
                                readOnly: true,
                                isLast: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Address Section
                          _buildSectionCard(
                            theme: theme,
                            title: 'Address',
                            icon: Icons.location_on_outlined,
                            accentColor: theme.colorScheme.primary,
                            delay: 2,
                            children: [
                              _buildModernTextField(
                                theme: theme,
                                label: 'Street Address',
                                controller: _addressController,
                                accentColor: theme.colorScheme.primary,
                              ),
                              // Searchable State/City selector
                              SelectState(
                                onCountryChanged: (_) {},
                                onStateChanged:
                                    (v) => setState(
                                      () => _stateController.text = v ?? '',
                                    ),
                                onCityChanged:
                                    (v) => setState(
                                      () => _cityController.text = v ?? '',
                                    ),
                                style: theme.textTheme.bodyLarge,
                                initialState: _stateController.text,
                                initialCity: _cityController.text,
                              ),
                              const SizedBox(height: 8),
                              _buildModernTextField(
                                theme: theme,
                                label: 'Pincode',
                                controller: _pincodeController,
                                accentColor: theme.colorScheme.primary,
                                keyboardType: TextInputType.number,
                                isLast: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomButtons(theme, colorScheme),
        ),
      ),
    );
  }

  // ==================== ANIMATED HEADER ====================
  Widget _buildAnimatedHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    Size size,
    String userHandle,
  ) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Gradient Background with shimmer
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Container(
              height: size.height * 0.22 + statusBarHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withAlpha(255),
                    colorScheme.primary,
                    colorScheme.primary.withAlpha(204),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Shimmer overlay
                  _buildShimmerOverlay(),
                  // Floating circles
                  ..._buildFloatingCircles(),
                  // Back button
                  Positioned(
                    top: statusBarHeight + 8,
                    left: 8,
                    child: Material(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          _triggerHaptic();
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Menu button
                  Positioned(
                    top: statusBarHeight + 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(cardColor: Theme.of(context).cardColor),
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'logout') {
                              _showLogoutDialog(Theme.of(context), context);
                            } else if (value == 'deactivate') {
                              _showDeactivationDialog();
                            }
                          },
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          offset: const Offset(0, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          itemBuilder:
                              (context) => [
                                PopupMenuItem(
                                  value: 'logout',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.logout_rounded,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Log Out',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'deactivate',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_forever_rounded,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Deactivate Account',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                      ),
                    ),
                  ),
                  // Title
                  Positioned(
                    top: statusBarHeight + 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '@$userHandle',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Curved bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
          ),
        ),
        // Avatar
        Positioned(
          bottom: -45,
          child: _buildAnimatedAvatar(theme, colorScheme),
        ),
      ],
    );
  }

  Widget _buildShimmerOverlay() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(0),
                Colors.white.withAlpha(25),
                Colors.white.withAlpha(0),
              ],
              stops: [
                (shimmerValue - 0.3).clamp(0.0, 1.0),
                shimmerValue.clamp(0.0, 1.0),
                (shimmerValue + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingCircles() {
    final positions = [
      {'top': -40.0, 'right': -30.0, 'size': 120.0, 'alpha': 20},
      {'top': 40.0, 'left': -30.0, 'size': 80.0, 'alpha': 15},
      {'bottom': 40.0, 'right': 40.0, 'size': 50.0, 'alpha': 12},
    ];

    return positions.asMap().entries.map((entry) {
      final index = entry.key;
      final pos = entry.value;

      return AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          final offset =
              math.sin(_shimmerController.value * math.pi * 2 + index) * 4;
          return Positioned(
            top: pos['top'] != null ? (pos['top'] as double) + offset : null,
            bottom:
                pos['bottom'] != null
                    ? (pos['bottom'] as double) + offset
                    : null,
            left: pos['left'] != null ? (pos['left'] as double) + offset : null,
            right:
                pos['right'] != null ? (pos['right'] as double) + offset : null,
            child: Container(
              height: pos['size'] as double,
              width: pos['size'] as double,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(pos['alpha'] as int),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildAnimatedAvatar(ThemeData theme, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          // Rotating gradient border
          AnimatedBuilder(
            animation: _avatarBorderController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    startAngle: _avatarBorderController.value * math.pi * 2,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withAlpha(128),
                      Colors.white.withAlpha(128),
                      colorScheme.primary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(76),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: colorScheme.primary.withAlpha(25),
                    backgroundImage:
                        _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (widget.userProfile.profilePicture != null
                                    ? NetworkImage(
                                      widget.userProfile.profilePicture!,
                                    )
                                    : null)
                                as ImageProvider?,
                    child:
                        (_selectedImage == null &&
                                widget.userProfile.profilePicture == null)
                            ? Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: colorScheme.primary,
                            )
                            : null,
                  ),
                ),
              );
            },
          ),
          // Camera badge
          Positioned(
            bottom: 4,
            right: 4,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withAlpha(204),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(102),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SECTION CARD ====================
  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Color accentColor,
    required int delay,
    required List<Widget> children,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (delay * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: accentColor.withAlpha(isDark ? 80 : 60),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withAlpha(isDark ? 40 : 30),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 40 : 15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header with vivid gradient
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withAlpha(isDark ? 60 : 40),
                          accentColor.withAlpha(isDark ? 25 : 15),
                          accentColor.withAlpha(isDark ? 15 : 8),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(23),
                        topRight: Radius.circular(23),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Animated icon container
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 600 + (delay * 150)),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      accentColor.withAlpha(isDark ? 180 : 140),
                                      accentColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withAlpha(
                                        isDark ? 100 : 80,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getSectionSubtitle(title),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: accentColor.withAlpha(
                                    isDark ? 200 : 180,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Decorative element
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(isDark ? 40 : 25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.edit_note_rounded,
                            color: accentColor,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content area
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: children),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getSectionSubtitle(String title) {
    switch (title) {
      case 'Personal Information':
        return 'Your basic details';
      case 'Contact Information':
        return 'How we can reach you';
      case 'Address':
        return 'Your delivery location';
      default:
        return '';
    }
  }

  // ==================== PROFILE COMPLETION CARD ====================
  Widget _buildProfileCompletionCard(ThemeData theme, ColorScheme colorScheme) {
    final completion = _calculateProfileCompletion();
    final completionColor = _getCompletionColor(completion);
    final isDark = theme.brightness == Brightness.dark;
    final percentage = (completion * 100).toInt();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                completionColor.withAlpha(isDark ? 50 : 30),
                completionColor.withAlpha(isDark ? 20 : 12),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: completionColor.withAlpha(isDark ? 100 : 60),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Circular Progress
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: completion),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, animatedCompletion, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: animatedCompletion,
                          strokeWidth: 6,
                          backgroundColor: theme.dividerColor.withAlpha(50),
                          valueColor: AlwaysStoppedAnimation(completionColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(animatedCompletion * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: completionColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 18),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      percentage >= 90
                          ? 'Profile Complete! 🎉'
                          : percentage >= 60
                          ? 'Almost there!'
                          : 'Complete your profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      percentage >= 90
                          ? 'All your information is up to date'
                          : 'Fill in the remaining fields for better experience',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color?.withAlpha(
                          160,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Progress badges
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniProgressBadge(
                            'Personal',
                            _firstNameController.text.isNotEmpty &&
                                _lastNameController.text.isNotEmpty &&
                                _usernameController.text.isNotEmpty,
                            colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildMiniProgressBadge(
                            'Contact',
                            _emailController.text.isNotEmpty &&
                                _phoneController.text.isNotEmpty,
                            colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildMiniProgressBadge(
                            'Address',
                            _addressController.text.isNotEmpty &&
                                _cityController.text.isNotEmpty,
                            colorScheme.primary,
                          ),
                        ),
                      ],
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

  Widget _buildMiniProgressBadge(String label, bool isComplete, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 4,
      ), // Reduced padding
      decoration: BoxDecoration(
        color: isComplete ? color.withAlpha(40) : Colors.grey.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isComplete ? color.withAlpha(100) : Colors.grey.withAlpha(50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center, // Center content
        children: [
          Icon(
            isComplete
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            size: 12,
            color: isComplete ? color : Colors.grey,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isComplete ? color : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MODERN TEXT FIELD ====================
  Widget _buildModernTextField({
    required ThemeData theme,
    required String label,
    required TextEditingController controller,
    required Color accentColor,
    bool readOnly = false,
    TextInputType? keyboardType,
    bool isLast = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
                ),
              ),
              if (readOnly) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 11,
                        color: theme.textTheme.bodyMedium?.color?.withAlpha(
                          120,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Read only',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyMedium?.color?.withAlpha(
                            120,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            onTap: readOnly ? null : _triggerHaptic,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color:
                  readOnly
                      ? theme.textTheme.bodyMedium?.color?.withAlpha(130)
                      : theme.textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor:
                  readOnly
                      ? (isDark
                          ? Colors.white.withAlpha(8)
                          : Colors.grey.withAlpha(20))
                      : (isDark ? Colors.white.withAlpha(5) : Colors.white),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor.withAlpha(60)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor.withAlpha(60)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LOGOUT Logic ====================
  void _handleLogout(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.read<AuthCubit>().logout();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _showLogoutDialog(ThemeData theme, BuildContext context) {
    _triggerHaptic();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Logout Dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (dialogContext, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Log Out'),
                ],
              ),
              content: const Text(
                'Are you sure you want to log out? You\'ll need to sign in again to access your account.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _triggerHaptic();
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withAlpha(178),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _handleLogout(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Log Out'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== DEACTIVATE Logic ====================
  void _showDeactivationDialog() {
    final passwordController = TextEditingController();
    final otpController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final otpFormKey = GlobalKey<FormState>();
    final PageController pageController = PageController();

    bool isObscured = true;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (innerContext, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: EdgeInsets.zero,
                content: SizedBox(
                  width: double.maxFinite,
                  height: 350,
                  child: PageView(
                    controller: pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // STEP 1: Password Confirmation
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red[700],
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Deactivate Account',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'To continue, please enter your password. This will send an OTP to your email and phone.',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: passwordController,
                                obscureText: isObscured,
                                enabled: !isLoading,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      isObscured
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed:
                                        isLoading
                                            ? null
                                            : () {
                                              setDialogState(() {
                                                isObscured = !isObscured;
                                              });
                                            },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  return null;
                                },
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed:
                                        isLoading
                                            ? null
                                            : () =>
                                                Navigator.pop(dialogContext),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color:
                                            isLoading
                                                ? Colors.grey[400]
                                                : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed:
                                        isLoading
                                            ? null
                                            : () async {
                                              if (formKey.currentState!
                                                  .validate()) {
                                                setDialogState(
                                                  () => isLoading = true,
                                                );
                                                final result = await context
                                                    .read<AuthCubit>()
                                                    .deactivateAccount(
                                                      passwordController.text,
                                                    );
                                                if (innerContext.mounted) {
                                                  setDialogState(
                                                    () => isLoading = false,
                                                  );
                                                  if (result['success']) {
                                                    pageController.nextPage(
                                                      duration: const Duration(
                                                        milliseconds: 300,
                                                      ),
                                                      curve: Curves.easeInOut,
                                                    );
                                                  } else {
                                                    SnackBarHelper.showError(
                                                      context,
                                                      result['message'],
                                                    );
                                                  }
                                                }
                                              }
                                            },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child:
                                        isLoading
                                            ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                            : const Text(
                                              'Confirm Password',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // STEP 2: OTP Verification
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: otpFormKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.security_rounded,
                                      color: Colors.blue[700],
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Verify OTP',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'An OTP has been sent to your email and phone. Please enter it below to complete deactivation.',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: otpController,
                                keyboardType: TextInputType.number,
                                enabled: !isLoading,
                                decoration: InputDecoration(
                                  labelText: 'Enter OTP',
                                  prefixIcon: const Icon(
                                    Icons.lock_clock_outlined,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'OTP is required';
                                  }
                                  return null;
                                },
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed:
                                        isLoading
                                            ? null
                                            : () {
                                              pageController.previousPage(
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                curve: Curves.easeInOut,
                                              );
                                            },
                                    child: Text(
                                      'Back',
                                      style: TextStyle(
                                        color:
                                            isLoading
                                                ? Colors.grey[400]
                                                : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed:
                                        isLoading
                                            ? null
                                            : () async {
                                              if (otpFormKey.currentState!
                                                  .validate()) {
                                                setDialogState(
                                                  () => isLoading = true,
                                                );
                                                final result = await context
                                                    .read<AuthCubit>()
                                                    .confirmDeactivation(
                                                      otpController.text,
                                                    );
                                                if (innerContext.mounted) {
                                                  setDialogState(
                                                    () => isLoading = false,
                                                  );
                                                  if (result['success']) {
                                                    Navigator.pop(
                                                      dialogContext,
                                                    );
                                                    Navigator.of(
                                                      context,
                                                    ).popUntil(
                                                      (route) => route.isFirst,
                                                    );
                                                  } else {
                                                    SnackBarHelper.showError(
                                                      context,
                                                      result['message'],
                                                    );
                                                  }
                                                }
                                              }
                                            },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child:
                                        isLoading
                                            ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                            : const Text(
                                              'Final Deactivation',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
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
              );
            },
          ),
    );
  }

  // ==================== BOTTOM BUTTONS ====================
  Widget _buildBottomButtons(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cancel Button
            Expanded(
              child: SizedBox(
                height: 52,
                child: Material(
                  color: theme.dividerColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap:
                        _isLoading
                            ? null
                            : () {
                              _triggerHaptic();
                              Navigator.of(context).pop();
                            },
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyMedium?.color?.withAlpha(
                            178,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Save Button
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _isLoading ? null : _updateProfile,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withAlpha(204),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withAlpha(76),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
