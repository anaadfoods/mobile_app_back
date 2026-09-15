import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/models/panchang/panchang_day_models.dart';

/// Modern wellness-styled Planetary Positions Card
/// Displays 9 Vedic Grahas with sidereal signs, formatted degrees (e.g. Libra 6°45′),
/// retrograde indicators, and Nakshatra/Pada details.
class PlanetaryPositionsCard extends StatelessWidget {
  final Map<String, PanchangPlanetItem> planets;
  final bool isDark;

  const PlanetaryPositionsCard({
    super.key,
    required this.planets,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;

    final planetList = [
      planets['Sun'],
      planets['Moon'],
      planets['Mars'],
      planets['Mercury'],
      planets['Jupiter'],
      planets['Venus'],
      planets['Saturn'],
      planets['Rahu'],
      planets['Ketu'],
    ].whereType<PanchangPlanetItem>().toList();

    if (planetList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.public_rounded,
                  size: 20,
                  color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planetary Positions (Graha Sthiti)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Lahiri Sidereal Zodiac • JPL Ephemeris',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (isDesktop)
            _buildDesktopTable(context, planetList)
          else
            _buildMobileGrid(context, planetList),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<PanchangPlanetItem> list) {
    final theme = Theme.of(context);
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2.5),
        2: FlexColumnWidth(2.5),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
              ),
            ),
          ),
          children: [
            _buildHeaderCell('Graha / Planet', theme),
            _buildHeaderCell('Sidereal Rashi', theme),
            _buildHeaderCell('Nakshatra • Pada', theme),
            _buildHeaderCell('Motion', theme),
          ],
        ),
        ...list.map((p) => TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  _getPlanetIcon(p.name),
                  const SizedBox(width: 8),
                  Text(
                    p.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                p.formatted.isNotEmpty ? p.formatted : '${p.rashiEn} ${p.degreeInRashi.toStringAsFixed(1)}°',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                p.nakshatra != null ? '${p.nakshatra} (P${p.nakshatraPada ?? 1})' : '—',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _buildMotionBadge(p.isRetrograde),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildMobileGrid(BuildContext context, List<PanchangPlanetItem> list) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: list.map((p) {
            final width = (constraints.maxWidth - 10) / 2;
            return SizedBox(
              width: width,
              child: _buildMobilePlanetCard(context, p),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMobilePlanetCard(BuildContext context, PanchangPlanetItem p) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.softCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getPlanetIcon(p.name),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  p.name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (p.isRetrograde) ...[
                const SizedBox(width: 4),
                _buildMotionBadge(true, compact: true),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            p.formatted.isNotEmpty ? p.formatted : '${p.rashiEn} ${p.degreeInRashi.toStringAsFixed(1)}°',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
            ),
          ),
          if (p.nakshatra != null) ...[
            const SizedBox(height: 4),
            Text(
              '${p.nakshatra} • P${p.nakshatraPada ?? 1}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMotionBadge(bool isRetrograde, {bool compact = false}) {
    final color = isRetrograde ? AppColors.harvestAmber : AppColors.successGreen;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        isRetrograde ? (compact ? 'Retro (R)' : 'Retrograde (R)') : 'Direct',
        style: TextStyle(
          color: color,
          fontSize: compact ? 9.5 : 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _getPlanetIcon(String name) {
    IconData icon;
    Color color;
    switch (name) {
      case 'Sun':
        icon = Icons.wb_sunny_rounded;
        color = Colors.amber;
        break;
      case 'Moon':
        icon = Icons.nightlight_round;
        color = Colors.blueGrey;
        break;
      case 'Mars':
        icon = Icons.circle;
        color = Colors.redAccent;
        break;
      case 'Mercury':
        icon = Icons.trip_origin_rounded;
        color = Colors.green;
        break;
      case 'Jupiter':
        icon = Icons.brightness_auto_rounded;
        color = Colors.orange;
        break;
      case 'Venus':
        icon = Icons.auto_awesome;
        color = Colors.pinkAccent;
        break;
      case 'Saturn':
        icon = Icons.album_outlined;
        color = Colors.deepPurpleAccent;
        break;
      case 'Rahu':
      case 'Ketu':
        icon = Icons.all_inclusive_rounded;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.circle;
        color = Colors.grey;
    }
    return Icon(icon, size: 14, color: color);
  }
}
