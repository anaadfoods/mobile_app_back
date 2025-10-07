import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/common_widgets/imput_widget.dart';
import 'package:grocery_app/screens/auth/signup_screen.dart';
import 'package:grocery_app/screens/auth/forget_password_screen.dart';
import 'package:grocery_app/screens/dashboard/dashboard_screen.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/services/notification_service.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:grocery_app/styles/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  Future<void> _checkAuthState() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn && mounted) {
        _navigateToDashboard();
      }
    } catch (e) {
      debugPrint('Auth state check error: $e');
    }
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => DashboardScreen()),
      (route) => false,
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final result = await _authService.loginUser(email, password);

      if (!mounted) return;

      if (result['success'] == true) {
        try {
          final fcmToken = await FirebaseMessaging.instance.getToken();
          final bearerToken = await _authService.getAccessToken();
          if (fcmToken != null && bearerToken != null) {
            await NotificationService().registerFcmTokenWithBackend(
              fcmToken,
              bearerToken,
            );
          }
        } catch (e) {
          debugPrint('Error registering FCM token: $e');
        }
        _navigateToDashboard();
      } else {
        SnackBarHelper.showError(
          context,
          result['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    resizeToAvoidBottomInset: true, // 👈 allows scrolling when keyboard opens
    body: Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset(
            "assets/images/OnBoarding/background_login_sign.png",
            fit: BoxFit.cover,
          ),
        ),

        // Content
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                // Only scroll when keyboard pushes content
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo
                          Align(
                            alignment: Alignment.topCenter,
                            child: Image.asset(
                              "assets/images/OnBoarding/logo.png",
                              height: 60,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Welcome Back!",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    "Login to your account",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 25),

                                  // Email
                                  CustomInput(
                                    height: 60,
                                    borderRadius: BorderRadius.circular(25),
                                    hintText: "Email",
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                      ).hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 15),

                                  // Password
                                  CustomInput(
                                    height: 60,
                                    borderRadius: BorderRadius.circular(25),
                                    hintText: "Password",
                                    obscureText: true,
                                    controller: _passwordController,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 5),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ForgetPasswordScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Forgot Password?",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Login button
                                  AppButton(
                                    label: _isLoading
                                        ? "Logging in..."
                                        : "Login",
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.bottonBackgroundColor,
                                    textColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    onPressed:
                                        _isLoading ? null : _handleLogin,
                                  ),
                                  const SizedBox(height: 10),

                                  // Register
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "Do not have an account?",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const SignupScreen(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          "Register",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // OR divider
                          Row(
                            children: [
                              const Expanded(
                                  child: Divider(color: Colors.white54)),
                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  "or",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              const Expanded(
                                  child: Divider(color: Colors.white54)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Social buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialLoginButton(
                                icon: Icons.g_mobiledata,
                                onPressed: () {},
                              ),
                              const SizedBox(width: 20),
                              _buildSocialLoginButton(
                                icon: Icons.apple,
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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



  Widget _buildSocialLoginButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(1.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(50.0),
      ),
      child: IconButton(
        icon: Icon(icon, size: 28, color: Colors.white),
        onPressed: _isLoading ? null : onPressed,
      ),
    );
  }
}
