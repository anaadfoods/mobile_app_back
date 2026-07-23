import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';

/// Clean and animated cancellation result dialog displaying API response messages
class CancellationResultDialog extends StatefulWidget {
  final String title;
  final String message;
  final bool refundInitiated;
  final String? orderNumber;
  final VoidCallback? onDismiss;

  const CancellationResultDialog({
    super.key,
    required this.title,
    required this.message,
    this.refundInitiated = false,
    this.orderNumber,
    this.onDismiss,
  });

  /// Helper method to display the animated result dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    bool refundInitiated = false,
    String? orderNumber,
    VoidCallback? onDismiss,
  }) async {
    HapticFeedback.mediumImpact();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CancellationResultDialog(
        title: title,
        message: message,
        refundInitiated: refundInitiated,
        orderNumber: orderNumber,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<CancellationResultDialog> createState() =>
      _CancellationResultDialogState();
}

class _CancellationResultDialogState extends State<CancellationResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.15, 0.7, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.pureWhite,
        elevation: 16,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon Circle
              ScaleTransition(
                scale: _iconScaleAnimation,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.deepSoilGreen,
                        AppColors.harvestAmber,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepSoilGreen.withAlpha(90),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.pureWhite,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.parchment : AppColors.charcoal,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Response Message Card
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.charcoal.withAlpha(80)
                              : AppColors.softCream,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.charcoal60
                                : AppColors.rawEarth12,
                          ),
                        ),
                        child: Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                            color: isDark
                                ? AppColors.parchment.withValues(alpha: 0.95)
                                : AppColors.charcoal87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Order Number Tag
                      if (widget.orderNumber != null &&
                          widget.orderNumber!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.primary.withAlpha(50),
                            ),
                          ),
                          child: Text(
                            'Order #${widget.orderNumber}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],

                      // Refund Status Banner
                      if (widget.refundInitiated) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.harvestAmber.withAlpha(25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.harvestAmber.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.harvestAmber.withAlpha(40),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: AppColors.harvestAmber,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Refund Initiated',
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: AppColors.harvestAmber,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '5–7 Working Days to original payment',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? AppColors.parchment70
                                            : AppColors.rawEarth70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Button
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      if (widget.onDismiss != null) {
                        widget.onDismiss!();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: AppColors.pureWhite,
                      elevation: 4,
                      shadowColor: theme.colorScheme.primary.withAlpha(80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Got It',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean interactive dialog for selecting/entering a cancellation reason
class CancellationReasonDialog extends StatefulWidget {
  final String type; // 'order' or 'subscription'

  const CancellationReasonDialog({super.key, required this.type});

  static Future<String?> show(BuildContext context, {required String type}) {
    HapticFeedback.lightImpact();
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CancellationReasonDialog(type: type),
    );
  }

  @override
  State<CancellationReasonDialog> createState() =>
      _CancellationReasonDialogState();
}

class _CancellationReasonDialogState extends State<CancellationReasonDialog> {
  late List<String> _reasons;
  String? _selectedReason;
  final TextEditingController _customReasonController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _reasons = widget.type == 'subscription'
        ? [
            'I am moving to a different city and no longer need this.',
            'I found a better price elsewhere.',
            'Delivery is taking too long / scheduling issues.',
            'Quality or product selection concerns.',
            'Other (Please specify)',
          ]
        : [
            'I found a better price elsewhere.',
            'I am moving to a different city and no longer need this.',
            'No longer need the products / changed my mind.',
            'Delivery is taking too long / scheduling issues.',
            'Other (Please specify)',
          ];
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.pureWhite,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      actionsPadding: const EdgeInsets.all(20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.softRed.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_outlined,
              color: AppColors.softRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.type == 'order'
                      ? 'Cancel Order'
                      : 'Cancel Subscription',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.parchment : AppColors.charcoal,
                  ),
                ),
                Text(
                  'Please select a reason',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? AppColors.parchment70 : AppColors.rawEarth70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._reasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedReason = reason;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? AppColors.darkSoftRed.withAlpha(40)
                            : AppColors.softRed.withAlpha(20))
                        : (isDark
                            ? AppColors.charcoal.withAlpha(60)
                            : AppColors.softCream.withAlpha(100)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? AppColors.darkSoftRed : AppColors.softRed)
                          : AppColors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 20,
                        color: isSelected
                            ? (isDark
                                ? AppColors.darkSoftRed
                                : AppColors.softRed)
                            : (isDark
                                ? AppColors.parchment.withValues(alpha: 0.5)
                                : AppColors.rawEarth.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reason,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.parchment
                                : AppColors.charcoal87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (_selectedReason == 'Other (Please specify)') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customReasonController,
                maxLines: 3,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.parchment : AppColors.charcoal,
                ),
                decoration: InputDecoration(
                  hintText: 'Please write your reason here...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.parchment.withValues(alpha: 0.5)
                        : AppColors.charcoal40,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.charcoal.withAlpha(80)
                      : AppColors.softCream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.darkSoftRed : AppColors.softRed,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Keep ${widget.type == 'order' ? 'Order' : 'Subscription'}',
            style: TextStyle(
              color: isDark
                  ? AppColors.parchment.withValues(alpha: 0.6)
                  : AppColors.charcoal40,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedReason == null) {
              SnackBarHelper.showError(context, 'Please select a reason');
              return;
            }
            String reason = _selectedReason!;
            if (reason == 'Other (Please specify)') {
              reason = _customReasonController.text.trim();
              if (reason.isEmpty) {
                SnackBarHelper.showError(context, 'Please enter a reason');
                return;
              }
            }
            Navigator.pop(context, reason);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkSoftRed : AppColors.softRed,
            foregroundColor: AppColors.pureWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Submit & Cancel'),
        ),
      ],
    );
  }
}
