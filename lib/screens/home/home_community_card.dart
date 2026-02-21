import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

/// Community card with press animation + shimmer effect.
///
/// Extracted from `home_screen.dart` to keep screen decomposition clean.
class AnimatedCommunityCard extends StatefulWidget {
  final Community community;
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

  // Shimmer animation
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  // Floating particles animation
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Shimmer sweep
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Floating particles - slow gentle movement
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final community = widget.community;
    final index = widget.index;

    // Alternate between green and brown gradients for variety
    final isEvenCard = index % 2 == 0;
    final baseColor =
        isEvenCard
            ? const Color(0xFF2E7D32) // Forest green
            : const Color(0xFF5D4037); // Brown

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
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
            vertical: AppColors.spacingS,
            horizontal: AppColors.spacingL,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusXL),
            boxShadow: [
              BoxShadow(
                color: (isEvenCard ? Colors.green : Colors.brown).withOpacity(
                  _isPressed ? 0.15 : 0.25,
                ),
                blurRadius: _isPressed ? 8 : 16,
                offset: Offset(0, _isPressed ? 4 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.radiusXL),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                Image.network(
                  community.image,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        color:
                            isEvenCard
                                ? Colors.green.shade800
                                : Colors.brown.shade800,
                        child: const Icon(
                          Icons.eco,
                          size: 60,
                          color: Colors.white24,
                        ),
                      ),
                ),

                // Gradient Overlay — only bottom 50%
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                      colors: [
                        Colors.transparent,
                        baseColor.withOpacity(0.33),
                        baseColor.withOpacity(0.51),
                      ],
                    ),
                  ),
                ),

                // Shimmer Effect Overlay
                AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.08),
                            Colors.transparent,
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

                // Floating Decorative Dots
                AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, _) {
                    final accentColor =
                        isEvenCard
                            ? const Color(0xFF69F0AE)
                            : const Color(0xFFFFAB91);
                    return Stack(
                      children: [
                        // Dot 1 - top right
                        Positioned(
                          top: 50 + (_floatAnimation.value * 8),
                          right: 25,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withOpacity(0.6),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Dot 2 - middle right
                        Positioned(
                          top: 90 + (_floatAnimation.value * -6),
                          right: 40,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withOpacity(0.5),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Dot 3 - lower right
                        Positioned(
                          top: 130 + (_floatAnimation.value * 5),
                          right: 20,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withOpacity(0.4),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.25),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(AppColors.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Coming Soon Badge - Glassmorphism Style
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isEvenCard
                                          ? const Color(0xFF69F0AE)
                                          : const Color(0xFFFFAB91))
                                      .withOpacity(0.3),
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
                                    color: (isEvenCard
                                            ? const Color(0xFF69F0AE)
                                            : const Color(0xFFFFAB91))
                                        .withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Coming Soon",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Community Name
                      _buildCommunityNameTitle(community, theme),

                      // Learn More Button - Glassmorphism Style
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Explore",
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
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

  Widget _buildCommunityNameTitle(Community community, ThemeData theme) {
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
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Reusable tappable card with subtle press animation.
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
