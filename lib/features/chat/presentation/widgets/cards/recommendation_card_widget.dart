import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

/// Renders Ayur Vigyan Wellness Recommendation Cards & Self Care Tips.
class RecommendationCardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;
  final List<Map<String, dynamic>> selfCareTips;

  const RecommendationCardWidget({
    Key? key,
    this.recommendations = const [],
    this.selfCareTips = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty && selfCareTips.isEmpty) {
      return const SizedBox.shrink();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 1. Recommendation Cards List ──
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 6),
          const Text(
            "🌿 Recommended for You",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.harvestAmber,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recommendations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final rec = recommendations[index];
                final String name =
                    (rec['name'] ?? rec['title'] ?? 'Ayurvedic Practice')
                        .toString();
                final String reason =
                    (rec['reason'] ?? rec['usage'] ?? '').toString();
                final String type = (rec['type'] ?? 'product').toString();
                final String price =
                    rec['price'] != null ? '₹${rec['price']}' : '';
                final dynamic recId =
                    rec['id'] ??
                    (rec['cta'] is Map ? rec['cta']['product_id'] : null);

                return Container(
                  width: 175,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.charcoal,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.white10,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            type == 'practice'
                                ? Icons.self_improvement_rounded
                                : Icons.eco_rounded,
                            color: AppColors.harvestAmber,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (reason.isNotEmpty)
                        Text(
                          reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10.8,
                            height: 1.25,
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (price.isNotEmpty)
                            Text(
                              price,
                              style: const TextStyle(
                                color: AppColors.harvestAmber,
                                fontSize: 11.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (recId != null)
                            InkWell(
                              onTap: () => context.push('/product/$recId'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.harvestAmber,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  "View",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],

        // ── 2. Self Care Tips ──
        if (selfCareTips.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.harvestAmber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.harvestAmber.withValues(alpha: 0.22),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.harvestAmber,
                      size: 13.5,
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Daily Wellness Tips",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.harvestAmber,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                ...selfCareTips.map((tip) {
                  String text = (tip['text'] ?? tip['description'] ?? tip['title'] ?? tip.toString()).toString().trim();
                  
                  // Filter out raw serialized JSON artifacts or stray brackets
                  if (text == '{' || text == '}' || text.startsWith('{"') || text.startsWith("{'") || text.contains('"url"') || text.contains("'url'")) {
                    if (tip['description'] != null && tip['description'].toString().trim().isNotEmpty) {
                      text = tip['description'].toString().trim();
                    } else if (tip['title'] != null && tip['title'].toString().trim().isNotEmpty) {
                      text = tip['title'].toString().trim();
                    } else {
                      return const SizedBox.shrink();
                    }
                  }

                  // Strip redundant leading bullets or colons
                  text = text.replaceAll(RegExp(r'^[•\-\*:]\s*'), '').trim();
                  if (text.isEmpty || text == '{' || text == '}') return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.2),
                    child: Text(
                      "• $text",
                      style: TextStyle(
                        fontSize: 11.6,
                        color: isDark ? Colors.white70 : AppColors.charcoal,
                        height: 1.32,
                      ),
                    ),
                  );
                }).where((widget) => widget is! SizedBox).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
