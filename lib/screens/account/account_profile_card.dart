import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'dart:math' as math;
import 'package:grocery_app/models/user_model.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/routes/app_routes.dart';

/// Hero-style profile card designed to sit inside the SliverAppBar header.
/// Shows centered avatar with shimmer border, name, email, and verified badge
/// on a transparent background (parent provides the gradient).
class AccountProfileCard extends StatefulWidget {
  final UserModel user;
  final String userName;

  const AccountProfileCard({
    super.key,
    required this.user,
    required this.userName,
  });

  @override
  State<AccountProfileCard> createState() => _AccountProfileCardState();
}

class _AccountProfileCardState extends State<AccountProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with shimmer border + edit overlay
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.pushNamed(AppRoute.editProfile.name, extra: widget.user);
          },
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              _buildAnimatedAvatar(theme),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.charcoal.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Name
        Text(
          widget.userName,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppColors.parchment,
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        // Email
        Text(
          widget.user.email,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.parchment.withAlpha(200),
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        // Verified Badge
        _buildVerifiedBadge(widget.user),
      ],
    );
  }

  Widget _buildAnimatedAvatar(ThemeData theme) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              startAngle: _shimmerController.value * math.pi * 2,
              colors: [
                AppColors.parchment,
                AppColors.parchment.withAlpha(100),
                AppColors.parchment,
              ],
            ),
          ),
          child: CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.parchment.withAlpha(30),
            child: CircleAvatar(
              radius: 31,
              backgroundColor: theme.colorScheme.primary.withAlpha(60),
              backgroundImage:
                  widget.user.profilePicture != null &&
                          widget.user.profilePicture!.isNotEmpty
                      ? NetworkImage(widget.user.profilePicture!)
                      : null,
              child:
                  widget.user.profilePicture == null ||
                          widget.user.profilePicture!.isEmpty
                      ? const Icon(
                        Icons.person_rounded,
                        size: 32,
                        color: AppColors.parchment,
                      )
                      : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerifiedBadge(UserModel user) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.parchment.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.parchment.withAlpha(60),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 15,
                  color: AppColors.harvestAmber,
                ),
                const SizedBox(width: 6),
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.parchment,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
