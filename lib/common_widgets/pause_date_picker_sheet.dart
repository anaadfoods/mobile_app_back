import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:intl/intl.dart';

class PauseDatePickerSheet extends StatefulWidget {
  final int maxPausesLeft;
  final Function(DateTime, DateTime) onConfirm;

  const PauseDatePickerSheet({
    super.key,
    required this.maxPausesLeft,
    required this.onConfirm,
  });

  @override
  State<PauseDatePickerSheet> createState() => _PauseDatePickerSheetState();
}

class _PauseDatePickerSheetState extends State<PauseDatePickerSheet> {
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [AppColors.parchment, AppColors.parchment]
                  : [AppColors.parchment, AppColors.parchment!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.charcoal60 : AppColors.rawEarth12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pause Subscription',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.harvestAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.maxPausesLeft} pause${widget.maxPausesLeft != 1 ? 's' : ''} remaining',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.harvestAmber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.charcoal87 : AppColors.parchment,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    iconSize: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: DateButton(
                    label: 'From',
                    selectedDate: selectedStartDate,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 1),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: theme.copyWith(
                              colorScheme: theme.colorScheme.copyWith(
                                primary: AppColors.deepSoilGreen,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null)
                        setState(() => selectedStartDate = date);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 24,
                    color: theme.hintColor,
                  ),
                ),
                Expanded(
                  child: DateButton(
                    label: 'To',
                    selectedDate: selectedEndDate,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            selectedStartDate?.add(const Duration(days: 1)) ??
                            DateTime.now().add(const Duration(days: 2)),
                        firstDate: selectedStartDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: theme.copyWith(
                              colorScheme: theme.colorScheme.copyWith(
                                primary: AppColors.deepSoilGreen,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) setState(() => selectedEndDate = date);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.harvestAmber,
                    AppColors.harvestAmber.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.harvestAmber.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: AppColors.transparent,
                child: InkWell(
                  onTap: () {
                    if (widget.maxPausesLeft <= 0) {
                      SnackBarHelper.showError(context, 'No pauses remaining');
                      return;
                    }
                    if (selectedStartDate == null || selectedEndDate == null) {
                      SnackBarHelper.showError(
                        context,
                        'Please select both dates',
                      );
                      return;
                    }
                    if (selectedEndDate!.isBefore(selectedStartDate!)) {
                      SnackBarHelper.showError(
                        context,
                        'End date must be after start',
                      );
                      return;
                    }
                    Navigator.pop(context);
                    widget.onConfirm(selectedStartDate!, selectedEndDate!);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.pause_circle_rounded,
                          color: AppColors.parchment,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Pause Subscription',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.parchment,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class ResumeSubscriptionSheet extends StatelessWidget {
  final VoidCallback onConfirm;

  const ResumeSubscriptionSheet({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [AppColors.parchment, AppColors.parchment]
                  : [AppColors.parchment, AppColors.parchment!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal60 : AppColors.rawEarth12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Resume Subscription?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your deliveries will resume from the next scheduled date.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepSoilGreen,
                    foregroundColor: AppColors.parchment,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Resume'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class DateButton extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const DateButton({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDark
                    ? [AppColors.parchment, AppColors.parchment]
                    : [AppColors.parchment, AppColors.parchment!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                selectedDate != null
                    ? AppColors.deepSoilGreen
                    : (isDark ? AppColors.charcoal60! : AppColors.rawEarth12!),
            width: selectedDate != null ? 2 : 1,
          ),
          boxShadow:
              selectedDate != null
                  ? [
                    BoxShadow(
                      color: AppColors.deepSoilGreen.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: AppColors.charcoal.withValues(
                        alpha: isDark ? 0.3 : 0.05,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        selectedDate != null
                            ? AppColors.deepSoilGreen.withValues(alpha: 0.15)
                            : (isDark
                                ? AppColors.charcoal87
                                : AppColors.parchment),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color:
                        selectedDate != null
                            ? AppColors.deepSoilGreen
                            : theme.hintColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              selectedDate != null
                  ? DateFormat('MMM d, yyyy').format(selectedDate!)
                  : 'Select date',
              style: theme.textTheme.titleMedium?.copyWith(
                color: selectedDate != null ? null : theme.hintColor,
                fontWeight:
                    selectedDate != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
