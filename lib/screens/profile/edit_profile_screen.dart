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

  const EditProfileScreen({Key? key, required this.userProfile})
    : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _profileService = ProfileService();
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  File? _selectedImage;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values
    _firstNameController = TextEditingController(
      text: widget.userProfile.firstName,
    );
    _lastNameController = TextEditingController(
      text: widget.userProfile.lastName,
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
      SnackBarHelper.showError(context, 'Error picking image: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // First update the profile image if selected
      if (_selectedImage != null) {
        final imageResult = await _profileService.uploadProfileImage(
          _selectedImage!,
        );
        if (!imageResult['success']) {
          SnackBarHelper.showError(
            context,
            imageResult['message'] ?? 'Failed to update profile image',
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final updatedProfile = widget.userProfile.copyWith(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        address: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
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

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? helperText,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: TextStyle(fontSize: 16),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator:
            validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile'), elevation: 0),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.2),
                              backgroundImage:
                                  _selectedImage != null
                                      ? FileImage(_selectedImage!)
                                      : null,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child:
                                    _selectedImage == null
                                        ? Image.network(
                                          widget.userProfile.profilePicture ??
                                              '',
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                        : Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Theme.of(context).primaryColor,
                                        ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Edit Your Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildReadOnlyField('Email', widget.userProfile.email),
                      SizedBox(height: 12),
                      _buildReadOnlyField(
                        'Phone',
                        widget.userProfile.phoneNumber,
                      ),
                      // SizedBox(height: 12),
                      // _buildReadOnlyField(
                      //   'Referral Code',
                      //   widget.userProfile.referralCode ?? '',
                      // ),
                      SizedBox(height: 24),
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        label: 'First Name',
                        controller: _firstNameController,
                      ),
                      _buildTextField(
                        label: 'Last Name',
                        controller: _lastNameController,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Address Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        label: 'Address',
                        controller: _addressController,
                        helperText: 'Enter your complete address',
                      ),
                      _buildTextField(
                        label: 'City',
                        controller: _cityController,
                      ),
                      _buildTextField(
                        label: 'State',
                        controller: _stateController,
                      ),
                      _buildTextField(
                        label: 'PIN Code',
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'PIN code is required';
                          }
                          if (value.length != 6) {
                            return 'PIN code must be 6 digits';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 32),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child:
                              _isLoading
                                  ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    'Update Profile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                      SizedBox(height: 20),
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
