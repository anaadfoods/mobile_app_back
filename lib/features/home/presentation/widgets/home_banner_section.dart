import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/utils/app_logger.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'home_skeletons.dart';
import '../../domain/entities/banner_entity.dart';

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

class HomeBannerSection extends StatefulWidget {
  final ValueChanged<Color>? onColorChanged;

  const HomeBannerSection({super.key, this.onColorChanged});

  @override
  State<HomeBannerSection> createState() => _HomeBannerSectionState();
}

class _HomeBannerSectionState extends State<HomeBannerSection>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<CarouselItem> _buildItemsFromBanners(List<BannerEntity> banners) {
    final List<CarouselItem> hardcodedDefaults = [
      CarouselItem(
        imagePath: '',
        title: 'Seed Integrity',
        subtitle:
            "We grow our produce using traditional variety seeds with over 5,000 years of lineage",
        buttonText: 'Shop Now',
        color: AppColors.deepSoilGreen,
        onTap: () {
          context.push('/products');
        },
      ),
      CarouselItem(
        imagePath: '',
        title: "Soil Science",
        subtitle:
            'Our soil is alive with microbes that unlock nutrition naturally without any synthetics.',
        buttonText: 'How We Farm',
        color: AppColors.successGreen,
        onTap: () {
          context.push('/about-us');
        },
      ),
      CarouselItem(
        imagePath: '',
        title: 'Post-Harvest',
        subtitle:
            "We blend traditional wisdom with modern care, so nutrition stays intact when it reaches your kitchen.",
        buttonText: 'See Subscriptions',
        color: AppColors.harvestAmber,
        onTap: () {
          context.push('/subscriptions');
        },
      ),
      CarouselItem(
        imagePath: '',
        title: 'Traceability',
        subtitle:
            "With batch being traceable, know exactly where your food came from, who grew it, and how.",
        buttonText: 'Trace Your Batch',
        color: AppColors.infoTeal,
        onTap: () {
          context.push('/products');
        },
      ),
    ];

    if (banners.isEmpty) return hardcodedDefaults;

    final sortedBanners = List<BannerEntity>.from(banners)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final List<CarouselItem> items = [];
    for (final banner in sortedBanners) {
      final titleLower = banner.title.toLowerCase();
      CarouselItem matchedDefault = hardcodedDefaults[0];

      if (banner.id == 2 ||
          titleLower.contains('ground') ||
          titleLower.contains('slowly') ||
          titleLower.contains('milling') ||
          titleLower.contains('integrity')) {
        matchedDefault = hardcodedDefaults[0];
      } else if (banner.id == 3 ||
          titleLower.contains('manufacture') ||
          titleLower.contains('grow') ||
          titleLower.contains('soil') ||
          titleLower.contains('science')) {
        matchedDefault = hardcodedDefaults[1];
      } else if (banner.id == 4 ||
          titleLower.contains('picked') ||
          titleLower.contains('sun') ||
          titleLower.contains('harvest') ||
          titleLower.contains('post')) {
        matchedDefault = hardcodedDefaults[2];
      } else if (banner.id == 5 ||
          titleLower.contains('remote') ||
          titleLower.contains('program') ||
          titleLower.contains('traceability') ||
          titleLower.contains('trace')) {
        matchedDefault = hardcodedDefaults[3];
      } else {
        final fallbackIndex = items.length % hardcodedDefaults.length;
        matchedDefault = hardcodedDefaults[fallbackIndex];
      }

      items.add(
        CarouselItem(
          imagePath: banner.image,
          title: matchedDefault.title,
          subtitle: matchedDefault.subtitle,
          buttonText: matchedDefault.buttonText,
          onTap: matchedDefault.onTap,
          color: matchedDefault.color ?? AppColors.deepSoilGreen,
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const HomeBannerSkeleton();
        }

        final banners = (state is HomeSuccess) ? state.banners : <BannerEntity>[];
        final items = _buildItemsFromBanners(banners);

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final currentColor = items.isNotEmpty && _currentPage < items.length
            ? (items[_currentPage].color ?? AppColors.amberWarn)
            : AppColors.amberWarn;

        return Column(
          children: [
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final glowIntensity =
                      0.15 + (math.sin(_pulseController.value * math.pi * 2) * 0.10);

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
                  itemCount: items.length,
                  itemBuilder: (context, index, realIndex) {
                    final item = items[index];
                    final isActive = index == _currentPage;
                    final itemColor = item.color ?? colorScheme.primary;
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
                            boxShadow: isActive
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
                                if (isNetworkImage)
                                  CachedNetworkImage(
                                    imageUrl: item.imagePath,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (context, url) =>
                                        Container(color: itemColor.withValues(alpha: 0.2)),
                                    errorWidget: (context, url, error) =>
                                        Container(color: itemColor),
                                  )
                                else
                                  Container(color: itemColor),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withValues(alpha: 0.6),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        item.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.9),
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
                    height: 180,
                    viewportFraction: 0.9,
                    enlargeCenterPage: true,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 4),
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentPage = index;
                      });
                      if (widget.onColorChanged != null && index < items.length) {
                        widget.onColorChanged!(items[index].color ?? colorScheme.primary);
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (items.isNotEmpty)
              AnimatedSmoothIndicator(
                activeIndex: _currentPage,
                count: items.length,
                effect: ExpandingDotsEffect(
                  dotWidth: 8,
                  dotHeight: 8,
                  activeDotColor: currentColor,
                  dotColor: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
          ],
        );
      },
    );
  }
}
