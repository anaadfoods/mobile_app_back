import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/subscription_plan_model.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/create_subscription_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/get_subscription_plans_use_case.dart';
import 'package:grocery_app/services/referral_reward_service.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/utils/app_logger.dart';
import 'checkout_state.dart';
import '../../domain/usecases/poll_payment_status_use_case.dart';
import '../../domain/usecases/verify_payment_response_use_case.dart';
import 'package:grocery_app/features/orders/domain/entities/order_entity.dart';
import 'package:grocery_app/features/orders/domain/usecases/create_order_use_case.dart';
import 'package:grocery_app/features/orders/domain/usecases/get_user_shipping_details_use_case.dart';
import 'package:grocery_app/models/shipping_details.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final CreateOrderUseCase _createOrderUseCase;
  final GetUserShippingDetailsUseCase _getUserShippingDetailsUseCase;
  final CreateSubscriptionUseCase _createSubscriptionUseCase;
  final GetSubscriptionPlansUseCase _getSubscriptionPlansUseCase;
  final ReferralRewardService _rewardService;
  final PollPaymentStatusUseCase _pollPaymentStatusUseCase;
  final VerifyPaymentResponseUseCase _verifyPaymentResponseUseCase;

  CheckoutCubit({
    CreateOrderUseCase? createOrderUseCase,
    GetUserShippingDetailsUseCase? getUserShippingDetailsUseCase,
    CreateSubscriptionUseCase? createSubscriptionUseCase,
    GetSubscriptionPlansUseCase? getSubscriptionPlansUseCase,
    ReferralRewardService? rewardService,
    PollPaymentStatusUseCase? pollPaymentStatusUseCase,
    VerifyPaymentResponseUseCase? verifyPaymentResponseUseCase,
  })  : _createOrderUseCase = createOrderUseCase ?? getIt<CreateOrderUseCase>(),
        _getUserShippingDetailsUseCase =
            getUserShippingDetailsUseCase ?? getIt<GetUserShippingDetailsUseCase>(),
        _createSubscriptionUseCase =
            createSubscriptionUseCase ?? getIt<CreateSubscriptionUseCase>(),
        _getSubscriptionPlansUseCase =
            getSubscriptionPlansUseCase ?? getIt<GetSubscriptionPlansUseCase>(),
        _rewardService = rewardService ?? getIt<ReferralRewardService>(),
        _pollPaymentStatusUseCase =
            pollPaymentStatusUseCase ?? getIt<PollPaymentStatusUseCase>(),
        _verifyPaymentResponseUseCase = verifyPaymentResponseUseCase ??
            getIt<VerifyPaymentResponseUseCase>(),
        super(CheckoutInitial());

  Future<void> initialize({
    Map<String, String>? customShipping,
    required bool isSubscription,
    int? selectedPlan,
  }) async {
    emit(CheckoutLoading());

    ShippingDetails? shippingDetails;
    if (customShipping != null) {
      shippingDetails = ShippingDetails(
        address: customShipping['address'] ?? '',
        name: customShipping['name'] ?? '',
        city: customShipping['city'] ?? '',
        state: customShipping['state'] ?? '',
        pincode: customShipping['pincode'] ?? '',
        phone: customShipping['phone'] ?? '',
      );
    } else {
      try {
        final entity = await _getUserShippingDetailsUseCase();
        if (entity != null) {
          shippingDetails = ShippingDetails(
            address: entity.address,
            name: entity.name,
            city: entity.city,
            state: entity.state,
            pincode: entity.pincode,
            phone: entity.phone,
          );
        }
      } catch (e) {
        AppLogger.instance.log('Error loading shipping details: $e');
      }
    }

    List<SubscriptionPlan> planDescriptions = [];
    SubscriptionPlan? subscription;
    if (isSubscription) {
      try {
        final plans = await _getSubscriptionPlansUseCase();
        planDescriptions = plans
            .map((e) => SubscriptionPlan(
                  id: e.id,
                  name: e.name,
                  durationMonths: e.durationMonths,
                  discountPercentage: '0',
                  totalDiscountPercentage: 0,
                  tagline: e.tagline,
                  description: e.description,
                  isActive: e.isActive,
                  activationDate: '',
                  isOneTimeOnly: false,
                  allowsInstallments: false,
                  installmentFrequencyMonths: 0,
                  isAvailable: true,
                ))
            .toList();
        if (planDescriptions.isNotEmpty && selectedPlan != null) {
          subscription = planDescriptions
              .where((p) => p.id == selectedPlan)
              .firstOrNull;
        }
      } catch (e) {
        AppLogger.instance.log('Error loading subscription plans: $e');
      }
    }

    int pendingRewardsCount = 0;
    try {
      pendingRewardsCount = await _rewardService.getPendingRewardsCount();
    } catch (e) {
      AppLogger.instance.log('Error loading pending rewards: $e');
    }

    emit(CheckoutLoaded(
      shippingDetails: shippingDetails,
      planDescriptions: planDescriptions,
      subscription: subscription,
      pendingRewardsCount: pendingRewardsCount,
      selectedPaymentMethod: isSubscription ? 'UPI' : 'COD',
      selectedPaymentType: isSubscription ? 'PAID_FULL' : 'FULL',
      useExistingAddress: customShipping == null,
    ));
  }

  void selectPaymentMethod(String method) {
    final currentState = state;
    if (currentState is CheckoutLoaded) {
      emit(currentState.copyWith(selectedPaymentMethod: method));
    }
  }

  void selectPaymentType(String type) {
    final currentState = state;
    if (currentState is CheckoutLoaded) {
      emit(currentState.copyWith(selectedPaymentType: type));
    }
  }

  void updateShippingDetails(ShippingDetails details) {
    final currentState = state;
    if (currentState is CheckoutLoaded) {
      emit(currentState.copyWith(
        shippingDetails: () => details,
        useExistingAddress: false,
      ));
    }
  }

  Future<void> submitCheckout({
    required bool isSubscription,
    CartModel? cart,
    Product? singleProduct,
    int? quantity,
    required double deliveryFee,
    required String expectedDeliveryDate,
    int? selectedPlan,
  }) async {
    final currentState = state;
    if (currentState is! CheckoutLoaded) return;

    final shipping = currentState.shippingDetails;
    if (shipping == null || !shipping.isComplete) {
      emit(currentState.copyWith(error: () => 'Please complete your shipping details.'));
      return;
    }

    emit(currentState.copyWith(isSubmitting: true, error: () => null));

    try {
      if (isSubscription) {
        final request = {
          'plan': selectedPlan,
          'delivery_address': shipping.address,
          'delivery_name': shipping.name,
          'delivery_city': shipping.city ?? "",
          'delivery_state': shipping.state ?? "",
          'delivery_pincode': shipping.pincode ?? "",
          'delivery_phone': shipping.phone ?? "",
          'payment_type': currentState.selectedPaymentType,
          'payment_method': currentState.selectedPaymentMethod,
          'delivery_fee': deliveryFee,
          'expected_delivery_date': expectedDeliveryDate,
          'items': [
            {
              'product_variant_id': singleProduct!.id,
              'quantity': quantity!,
            }
          ],
        };

        final response = await _createSubscriptionUseCase(request);
        if (response.requiresOnlinePayment) {
          emit(CheckoutSuccess(
            result: {
              'success': true,
              'checkout_url': response.checkoutUrl ?? (response.paymentLinks != null ? response.paymentLinks!['checkout_url'] : null),
              'subscription_id': response.subscriptionId,
            },
            isSubscription: true,
          ));
        } else {
          emit(CheckoutSuccess(
            result: {
              'success': true,
              'subscription_id': response.subscriptionId,
            },
            isSubscription: true,
          ));
        }
      } else {
        final List<CreateOrderItemParams> items = [];
        if (cart != null) {
          items.addAll(cart.items.map((i) => CreateOrderItemParams(
                productVariantId: i.productVariant.id,
                quantity: i.quantity,
              )));
        } else if (singleProduct != null && quantity != null) {
          items.add(CreateOrderItemParams(
            productVariantId: singleProduct.id,
            quantity: quantity,
          ));
        }

        final params = CreateOrderParams(
          paymentMethod: currentState.selectedPaymentMethod,
          shippingName: shipping.name,
          shippingPhone: shipping.phone,
          shippingAddress: shipping.address,
          shippingCity: shipping.city,
          shippingState: shipping.state,
          shippingPincode: shipping.pincode,
          items: items,
          notes: null,
        );

        final response = await _createOrderUseCase(params);
        if (response.checkoutUrl != null && response.success) {
          // Online payment: redirect to payment gateway
          emit(CheckoutSuccess(
            result: {
              'success': true,
              'checkout_url': response.checkoutUrl,
              'order_number': response.orderNumber,
              'merchant_transaction_id': response.merchantTransactionId,
              'order_id': response.orderId ?? 0,
            },
            isSubscription: false,
          ));
        } else if (response.success) {
          // COD: order placed directly
          emit(CheckoutSuccess(
            result: {
              'success': true,
              'order': response.order,
              'order_id': response.orderId ?? 0,
              'order_number': response.orderNumber,
            },
            isSubscription: false,
          ));
        } else {
          final errorMsg = _parseServerError(response.message ?? 'Order creation failed');
          emit(CheckoutFailure(errorMsg));
        }
      }
    } catch (e) {
      final errorMsg = _parseServerError(e);
      emit(CheckoutFailure(errorMsg));
    } finally {
      final finalState = state;
      if (finalState is CheckoutLoaded) {
        emit(finalState.copyWith(isSubmitting: false));
      }
    }
  }

  Future<bool> verifyPaymentStatus(String reference) async {
    try {
      final status = await _pollPaymentStatusUseCase(reference);
      return status.isSuccess;
    } catch (_) {
      return false;
    }
  }

  Future<void> verifyJuspayResponse(String orderId) async {
    try {
      await _verifyPaymentResponseUseCase(orderId);
    } catch (e) {
      AppLogger.instance.log('Juspay verification error: $e');
    }
  }

  String _parseServerError(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    final errorString = error.toString().toLowerCase();
    if (errorString.contains('405') || errorString.contains('method not allowed')) {
      return 'Action not allowed. Please contact support.';
    }

    List<String> messages = [];

    if (error is Map) {
      final map = Map<String, dynamic>.from(error);
      if (map['message'] != null) {
        final msg = _cleanSingleErrorMessage(map['message']);
        if (msg.isNotEmpty) messages.add(msg);
      }
      if (map['detail'] != null) {
        final d = _cleanSingleErrorMessage(map['detail']);
        if (d.isNotEmpty && !messages.contains(d)) messages.add(d);
      } else if (map['error'] != null && map['error'] is String) {
        final e = _cleanSingleErrorMessage(map['error']);
        if (e.isNotEmpty && !messages.contains(e)) messages.add(e);
      }
      if (map['errors'] != null) {
        final errs = map['errors'];
        if (errs is Map) {
          errs.forEach((key, val) {
            final parsedVal = _cleanSingleErrorMessage(val);
            if (parsedVal.isNotEmpty && !messages.contains(parsedVal)) {
              messages.add(parsedVal);
            }
          });
        } else if (errs is List) {
          for (var item in errs) {
            final parsedVal = _cleanSingleErrorMessage(item);
            if (parsedVal.isNotEmpty && !messages.contains(parsedVal)) {
              messages.add(parsedVal);
            }
          }
        } else if (errs is String) {
          final parsedVal = _cleanSingleErrorMessage(errs);
          if (parsedVal.isNotEmpty && !messages.contains(parsedVal)) {
            messages.add(parsedVal);
          }
        }
      }
      if (messages.isNotEmpty) {
        return messages.join('\n\n');
      }
    }

    final singleClean = _cleanSingleErrorMessage(error);
    return singleClean.isNotEmpty ? singleClean : error.toString();
  }

  String _cleanSingleErrorMessage(dynamic raw) {
    if (raw == null) return '';
    String text = '';

    if (raw is List) {
      text = raw
          .map((e) => _cleanSingleErrorMessage(e))
          .where((e) => e.isNotEmpty)
          .join('\n\n');
    } else if (raw is Map) {
      List<String> list = [];
      raw.forEach((key, val) {
        final cleanVal = _cleanSingleErrorMessage(val);
        if (cleanVal.isNotEmpty && !list.contains(cleanVal)) {
          list.add(cleanVal);
        }
      });
      text = list.join('\n\n');
    } else {
      text = raw.toString();
    }

    text = text
        .replaceAll(RegExp(r'^\[\s*'), '')
        .replaceAll(RegExp(r'\s*\]$'), '')
        .trim();

    text = text.replaceAll(RegExp(r'^\s*•?\s*\w+:\s*'), '');

    if (text.startsWith('"') && text.endsWith('"') && text.length > 2) {
      text = text.substring(1, text.length - 1);
    }

    return text.trim();
  }
}
