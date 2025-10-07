import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../helpers/snackbar_helper.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel userProfile;

  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // --- STATE AND SERVICES ---
  final _authService = AuthService();
  final _profileService = ProfileService();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  File? _selectedImage;

  // --- CONTROLLERS ---
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
    // Initialize all controllers with current user profile data
    _firstNameController = TextEditingController(text: widget.userProfile.firstName ?? "");
    _lastNameController = TextEditingController(text: widget.userProfile.lastName ?? "");
    _usernameController = TextEditingController(text: widget.userProfile.username ?? "");
    _emailController = TextEditingController(text: widget.userProfile.email);
    _phoneController = TextEditingController(text: widget.userProfile.phoneNumber);
    _addressController = TextEditingController(text: widget.userProfile.address ?? '');
    _cityController = TextEditingController(text: widget.userProfile.city ?? '');
    _stateController = TextEditingController(text: widget.userProfile.state ?? '');
    _pincodeController = TextEditingController(text: widget.userProfile.pincode ?? '');
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
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

  // --- LOGIC METHODS (UNCHANGED) ---

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
      // 1. Update profile image if a new one is selected
      if (_selectedImage != null) {
        final imageResult = await _profileService.uploadProfileImage(_selectedImage!);
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

      // 2. Prepare the updated user profile data
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
      
      // 3. Call the update service
      final result = await _authService.updateProfile(updatedProfile);

      if (!mounted) return;

      if (result['success']) {
        SnackBarHelper.showSuccess(context, 'Profile updated successfully');
        Navigator.pop(context, true); // Pop with a success flag
      } else {
        SnackBarHelper.showError(
          context,
          result['message'] ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      if(mounted) SnackBarHelper.showError(context, 'An error occurred while updating profile');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- UI BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    String userHandle = widget.userProfile.username ?? "edit_profile";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '@$userHandle',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // -- Profile Picture --
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (widget.userProfile.profilePicture != null
                                ? NetworkImage(widget.userProfile.profilePicture!)
                                : null) as ImageProvider?,
                        child: (_selectedImage == null && widget.userProfile.profilePicture == null)
                            ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            // -- Form Fields --
            _buildTextField(label: 'First Name', controller: _firstNameController),
            _buildTextField(label: 'Last Name', controller: _lastNameController),
            _buildTextField(label: 'Username', controller: _usernameController),
            _buildTextField(label: 'Email', controller: _emailController, readOnly: true),
            _buildTextField(label: 'Phone Number', controller: _phoneController, readOnly: true),
            _buildTextField(label: 'Address', controller: _addressController),
            _buildTextField(label: 'City', controller: _cityController),
            _buildTextField(label: 'State', controller: _stateController),
            _buildTextField(label: 'Pincode', controller: _pincodeController, keyboardType: TextInputType.number),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? Colors.grey[100] : Colors.grey[50],
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Color(0xFFB58A55), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Color(0xFFB58A55),
                side: BorderSide(color: Color(0xFFB58A55), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Color(0xFFB58A55),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                  shadowColor: Color(0xFFB58A55).withOpacity(0.4)),
            ),
          ),
        ],
      ),
    );
  }
}