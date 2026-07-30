import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/helpers/animated_transitions.dart';
import '../../domain/entities/community_entity.dart';
import '../screens/community_detail_screen.dart';

class AnimatedCommunityCard extends StatefulWidget {
  final CommunityEntity community;
  final int index;

  const AnimatedCommunityCard({
    super.key,
    required this.community,
    required this.index,
  });

  @override
  State<AnimatedCommunityCard> createState() => _AnimatedCommunityCardState();
}

class _AnimatedCommunityCardState extends State<AnimatedCommunityCard>
    with TickerProviderStateMixin {
  bool _isPressed = false;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
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
    final theme = Theme.of(context);
    final community = widget.community;
    final index = widget.index;

    final isEvenCard = index % 2 == 0;
    final baseColor =
        isEvenCard ? AppColors.deepSoilGreen : AppColors.rawEarth;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.mediumImpact();
        Navigator.of(context, rootNavigator: true).push(
          AnimatedTransitions.fadeScale(
            CommunityDetailScreen(community: community),
          ),
        );
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 180,
          margin: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isEvenCard
                        ? AppColors.deepSoilGreen
                        : AppColors.rawEarth)
                    .withValues(alpha: _isPressed ? 0.15 : 0.25),
                blurRadius: _isPressed ? 8 : 16,
                offset: Offset(0, _isPressed ? 4 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: community.fullImageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Container(
                    color: isEvenCard
                        ? AppColors.deepSoilGreen
                        : AppColors.rawEarth,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isEvenCard
                        ? AppColors.deepSoilGreen
                        : AppColors.rawEarth,
                    child: const Icon(
                      Icons.eco,
                      size: 60,
                      color: Colors.white24,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                      colors: [
                        AppColors.transparent,
                        baseColor.withValues(alpha: 0.4),
                        baseColor.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.transparent,
                            AppColors.parchment.withValues(alpha: 0.08),
                            AppColors.transparent,
                          ],
                          stops: [
                            (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                            _shimmerAnimation.value.clamp(0.0, 1.0),
                            (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RepaintBoundary(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.parchment.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.parchment.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.parchment
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(1),
                                    decoration: BoxDecoration(
                                      color: AppColors.parchment
                                          .withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      size: 12,
                                      color: AppColors.harvestAmber,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Coming Soon",
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.parchment,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildCommunityNameTitle(community, theme),
                      RepaintBoundary(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.parchment.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.parchment.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Explore",
                                    style:
                                        theme.textTheme.labelLarge?.copyWith(
                                      color: AppColors.parchment,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: AppColors.parchment,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityNameTitle(CommunityEntity community, ThemeData theme) {
    final nameLower = community.name.toLowerCase();
    if (nameLower.contains('grinity')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: SvgPicture.asset('assets/images/3.svg', height: 28),
      );
    } else if (nameLower.contains('krinity')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: SvgPicture.asset('assets/images/4.svg', height: 28),
      );
    }
    return Text(
      community.name,
      style: theme.textTheme.headlineSmall?.copyWith(
        color: AppColors.parchment,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            blurRadius: 8,
            color: AppColors.charcoal.withValues(alpha: 0.3),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class TappableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const TappableCard({super.key, required this.child, required this.onTap});

  @override
  State<TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<TappableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.identity()..translate(0.0, _isPressed ? 2.0 : 0.0),
          child: widget.child,
        ),
      ),
    );
  }
}
