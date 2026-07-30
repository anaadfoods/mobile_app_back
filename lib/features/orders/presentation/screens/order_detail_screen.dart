import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/routes/app_routes.dart';
import 'package:grocery_app/services/api_config.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/get_order_tracking_use_case.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';
import '../widgets/order_detail_header.dart';
import '../widgets/order_tracking_timeline.dart';
import '../widgets/order_products_card.dart';
import '../widgets/order_price_summary.dart';
import '../widgets/order_delivery_card.dart';
import '../widgets/order_actions_card.dart';
import '../widgets/order_cancellation_dialogs.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderEntity? order;
  final String? orderId;
  final String? orderNumber;

  const OrderDetailScreen({super.key, this.order, this.orderId, this.orderNumber});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  OrderEntity? _currentOrder;
  OrderTrackingEntity? _orderTracking;
  bool _isLoadingTracking = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    if (widget.order != null) {
      _currentOrder = widget.order;
      _animController.forward();
      _fetchTracking();
    } else if (widget.orderId != null) {
      context.read<OrderCubit>().fetchOrderDetails(int.parse(widget.orderId!));
    } else if (widget.orderNumber != null) {
      context.read<OrderCubit>().fetchOrderDetailsByNumber(widget.orderNumber!);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchTracking() async {
    if (_currentOrder == null || _isLoadingTracking) return;

    setState(() => _isLoadingTracking = true);
    try {
      final tracking = await getIt<GetOrderTrackingUseCase>()(_currentOrder!.orderNumber);
      if (mounted) {
        setState(() {
          _orderTracking = tracking;
          _isLoadingTracking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingTracking = false);
      }
    }
  }

  void _handleBack(BuildContext context) {
    context.goNamed(AppRoute.orderList.name);
  }

  Future<void> _downloadInvoice() async {
    if (_currentOrder == null) return;
    SnackBarHelper.showLoading(context, 'Downloading invoice...');
    await context.read<OrderCubit>().downloadInvoice(_currentOrder!.orderNumber);
  }

  Future<void> _cancelOrder() async {
    if (_currentOrder == null) return;
    final warningProceed = await showDialog<bool>(
      context: context,
      builder: (_) => const CancelWarningDialog(type: 'order'),
    );
    if (warningProceed != true) return;

    final confirmProceed = await showDialog<bool>(
      context: context,
      builder: (_) => const CancelConfirmDialog(type: 'order'),
    );
    if (confirmProceed != true) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const CancelReasonDialog(type: 'order'),
    );
    if (reason == null || reason.isEmpty) return;

    if (!mounted) return;
    setState(() => _isCancelling = true);
    final result = await context.read<OrderCubit>().cancelOrder(
          _currentOrder!.id,
          reason: reason,
        );
    if (mounted) {
      setState(() => _isCancelling = false);
      if (result != null && result['success'] == true) {
        SnackBarHelper.showSuccess(context, 'Order cancelled successfully');
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<OrderCubit, OrderState>(
      listener: (context, state) {
        if (state is OrderSuccess && state.selectedOrderDetails != null) {
          setState(() {
            _currentOrder = state.selectedOrderDetails;
          });
          _animController.forward();
          _fetchTracking();
        } else if (state is OrderActionSuccess) {
          SnackBarHelper.showSuccess(context, state.message);
        } else if (state is OrderError) {
          SnackBarHelper.showError(context, state.message);
        }
      },
      builder: (context, state) {
        if (_currentOrder == null) {
          return const Scaffold(
            body: LoadingStateWidget(),
          );
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            context.goNamed(AppRoute.orderList.name);
          },
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<OrderCubit>().fetchOrderDetails(_currentOrder!.id);
              },
              color: theme.colorScheme.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  OrderDetailHeader(
                    order: _currentOrder!,
                    onBack: () => _handleBack(context),
                    onRefresh: () {
                      context.read<OrderCubit>().fetchOrderDetails(_currentOrder!.id);
                    },
                  ),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        child: Column(
                          children: [
                            _buildDeliveryDateHeader(theme, isDark),
                            const SizedBox(height: 16),
                            OrderTrackingTimeline(
                              order: _currentOrder!,
                              tracking: _orderTracking,
                            ),
                            const SizedBox(height: 16),
                            if (_currentOrder!.hasReferralReward) ...[
                              _buildReferralRewardBanner(theme, isDark),
                              const SizedBox(height: 16),
                            ],
                            OrderProductsCard(items: _currentOrder!.items),
                            const SizedBox(height: 16),
                            OrderPriceSummary(order: _currentOrder!),
                            const SizedBox(height: 16),
                            OrderDeliveryCard(order: _currentOrder!),
                            const SizedBox(height: 16),
                            OrderActionsCard(
                              order: _currentOrder!,
                              isCancelling: _isCancelling,
                              onDownloadInvoice: _downloadInvoice,
                              onCancelOrder: _cancelOrder,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: _buildWhatsAppFAB(),
          ),
        );
      },
    );
  }

  Widget _buildDeliveryDateHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.deepSoilGreen.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ApiConfig.showExpectedDeliveryDate
                      ? 'Arriving ${_formatDate(_currentOrder!.expectedDeliveryDate)}'
                      : ApiConfig.alternativeDeliveryText,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Order Number: #${_currentOrder!.orderNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralRewardBanner(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.harvestAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.harvestAmber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.redeem_rounded, color: AppColors.harvestAmber, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '🎉 You unlocked a referral reward with this order!',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.harvestAmber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  FloatingActionButton _buildWhatsAppFAB() {
    return FloatingActionButton.extended(
      backgroundColor: AppColors.parchment,
      foregroundColor: AppColors.charcoal,
      icon: const Icon(Icons.chat_rounded),
      label: const Text('Chat Support'),
      onPressed: () async {
        HapticFeedback.lightImpact();
        final authState = context.read<AuthCubit>().state;
        final user = authState is Authenticated ? authState.user : null;
        const phone = '+919996166186';
        final message = Uri.encodeComponent(
          'Hi! I need help with my order.\n\n'
          'Order #${_currentOrder!.orderNumber}\n'
          'Status: ${_currentOrder!.status}\n'
          'Amount: ₹${_currentOrder!.total}\n\n'
          'Name: ${user?.firstName ?? ''} ${user?.lastName ?? ''}\n'
          'Phone: ${user?.phoneNumber ?? ''}',
        );
        final url = 'https://wa.me/$phone?text=$message';
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          }
        } catch (_) {
          if (mounted) {
            SnackBarHelper.showError(context, 'Could not open WhatsApp');
          }
        }
      },
    );
  }
}
