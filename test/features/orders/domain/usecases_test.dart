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
import 'package:grocery_app/features/orders/domain/usecases/get_order_tracking_use_case.dart';
import 'package:grocery_app/features/orders/domain/usecases/get_user_shipping_details_use_case.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}
class MockPaymentsRepository extends Mock implements PaymentsRepository {}
class MockCreateOrderParams extends Mock implements CreateOrderParams {}

void main() {
  late MockOrdersRepository mockOrdersRepository;
  late MockPaymentsRepository mockPaymentsRepository;

  setUp(() {
    mockOrdersRepository = MockOrdersRepository();
    mockPaymentsRepository = MockPaymentsRepository();
  });

  group('Orders Feature Use Cases', () {
    test('GetOrdersUseCase filters out unpaid UPI orders', () async {
      final o1 = OrderEntity(
        id: 1,
        orderNumber: "O1",
        status: "CONFIRMED",
        paymentStatus: "SUCCESS",
        paymentMethod: "UPI",
        deliveryAddress: "Addr",
        deliveryCity: "City",
        deliveryState: "State",
        deliveryPincode: "123",
        deliveryPhone: "456",
        recipientName: "Name",
        subtotal: 10.0,
        tax: 1.0,
        deliveryCharges: 2.0,
        discount: 0.0,
        total: 13.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expectedDeliveryDate: DateTime.now(),
        isSubscriptionOrder: false,
        isFirstOrder: false,
        hasReferralReward: false,
        items: [],
      );

      final o2 = OrderEntity(
        id: 2,
        orderNumber: "O2",
        status: "CONFIRMED",
        paymentStatus: "PENDING",
        paymentMethod: "UPI",
        deliveryAddress: "Addr",
        deliveryCity: "City",
        deliveryState: "State",
        deliveryPincode: "123",
        deliveryPhone: "456",
        recipientName: "Name",
        subtotal: 10.0,
        tax: 1.0,
        deliveryCharges: 2.0,
        discount: 0.0,
        total: 13.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expectedDeliveryDate: DateTime.now(),
        isSubscriptionOrder: false,
        isFirstOrder: false,
        hasReferralReward: false,
        items: [],
      );

      final o3 = OrderEntity(
        id: 3,
        orderNumber: "O3",
        status: "CONFIRMED",
        paymentStatus: "PENDING",
        paymentMethod: "COD",
        deliveryAddress: "Addr",
        deliveryCity: "City",
        deliveryState: "State",
        deliveryPincode: "123",
        deliveryPhone: "456",
        recipientName: "Name",
        subtotal: 10.0,
        tax: 1.0,
        deliveryCharges: 2.0,
        discount: 0.0,
        total: 13.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expectedDeliveryDate: DateTime.now(),
        isSubscriptionOrder: false,
        isFirstOrder: false,
        hasReferralReward: false,
        items: [],
      );

      when(() => mockOrdersRepository.getOrders()).thenAnswer((_) async => [o1, o2, o3]);

      final useCase = GetOrdersUseCase(mockOrdersRepository);
      final result = await useCase();

      expect(result.length, 2);
      expect(result.contains(o1), true);
      expect(result.contains(o3), true);
      expect(result.contains(o2), false);
    });

    test('GetOrderByIdUseCase calls repository', () async {
      final o1 = OrderEntity(
        id: 1,
        orderNumber: "O1",
        status: "CONFIRMED",
        paymentStatus: "SUCCESS",
        paymentMethod: "UPI",
        deliveryAddress: "Addr",
        deliveryCity: "City",
        deliveryState: "State",
        deliveryPincode: "123",
        deliveryPhone: "456",
        recipientName: "Name",
        subtotal: 10.0,
        tax: 1.0,
        deliveryCharges: 2.0,
        discount: 0.0,
        total: 13.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expectedDeliveryDate: DateTime.now(),
        isSubscriptionOrder: false,
        isFirstOrder: false,
        hasReferralReward: false,
        items: [],
      );

      when(() => mockOrdersRepository.getOrderById(1)).thenAnswer((_) async => o1);

      final useCase = GetOrderByIdUseCase(mockOrdersRepository);
      final result = await useCase(1);

      expect(result, o1);
      verify(() => mockOrdersRepository.getOrderById(1)).called(1);
    });

    test('CreateOrderUseCase calls repository with params', () async {
      final params = CreateOrderParams(
        paymentMethod: "UPI",
        shippingAddress: "Addr",
        shippingCity: "City",
        shippingState: "State",
        shippingPincode: "123",
        shippingPhone: "456",
        shippingName: "Name",
        items: [],
      );
      final response = OrderCreateResponseEntity(success: true, orderNumber: "ORD999");
      when(() => mockOrdersRepository.createOrder(params)).thenAnswer((_) async => response);

      final useCase = CreateOrderUseCase(mockOrdersRepository, mockPaymentsRepository);
      final result = await useCase(params);

      expect(result, response);
      verify(() => mockOrdersRepository.createOrder(params)).called(1);
    });

    test('CancelOrderUseCase calls repository', () async {
      final response = {'status': 'success'};
      when(() => mockOrdersRepository.cancelOrder(1, reason: 'cancel')).thenAnswer((_) async => response);

      final useCase = CancelOrderUseCase(mockOrdersRepository);
      final result = await useCase(1, reason: 'cancel');

      expect(result, response);
      verify(() => mockOrdersRepository.cancelOrder(1, reason: 'cancel')).called(1);
    });

    test('DownloadInvoiceUseCase calls repository', () async {
      when(() => mockOrdersRepository.downloadInvoice("ORD123")).thenAnswer((_) async => "/path/to/file.pdf");

      final useCase = DownloadInvoiceUseCase(mockOrdersRepository);
      final result = await useCase("ORD123");

      expect(result, "/path/to/file.pdf");
      verify(() => mockOrdersRepository.downloadInvoice("ORD123")).called(1);
    });

    test('GetOrderTrackingUseCase calls repository', () async {
      final tracking = OrderTrackingEntity(
        id: 1,
        order: 10,
        orderNumber: "ORD123",
        orderStatus: "SHIPPED",
        status: "IN TRANSIT",
        trackingEvents: [],
      );
      when(() => mockOrdersRepository.getOrderTracking("ORD123")).thenAnswer((_) async => tracking);

      final useCase = GetOrderTrackingUseCase(mockOrdersRepository);
      final result = await useCase("ORD123");

      expect(result, tracking);
      verify(() => mockOrdersRepository.getOrderTracking("ORD123")).called(1);
    });

    test('GetUserShippingDetailsUseCase calls repository', () async {
      final details = ShippingDetailsEntity(
        address: "addr",
        name: "name",
        city: "city",
        state: "state",
        pincode: "123",
        phone: "456",
      );
      when(() => mockOrdersRepository.getUserShippingDetails()).thenAnswer((_) async => details);

      final useCase = GetUserShippingDetailsUseCase(mockOrdersRepository);
      final result = await useCase();

      expect(result, details);
      verify(() => mockOrdersRepository.getUserShippingDetails()).called(1);
    });
  });
}
