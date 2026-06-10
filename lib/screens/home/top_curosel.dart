import 'dart:ui';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'dart:math' as math;

class CarouselItem {
  final String imagePath;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;
  final Color? color;

  const CarouselItem({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
    this.color,
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

  /// Animation controller for pulse/glow effect
  late AnimationController _pulseController;

  late List<CarouselItem> _carouselItems;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _initCarouselItems();

    // Notify initial color
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_carouselItems.isNotEmpty && widget.onColorChanged != null) {
        // Use the color of the first item, or fallback to primary
        final color =
            _carouselItems[0].color ?? Theme.of(context).colorScheme.primary;
        widget.onColorChanged!(color);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initCarouselItems() async {
    // Default hardcoded items (preserved for fallback or initial state)
    // We also use these to get the hardcoded buttonText, color, and onTap by index
    final List<CarouselItem> hardcodedDefaults = [
      CarouselItem(
        imagePath: '',
        title: 'Ground slowly',
        subtitle:
            "Low RPM Natural Stone Milling of the flour preserves every bit of nutrition",
        buttonText: 'See the Product',
        color: AppColors.parchment, // Brownish for grains/milling
        onTap: () {
          final dashboardState =
              context.findAncestorStateOfType<DashboardScreenState>();
          dashboardState?.switchToTab(1);
        },
      ),
      CarouselItem(
        imagePath: '',
        title: 'We don’t manufacture. We grow',
        subtitle: 'A return to Truly Nutritional Food',
        buttonText: 'Read Our Roots',
        color: AppColors.parchment, // Green for growing
        onTap: () {
          context.push('/about-us');
        },
      ),
      CarouselItem(
        imagePath: '',
        title: 'Picked before the sun rose',
        subtitle: "Harvested only when you order. Not a moment sooner",
        buttonText: 'Visit our Plot',
        color: AppColors.parchment, // Golden/Orange for sun/harvest
        onTap: () {
          context.push('/product/1');
        },
      ),
      CarouselItem(
        imagePath: '',
        title: 'Remote Farming Program',
        subtitle: "You can’t be at the farm. So we bring the farm to you.",
        buttonText: 'Visit our Plot',
        color: AppColors.parchment, // Teal for remote/tech+farm
        onTap: () {
          final authState = context.read<AuthCubit>().state;
          final isRfp = authState is Authenticated && authState.user.isRfp;
          context.push(isRfp ? '/delivery' : '/contract-farming');
        },
      ),
    ];

    // Initialize with defaults first so UI has something to show
    if (mounted) {
      setState(() {
        _carouselItems = hardcodedDefaults;
      });
    }

    try {
      final BannerService bannerService = getIt<BannerService>();
      final List<BannerModel> apiBanners = await bannerService.fetchBanners();

      if (apiBanners.isNotEmpty && mounted) {
        List<CarouselItem> newItems = [];

        // Map API banners to hardcoded styles based on index
        for (int i = 0; i < apiBanners.length; i++) {
          final banner = apiBanners[i];

          // Use hardcoded styles from defaults if available, otherwise reuse last one or default
          final styleSource =
              i < hardcodedDefaults.length
                  ? hardcodedDefaults[i]
                  : hardcodedDefaults.last;

          newItems.add(
            CarouselItem(
              imagePath: banner.image, // URL from API
              title: banner.title,
              subtitle: banner.subtitle,
              buttonText: styleSource.buttonText, // Hardcoded
              color: styleSource.color, // Hardcoded
              onTap: styleSource.onTap, // Hardcoded
            ),
          );
        }

        setState(() {
          _carouselItems = newItems;
        });

        // Notify color change for the new first item
        if (_carouselItems.isNotEmpty && widget.onColorChanged != null) {
          final color =
              _carouselItems[0].color ?? Theme.of(context).colorScheme.primary;
          widget.onColorChanged!(color);
        }
      }
    } catch (e) {
      AppLogger.instance.log("Error fetching banners: $e");
      // Fallback to defaults (already set)
    }
  }

  /// Notify parent when carousel page changes
  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });

    // Notify parent with the new color or fallback
    if (widget.onColorChanged != null) {
      final color =
          _carouselItems[index].color ?? Theme.of(context).colorScheme.primary;
      widget.onColorChanged!(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenHeight = MediaQuery.sizeOf(context).height;

    // Determine current color for glow effect
    final currentColor =
        _carouselItems.isNotEmpty && _currentPage < _carouselItems.length
            ? (_carouselItems[_currentPage].color ?? AppColors.amberWarn)
            : AppColors.amberWarn;

    return Column(
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final glowIntensity =
                  0.15 +
                  (math.sin(_pulseController.value * math.pi * 2) * 0.10);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(alpha: glowIntensity),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: CarouselSlider.builder(
              itemCount: _carouselItems.length,
              itemBuilder: (context, index, realIndex) {
                final item = _carouselItems[index];
                final isActive = index == _currentPage;
                final itemColor = item.color ?? colorScheme.primary;

                // Check if image path is a URL (http/https) or asset
                final isNetworkImage = item.imagePath.startsWith('http');

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
                                    color: itemColor.withValues(alpha: 0.3),
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
                            // Image (Network or Asset)
                            isNetworkImage
                                ? CachedNetworkImage(
                                  imageUrl: item.imagePath,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  memCacheWidth: 600,
                                  placeholder:
                                      (context, url) => Center(
                                        child: CircularProgressIndicator(
                                          color: itemColor,
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => const Center(
                                        child: Icon(Icons.error),
                                      ),
                                )
                                : item.imagePath.isEmpty
                                ? Container(
                                  color: itemColor.withValues(alpha: 0.2),
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: itemColor.withValues(alpha: 0.5),
                                      size: 48,
                                    ),
                                  ),
                                )
                                : SvgPicture.asset(
                                  item.imagePath,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholderBuilder:
                                      (context) => Center(
                                        child: CircularProgressIndicator(
                                          color: itemColor,
                                        ),
                                      ),
                                ),
                            // Subtle gradient to give depth to the image
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.charcoal.withValues(alpha: 0.25),
                                    AppColors.transparent,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                            // Frosted Glass Content Panel
                            Positioned(
                              bottom: 12,
                              left: 16,
                              right: 16,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 6,
                                    sigmaY: 6,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.charcoal.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.parchment.withValues(
                                          alpha: 0.12,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.title,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: AppColors.parchment,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.subtitle,
                                          style: textTheme.labelSmall?.copyWith(
                                            color: AppColors.parchment
                                                .withValues(alpha: 0.88),
                                            fontWeight: FontWeight.w400,
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: SizedBox(
                                            height: 28,
                                            child: TextButton(
                                              onPressed: item.onTap,
                                              style: TextButton.styleFrom(
                                                backgroundColor: colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.9),
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                      color:
                                                          colorScheme.onPrimary,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
          ),
        ),
        const SizedBox(height: 10),
        // Dots Indicator
        AnimatedSmoothIndicator(
          activeIndex: _currentPage,
          count: _carouselItems.length,
          effect: ExpandingDotsEffect(
            activeDotColor: currentColor,
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
