import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:grocery_app/routes/app_routes.dart';
import 'package:grocery_app/common_widgets/notification_badge_widget.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:grocery_app/features/subscriptions/presentation/cubit/subscription_cubit.dart';
import 'package:grocery_app/features/subscriptions/presentation/cubit/subscription_state.dart';
import 'panchang_chakra_button.dart';
import 'home_search_bar.dart';

class HomeHeaderWidget extends StatelessWidget {
  final Color? dynamicColor;
  final TextEditingController searchController;
  final FocusNode focusNode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final bool isSearching;

  const HomeHeaderWidget({
    super.key,
    required this.dynamicColor,
    required this.searchController,
    required this.focusNode,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.isSearching,
  });

  String _formatFriendlyDate(String dateString) {
    if (dateString.isEmpty) return '';
    final parsed = DateTime.tryParse(dateString);
    if (parsed == null) return dateString;
    const monthsList = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (parsed.month < 1 || parsed.month > 12) return dateString;
    return '${monthsList[parsed.month - 1]} ${parsed.day}';
  }

  Widget _buildModernIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    bool hasBadge = false,
    Widget? customChild,
  }) {
    Widget content = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.2 * value),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Transform.rotate(
            angle: math.sin(value * math.pi * 2) * 0.1,
            child: customChild ??
                Icon(icon, color: theme.colorScheme.onPrimary, size: 24),
          ),
        );
      },
    );

    if (hasBadge) {
      content = NotificationBadgeWidget(child: content);
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dynamicColor != null
              ? [
                  Color.lerp(
                    AppColors.deepSoilGreen,
                    dynamicColor,
                    0.55,
                  )!,
                  Color.lerp(
                    const Color(0xFF3D6B28),
                    dynamicColor,
                    0.45,
                  )!,
                ]
              : const [
                  AppColors.deepSoilGreen,
                  Color(0xFF3D6B28),
                ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
              top: 12,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: BlocBuilder<AuthCubit, AuthState>(
                    buildWhen: (prev, curr) => prev != curr,
                    builder: (context, authState) {
                      String name = "User";
                      if (authState is Authenticated) {
                        name = authState.user.firstName[0].toUpperCase() +
                            authState.user.firstName.substring(1);
                      }

                      return BlocBuilder<SubscriptionCubit, SubscriptionState>(
                        builder: (context, subState) {
                          String? nextDelivery;
                          if (subState is SubscriptionSuccess) {
                            for (final sub in subState.userSubscriptions) {
                              if (sub.status.toUpperCase() == 'ACTIVE') {
                                nextDelivery = sub.nextDeliveryDate;
                                break;
                              }
                            }
                          }

                          final hour = DateTime.now().hour;
                          String greetingPrefix = hour < 12
                              ? 'Good morning'
                              : hour < 17
                                  ? 'Good afternoon'
                                  : 'Good evening';

                          String greetingMessage = '$greetingPrefix,\n$name';
                          if (nextDelivery != null && nextDelivery.isNotEmpty) {
                            final fmtDate = _formatFriendlyDate(nextDelivery);
                            if (fmtDate.isNotEmpty) {
                              greetingMessage = ApiConfig
                                      .showExpectedDeliveryDate
                                  ? '$greetingPrefix,$name\nNext delivery: $fmtDate'
                                  : '$greetingPrefix,$name\nNext delivery: ${ApiConfig.alternativeDeliveryText}';
                            }
                          }

                          return GestureDetector(
                            onTap: () {
                              context.go(AppRoute.profile.path);
                            },
                            child: Row(
                              children: [
                                Hero(
                                  tag: 'app_logo',
                                  child: Image.asset(
                                    'assets/images/OnBoarding/logo.png',
                                    height: 40,
                                    width: 40,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    greetingMessage,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                      fontSize: 14,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PanchangChakraButton(
                      theme: theme,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        SnackBarHelper.showWarning(
                          context,
                          "Panchang feature is coming soon!",
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildModernIconButton(
                      icon: Icons.notifications_rounded,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push(AppRoute.notifications.path);
                      },
                      theme: theme,
                      hasBadge: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          HomeSearchBar(
            controller: searchController,
            focusNode: focusNode,
            onChanged: onSearchChanged,
            onClear: onSearchClear,
            isSearching: isSearching,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
