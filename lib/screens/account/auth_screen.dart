import 'package:flutter/material.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/screens/auth/signup_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.green[400]),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
          

          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            const Text("Welcome to Annad", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen()));
              },
              style: ElevatedButton.styleFrom(
                
                backgroundColor: const Color.fromARGB(255, 61, 204, 59),
                minimumSize: Size(double.infinity, 50),
              ),
              child: const Text("Create account", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: const Text("Login", style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 30),
            _buildBenefitItem(Icons.currency_rupee, "Upto ₹100 cashback on your first order"),
            _buildBenefitItem(Icons.local_shipping, "Free Delivery on first order – for top categories"),
            // _buildBenefitItem(Icons.loop, "Easy Returns"),
            _buildBenefitItem(Icons.money, "Pay on Delivery"),
          ],
        ),
      ),
    );
  }
}
