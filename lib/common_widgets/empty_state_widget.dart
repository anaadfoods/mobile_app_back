import 'package:flutter/material.dart';

/// A reusable empty state widget for showing when there's no data.
/// 
/// Consolidates the various empty state implementations across the app.
/// 
/// Usage:
/// ```dart
/// EmptyStateWidget(
///   icon: Icons.notifications_off,
///   title: 'No notifications',
///   subtitle: 'You\'re all caught up!',
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  /// The icon to display
  final IconData icon;
  
  /// The title text
  final String title;
  
  /// The subtitle/description text
  final String? subtitle;
  
  /// Optional button text
  final String? buttonText;
  
  /// Callback when button is pressed
  final VoidCallback? onButtonPressed;
  
  /// Icon color (defaults to primary with opacity)
  final Color? iconColor;
  
  /// Icon background color
  final Color? iconBackgroundColor;
  
  /// Whether to animate the entrance
  final bool animated;
  
  /// Icon size (default: 64)
  final double iconSize;
  
  /// Icon container size (default: 120)
  final double iconContainerSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
    this.iconBackgroundColor,
    this.animated = true,
    this.iconSize = 64,
    this.iconContainerSize = 120,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBackgroundColor ?? colorScheme.primary.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Action Button
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
    
    if (animated) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: child,
            ),
          );
        },
        child: content,
      );
    }
    
    return content;
  }
}

/// Preset empty states for common use cases
class EmptyStatePresets {
  /// No notifications empty state
  static EmptyStateWidget notifications({VoidCallback? onRefresh}) {
    return EmptyStateWidget(
      icon: Icons.notifications_off_rounded,
      title: 'No notifications',
      subtitle: 'You\'re all caught up! Check back later.',
      buttonText: onRefresh != null ? 'Refresh' : null,
      onButtonPressed: onRefresh,
    );
  }
  
  /// No orders empty state
  static EmptyStateWidget orders({VoidCallback? onBrowse}) {
    return EmptyStateWidget(
      icon: Icons.receipt_long_rounded,
      title: 'No orders yet',
      subtitle: 'Your order history will appear here.',
      buttonText: onBrowse != null ? 'Browse Products' : null,
      onButtonPressed: onBrowse,
    );
  }
  
  /// Empty cart
  static EmptyStateWidget cart({VoidCallback? onBrowse}) {
    return EmptyStateWidget(
      icon: Icons.shopping_cart_outlined,
      title: 'Your cart is empty',
      subtitle: 'Add some items to get started.',
      buttonText: onBrowse != null ? 'Start Shopping' : null,
      onButtonPressed: onBrowse,
    );
  }
  
  /// No search results
  static EmptyStateWidget searchResults({String? query}) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: 'No results found',
      subtitle: query != null 
          ? 'No results for "$query". Try a different search.'
          : 'Try searching with different keywords.',
    );
  }
  
  /// No favorites
  static EmptyStateWidget favorites({VoidCallback? onBrowse}) {
    return EmptyStateWidget(
      icon: Icons.favorite_border_rounded,
      title: 'No favorites yet',
      subtitle: 'Items you mark as favorite will appear here.',
      buttonText: onBrowse != null ? 'Explore Products' : null,
      onButtonPressed: onBrowse,
    );
  }
  
  /// No subscriptions
  static EmptyStateWidget subscriptions({VoidCallback? onExplore}) {
    return EmptyStateWidget(
      icon: Icons.card_membership_rounded,
      title: 'No subscriptions',
      subtitle: 'Subscribe to products for regular delivery.',
      buttonText: onExplore != null ? 'Explore Plans' : null,
      onButtonPressed: onExplore,
    );
  }
}

