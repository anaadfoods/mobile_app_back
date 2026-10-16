import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/rfp_delivery_otp_status.dart';
import '../rfp_theme.dart';

/// Prominent delivery OTP verification card displayed when a delivery
/// is out for delivery. Handles both:
/// 1. Active OTP received: prominent 6-digit code with copy & expiry.
/// 2. Awaiting OTP: informative card with "Check OTP" refresh button.
class RfpDeliveryOtpCard extends StatefulWidget {
  final RfpDeliveryOtpStatus? otpStatus;
  final bool isOutForDelivery;
  final VoidCallback? onRefresh;

  const RfpDeliveryOtpCard({
    super.key,
    this.otpStatus,
    this.isOutForDelivery = false,
    this.onRefresh,
  });

  @override
  State<RfpDeliveryOtpCard> createState() => _RfpDeliveryOtpCardState();
}

class _RfpDeliveryOtpCardState extends State<RfpDeliveryOtpCard> {
  bool _copied = false;

  void _copyOtp(String otp) {
    if (otp.isEmpty) return;
    Clipboard.setData(ClipboardData(text: otp));
    setState(() => _copied = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delivery OTP $otp copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: RfpTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _handleRefresh() {
    if (widget.onRefresh == null) return;
    widget.onRefresh!();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.otpStatus;
    final isActive = status?.isActive == true;

    if (!widget.isOutForDelivery && !isActive) {
      return const SizedBox.shrink();
    }

    final isExpired = status?.isExpired == true;
    final otp = status?.otp ?? '';
    final expiresAt = status?.expiresAt;
    final expiryStr =
        expiresAt != null
            ? DateFormat('hh:mm a').format(expiresAt.toLocal())
            : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF166534).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isActive: isActive),
          const SizedBox(height: 12),
          Text(
            isActive
                ? 'Share this OTP with your delivery agent to receive your fresh harvest box:'
                : (isExpired
                    ? 'Your previous delivery verification code has expired.'
                    : 'Your harvest is out for delivery! The delivery agent will generate your doorstep verification code on arrival.'),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (isActive)
            _buildActiveBox(otp, expiryStr)
          else
            _buildAwaitingBox(isExpired),
        ],
      ),
    );
  }

  Widget _buildHeader({required bool isActive}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isActive ? 'DELIVERY VERIFICATION OTP' : 'OUT FOR DELIVERY',
                style: const TextStyle(
                  color: Color(0xFF166534),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 15,
              color: Color(0xFF166534),
            ),
            const SizedBox(width: 4),
            const Text(
              'Doorstep Security',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF166534),
              ),
            ),
            if (isActive && widget.onRefresh != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: _handleRefresh,
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: Color(0xFF166534),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActiveBox(String otp, String? expiryStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                otp.split('').join('  '),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF14532D),
                  letterSpacing: 2,
                ),
              ),
              InkWell(
                onTap: () => _copyOtp(otp),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _copied
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _copied ? Icons.check : Icons.copy_rounded,
                        size: 14,
                        color:
                            _copied
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF4B5563),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _copied ? 'Copied' : 'Copy',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              _copied
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (expiryStr != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Color(0xFF4B5563)),
              const SizedBox(width: 4),
              Text(
                'Valid until $expiryStr',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAwaitingBox(bool isExpired) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  isExpired
                      ? Icons.timer_off_outlined
                      : Icons.hourglass_top_rounded,
                  size: 16,
                  color: const Color(0xFF166534),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isExpired
                        ? 'Ask agent for a new code'
                        : 'Waiting for agent OTP...',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onRefresh != null)
            InkWell(
              onTap: _handleRefresh,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: Color(0xFF166534),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Check OTP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
