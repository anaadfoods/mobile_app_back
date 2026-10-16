import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/common_widgets/anaad_section_header.dart';
import 'package:grocery_app/features/rfp/presentation/cubit/rfp_batch_cubit.dart';
import 'package:grocery_app/features/rfp/presentation/rfp_theme.dart';
import 'rfp_batch_carousel_card.dart';

/// Interactive RFP Batches Carousel shown on the Home Screen below the top carousel.
///
/// Uses the same rectangular, scaling carousel style with page indicators
/// and rich gradient cards as [SubscriptionTable].
class RfpBatchesCarousel extends StatefulWidget {
  const RfpBatchesCarousel({super.key});

  @override
  State<RfpBatchesCarousel> createState() => _RfpBatchesCarouselState();
}

class _RfpBatchesCarouselState extends State<RfpBatchesCarousel>
    with TickerProviderStateMixin {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.70, initialPage: 1000);
    _startAutoScroll();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<RfpBatchCubit>();
      if (cubit.state.batches.isEmpty && !cubit.state.isLoading) {
        cubit.loadBatchData();
      }
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final batches = context.read<RfpBatchCubit>().state.batches;
      if (batches.length <= 1) return;
      final currentPage = _pageController.page?.round() ?? 1000;
      _pageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final cardHeight = (size.height * 0.44).clamp(320.0, 390.0);

    return BlocBuilder<RfpBatchCubit, RfpBatchState>(
      builder: (context, state) {
        if (state.isLoading && state.batches.isEmpty) {
          return _buildLoadingState(isDark, cardHeight);
        }
        if (state.batches.isEmpty) {
          return const SizedBox.shrink();
        }

        final batches = state.batches;

        // If only 1 batch is available, render single card without infinite loop or swiping
        if (batches.length == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnaadSectionHeader(
                title: 'Remote Farming Program',
                actionLabel: '',
                onAction: () => context.push('/rfp/batches'),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: cardHeight,
                  child: RfpBatchCarouselCard(
                    batch: batches.first,
                    isActive: true,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnaadSectionHeader(
              title: 'Remote Farming Program',
              actionLabel: '',
              onAction: () => context.push('/rfp/batches'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            ),
            SizedBox(
              height: cardHeight,
              child: GestureDetector(
                onPanDown: (_) => _stopAutoScroll(),
                onPanEnd: (_) => _startAutoScroll(),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: null, // infinite scroll illusion
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index % batches.length);
                  },
                  itemBuilder: (context, index) {
                    final actualIndex = index % batches.length;
                    final batch = batches[actualIndex];
                    final isActive = actualIndex == _currentIndex;

                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double scale = 1.0;
                        double opacity = 1.0;

                        if (_pageController.position.haveDimensions) {
                          final page = _pageController.page ?? 1000.0;
                          final diff = (page - index).abs();
                          scale = (1 - (diff * 0.12)).clamp(0.82, 1.0);
                          opacity = (1 - (diff * 0.25)).clamp(0.55, 1.0);
                        }

                        return Center(
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.scale(scale: scale, child: child),
                          ),
                        );
                      },
                      child: RfpBatchCarouselCard(
                        batch: batch,
                        isActive: isActive,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildPageIndicators(batches.length, isDark),
          ],
        );
      },
    );
  }

  Widget _buildPageIndicators(int count, bool isDark) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color:
                isActive
                    ? const Color(0xFF003629)
                    : (isDark ? Colors.white24 : Colors.black12),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: const Color(0xFF003629).withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                    : null,
          ),
        );
      }),
    );
  }

  Widget _buildLoadingState(bool isDark, double height) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: RfpTheme.primary),
      ),
    );
  }
}
