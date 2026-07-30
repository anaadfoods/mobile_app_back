import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/common_widgets/error_dialog.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/helpers/animated_transitions.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/models/subscription_plan_model.dart';
import 'package:grocery_app/routes/app_routes.dart';
import 'package:grocery_app/features/orders/domain/entities/order_entity.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/features/misc/presentation/screens/order_failed_dialog.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/utils/checkout_calculator.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../widgets/checkout_bottom_bar.dart';
import '../widgets/checkout_header.dart';
import '../widgets/checkout_loading_overlay.dart';
import '../widgets/congratulation_card.dart';
import '../widgets/delivery_time_card.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/reward_notification_card.dart';
import '../widgets/shipping_address_card.dart';
import 'webview_page.dart';

class CheckoutScreen extends StatefulWidget {
  final CartModel? cart;
  final Product? singleProduct;
  final double? price;
  final int? quantity;
  final bool isSubscription;
  final String? paymentType;
  final int? selectedPlan;
  final Map<String, String>? shippingDetails;
  final double codDeliveryCharge;
  final double prepaidDeliveryCharge;
  final String expectedDeliveryDate;

  const CheckoutScreen({
    super.key,
    this.cart,
    this.price,
    this.singleProduct,
    this.quantity,
    this.isSubscription = false,
    this.selectedPlan,
    this.shippingDetails,
    required this.codDeliveryCharge,
    required this.prepaidDeliveryCharge,
    required this.expectedDeliveryDate,
    this.paymentType,
  }) : assert(cart != null || (singleProduct != null && quantity != null));

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int get totalItems => widget.cart?.totalItems ?? widget.quantity ?? 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CheckoutCubit>(
      create: (context) => CheckoutCubit()
        ..initialize(
          customShipping: widget.shippingDetails,
          isSubscription: widget.isSubscription,
          selectedPlan: widget.selectedPlan,
        ),
      child: BlocConsumer<CheckoutCubit, CheckoutState>(
        listener: (context, state) {
          if (state is CheckoutFailure) {
            _showOrderFailedDialog(context, state.errorMessage);
          } else if (state is CheckoutSuccess) {
            _handleSuccess(context, state);
          } else if (state is CheckoutLoaded && state.error != null) {
            SnackBarHelper.showError(context, state.error!);
          }
        },
        builder: (context, state) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          final bool isLoading = state is CheckoutInitial || state is CheckoutLoading;
          final bool isSubmitting = state is CheckoutLoaded && state.isSubmitting;

          String selectedPaymentMethod = 'COD';
          String selectedPaymentType = 'FULL';
          double deliveryCharge = widget.prepaidDeliveryCharge;
          String calculatedTotal = '0.00';
          SubscriptionPlan? activeSub;

          if (state is CheckoutLoaded) {
            selectedPaymentMethod = state.selectedPaymentMethod;
            selectedPaymentType = state.selectedPaymentType;
            activeSub = state.subscription;

            deliveryCharge = CheckoutCalculator.deliveryCharge(
              paymentMethod: selectedPaymentMethod,
              codCharge: widget.codDeliveryCharge,
              prepaidCharge: widget.prepaidDeliveryCharge,
            );

            double basePrice;
            if (widget.isSubscription) {
              basePrice = CheckoutCalculator.subscriptionBasePrice(
                widget.price,
                widget.quantity,
              );
            } else {
              basePrice = widget.cart != null
                  ? CheckoutCalculator.cartBasePrice(widget.cart)
                  : CheckoutCalculator.singleProductBasePrice(
                      widget.singleProduct!.finalPrice,
                      widget.quantity,
                    );
            }
            calculatedTotal = CheckoutCalculator.total(basePrice, deliveryCharge)
                .toString();
          }

          final scaffold = Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    CheckoutHeader(
                      isSubscription: widget.isSubscription,
                      totalItems: totalItems,
                    ),
                    if (isLoading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state is CheckoutLoaded)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DeliveryTimeCard(
                                expectedDeliveryDate: widget.expectedDeliveryDate,
                                currentDeliveryCharge: deliveryCharge,
                              ),
                              const SizedBox(height: 16),
                              if (state.shippingDetails != null)
                                ShippingAddressCard(
                                  shippingDetails: state.shippingDetails,
                                ),
                              const SizedBox(height: 16),
                              if (widget.isSubscription && activeSub != null)
                                CongratulationCard(subscription: activeSub),
                              const SizedBox(height: 16),
                              OrderSummaryCard(
                                isSubscription: widget.isSubscription,
                                cart: widget.cart,
                                singleProduct: widget.singleProduct,
                                quantity: widget.quantity,
                                price: widget.price,
                                subscription: activeSub,
                                totalPrice: calculatedTotal,
                                currentDeliveryCharge: deliveryCharge,
                              ),
                              const SizedBox(height: 16),
                              if (state.pendingRewardsCount > 0)
                                RewardNotificationCard(
                                  pendingRewardsCount: state.pendingRewardsCount,
                                ),
                              const SizedBox(height: 16),
                              PaymentMethodCard(
                                isSubscription: widget.isSubscription,
                                selectedPaymentMethod: selectedPaymentMethod,
                                onSelected: (method) => context
                                    .read<CheckoutCubit>()
                                    .selectPaymentMethod(method),
                              ),
                              SizedBox(
                                height: (widget.isSubscription && activeSub != null
                                        ? 172.0
                                        : 88.0) +
                                    MediaQuery.paddingOf(context).bottom +
                                    16.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                if (!isLoading && state is CheckoutLoaded)
                  CheckoutBottomBar(
                    isSubscription: widget.isSubscription,
                    subscription: activeSub,
                    selectedPaymentType: selectedPaymentType,
                    totalPrice: calculatedTotal,
                    isSubmitting: isSubmitting,
                    onSubmit: () => context.read<CheckoutCubit>().submitCheckout(
                          isSubscription: widget.isSubscription,
                          cart: widget.cart,
                          singleProduct: widget.singleProduct,
                          quantity: widget.quantity,
                          deliveryFee: deliveryCharge,
                          expectedDeliveryDate: widget.expectedDeliveryDate,
                          selectedPlan: widget.selectedPlan,
                        ),
                  ),
                if (isSubmitting) const CheckoutLoadingOverlay(),
              ],
            ),
          );

