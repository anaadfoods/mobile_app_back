import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

class CancelWarningDialog extends StatelessWidget {
  final String type; // 'order' or 'subscription'

  const CancelWarningDialog({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.softCream,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkSoftRed : AppColors.softRed).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: isDark ? AppColors.darkSoftRed : AppColors.softRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Warning'),
        ],
      ),
      content: Text(
        type == 'order'
            ? 'Cancelling this order is permanent. Once cancelled, it cannot be processed or shipped.'
            : 'Cancelling this subscription will stop all future scheduled deliveries permanently.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.parchment.withValues(alpha: 0.7) : AppColors.charcoal54,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Go Back',
            style: TextStyle(
              color: isDark ? AppColors.parchment.withValues(alpha: 0.6) : AppColors.charcoal40,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkSoftRed : AppColors.softRed,
            foregroundColor: AppColors.pureWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Proceed to Cancel'),
        ),
      ],
    );
  }
}

class CancelConfirmDialog extends StatelessWidget {
  final String type; // 'order' or 'subscription'

  const CancelConfirmDialog({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.softCream,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkSoftRed : AppColors.softRed).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.help_outline_rounded,
              color: isDark ? AppColors.darkSoftRed : AppColors.softRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(type == 'order' ? 'Cancel Order?' : 'Cancel Subscription?'),
        ],
      ),
      content: Text(
        type == 'order'
            ? 'Are you absolutely sure you want to cancel this order? This action cannot be undone.'
            : 'Are you absolutely sure you want to cancel this subscription? All scheduled deliveries will be lost.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.parchment.withValues(alpha: 0.7) : AppColors.charcoal54,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'No, Keep It',
            style: TextStyle(
              color: isDark ? AppColors.parchment.withValues(alpha: 0.6) : AppColors.charcoal40,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkSoftRed : AppColors.softRed,
            foregroundColor: AppColors.pureWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Yes, Cancel'),
        ),
      ],
    );
  }
}

class CancelReasonDialog extends StatefulWidget {
  final String type; // 'order' or 'subscription'

  const CancelReasonDialog({super.key, required this.type});

  @override
  State<CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<CancelReasonDialog> {
  final List<String> _reasons = [
    'Found a better alternative / price',
    'No longer need the products / changed my mind',
    'Delivery is taking too long / scheduling issues',
    'Quality or quantity concerns',
    'Other (Please specify)',
  ];

  String? _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.softCream,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkSoftRed : AppColors.softRed).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.help_outline_rounded,
              color: isDark ? AppColors.darkSoftRed : AppColors.softRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(widget.type == 'order' ? 'Cancel Order?' : 'Cancel Subscription?'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why are you cancelling?',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.parchment : AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 12),
            ..._reasons.map((reason) {
              return Theme(
                data: theme.copyWith(
                  unselectedWidgetColor: isDark
                      ? AppColors.parchment.withValues(alpha: 0.5)
                      : AppColors.charcoal40,
                ),
                child: RadioListTile<String>(
                  title: Text(
                    reason,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.parchment.withValues(alpha: 0.9)
                          : AppColors.charcoal87,
                    ),
                  ),
                  value: reason,
                  groupValue: _selectedReason,
                  activeColor: isDark ? AppColors.darkSoftRed : AppColors.softRed,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() {
                      _selectedReason = val;
                    });
                  },
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkSoftRed : AppColors.softRed,
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
            'No, Keep It',
            style: TextStyle(
              color: isDark ? AppColors.parchment.withValues(alpha: 0.6) : AppColors.charcoal40,
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
                SnackBarHelper.showError(context, 'Please write your reason');
                return;
              }
            }
            Navigator.pop(context, reason);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkSoftRed : AppColors.softRed,
            foregroundColor: AppColors.pureWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Yes, Cancel'),
        ),
      ],
    );
  }
}
