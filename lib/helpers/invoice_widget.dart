import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/features/subscriptions/domain/repositories/subscriptions_repository.dart';
import 'package:grocery_app/styles/colors.dart';

class InvoiceTrackerWidget extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<InvoiceEntity> invoices;
  final Function(InvoiceEntity) onInvoiceTap;

  const InvoiceTrackerWidget({
    super.key,
    required this.isLoading,
    this.error,
    required this.invoices,
    required this.onInvoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.deepSoilGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color:
                      isDark
                          ? AppColors.amberWarn.withValues(alpha: 0.5)
                          : AppColors.deepSoilGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Invoices',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              if (!isLoading && invoices.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.deepSoilGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${invoices.length}',
                    style: const TextStyle(
                      color: AppColors.parchment,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.deepSoilGreen.withValues(alpha: 0.6),
                      AppColors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        _buildContent(context, theme, isDark),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, bool isDark) {
    if (isLoading) return _buildLoadingState(isDark);
    if (error != null || invoices.isEmpty)
      return _buildEmptyState(theme, isDark);
    return _buildInvoiceList(context, theme, isDark);
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.parchment.withValues(alpha: 0.05)
                : AppColors.deepSoilGreen.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.deepSoilGreen,
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.parchment.withValues(alpha: 0.05)
                : AppColors.deepSoilGreen.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
                  ? AppColors.parchment.withValues(alpha: 0.08)
                  : AppColors.deepSoilGreen.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 32,
            color:
                isDark
                    ? AppColors.amberWarn.withValues(alpha: 0.5)
                    : AppColors.deepSoilGreen.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No invoices yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Invoices will appear here once generated.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceList(BuildContext context, ThemeData theme, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder:
          (context, index) =>
              _buildInvoiceCard(invoices[index], index, theme, isDark),
    );
  }

  Widget _buildInvoiceCard(
    InvoiceEntity invoice,
    int index,
    ThemeData theme,
    bool isDark,
  ) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => onInvoiceTap(invoice),
        borderRadius: BorderRadius.circular(14),
        splashColor: AppColors.deepSoilGreen.withValues(alpha: 0.08),
        highlightColor: AppColors.deepSoilGreen.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            color:
                isDark
                    ? AppColors.parchment.withValues(alpha: 0.06)
                    : theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isDark
                      ? AppColors.parchment.withValues(alpha: 0.09)
                      : AppColors.deepSoilGreen.withValues(alpha: 0.13),
            ),
            boxShadow:
                isDark
                    ? null
                    : [
                      BoxShadow(
                        color: AppColors.deepSoilGreen.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                // Index badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.deepSoilGreen,
                        AppColors.deepSoilGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.parchment,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Invoice info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.tag_rounded,
                            size: 11,
                            color: AppColors.deepSoilGreen.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            invoice.invoiceNumber,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Download button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: AppColors.deepSoilGreen,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
