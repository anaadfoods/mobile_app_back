import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/action_button.dart';
import '../../domain/entities/chat_message.dart';
import 'cards/confirmation_card_widget.dart';
import 'cards/order_status_card_widget.dart';
import 'cards/product_card_grid_widget.dart';
import 'cards/recommendation_card_widget.dart';
import 'cards/subscription_card_widget.dart';
import 'cards/cart_card_widget.dart';
import 'cards/health_observation_card_widget.dart';
import 'cards/thali_card_widget.dart';
import 'cards/error_retry_card_widget.dart';

/// Gemini/Claude-style Boxed Chat Message Bubble.
/// Renders short framing markdown text and typed content cards (Order Stepper, Product Grid, Confirmation Card).
class ChatMessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isStreaming;
  final int messageIndex;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.messageIndex = 0,
  });

  void _safeNavigate(BuildContext context, String path) {
    final cleanPath = path.trim();
    if (cleanPath == '/cart') {
      context.go('/cart');
    } else if (cleanPath == '/home' || cleanPath == '/') {
      context.go('/home');
    } else if (cleanPath == '/profile' || cleanPath == '/account') {
      context.go('/profile');
    } else if (cleanPath == '/categories' || cleanPath == '/explore') {
      context.go('/categories');
    } else if (cleanPath == '/wishlist' || cleanPath == '/favourite') {
      context.go('/wishlist');
    } else {
      context.push(cleanPath);
    }
  }

  void _handleLinkTap(BuildContext context, String? href) {
    if (href == null || href.isEmpty) return;

    if (href.startsWith('/')) {
      _safeNavigate(context, href);
    } else {
      try {
        final uri = Uri.parse(href);
        launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  /// 1. Render Action Buttons in Chat Message Bubble
  Widget buildActionButtons(List<ActionButton> buttons, BuildContext context) {
    if (buttons.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
      child: Wrap(
        spacing: 6.0,
        runSpacing: 6.0,
        children:
            buttons.map((btn) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleNavigation(context, btn),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5.5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? AppColors.harvestAmber.withValues(alpha: 0.16)
                              : AppColors.harvestAmber.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.harvestAmber.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForAction(btn.actionType),
                          size: 13.5,
                          color:
                              isDark
                                  ? AppColors.harvestAmber
                                  : AppColors.deepSoilGreen,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          btn.label,
                          style: TextStyle(
                            fontSize: 11.8,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? AppColors.harvestAmber
                                    : AppColors.deepSoilGreen,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  /// 2. Icon Mapper for Action Types
  IconData _getIconForAction(String actionType) {
    switch (actionType) {
      case 'NAVIGATE_TO_PRODUCT_DETAIL':
      case 'SHOW_PRODUCT_CATALOG':
        return Icons.shopping_bag_outlined;
      case 'OPEN_ORDER_TRACKER':
      case 'OPEN_ORDER_HISTORY':
        return Icons.local_shipping_outlined;
      case 'OPEN_CART_DRAWER':
        return Icons.shopping_cart_outlined;
      case 'OPEN_SUBSCRIPTION_PICKER':
        return Icons.calendar_today_outlined;
      case 'NAVIGATE_TO_PANCHANG':
        return Icons.calendar_month_outlined;
      case 'NAVIGATE_TO_KUNDLI':
        return Icons.auto_awesome_outlined;
      case 'NAVIGATE_TO_PRAKRITI':
        return Icons.eco_outlined;
      default:
        return Icons.touch_app_outlined;
    }
  }

  /// 3. Implement Screen Redirections
  void _handleNavigation(BuildContext context, ActionButton btn) {
    final data = btn.data;
    final actionType = btn.actionType.toUpperCase();
    final targetScreen = btn.targetScreen;
    final dynamic variantId =
        data['variant_id'] ?? data['id'] ?? data['product_id'] ?? data['pk'];
    final dynamic orderId = data['order_id'] ?? data['id'] ?? data['pk'];
    final dynamic subscriptionId =
        data['subscription_id'] ?? data['id'] ?? data['plan_id'];

    if (targetScreen.startsWith('/')) {
      _safeNavigate(context, targetScreen);
      return;
    }

    if (actionType.contains('PRODUCT') ||
        targetScreen == 'ProductDetailScreen' ||
        targetScreen == 'ProductCatalogScreen') {
      if (variantId != null) {
        context.push('/product/$variantId');
      } else {
        context.push('/products');
      }
    } else if (actionType.contains('ORDER') ||
        targetScreen == 'OrderTrackerScreen' ||
        targetScreen == 'OrderHistoryScreen') {
      if (orderId != null) {
        context.push('/order/$orderId');
      } else {
        context.push('/orders');
      }
    } else if (actionType.contains('CART') || targetScreen == 'CartScreen') {
      context.go('/cart');
    } else if (actionType.contains('CHECKOUT') ||
        targetScreen == 'CheckoutScreen') {
      context.push('/checkout');
    } else if (actionType.contains('SUBSCRIPTION') ||
        targetScreen == 'SubscriptionScreen') {
      if (subscriptionId != null) {
        context.push('/subscription/$subscriptionId');
      } else {
        context.push('/subscriptions');
      }
    } else if (targetScreen == 'PrakritiQuizScreen' || targetScreen == 'PrakritiAssessmentScreen') {
      context.push('/prakriti-quiz');
    } else if (targetScreen == 'PanchangHomeScreen' || targetScreen == 'PanchangScreen') {
      context.push('/panchang-home');
    } else if (targetScreen == 'KundliDetailsScreen') {
      context.push('/kundli-details');
    } else if (data['route'] != null) {
      final route = data['route'].toString();
      if (route == '/product-detail' && variantId != null) {
        context.push('/product/$variantId');
      } else if (route == '/order-tracker' && orderId != null) {
        context.push('/order/$orderId');
      } else {
        _safeNavigate(context, route);
      }
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Collect action buttons from message entity or fallback to uiAction
    List<ActionButton> buttons = message.actionButtons;
    if (buttons.isEmpty && message.uiAction != null) {
      buttons = [ActionButton.fromUiAction(message.uiAction!)];
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 12.0),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Sender Header (for Assistant) ──
          if (message.isAssistant)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: AppColors.harvestAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 12,
                      color: AppColors.harvestAmber,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    "Anaad AI",
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.harvestAmber,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

          // ── Message Box Container ──
          Align(
            alignment:
                message.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.88,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 13.0,
                vertical: 8.5,
              ),
              decoration: BoxDecoration(
                color:
                    message.isUser
                        ? (isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.deepSoilGreen)
                        : (isDark
                            ? AppColors.darkSurface
                            : AppColors.pureWhite),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft:
                      message.isUser ? const Radius.circular(14) : Radius.zero,
                  bottomRight:
                      message.isUser ? Radius.zero : const Radius.circular(14),
                ),
                border: Border.all(
                  color:
                      message.isUser
                          ? AppColors.deepSoilGreen.withValues(alpha: 0.35)
                          : (isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.parchment),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isUser) ...[
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.pureWhite,
                        fontSize: 13.8,
                        height: 1.4,
                      ),
                    ),
                    if (message.timestamp != null) ...[
                      const SizedBox(height: 3),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          '${message.timestamp!.hour.toString().padLeft(2, '0')}:${message.timestamp!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9.0,
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // Framing intro text
                    Builder(
                      builder: (_) {
                        String displayContent = message.content.trim();
                        if ((displayContent.startsWith('{') &&
                                displayContent.endsWith('}')) ||
                            displayContent.contains('"products_data"')) {
                          if (message.productsData.isNotEmpty) {
                            final names =
                                message.productsData
                                    .map(
                                      (p) =>
                                          (p['product_name'] ?? p['name'] ?? '')
                                              .toString(),
                                    )
                                    .where((n) => n.isNotEmpty)
                                    .take(3)
                                    .toList();
                            displayContent =
                                names.isNotEmpty
                                    ? 'Here are the top organic options from our catalog for you: ${names.join(", ")}.'
                                    : 'Here are the top organic food products available in our Anaad Foods catalog for your query.';
                          } else {
                            displayContent =
                                'Here is the summary of information for your request.';
                          }
                        }

                        return MarkdownBody(
                          data: displayContent + (isStreaming ? ' ▍' : ''),
                          selectable: true,
                          onTapLink:
                              (text, href, title) =>
                                  _handleLinkTap(context, href),
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: isDark ? Colors.white.withValues(alpha: 0.92) : AppColors.charcoal,
                              fontSize: 13.8,
                              height: 1.45,
                              letterSpacing: -0.1,
                            ),
                            pPadding: const EdgeInsets.only(bottom: 5.0),
                            h1: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: isDark ? Colors.white : AppColors.deepSoilGreen,
                            ),
                            h2: TextStyle(
                              fontSize: 14.2,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: isDark ? Colors.white : AppColors.deepSoilGreen,
                            ),
                            h3: TextStyle(
                              fontSize: 13.6,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: isDark ? AppColors.harvestAmber : AppColors.deepSoilGreen,
                            ),
                            h3Padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
                            listBullet: const TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: AppColors.harvestAmber,
                            ),
                            listIndent: 14.0,
                            listBulletPadding: const EdgeInsets.only(right: 5.0),
                            strong: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.charcoal,
                            ),
                            em: TextStyle(
                              fontSize: 11.2,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.white54 : Colors.black45,
                              height: 1.35,
                            ),
                            blockquote: TextStyle(
                              fontSize: 12.0,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(6),
                              border: Border(
                                left: BorderSide(
                                  color: AppColors.harvestAmber.withValues(alpha: 0.6),
                                  width: 2.5,
                                ),
                              ),
                            ),
                            blockquotePadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            code: TextStyle(
                              fontSize: 11.5,
                              fontFamily: 'monospace',
                              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                        );
                      },
                    ),

                    // Extract structured UI action type
                    Builder(
                      builder: (context) {
                        final String? actionType =
                            message.uiAction?['action']?.toString() ??
                            message.uiAction?['action_type']?.toString();

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Typed Content Card 1: Order Status Stepper ──
                            if (actionType == 'render_order_tracker' ||
                                message.orderData != null ||
                                message.responseType == 'order_status')
                              OrderStatusCardWidget(
                                orderData:
                                    message.orderData ??
                                    {
                                      'order_number': 'ORD-9823',
                                      'expected_delivery': 'Aug 9',
                                      'current_step': 3,
                                    },
                              ),

                            // ── Typed Content Card 2: Product Card Grid / Carousel ──
                            if (actionType == 'render_product_carousel' ||
                                message.productsData.isNotEmpty ||
                                message.responseType == 'product_list')
                              ProductCardGridWidget(
                                products: message.productsData,
                              ),

                            // ── Typed Content Card 3: Wellness Recommendations & Self Care Tips ──
                            // Only render recommendation items if productsData is empty (avoid duplicate carousels)
                            if (actionType == 'render_recommendation_cards' ||
                                (message.productsData.isEmpty &&
                                    message.recommendations.isNotEmpty) ||
                                message.selfCareTips.isNotEmpty ||
                                message.responseType == 'health_recommendation')
                              RecommendationCardWidget(
                                recommendations:
                                    message.productsData.isEmpty
                                        ? message.recommendations
                                        : const [],
                                selfCareTips: message.selfCareTips,
                              ),

                            // ── Typed Content Card 4: Confirmation Amber Card ──
                            if (actionType == 'render_confirmation_dialog' ||
                                actionType == 'CONFIRM_SIDE_EFFECT_ACTION' ||
                                message.confirmationData != null ||
                                message.responseType == 'confirmation_required')
                              ConfirmationCardWidget(
                                confirmationData:
                                    message.confirmationData ??
                                    {
                                      'action_title':
                                          'Confirm before this happens',
                                      'description':
                                          'Add 2 x A2 desi ghee 500g to cart — ₹900 total',
                                      'api_name': 'post_api_cart_items',
                                    },
                              ),

                            // ── Typed Content Card 5: Subscription Card ──
                            if (actionType == 'render_subscription_card' ||
                                actionType ==
                                    'render_subscription_plans_card')
                              SubscriptionCardWidget(
                                subscriptionData: message.thaliData ?? {},
                              ),

                            // ── Typed Content Card 6: Cart Card ──
                            if (actionType == 'render_cart_card' ||
                                message.cartData != null ||
                                message.responseType == 'cart_view')
                              CartCardWidget(cartData: message.cartData ?? {}),

                            // ── Typed Content Card 7: Health Observation Consent ──
                            if (message.healthObservation != null)
                              HealthObservationCardWidget(
                                observation: message.healthObservation!,
                                isSaved: message.observationSaved,
                                messageIndex: messageIndex,
                              ),

                            // ── Typed Content Card 8: Dedicated Thali/Meal Plan ──
                            if (message.thaliData != null &&
                                message.responseType == 'thali_suggestion')
                              ThaliCardWidget(thaliData: message.thaliData!),

                            // ── Typed Content Card 9: Error / Retry ──
                            if (message.responseType == 'error')
                              ErrorRetryCardWidget(
                                errorMessage: message.content,
                                onRetry: null,
                              ),
                          ],
                        );
                      },
                    ),

                    // Action buttons rendering
                    buildActionButtons(buttons, context),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Helpful feedback recorded!"),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.thumb_up_outlined,
                                size: 12.5,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Feedback submitted for prompt tuning.",
                                    ),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.thumb_down_outlined,
                                size: 12.5,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: message.content),
                                );
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.greenAccent,
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text("Copied to clipboard", style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    backgroundColor: Color(0xFF1E293B),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.content_copy_rounded,
                                      size: 12,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      "Copy",
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark ? Colors.white38 : Colors.black38,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (message.timestamp != null)
                          Text(
                            '${message.timestamp!.hour.toString().padLeft(2, '0')}:${message.timestamp!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color:
                                  isDark
                                      ? Colors.white30
                                      : AppColors.charcoal40,
                              fontSize: 9.0,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
