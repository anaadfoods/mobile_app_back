import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:grocery_app/models/user_model.dart';
import 'package:grocery_app/screens/profile/edit_profile_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/routes/app_routes.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // Pulse animation for profile card
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Shimmer animation for avatar
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _triggerMediumHaptic() {
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: () {
          _triggerMediumHaptic();
          context.pushNamed(AppRoute.editProfile.name, extra: widget.user);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withAlpha(40),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with animated gradient border
              _buildAnimatedAvatar(theme, widget.user),
              const SizedBox(width: 14),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.userName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.user.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color?.withAlpha(
                          153,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildVerifiedBadge(theme, widget.user),
                  ],
                ),
              ),
              // Edit Button with ripple
              Material(
                color: colorScheme.primary.withAlpha(25),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {
                    _triggerHaptic();
                    context.pushNamed(
                      AppRoute.editProfile.name,
                      extra: widget.user,
                    );
                  },
                  customBorder: const CircleBorder(),
                  splashColor: colorScheme.primary.withAlpha(51),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedAvatar(ThemeData theme, UserModel user) {
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              startAngle: _shimmerController.value * math.pi * 2,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withAlpha(128),
                colorScheme.primary,
              ],
            ),
          ),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: theme.cardColor,
            child: CircleAvatar(
              radius: 29,
              backgroundColor: colorScheme.primary.withAlpha(25),
              backgroundImage:
                  user.profilePicture != null && user.profilePicture!.isNotEmpty
                      ? NetworkImage(user.profilePicture!)
                      : null,
              child:
                  user.profilePicture == null || user.profilePicture!.isEmpty
                      ? Icon(
                        Icons.person_rounded,
                        size: 32,
                        color: colorScheme.primary,
                      )
                      : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerifiedBadge(ThemeData theme, UserModel user) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withAlpha(51),
                  Colors.orange.withAlpha(38),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withAlpha(76), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 4),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[700],
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
