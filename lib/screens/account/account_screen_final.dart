import 'package:flutter/material.dart';
import 'package:grocery_app/screens/account/account_screen.dart';
import 'package:grocery_app/screens/account/auth_screen.dart';
import 'package:grocery_app/services/auth_service.dart';

class AccountScreenFinal extends StatefulWidget {
  const AccountScreenFinal({super.key});

  @override
  State<AccountScreenFinal> createState() => _AccountScreenFinalState();
}

class _AccountScreenFinalState extends State<AccountScreenFinal> {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _initializeAuthState();
    _setupAuthListener();
  }

  Future<void> _initializeAuthState() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
      });
    }
  }

  void _setupAuthListener() {
    AuthService.authStateChanges.listen((isLoggedIn) {
      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
        });
      }
    });
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLoggedIn ? "User Detail" : "Login")),
      body: _isLoggedIn ? const AccountScreen() : const AuthScreen(),
    );
  }
}
