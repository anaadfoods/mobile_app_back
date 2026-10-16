import 'package:flutter/material.dart';

/// Timeline row widget for the Seasonal Journey Harvest Log.
class RfpTimelineItemTile extends StatelessWidget {
  final Widget node;
  final String title;
  final String? trailingText;
  final Color? trailingTextColor;
  final Widget? trailingBadge;
  final String? subtitle;
  final String? quoteReason;
  final bool isFuture;
  final bool isLast;

  const RfpTimelineItemTile({
    super.key,
    required this.node,
    required this.title,
    this.trailingText,
    this.trailingTextColor,
    this.trailingBadge,
    this.subtitle,
    this.quoteReason,
    this.isFuture = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                node,
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color:
                                isFuture
                                    ? const Color(0xFF718096)
                                    : const Color(0xFF1A202C),
                          ),
                        ),
                      ),
                      if (trailingBadge != null)
                        trailingBadge!
                      else if (trailingText != null)
                        Text(
                          trailingText!,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: trailingTextColor ?? const Color(0xFF4A5568),
                          ),
                        ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                  if (quoteReason != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF2F5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFF3D2DF),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '"$quoteReason"',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8B2C4D),
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nodes and badges for timeline items
class RfpTimelineNodes {
  static Widget completed() {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Color(0xFF1E7E34),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 11, color: Colors.white),
    );
  }

  static Widget cancelled() {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Color(0xFFD688A6),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.close, size: 11, color: Colors.white),
    );
  }

  static Widget activeHalo() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1E7E34), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E7E34).withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF1E7E34),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  static Widget future() {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: const BoxDecoration(
        color: Color(0xFFCBD5E1),
        shape: BoxShape.circle,
      ),
    );
  }

  static Widget cancelledBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'CANCELLED / DELAYED',
        style: TextStyle(
          color: Color(0xFFC62828),
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
