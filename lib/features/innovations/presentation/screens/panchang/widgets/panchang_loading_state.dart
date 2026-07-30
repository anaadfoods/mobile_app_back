import 'package:grocery_app/common_widgets/global_import.dart';

class PanchangLoadingState extends StatefulWidget {
  const PanchangLoadingState({super.key});

  @override
  State<PanchangLoadingState> createState() => _PanchangLoadingStateState();
}

class _PanchangLoadingStateState extends State<PanchangLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildShimmerCard(height: 120),
          const SizedBox(height: 20),
          _buildShimmerCard(
            height: (MediaQuery.sizeOf(context).width * 0.75).clamp(280.0, 320.0),
          ),
          const SizedBox(height: 20),
          _buildShimmerCard(height: 150),
        ],
      ),
    );
  }

  Widget _buildShimmerCard({required double height}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
              colors: isDark
                  ? [
                      AppColors.charcoal.withValues(alpha: 0.8),
                      AppColors.deepSoilGreen.withValues(alpha: 0.6),
                      AppColors.charcoal.withValues(alpha: 0.8),
                    ]
                  : [
                      AppColors.rawEarth12,
                      Theme.of(context).scaffoldBackgroundColor,
                      AppColors.rawEarth12,
                    ],
            ),
          ),
        );
      },
    );
  }
}
