import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ThemeDemoScreen — Demonstrates every pillar of the global theme system.
///
/// This screen is a living reference for the team. It shows:
///   • Text styled exclusively via the theme (context.text / AppTextStyles)
///   • Buttons using the global ElevatedButton / OutlinedButton / TextButton themes
///   • Containers using AppSpacing + AppColors
///   • Context extensions (context.colors, context.isDark)
///   • No hardcoded colors, no inline TextStyle, no magic padding numbers
/// ═══════════════════════════════════════════════════════════════════════════
class ThemeDemoScreen extends StatelessWidget {
  const ThemeDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme System Demo')),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: Typography ──────────────────────────────────────
            _SectionHeader(title: 'Typography'),
            AppSpacing.verticalSm,
            Text('Heading Style', style: context.text.displayLarge),
            AppSpacing.verticalXs,
            Text('Subheading Style', style: context.text.displayMedium),
            AppSpacing.verticalXs,
            Text('Title Style', style: context.text.displaySmall),
            AppSpacing.verticalXs,
            Text('Body Large Style', style: context.text.bodyLarge),
            AppSpacing.verticalXs,
            Text('Body Medium (Secondary)', style: context.text.bodyMedium),
            AppSpacing.verticalXs,
            Text('Caption Style', style: context.text.bodySmall),
            AppSpacing.verticalXs,
            Text(
              'Button Label Style',
              style: context.text.labelLarge?.copyWith(
                color: context.colors.primary,
              ),
            ),

            AppSpacing.verticalXl,

            // ── Section 2: Color Palette ──────────────────────────────────
            _SectionHeader(title: 'Color Palette'),
            AppSpacing.verticalSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ColorChip(label: 'Primary', color: AppColors.deepSoilGreen),
                _ColorChip(
                  label: 'Primary Light',
                  color: AppColors.deepSoilGreen,
                ),
                _ColorChip(label: 'Secondary', color: AppColors.rawEarth),
                _ColorChip(label: 'Button BG', color: AppColors.deepSoilGreen),
                _ColorChip(label: 'Success', color: AppColors.deepSoilGreen),
                _ColorChip(label: 'Error', color: AppColors.rawEarth),
                _ColorChip(label: 'Warning', color: AppColors.harvestAmber),
                _ColorChip(label: 'Info', color: AppColors.deepSoilGreen),
              ],
            ),

            AppSpacing.verticalXl,

            // ── Section 3: Buttons ────────────────────────────────────────
            _SectionHeader(title: 'Buttons'),
            AppSpacing.verticalSm,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Elevated Button'),
              ),
            ),
            AppSpacing.verticalMd,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Outlined Button'),
              ),
            ),
            AppSpacing.verticalMd,
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('Text Button'),
              ),
            ),

            AppSpacing.verticalXl,

            // ── Section 4: Input Field ────────────────────────────────────
            _SectionHeader(title: 'Input Field'),
            AppSpacing.verticalSm,
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'user@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),

            AppSpacing.verticalXl,

            // ── Section 5: Spacing Demo ───────────────────────────────────
            _SectionHeader(title: 'Spacing Scale'),
            AppSpacing.verticalSm,
            _SpacingBar(
              label: 'xs (${AppSpacing.xs})',
              width: AppSpacing.xs * 10,
            ),
            AppSpacing.verticalXs,
            _SpacingBar(
              label: 'sm (${AppSpacing.sm})',
              width: AppSpacing.sm * 10,
            ),
            AppSpacing.verticalXs,
            _SpacingBar(
              label: 'md (${AppSpacing.md})',
              width: AppSpacing.md * 10,
            ),
            AppSpacing.verticalXs,
            _SpacingBar(
              label: 'lg (${AppSpacing.lg})',
              width: AppSpacing.lg * 10,
            ),
            AppSpacing.verticalXs,
            _SpacingBar(
              label: 'xl (${AppSpacing.xl})',
              width: AppSpacing.xl * 10,
            ),
            AppSpacing.verticalXs,
            _SpacingBar(
              label: 'xxl (${AppSpacing.xxl})',
              width: AppSpacing.xxl * 10,
            ),

            AppSpacing.verticalXl,

            // ── Section 6: Card with theme-aware container ────────────────
            _SectionHeader(title: 'Themed Container'),
            AppSpacing.verticalSm,
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppColors.radiusM),
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.deepSoilGreen,
                        size: 20,
                      ),
                      AppSpacing.horizontalSm,
                      Text(
                        'Theme system active',
                        style: context.text.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalSm,
                  Text(
                    'This container uses AppSpacing for padding, '
                    'AppColors for the border radius constant, '
                    'and context.colors for theme-aware colors.',
                    style: context.text.bodyMedium,
                  ),
                ],
              ),
            ),

            AppSpacing.verticalXl,

            // ── Section 7: Theme Info ─────────────────────────────────────
            _SectionHeader(title: 'Theme Info'),
            AppSpacing.verticalSm,
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color:
                    context.isDark
                        ? AppColors.parchment.withValues(alpha: 0.05)
                        : AppColors.charcoal.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(AppColors.radiusS),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'context.isDark', value: '${context.isDark}'),
                  AppSpacing.verticalXs,
                  _InfoRow(
                    label: 'Screen width',
                    value: '${context.screenWidth.toStringAsFixed(0)}px',
                  ),
                  AppSpacing.verticalXs,
                  _InfoRow(
                    label: 'Screen height',
                    value: '${context.screenHeight.toStringAsFixed(0)}px',
                  ),
                  AppSpacing.verticalXs,
                  _InfoRow(
                    label: 'Primary color',
                    value:
                        '#${context.colors.primary.toARGB32().toRadixString(16).toUpperCase()}',
                  ),
                ],
              ),
            ),

            AppSpacing.verticalXxl,
          ],
        ),
      ),
    );
  }
}

// ── Private helper widgets ───────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.text.displaySmall?.copyWith(
            color: context.colors.primary,
          ),
        ),
        AppSpacing.verticalXs,
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _ColorChip extends StatelessWidget {
  final String label;
  final Color color;
  const _ColorChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final textColor =
        color.computeLuminance() > 0.5
            ? AppColors.charcoal87
            : AppColors.parchment;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppColors.radiusS),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SpacingBar extends StatelessWidget {
  final String label;
  final double width;
  const _SpacingBar({required this.label, required this.width});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: context.text.bodySmall)),
        AppSpacing.horizontalSm,
        Container(
          height: 16,
          width: width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.colors.primary,
                context.colors.primary.withValues(alpha: 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.text.bodyMedium),
        Text(
          value,
          style: context.text.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
