import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_booking.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_delivery.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_my_subscriptions_use_case.dart';
import 'package:grocery_app/features/rfp/presentation/screens/rfp_subscriptions_list_screen.dart';
import 'package:grocery_app/features/rfp/presentation/widgets/rfp_account_subscription_tile.dart';

class MockGetMySubscriptionsUseCase extends Mock
    implements GetMySubscriptionsUseCase {}

void main() {
  late MockGetMySubscriptionsUseCase mockGetMySubscriptions;

  setUp(() {
    mockGetMySubscriptions = MockGetMySubscriptionsUseCase();
    if (getIt.isRegistered<GetMySubscriptionsUseCase>()) {
      getIt.unregister<GetMySubscriptionsUseCase>();
    }
    getIt.registerLazySingleton<GetMySubscriptionsUseCase>(
      () => mockGetMySubscriptions,
    );
  });

  tearDown(() {
    if (getIt.isRegistered<GetMySubscriptionsUseCase>()) {
      getIt.unregister<GetMySubscriptionsUseCase>();
    }
  });

  final testBooking = RfpBooking(
    id: 'sub_123',
    batchId: 'batch_01',
    batchNumber: 26,
    planId: 'plan_std',
    planName: 'MARCH 26',
    status: 'ACTIVE',
    startDate: DateTime(2026, 9, 2),
    endDate: DateTime(2026, 11, 25),
    patchConfigs: const [],
    totalAmount: 10120,
    bookingAmountPaid: 920,
    remainingAmount: 9200,
    bookedAt: DateTime(2026, 8, 20),
    bookingPaid: true,
    remainingPaid: false,
    deliveryDays: const ['Monday', 'Thursday'],
    address: const RfpBookingAddress(
      fullName: 'Demo Customer',
      addressLine: 'Flat 402, Green Valley Apartments',
      city: 'Gurugram',
      pincode: '122001',
      phone: '9876543210',
    ),
    deliveries: [
      RfpDelivery(
        id: 'del_01',
        weekNumber: 1,
        date: DateTime(2026, 10, 3),
        status: 'upcoming',
        dayOfWeek: 'Monday',
        patches: const [],
      ),
    ],
  );

  group('RfpSubscriptionsListScreen', () {
    testWidgets('renders empty state when user has no subscriptions',
        (tester) async {
      when(() => mockGetMySubscriptions()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        const MaterialApp(
          home: RfpSubscriptionsListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MY SUBSCRIPTIONS'), findsOneWidget);
      expect(find.text('No Farming Subscriptions'), findsOneWidget);
      expect(find.text('Explore Farming Programs'), findsOneWidget);
    });

    testWidgets('renders subscription card with batch name and dates',
        (tester) async {
      when(() => mockGetMySubscriptions())
          .thenAnswer((_) async => [testBooking]);

      await tester.pumpWidget(
        const MaterialApp(
          home: RfpSubscriptionsListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MARCH 26'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Monday · Thursday'), findsOneWidget);
      expect(find.text('View subscription'), findsOneWidget);
      expect(find.textContaining('Next delivery: '), findsOneWidget);
    });

    testWidgets('renders error state when fetch fails and allows retry', (tester) async {
      when(() => mockGetMySubscriptions()).thenThrow(Exception('Network error connecting to farm server'));

      await tester.pumpWidget(
        const MaterialApp(
          home: RfpSubscriptionsListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load subscriptions'), findsOneWidget);
      expect(find.textContaining('Network error connecting to farm server'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      when(() => mockGetMySubscriptions()).thenAnswer((_) async => [testBooking]);
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('MARCH 26'), findsOneWidget);
    });

    testWidgets('supports pull-to-refresh', (tester) async {
      when(() => mockGetMySubscriptions()).thenAnswer((_) async => [testBooking]);

      await tester.pumpWidget(
        const MaterialApp(
          home: RfpSubscriptionsListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MARCH 26'), findsOneWidget);

      await tester.fling(find.text('MARCH 26'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      verify(() => mockGetMySubscriptions()).called(greaterThanOrEqualTo(2));
    });
  });

  group('RfpAccountSubscriptionTile', () {
    testWidgets('renders navigation title and subtitle without fetching data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RfpAccountSubscriptionTile(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Subscriptions'), findsOneWidget);
      expect(find.text('Remote Farming Program & Harvest Schedule'), findsOneWidget);
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
    });

    testWidgets('renders optional active count badge if passed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RfpAccountSubscriptionTile(activeCount: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Subscriptions'), findsOneWidget);
      expect(find.text('2 Active'), findsOneWidget);
    });
  });
}
