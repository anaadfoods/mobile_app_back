import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import '../../domain/entities/banner_entity.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

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
  final ValueChanged<Color>? onColorChanged;

  const TopCurosel({super.key, this.onColorChanged});

  @override
  State<TopCurosel> createState() => _TopCuroselState();
}

class _TopCuroselState extends State<TopCurosel>
    with SingleTickerProviderStateMixin {
  final CarouselSliderController _carouselController = CarouselSliderController();
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

  List<CarouselItem> _buildCarouselItems(
    BuildContext context,
    List<BannerEntity> apiBanners,
  ) {
    final List<CarouselItem> hardcodedDefaults = [
      CarouselItem(
        imagePath: '',
        title: 'Seed Integrity',
        subtitle:
            "We grow our produce using traditional variety seeds with over 5,000 years of lineage",
        buttonText: 'Shop Now',
        color: AppColors.deepSoilGreen,
        onTap: () {
          context.go('/products');
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
          context.go('/subscriptions');
        },
      ),
      CarouselItem(
        imagePath: '',
        title: 'Traceability',
        subtitle:
            "With batch being traceable, know exactly where your food came from, who grew it, and how.",
        buttonText: 'Trace Your Batch',
        color: AppColors.rawEarth,
        onTap: () {
          context.go('/products');
        },
      ),
    ];

    if (apiBanners.isEmpty) {
      return hardcodedDefaults;
    }

    final sortedBanners = List<BannerEntity>.from(apiBanners)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final List<CarouselItem> items = [];
    for (final banner in sortedBanners) {
      final String titleLower = banner.title.toLowerCase();
      CarouselItem matchedDefault = hardcodedDefaults[0];

      if (banner.id == 2 || titleLower.contains('integrity')) {
        matchedDefault = hardcodedDefaults[0];
      } else if (banner.id == 3 || titleLower.contains('soil')) {
        matchedDefault = hardcodedDefaults[1];
      } else if (banner.id == 4 || titleLower.contains('post')) {
        matchedDefault = hardcodedDefaults[2];
      } else if (banner.id == 5 || titleLower.contains('trace')) {
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
        final banners = (state is HomeSuccess) ? state.banners : <BannerEntity>[];
        final carouselItems = _buildCarouselItems(context, banners);

        if (carouselItems.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: carouselItems.length,
              options: CarouselOptions(
                height: 180,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                viewportFraction: 0.92,
                enlargeCenterPage: true,
                onPageChanged: (index, reason) {
                  setState(() => _currentPage = index);
                  if (widget.onColorChanged != null) {
                    final itemColor =
                        carouselItems[index].color ?? AppColors.deepSoilGreen;
                    widget.onColorChanged!(itemColor);
                  }
                },
              ),
              itemBuilder: (context, index, realIndex) {
                final item = carouselItems[index];
                return _buildCarouselCard(context, item);
              },
            ),
            const SizedBox(height: 12),
            AnimatedSmoothIndicator(
              activeIndex: _currentPage,
              count: carouselItems.length,
              effect: ExpandingDotsEffect(
                dotWidth: 8,
                dotHeight: 8,
                activeDotColor: Theme.of(context).colorScheme.primary,
                dotColor: AppColors.parchment.withValues(alpha: 0.4),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCarouselCard(BuildContext context, CarouselItem item) {
    final theme = Theme.of(context);
    final cardColor = item.color ?? theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.imagePath.isNotEmpty)
              CachedNetworkImage(
                imageUrl: item.imagePath,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: cardColor),
                errorWidget: (context, url, err) => Container(color: cardColor),
              )
            else
              Container(color: cardColor),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    cardColor.withValues(alpha: 0.92),
                    cardColor.withValues(alpha: 0.65),
                    AppColors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.parchment,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 200,
                    child: Text(
                      item.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.parchment.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: item.onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.parchment,
                      foregroundColor: cardColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      item.buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
