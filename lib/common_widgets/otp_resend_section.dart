import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grocery_app/styles/colors.dart';

class OtpResendSection extends StatefulWidget {
  final Future<void> Function() onResend;

  const OtpResendSection({
    super.key,
    required this.onResend,
  });

  @override
  State<OtpResendSection> createState() => _OtpResendSectionState();
}

class _OtpResendSectionState extends State<OtpResendSection> {
  static const int _initialCooldown = 30;
  int _secondsRemaining = _initialCooldown;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = _initialCooldown;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0 || _isLoading) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      await widget.onResend();
      if (mounted) {
        _startTimer();
      }
    } catch (e) {
      // Exceptions should be handled by caller's onResend callback.
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onPrimary.withValues(alpha: 0.8),
      fontSize: 14,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        if (_secondsRemaining > 0)
          Text(
            "Resend OTP in $_secondsRemaining seconds",
            style: textStyle?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive the code? ",
                style: textStyle,
              ),
              _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.parchment),
                      ),
                    )
                  : GestureDetector(
                      onTap: _handleResend,
                      child: Text(
                        "Resend OTP",
                        style: textStyle?.copyWith(
                          color: AppColors.parchment,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.parchment,
                        ),
                      ),
                    ),
            ],
          ),
      ],
    );
  }
}
