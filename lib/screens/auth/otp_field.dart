import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

// You can run this file directly to see the screen


class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  @override
  Widget build(BuildContext context) {
    // Define the theme for the Pinput boxes
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), // Lighter green
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Scaffold(
      // Main background color for the screen
      backgroundColor: const Color.fromRGBO(42, 69, 53, 1.0),
      body: Container(
        width: 500,
        height: 900,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ## Main Title ##
              const Text(
                'OTP Verification',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              // ## Subtitle ##
              const Text(
                "We've sent a 6-digit OTP to your registered\nmobile number or email",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),

              // ## Pinput (OTP Input Field) ##
              Pinput(
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: Colors.white),
                  ),
                ),
                onCompleted: (pin) => debugPrint(pin),
              ),
              const SizedBox(height: 40),

              // ## Verify Button ##
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement verification logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(193, 147, 81, 1.0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Verify',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ## Login Text ##
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                  children: <TextSpan>[
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withOpacity(0.9)
                      ),
                      // recognizer: TapGestureRecognizer()..onTap = () {
                      //   // TODO: Navigate to login screen
                      // },
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
}