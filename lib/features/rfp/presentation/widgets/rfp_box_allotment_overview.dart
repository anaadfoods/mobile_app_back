import 'package:flutter/material.dart';

/// Box Allotment Overview with circular thumbnails (Delivered vs Locked).
class RfpBoxAllotmentOverview extends StatelessWidget {
  const RfpBoxAllotmentOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Box Allotment Overview',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '6-Week Season',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAllotmentItem(
                  title: 'Root Veg',
                  subtitle: 'Delivered',
                  subtitleColor: const Color(0xFF1E7E34),
                  icon: Icons.eco,
                  isLocked: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAllotmentItem(
                  title: 'Greens Tub',
                  subtitle: 'Delivered',
                  subtitleColor: const Color(0xFF1E7E34),
                  icon: Icons.local_florist,
                  isLocked: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAllotmentItem(
                  title: 'Winter Orcha...',
                  subtitle: 'Locked',
                  subtitleColor: const Color(0xFF94A3B8),
                  icon: Icons.lock,
                  isLocked: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllotmentItem({
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
    required bool isLocked,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFF8FAFC) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLocked ? const Color(0xFFE2E8F0) : const Color(0xFFDCFCE7),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isLocked ? const Color(0xFFE2E8F0) : const Color(0xFFBBF7D0),
            ),
            child: Icon(
              icon,
              size: 20,
              color:
                  isLocked ? const Color(0xFF94A3B8) : const Color(0xFF166534),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color:
                  isLocked ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}
