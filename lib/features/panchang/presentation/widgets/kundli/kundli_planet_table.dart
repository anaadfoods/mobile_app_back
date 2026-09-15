// lib/features/panchang/presentation/widgets/kundli/kundli_planet_table.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/kundli_entities.dart';

class KundliPlanetTable extends StatelessWidget {
  final List<KundliPlanet> planets;

  const KundliPlanetTable({super.key, required this.planets});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFE5DECC)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFF2E6B34), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Planetary Positions (Grahas)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B2E1D),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 38,
                dataRowMaxHeight: 42,
                horizontalMargin: 8,
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('Graha', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Rashi', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Deg', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('House', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Nakshatra', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Dosha', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: planets.map((p) {
                  return DataRow(
                    cells: [
                      DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text('${p.rashi} (${p.rashiEn})')),
                      DataCell(Text('${p.degree}°')),
                      DataCell(Text('H${p.house}')),
                      DataCell(Text('${p.nakshatra} (P${p.nakshatraPada})')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDoshaColor(p.dosha).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p.dosha,
                            style: TextStyle(
                              color: _getDoshaColor(p.dosha),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDoshaColor(String dosha) {
    switch (dosha.toUpperCase()) {
      case 'PITTA':
        return const Color(0xFFC0392B);
      case 'VATA':
        return const Color(0xFF2980B9);
      case 'KAPHA':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF7F8C8D);
    }
  }
}
