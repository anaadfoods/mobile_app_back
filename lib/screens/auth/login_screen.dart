import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/common_widgets/imput_widget.dart';
import 'package:grocery_app/screens/auth/signup_screen.dart' show SignupScreen;
import 'package:grocery_app/screens/dashboard/dashboard_screen.dart';
import 'package:grocery_app/services/auth_service.dart';

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
    // Delay the auth check to avoid blocking initial render
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
      print('Auth state check error: $e');
    }
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => DashboardScreen()),
      (route) => false,
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final result = await _authService.loginUser(email, password);

      if (!mounted) return;

      if (result['success'] == true) {
        _navigateToDashboard();
        // Do not show error snackbar on success
      } else {
        _showErrorSnackBar(result['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('An error occurred during login: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
      appBar: AppBar(
        title: Text("Login"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _navigateToDashboard,
            child: const Text("Skip"),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Let's get started",
                  style: TextStyle(fontWeight: FontWeight.normal, fontSize: 20),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Login",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ),
                const SizedBox(height: 20),
                CustomInput(
                  hintText: "Email",
                  obscureText: false,
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
                const SizedBox(height: 20),
                CustomInput(
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
                const SizedBox(height: 20),
                AppButton(
                  label: _isLoading ? "Logging in..." : "Login",
                  fontWeight: FontWeight.bold,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  onPressed: _isLoading ? null : _handleLogin,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("New to Anaad Foods?"),
                    TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignupScreen(),
                                  ),
                                );
                              },
                      child: Text("Sign Up"),
                    ),
                  ],
                ),
                if (!_isLoading) ...[
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Forgot Password?"),
                      TextButton(
                        onPressed: () {},
                        child: Text("Reset Password"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialLoginButton(
                        icon: Icons.g_mobiledata,
                        onPressed: () {
                          // Handle Google login
                        },
                      ),
                      const SizedBox(width: 20),
                      _buildSocialLoginButton(
                        icon: Icons.apple,
                        onPressed: () {
                          // Handle Apple login
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: EdgeInsets.all(1.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(50.0),
      ),
      child: IconButton(
        icon: Icon(icon, size: 25),
        onPressed: _isLoading ? null : onPressed,
      ),
    );
  }
}
