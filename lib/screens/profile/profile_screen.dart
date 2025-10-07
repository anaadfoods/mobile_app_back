import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/styles/colors.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'edit_profile_screen.dart';
import '../../helpers/notification_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  UserModel? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile')));
      }
    }
  }

  Widget _buildProfileHeader() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(50),
          ),

          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child:
                _userProfile?.profilePicture != null
                    ? Image.network(
                      _userProfile?.profilePicture ?? '',
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
            decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(50)

            ),
            child:IconButton(

            icon: Icon(Icons.edit),
            iconSize: 1,
            onPressed: () async {
              if (_userProfile != null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            EditProfileScreen(userProfile: _userProfile!),
                  ),
                );

                // Reload profile if update was successful
                if (result == true) {
                  await _loadUserProfile();
                  // Notify parent screens to refresh
                  Navigator.pop(context, true);
                }
              }
            },
          ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildReferralCode() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade300, Colors.purple.shade500],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Referral Code',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _userProfile?.referralCode ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: Colors.white),
                onPressed: () async {
                  if (_userProfile?.referralCode != null) {
                    await Clipboard.setData(
                      ClipboardData(text: _userProfile!.referralCode!),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Referral code copied to clipboard'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(' ${_userProfile?.username ?? ''}'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(),
              
              _buildInfoCard(
                "Name",
                '${_userProfile?.firstName[0].toUpperCase()}${_userProfile?.firstName.substring(1)} ${_userProfile?.lastName[0].toUpperCase()}${_userProfile?.lastName.substring(1)}',
                Icons.person,
              ),
              _buildInfoCard(
                'Username',
                _userProfile?.username ?? '',
                Icons.account_circle,
              ),
              _buildInfoCard(
                'Phone Number',
                _userProfile?.phoneNumber ?? '',
                Icons.phone,
              ),
              _buildInfoCard("Email", _userProfile!.email, Icons.email),
              _buildInfoCard(
                'Gender',
                _userProfile?.gender == 'M'
                    ? 'Male'
                    : _userProfile?.gender == 'F'
                    ? 'Female'
                    : _userProfile?.gender == 'O'
                    ? 'Other'
                    : '-',
                Icons.wc,
              ),

              _buildInfoCard(
                'Address',
                '${_userProfile?.address ?? ''} ,  ${_userProfile?.city ?? ''}, ${_userProfile?.state ?? ''} , ${_userProfile?.pincode ?? ''}',
                Icons.location_city,
              ),

              SizedBox(height: 20),
              // if (_userProfile?.isEmailVerified == false)
              //   Padding(
              //     padding: EdgeInsets.all(16),
              //     child: ElevatedButton.icon(
              //       onPressed: () {
              //         // TODO: Implement email verification
              //       },
              //       icon: Icon(Icons.email),
              //       label: Text('Verify Email'),
              //       style: ElevatedButton.styleFrom(
              //         minimumSize: Size(double.infinity, 50),
              //       ),
              //     ),
              //   ),
            ],
          ),
        ),
      ),
    );
  }
}
