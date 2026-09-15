import 'package:grocery_app/common_widgets/global_import.dart';

/// Kundli Summary Card for the Personalized View
class KundliSummaryCard extends StatelessWidget {
  final Map<String, dynamic>? kundliData;
  final bool isDark;

  const KundliSummaryCard({
    super.key,
    this.kundliData,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBirthDetails = kundliData != null && kundliData!['lagna'] != null;
    final name = hasBirthDetails ? (kundliData!['birth_details']?['name'] ?? kundliData!['kundli_person_name'] ?? '') as String : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(hasBirthDetails ? '/kundli-details' : '/kundli-input'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.pureWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          size: 20,
                          color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? "$name's Natal Kundli Summary" : 'Your Natal Kundli Summary',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'Vedic Astrology & Astrological Prakriti',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (hasBirthDetails)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              if (hasBirthDetails)
                _buildKundliDetails(context, theme, name)
              else
                _buildEmptyState(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKundliDetails(BuildContext context, ThemeData theme, String name) {
    final lagna = kundliData!['lagna'] ?? {};
    final moonSign = kundliData!['janma_rashi_en'] ?? kundliData!['janma_rashi'] ?? 'Libra';
    final sunSign = kundliData!['sun_sign_en'] ?? kundliData!['sun_sign'] ?? 'Leo';
    final nakshatra = kundliData!['janma_nakshatra'] ?? 'Swati';
    final pada = kundliData!['janma_nakshatra_pada'] ?? 1;

    return Column(
      children: [
        if (name.isNotEmpty) ...[
          Text(
            name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(child: _buildItemTile('Lagna (Ascendant)', '${lagna['sign_en'] ?? 'Scorpio'} ${lagna['degree'] ?? 0}°', theme)),
            const SizedBox(width: 12),
            Expanded(child: _buildItemTile('Moon Sign (Rashi)', moonSign, theme)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildItemTile('Sun Sign', sunSign, theme)),
            const SizedBox(width: 12),
            Expanded(child: _buildItemTile('Janma Nakshatra', '$nakshatra (P$pada)', theme)),
          ],
        ),
      ],
    );
  }

  Widget _buildItemTile(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete your birth details to generate your personalized Vedic Kundli, Dasha periods, and Astrological Prakriti.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: () {
            context.push('/kundli-input');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
            foregroundColor: isDark ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
          label: const Text('Add Birth Details', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