          return PopScope(
            canPop: !isSubmitting,
            child: scaffold,
          );
        },
      ),
    );
  }





  void _showOrderFailedDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (_) => OrderFailedDialog(error: error),
    );
  }

  void _handleSuccess(BuildContext context, CheckoutSuccess success) {
    if (success.isSubscription) {
      final checkoutUrl = success.result['checkout_url'];
      if (checkoutUrl != null) {
        _launchSubscriptionWebView(context, success.result);
      } else {
        _showSubscriptionSuccessMessage(context, success.result);
      }
    } else {
      if (success.result['checkout_url'] != null) {
        _launchOrderWebView(context, success.result);
      } else {
        // COD order placed — navigate to order details
        final order = success.result['order'] as OrderEntity?;
        final orderId = order?.id.toString() ?? success.result['order_id']?.toString() ?? '0';
        context.goNamed(AppRoute.orderList.name);
        context.pushNamed(
          AppRoute.orderDetails.name,
          pathParameters: {'id': orderId},
          extra: order,
        );
      }
    }
  }

  void _showSubscriptionSuccessMessage(
    BuildContext context,
    Map<String, dynamic> result,
  ) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Subscription Created'),
        content: const Text(
          'Your subscription has been created successfully!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(diagContext).pop();
              if (result['subscription_id'] != null) {
                context.goNamed(AppRoute.subscriptionList.name);
                context.pushNamed(
                  AppRoute.subscriptionDetails.name,
                  pathParameters: {'id': result['subscription_id'].toString()},
                );
              } else {
                context.go(AppRoute.home.path);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _launchSubscriptionWebView(
    BuildContext context,
    Map<String, dynamic> result,
  ) {
    final cubit = context.read<CheckoutCubit>();
    Navigator.push(
      context,
      AnimatedTransitions.slideFromBottom(
        WebViewPage(
          url: result['checkout_url'],
          orderId: int.tryParse(result['subscription_id']?.toString() ?? '0') ?? 0,
          title: 'Secure Payment',
          subID: int.tryParse(result['subscription_id']?.toString() ?? '0') ?? 0,
          isSubscription: true,
          merchantTransactionId: result['merchant_transaction_id'],
          reference: result['subscription_number'],
          onPaymentSuccess: (url) async {
            final ref = result['subscription_number']?.toString() ??
                result['merchant_transaction_id']?.toString() ??
                result['subscription_id']?.toString() ??
                '';
            final success = await cubit.verifyPaymentStatus(ref);
            if (!context.mounted) return;
            Navigator.pop(context); // Close webview

            if (success) {
              final subId = int.tryParse(result['subscription_id']?.toString() ?? '0') ?? 0;
              context.goNamed(AppRoute.subscriptionList.name);
              if (subId > 0) {
                context.pushNamed(
                  AppRoute.subscriptionDetails.name,
                  pathParameters: {'id': subId.toString()},
                );
              } else {
                _showSubscriptionSuccessMessage(context, result);
              }
            } else {
              _showSubscriptionSuccessMessage(context, result);
            }
          },
          onPaymentFailure: (url) {
            Navigator.pop(context);
            SnackBarHelper.showPaymentIssue(context);
          },
        ),
      ),
    );
  }

  void _launchOrderWebView(BuildContext context, Map<String, dynamic> result) {
    final cubit = context.read<CheckoutCubit>();
    Navigator.push(
      context,
      AnimatedTransitions.slideFromBottom(
        WebViewPage(
          url: result['checkout_url'],
          orderId: int.tryParse(result['order_id']?.toString() ?? '0') ?? 0,
          title: 'Secure Payment',
          merchantTransactionId: result['merchant_transaction_id'],
          reference: result['order_number'],
          onPaymentSuccess: (url) async {
            final ref = result['order_number']?.toString() ??
                result['merchant_transaction_id']?.toString() ??
                '';
            final success = await cubit.verifyPaymentStatus(ref);
            if (!context.mounted) return;
            Navigator.pop(context); // Close webview

            if (success) {
              final orderId = int.tryParse(result['order_id']?.toString() ?? '0') ?? 0;
              final orderNumber = result['order_number']?.toString();
              context.goNamed(AppRoute.orderList.name);
              
              final targetId = orderId > 0 ? orderId.toString() : (orderNumber ?? '');
              if (targetId.isNotEmpty) {
                context.pushNamed(AppRoute.orderDetails.name, pathParameters: {'id': targetId});
              } else {
                SnackBarHelper.showInfo(context, 'Payment complete! Order is placed.');
              }
            } else {
              SnackBarHelper.showInfo(context, 'Payment complete! Order is placed.');
              context.goNamed(AppRoute.orderList.name);
            }
          },
          onPaymentFailure: (url) {
            Navigator.pop(context);
            SnackBarHelper.showError(context, 'Payment failed or cancelled');
          },
        ),
      ),
    );
  }
}
