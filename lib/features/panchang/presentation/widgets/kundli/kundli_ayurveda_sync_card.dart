// lib/features/panchang/presentation/widgets/kundli/kundli_ayurveda_sync_card.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/kundli_entities.dart';

class KundliAyurvedaSyncCard extends StatelessWidget {
  final AstrologicalBodyType bodyType;
  final VoidCallback? onAskAyurAI;

  const KundliAyurvedaSyncCard({
    super.key,
    required this.bodyType,
    this.onAskAyurAI,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.5)),
      ),
      color: const Color(0xFFFAF7EE),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.spa_rounded, color: Color(0xFF2E6B34), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kundli ↔ Body Type Harmony',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B2E1D),
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E6B34).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bodyType.astrologicalPrakriti,
                    style: const TextStyle(
                      color: Color(0xFF2E6B34),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Lagna Element: ${bodyType.lagnaElement} | Lagna Lord: ${bodyType.lagnaLord}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5D6D7E),
              ),
            ),
            const SizedBox(height: 12),
            // Dosha Progress Bars
            _buildDoshaBar('Vata (Air & Ether)', bodyType.vataScore, const Color(0xFF2980B9)),
            const SizedBox(height: 6),
            _buildDoshaBar('Pitta (Fire & Water)', bodyType.pittaScore, const Color(0xFFC0392B)),
            const SizedBox(height: 6),
            _buildDoshaBar('Kapha (Earth & Water)', bodyType.kaphaScore, const Color(0xFF27AE60)),
            const SizedBox(height: 16),
            if (bodyType.foodsToFavor.isNotEmpty) ...[
              const Text(
                'Foods to Favor:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2E1D)),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: bodyType.foodsToFavor.map((f) {
                  return Chip(
                    label: Text(f, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            if (onAskAyurAI != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAskAyurAI,
                  icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF2E6B34)),
                  label: const Text('Consult Ayur AI on Kundli Diet', style: TextStyle(color: Color(0xFF2E6B34))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2E6B34)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoshaBar(String label, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Text('${score.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (score / 100).clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFE5DECC),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
