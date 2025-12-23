import 'package:grocery_app/common_widgets/global_import.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel userProfile;
  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _authService = AuthService();
  final _profileService = ProfileService();
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

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.userProfile.firstName ?? "",
    );
    _lastNameController = TextEditingController(
      text: widget.userProfile.lastName ?? "",
    );
    _usernameController = TextEditingController(
      text: widget.userProfile.username ?? "",
    );
    _emailController = TextEditingController(text: widget.userProfile.email);
    _phoneController = TextEditingController(
      text: widget.userProfile.phoneNumber,
    );
    _addressController = TextEditingController(
      text: widget.userProfile.address ?? '',
    );
    _cityController = TextEditingController(
      text: widget.userProfile.city ?? '',
    );
    _stateController = TextEditingController(
      text: widget.userProfile.state ?? '',
    );
    _pincodeController = TextEditingController(
      text: widget.userProfile.pincode ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
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
    setState(() => _isLoading = true);
    try {
      if (_selectedImage != null) {
        final imageResult = await _profileService.uploadProfileImage(
          _selectedImage!,
        );
        if (!imageResult['success']) {
          if (mounted) {
            SnackBarHelper.showError(
              context,
              imageResult['message'] ?? 'Failed to update profile image',
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }
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
      final result = await _authService.updateProfile(updatedProfile);
      if (!mounted) return;
      if (result['success']) {
        SnackBarHelper.showSuccess(context, 'Profile updated successfully');
        Navigator.pop(context, true);
      } else {
        SnackBarHelper.showError(
          context,
          result['message'] ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      if (mounted)
        SnackBarHelper.showError(
          context,
          'An error occurred while updating profile',
        );
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
    final isDark = theme.brightness == Brightness.dark;
    String userHandle = widget.userProfile.username ?? "edit_profile";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text('@$userHandle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppColors.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                        width: 3,
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
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: theme.cardColor,
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
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
                                  Icons.person,
                                  size: 60,
                                  color: theme.disabledColor,
                                )
                                : null,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(AppColors.spacingS),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.cardColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: colorScheme.onPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColors.spacingXL),

            // Personal Info Section
            _buildSectionCard(
              title: 'Personal Information',
              icon: Icons.person_outline,
              children: [
                _buildTextField(
                  label: 'First Name',
                  controller: _firstNameController,
                ),
                _buildTextField(
                  label: 'Last Name',
                  controller: _lastNameController,
                ),
                _buildTextField(
                  label: 'Username',
                  controller: _usernameController,
                ),
              ],
            ),
            const SizedBox(height: AppColors.spacingL),

            // Contact Info Section
            _buildSectionCard(
              title: 'Contact Information',
              icon: Icons.contact_mail_outlined,
              children: [
                _buildTextField(
                  label: 'Email',
                  controller: _emailController,
                  readOnly: true,
                ),
                _buildTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  readOnly: true,
                ),
              ],
            ),
            const SizedBox(height: AppColors.spacingL),

            // Address Section
            _buildSectionCard(
              title: 'Address',
              icon: Icons.location_on_outlined,
              children: [
                _buildTextField(
                  label: 'Address',
                  controller: _addressController,
                ),
                _buildTextField(label: 'City', controller: _cityController),
                _buildTextField(label: 'State', controller: _stateController),
                _buildTextField(
                  label: 'Pincode',
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: AppColors.spacingL),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.spacingL),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppColors.radiusL),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(AppColors.shadowOpacityLight),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppColors.spacingS),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppColors.radiusS),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: AppColors.spacingM),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spacingL),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType? keyboardType,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppColors.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: AppColors.spacingS),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusM),
              ),
              fillColor:
                  readOnly
                      ? theme.inputDecorationTheme.fillColor?.withOpacity(0.5)
                      : null,
              suffixIcon:
                  readOnly
                      ? Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: theme.disabledColor,
                      )
                      : null,
            ).applyDefaults(theme.inputDecorationTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppColors.spacingL),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(AppColors.shadowOpacityLight),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppColors.spacingM,
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppColors.spacingL),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppColors.spacingM,
                  ),
                ),
                child:
                    _isLoading
                        ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                        : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
