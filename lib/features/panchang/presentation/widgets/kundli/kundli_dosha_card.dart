// lib/features/panchang/presentation/widgets/kundli/kundli_dosha_card.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/kundli_entities.dart';

class KundliDoshaCard extends StatelessWidget {
  final MangalDoshaReport mangalDosha;
  final SadeSatiReport sadeSati;

  const KundliDoshaCard({
    super.key,
    required this.mangalDosha,
    required this.sadeSati,
  });

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
                const Icon(Icons.shield_outlined, color: Color(0xFF2E6B34), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Astrological Doshas & Transits',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B2E1D),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildReportRow(
              title: 'Mangal (Kuja) Dosha',
              status: mangalDosha.isManglik ? (mangalDosha.isCancelled ? 'Cancelled' : 'Present') : 'Absent',
              severity: mangalDosha.severity,
              description: mangalDosha.description,
              color: mangalDosha.isManglik ? const Color(0xFFC0392B) : const Color(0xFF27AE60),
            ),
            const Divider(height: 16, color: Color(0xFFF0EBE1)),
            _buildReportRow(
              title: 'Shani Sade Sati',
              status: sadeSati.isActive ? sadeSati.phase : 'Inactive',
              severity: sadeSati.isActive ? 'ACTIVE' : 'NONE',
              description: sadeSati.description,
              color: sadeSati.isActive ? const Color(0xFF8E44AD) : const Color(0xFF27AE60),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow({
    required String title,
    required String status,
    required String severity,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF5D6D7E))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
