import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/orders/domain/entities/order_entity.dart';
import 'package:grocery_app/features/orders/domain/repositories/orders_repository.dart';
import 'package:grocery_app/features/payments/domain/repositories/payments_repository.dart';
import 'package:grocery_app/features/orders/domain/usecases/get_orders_use_case.dart';
import 'package:grocery_app/features/orders/domain/usecases/get_order_by_id_use_case.dart';
import 'package:grocery_app/features/orders/domain/usecases/create_order_use_case.dart';
import 'package:grocery_app/features/orders/domain/usecases/cancel_order_use_case.dart';
import 'package:grocery_app/features/orders/domain/usecases/download_invoice_use_case.dart';
import 'package:grocery_app/features/orders/presentation/cubit/order_cubit.dart';
import 'package:grocery_app/features/orders/presentation/cubit/order_state.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}
class MockPaymentsRepository extends Mock implements PaymentsRepository {}

void main() {
  late MockOrdersRepository mockRepository;
  late MockPaymentsRepository mockPaymentsRepository;
  late OrderCubit orderCubit;
  late OrderEntity activePaidUpiOrder;
  late OrderEntity activeUnpaidUpiOrder;
  late OrderEntity codOrder;

  setUp(() {
    mockRepository = MockOrdersRepository();
    mockPaymentsRepository = MockPaymentsRepository();
    orderCubit = OrderCubit(
      getOrdersUseCase: GetOrdersUseCase(mockRepository),
      getOrderByIdUseCase: GetOrderByIdUseCase(mockRepository),
      createOrderUseCase: CreateOrderUseCase(mockRepository, mockPaymentsRepository),
      cancelOrderUseCase: CancelOrderUseCase(mockRepository),
      downloadInvoiceUseCase: DownloadInvoiceUseCase(mockRepository),
    );

    activePaidUpiOrder = OrderEntity(
      id: 1,
      orderNumber: "ORD123",
      status: "CONFIRMED",
      paymentStatus: "SUCCESS",
      paymentMethod: "UPI",
      deliveryAddress: "Address 1",
      deliveryCity: "City",
      deliveryState: "State",
      deliveryPincode: "123456",
      deliveryPhone: "9876543210",
      recipientName: "User 1",
      subtotal: 100.0,
      tax: 5.0,
      deliveryCharges: 10.0,
      discount: 0.0,
      total: 115.0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      expectedDeliveryDate: DateTime(2026, 1, 2),
      isSubscriptionOrder: false,
      isFirstOrder: false,
      hasReferralReward: false,
      items: [],
    );

    activeUnpaidUpiOrder = OrderEntity(
      id: 2,
      orderNumber: "ORD456",
      status: "CONFIRMED",
      paymentStatus: "PENDING",
      paymentMethod: "UPI",
      deliveryAddress: "Address 2",
      deliveryCity: "City",
      deliveryState: "State",
      deliveryPincode: "123456",
      deliveryPhone: "9876543210",
      recipientName: "User 2",
      subtotal: 200.0,
      tax: 10.0,
      deliveryCharges: 10.0,
      discount: 0.0,
      total: 220.0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      expectedDeliveryDate: DateTime(2026, 1, 2),
      isSubscriptionOrder: false,
      isFirstOrder: false,
      hasReferralReward: false,
      items: [],
    );

    codOrder = OrderEntity(
      id: 3,
      orderNumber: "ORD789",
      status: "CONFIRMED",
      paymentStatus: "PENDING",
      paymentMethod: "COD",
      deliveryAddress: "Address 3",
      deliveryCity: "City",
      deliveryState: "State",
      deliveryPincode: "123456",
      deliveryPhone: "9876543210",
      recipientName: "User 3",
      subtotal: 300.0,
      tax: 15.0,
      deliveryCharges: 10.0,
      discount: 0.0,
      total: 325.0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      expectedDeliveryDate: DateTime(2026, 1, 2),
      isSubscriptionOrder: false,
      isFirstOrder: false,
      hasReferralReward: false,
      items: [],
    );

    registerFallbackValue(
      CreateOrderParams(
        paymentMethod: "COD",
        shippingAddress: "addr",
        shippingCity: "city",
        shippingState: "state",
        shippingPincode: "123",
        shippingPhone: "456",
        shippingName: "name",
        items: [],
      ),
    );
  });

  tearDown(() {
    orderCubit.close();
  });

  group('OrderCubit Clean Architecture Characterization Tests', () {
    test('fetchOrders emits OrderLoading then OrderSuccess and filters out unpaid UPI orders', () async {
      final allOrders = [activePaidUpiOrder, activeUnpaidUpiOrder, codOrder];
      when(() => mockRepository.getOrders()).thenAnswer((_) async => allOrders);

      final states = <OrderState>[];
      final subscription = orderCubit.stream.listen(states.add);

      await orderCubit.fetchOrders();
      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<OrderLoading>());
      expect(states[1], isA<OrderSuccess>());

      final successState = states[1] as OrderSuccess;
      expect(successState.orders.length, 2);
      expect(successState.orders.contains(activePaidUpiOrder), true);
      expect(successState.orders.contains(codOrder), true);
      expect(successState.orders.contains(activeUnpaidUpiOrder), false);

      await subscription.cancel();
    });

    test('fetchOrderDetails emits OrderLoading then OrderSuccess with selectedOrderDetails', () async {
      when(() => mockRepository.getOrderById(1)).thenAnswer((_) async => activePaidUpiOrder);

      final states = <OrderState>[];
      final subscription = orderCubit.stream.listen(states.add);

      await orderCubit.fetchOrderDetails(1);
      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<OrderLoading>());
      expect(states[1], isA<OrderSuccess>());
      expect((states[1] as OrderSuccess).selectedOrderDetails, activePaidUpiOrder);

      await subscription.cancel();
    });

    test('createOrder emits OrderLoading then OrderPlacementSuccess and refreshes orders', () async {
      final mockResponse = OrderCreateResponseEntity(success: true, orderNumber: "ORD999");
      when(() => mockRepository.createOrder(any())).thenAnswer((_) async => mockResponse);
      when(() => mockRepository.getOrders()).thenAnswer((_) async => [codOrder]);

      final states = <OrderState>[];
      final subscription = orderCubit.stream.listen(states.add);

      final params = CreateOrderParams(
        paymentMethod: "COD",
        shippingAddress: "Address",
        shippingCity: "City",
        shippingState: "State",
        shippingPincode: "123",
        shippingPhone: "987",
        shippingName: "Recipient",
        items: [],
      );

      await orderCubit.createOrder(params);
      await Future.delayed(Duration.zero);

      expect(states.length, 4);
      expect(states[0], isA<OrderLoading>());
      expect(states[1], isA<OrderPlacementSuccess>());
      expect((states[1] as OrderPlacementSuccess).response, mockResponse);
      expect(states[2], isA<OrderLoading>());
      expect(states[3], isA<OrderSuccess>());

      await subscription.cancel();
    });

    test('cancelOrder emits OrderLoading then OrderActionSuccess and refreshes orders', () async {
      final mockResult = {'success': true, 'message': 'Order cancelled'};
      when(() => mockRepository.cancelOrder(1, reason: 'Too late')).thenAnswer((_) async => mockResult);
      when(() => mockRepository.getOrders()).thenAnswer((_) async => [codOrder]);

      final states = <OrderState>[];
      final subscription = orderCubit.stream.listen(states.add);

      await orderCubit.cancelOrder(1, reason: 'Too late');
      await Future.delayed(Duration.zero);

      expect(states.length, 4);
      expect(states[0], isA<OrderLoading>());
      expect(states[1], isA<OrderActionSuccess>());
      expect((states[1] as OrderActionSuccess).message, 'Order cancelled');
      expect(states[2], isA<OrderLoading>());
      expect(states[3], isA<OrderSuccess>());

      await subscription.cancel();
    });

    test('downloadInvoice emits OrderActionSuccess with path', () async {
      when(() => mockRepository.downloadInvoice("ORD123")).thenAnswer((_) async => "/path/to/invoice.pdf");

      final states = <OrderState>[];
      final subscription = orderCubit.stream.listen(states.add);

      await orderCubit.downloadInvoice("ORD123");
      await Future.delayed(Duration.zero);

      expect(states.length, 1);
      expect(states[0], isA<OrderActionSuccess>());
      expect((states[0] as OrderActionSuccess).message, 'Invoice saved to /path/to/invoice.pdf');

      await subscription.cancel();
    });
  });
}
