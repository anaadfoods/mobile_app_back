import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/screens/RFP/delivery_screen.dart';
import 'package:grocery_app/helpers/color_extractor.dart';
import 'dart:math' as math;

class CarouselItem {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  const CarouselItem({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });
}

class TopCurosel extends StatefulWidget {
  /// Callback that fires when the dominant color changes based on carousel image
  final ValueChanged<Color>? onColorChanged;

  const TopCurosel({super.key, this.onColorChanged});

  @override
  State<TopCurosel> createState() => _TopCuroselState();
}

class _TopCuroselState extends State<TopCurosel>
    with SingleTickerProviderStateMixin {
  final CarouselController _carouselController = CarouselController();
  int _currentPage = 0;

  /// Pre-extracted colors for each carousel image
  List<Color> _extractedColors = [];
  bool _colorsLoaded = false;

  /// Animation controller for pulse/glow effect
  late AnimationController _pulseController;

  // Define carousel items as class-level for color extraction
  late List<CarouselItem> _carouselItems;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _initCarouselItems();
    _extractColors();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initCarouselItems() {
    _carouselItems = [
      CarouselItem(
        imageUrl:
            'https://res.cloudinary.com/dcuwcjq1f/image/upload/v1759836582/atta_chaki_carousel_zowh5e.jpg',
        title: ' Ground slowly',
        subtitle:
            "Low RPM Natural Stone Milling of the flour preserves every bit of nutrition",
        buttonText: 'See the Product',
        onTap: () {
          final dashboardState =
              context.findAncestorStateOfType<DashboardScreenState>();
          dashboardState?.switchToTab(3);
        },
      ),
      CarouselItem(
        imageUrl:
            'https://res.cloudinary.com/dcuwcjq1f/image/upload/v1759836622/atta_crousel_image_dpennd.jpg',
        title: 'We don’t manufacture. We grow',
        subtitle: 'A return to Truly Nutritional Food',
        buttonText: 'Read Our Roots',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AboutScreen()),
          );
        },
      ),
      CarouselItem(
        imageUrl:
            'https://res.cloudinary.com/dcuwcjq1f/image/upload/v1759836642/farm_carousel_lcnpp8.jpg',
        title: 'Picked before the sun rose',
        subtitle: "Harvested only when you order. Not a moment sooner",
        buttonText: 'Visit our Plot',
        onTap: () async {
          final produt = await CategoryService.fetchProductById(2);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: produt),
            ),
          );
        },
      ),
      CarouselItem(
        imageUrl:
            'https://res.cloudinary.com/dcuwcjq1f/image/upload/v1759836653/farmer_consultancy_aaosxa.jpg',
        title: ' Remote Farming Program',
        subtitle: " You can’t be at the farm. So we bring the farm to you.",
        buttonText: 'Visit our Plot',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (buiilder) {
                return DeliveryScreen();
              },
            ),
          );
        },
      ),
    ];
  }

  /// Extract dominant colors from all carousel images
  Future<void> _extractColors() async {
    final imageUrls = _carouselItems.map((item) => item.imageUrl).toList();

    try {
      final colors = await ColorExtractor.extractColorsFromUrls(imageUrls);
      if (mounted) {
        setState(() {
          _extractedColors = colors;
          _colorsLoaded = true;
        });
        // Notify parent with the first image's color
        if (colors.isNotEmpty) {
          widget.onColorChanged?.call(colors[0]);
        }
      }
    } catch (e) {
      debugPrint('Failed to extract carousel colors: $e');
    }
  }

  /// Notify parent when carousel page changes
  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });

    // Notify parent with the new color
    if (_colorsLoaded && _extractedColors.isNotEmpty) {
      widget.onColorChanged?.call(_extractedColors[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final glowIntensity =
                0.2 + (math.sin(_pulseController.value * math.pi * 2) * 0.15);
            final currentColor =
                _colorsLoaded && _extractedColors.isNotEmpty
                    ? _extractedColors[_currentPage]
                    : colorScheme.primary;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: currentColor.withOpacity(glowIntensity),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: currentColor.withOpacity(glowIntensity * 0.5),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: CarouselSlider.builder(
                itemCount: _carouselItems.length,
                itemBuilder: (context, index, realIndex) {
                  final item = _carouselItems[index];
                  final isActive = index == _currentPage;
                  final itemColor =
                      _colorsLoaded && _extractedColors.length > index
                          ? _extractedColors[index]
                          : colorScheme.primary;

                  return AnimatedScale(
                    scale: isActive ? 1.0 : 0.92,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: isActive ? 1.0 : 0.7,
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow:
                              isActive
                                  ? [
                                    BoxShadow(
                                      color: itemColor.withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                  : [],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.6),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.center,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 16,
                                right: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.title,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          const Shadow(
                                            blurRadius: 2,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.subtitle,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: Colors.white.withOpacity(0.95),
                                        fontWeight: FontWeight.w500,
                                        shadows: [
                                          const Shadow(
                                            blurRadius: 2,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        height: 28,
                                        child: TextButton(
                                          onPressed: item.onTap,
                                          style: TextButton.styleFrom(
                                            backgroundColor: colorScheme.primary
                                                .withOpacity(0.9),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            item.buttonText,
                                            style: textTheme.labelMedium
                                                ?.copyWith(
                                                  fontSize: 10,
                                                  color: colorScheme.onPrimary,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                  viewportFraction: 1,
                  height: screenHeight * 0.22,
                  autoPlay: true,
                  enlargeCenterPage: false,
                  enableInfiniteScroll: true,
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayCurve: Curves.easeOutCubic,
                  onPageChanged: (index, reason) {
                    _onPageChanged(index);
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        AnimatedSmoothIndicator(
          activeIndex: _currentPage,
          count: _carouselItems.length,
          effect: ExpandingDotsEffect(
            activeDotColor: colorScheme.primary,
            dotColor: theme.disabledColor,
            dotHeight: 8,
            dotWidth: 8,
          ),
          onDotClicked: (index) {
            _carouselController.animateToPage(
              index,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
          },
        ),
      ],
    );
  }
}

extension on CarouselController {
  void animateToPage(
    int index, {
    required Duration duration,
    required Cubic curve,
  }) {}
}

