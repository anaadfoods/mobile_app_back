import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:grocery_app/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:grocery_app/features/orders/domain/entities/order_entity.dart';
import 'package:grocery_app/features/orders/domain/failures/order_failure.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/models/order_tracking_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/api_exception.dart';

class MockOrdersRemoteDataSource extends Mock implements OrdersRemoteDataSource {}
class MockOrderModel extends Mock implements OrderModel {}

void main() {
  late MockOrdersRemoteDataSource mockDataSource;
  late OrdersRepositoryImpl repository;
  late Order testOrderDto;

  setUp(() {
    mockDataSource = MockOrdersRemoteDataSource();
    repository = OrdersRepositoryImpl(remoteDataSource: mockDataSource);

    testOrderDto = Order(
      id: 10,
      orderNumber: "ORD1234",
      status: "DELIVERED",
      paymentStatus: "SUCCESS",
      paymentMethod: "COD",
      deliveryAddress: "Address",
      deliveryCity: "City",
      deliveryState: "State",
      deliveryPincode: "123",
      deliveryPhone: "987",
      recipientName: "User",
      subtotal: 100.0,
      tax: 5.0,
      deliveryCharges: 10.0,
      discount: 0.0,
      total: 115.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      expectedDeliveryDate: DateTime.now(),
      isSubscriptionOrder: false,
      isFirstOrder: false,
      hasReferralReward: false,
      items: [
        OrderItemResponse(
          productDetails: Product(
            id: 1,
            sku: "SKU",
            weight: "500",
            weightUnit: "g",
            price: 100.0,
            discountPercentage: 0.0,
            finalPrice: 100.0,
            isInStock: true,
            isActive: true,
            productName: "Apple",
            productDescription: "Fresh Apple",
            productCategory: "Fruits",
            productImages: [],
          ),
          quantity: 2,
          price: 100.0,
          discount: 0.0,
          total: 200.0,
        )
      ],
    );

    registerFallbackValue(MockOrderModel());
  });

  group('OrdersRepositoryImpl Tests', () {
    test('getOrders maps successfully', () async {
      when(() => mockDataSource.getOrders()).thenAnswer((_) async => [testOrderDto]);

      final result = await repository.getOrders();

      expect(result.length, 1);
      final entity = result.first;
      expect(entity.id, 10);
      expect(entity.orderNumber, "ORD1234");
      expect(entity.items.length, 1);
      expect(entity.items.first.productDetails.productName, "Apple");
    });

    test('getOrderById maps successfully', () async {
      when(() => mockDataSource.getOrderById(10)).thenAnswer((_) async => testOrderDto);

      final result = await repository.getOrderById(10);

      expect(result.id, 10);
      expect(result.status, "DELIVERED");
      expect(result.items.first.productDetails.productName, "Apple");
    });

    test('createOrder handles OrderCreateResponse maps successfully', () async {
      final createResponse = OrderCreateResponse(
        success: true,
        orderNumber: "ORD999",
        checkoutUrl: "https://pay.com",
      );
      when(() => mockDataSource.createOrder(any())).thenAnswer((_) async => createResponse);

      final params = CreateOrderParams(
        paymentMethod: "UPI",
        shippingAddress: "Addr",
        shippingCity: "City",
        shippingState: "State",
        shippingPincode: "123",
        shippingPhone: "456",
        shippingName: "Name",
        items: [CreateOrderItemParams(productVariantId: 1, quantity: 2)],
      );

      final result = await repository.createOrder(params);

      expect(result.success, true);
      expect(result.orderNumber, "ORD999");
      expect(result.checkoutUrl, "https://pay.com");
    });

    test('cancelOrder maps successfully', () async {
      final cancelResult = {'success': true, 'message': 'Cancelled'};
      when(() => mockDataSource.cancelOrder(10, reason: 'cancel')).thenAnswer((_) async => cancelResult);

      final result = await repository.cancelOrder(10, reason: 'cancel');

      expect(result['success'], true);
      expect(result['message'], 'Cancelled');
    });

    test('downloadInvoice maps successfully', () async {
      when(() => mockDataSource.downloadInvoice("ORD1234")).thenAnswer((_) async => "/path/invoice.pdf");

      final result = await repository.downloadInvoice("ORD1234");

      expect(result, "/path/invoice.pdf");
    });

    test('getOrderTracking maps successfully', () async {
      final trackingDto = OrderTracking(
        id: 1,
        order: 10,
        orderNumber: "ORD1234",
        orderStatus: "SHIPPED",
        status: "IN TRANSIT",
        trackingEvents: [
          TrackingEvent(
            id: 1,
            activity: "Picked Up",
            location: "Hub",
            timestamp: DateTime(2026, 1, 25, 12, 0),
            status: "Success",
            courierStatus: "Success",
            courierStatusCode: "1",
            createdAt: DateTime(2026, 1, 25, 12, 0),
          )
        ],
      );
      when(() => mockDataSource.getOrderTracking("ORD1234")).thenAnswer((_) async => trackingDto);

      final result = await repository.getOrderTracking("ORD1234");

      expect(result, isNotNull);
      expect(result!.orderNumber, "ORD1234");
      expect(result.status, "IN TRANSIT");
      expect(result.trackingEvents.length, 1);
      expect(result.trackingEvents.first.activity, "Picked Up");
    });

    test('getUserShippingDetails maps successfully', () async {
      final shippingDto = ShippingDetails(
        address: "Home Address",
        name: "User",
        city: "City",
        state: "State",
        pincode: "123456",
        phone: "987",
      );
      when(() => mockDataSource.getUserShippingDetails()).thenAnswer((_) async => shippingDto);

      final result = await repository.getUserShippingDetails();

      expect(result, isNotNull);
      expect(result!.address, "Home Address");
      expect(result.city, "City");
    });

    test('translates ApiException to OrderFailure', () async {
      when(() => mockDataSource.getOrders()).thenThrow(ApiException("Unauthorized", 401));

      expect(() => repository.getOrders(), throwsA(isA<OrderFailure>().having(
        (f) => f.type, 'type', OrderFailureType.unauthorized
      )));
    });
  });
}
