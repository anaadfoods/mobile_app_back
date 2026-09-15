import 'package:grocery_app/common_widgets/global_import.dart';

class AiMemoryCard extends StatelessWidget {
  final bool isDark;
  final List<Map<String, dynamic>> memoryFacts;
  final bool isLoading;

  const AiMemoryCard({
    super.key,
    required this.isDark,
    required this.memoryFacts,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && memoryFacts.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);

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
                  Icons.psychology_alt_rounded,
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
                      'AI Memory',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'What Anaad AI knows about you',
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
          
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (memoryFacts.isNotEmpty)
            _buildFactsList(theme)
          else
            _buildEmptyState(theme),
        ],
      ),
    );
  }

  Widget _buildFactsList(ThemeData theme) {
    final displayFacts = memoryFacts.take(10).toList();
    final hasMore = memoryFacts.length > 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayFacts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final factData = displayFacts[index];
            final fact = factData['fact'] ?? '';
            final category = (factData['category'] ?? '').toString().toLowerCase();
            final updatedAt = factData['updated_at'] ?? '';
            
            IconData iconData = Icons.lightbulb_outline;
            if (category.contains('medical') || category.contains('health')) {
              iconData = Icons.medical_services_outlined;
            } else if (category.contains('diet') || category.contains('food')) {
              iconData = Icons.restaurant_outlined;
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  iconData,
                  size: 16,
                  color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fact,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                      ),
                      if (updatedAt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(updatedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        if (hasMore) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                // Show more action
              },
              child: Text(
                'Show more (${memoryFacts.length - 10})',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 40,
              color: theme.hintColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No memories yet. Chat with Anaad AI to start building your health profile.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
