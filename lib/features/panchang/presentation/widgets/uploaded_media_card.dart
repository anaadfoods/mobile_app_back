import 'package:grocery_app/common_widgets/global_import.dart';

class UploadedMediaCard extends StatefulWidget {
  final bool isDark;
  final List<Map<String, dynamic>> medicalReports;
  final List<Map<String, dynamic>> foodThaliLogs;

  const UploadedMediaCard({
    super.key,
    required this.isDark,
    required this.medicalReports,
    required this.foodThaliLogs,
  });

  @override
  State<UploadedMediaCard> createState() => _UploadedMediaCardState();
}

class _UploadedMediaCardState extends State<UploadedMediaCard> {
  int _selectedIndex = 0; // 0 for Medical Reports, 1 for Food Thali

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (widget.isDark ? AppColors.pureWhite : AppColors.charcoal).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
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
                  color: (widget.isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.collections_rounded,
                  size: 20,
                  color: widget.isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Uploads',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Medical Reports & Food Thali',
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
          
          Row(
            children: [
              _buildFilterChip('Medical Reports', 0, theme),
              const SizedBox(width: 12),
              _buildFilterChip('Food Thali', 1, theme),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_selectedIndex == 0)
            _buildMedicalReportsGrid(theme)
          else
            _buildFoodThaliGrid(theme),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, ThemeData theme) {
    final isSelected = _selectedIndex == index;
    final selectedColor = widget.isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      selectedColor: selectedColor.withValues(alpha: 0.15),
      backgroundColor: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: isSelected ? selectedColor : theme.hintColor,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? selectedColor.withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildMedicalReportsGrid(ThemeData theme) {
    if (widget.medicalReports.isEmpty) {
      return _buildEmptyState('No medical reports uploaded yet.', Icons.description_outlined, theme);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: widget.medicalReports.length,
      itemBuilder: (context, index) {
        final item = widget.medicalReports[index];
        final title = item['title'] ?? 'Report';
        final date = item['date'] ?? 'Unknown Date';
        final status = item['status'] ?? 'COMPLETED';
        final isProcessing = status == 'PROCESSING';

        return Container(
          decoration: BoxDecoration(
            color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.picture_as_pdf_rounded,
                color: widget.isDark ? AppColors.softRed : AppColors.softRed,
                size: 32,
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isProcessing ? AppColors.amberWarn : AppColors.successGreen).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: isProcessing ? AppColors.amberWarn : AppColors.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoodThaliGrid(ThemeData theme) {
    if (widget.foodThaliLogs.isEmpty) {
      return _buildEmptyState('No food thali logs uploaded yet.', Icons.restaurant_menu_outlined, theme);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: widget.foodThaliLogs.length,
      itemBuilder: (context, index) {
        final item = widget.foodThaliLogs[index];
        final imageUrl = item['image_url'];
        final mealType = item['meal_type'] ?? 'Meal';
        final date = item['date'] ?? 'Unknown Date';

        return Container(
          decoration: BoxDecoration(
            color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(
                        color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        child: Icon(Icons.fastfood_outlined, color: theme.hintColor),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: theme.hintColor.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
