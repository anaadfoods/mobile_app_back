import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_booking.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_delivery.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_batch.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_plan.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_vegetable.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_plan_pricing.dart';
import 'package:grocery_app/features/rfp/presentation/cubit/rfp_batch_cubit.dart';
import 'package:grocery_app/features/rfp/presentation/widgets/rfp_progress_card.dart';
import 'package:grocery_app/features/rfp/presentation/widgets/rfp_subscription_summary.dart';
import 'package:grocery_app/features/rfp/presentation/widgets/rfp_storefront_plan_card.dart';
import 'package:grocery_app/features/rfp/presentation/widgets/rfp_fresh_harvest_ledger.dart';
import 'package:grocery_app/features/rfp/presentation/widgets/rfp_split_payment_section.dart';
import 'package:grocery_app/features/home/presentation/widgets/rfp_batch_carousel_card.dart';

void main() {
  final df = DateFormat('dd MMM');

  final testBooking = RfpBooking(
    id: 'sub_123',
    batchId: 'batch_01',
    batchNumber: 1,
    planId: 'plan_std',
    planName: 'Standard 12-Week Plan',
    status: 'active',
    startDate: DateTime.now().subtract(const Duration(days: 21)),
    endDate: DateTime.now().add(const Duration(days: 63)),
    patchConfigs: const [],
    totalAmount: 10400,
    bookingAmountPaid: 1200,
    remainingAmount: 9200,
    bookedAt: DateTime.now().subtract(const Duration(days: 25)),
    bookingPaid: true,
    remainingPaid: false,
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
        date: DateTime.now().subtract(const Duration(days: 18)),
        status: 'delivered',
        dayOfWeek: 'Monday',
        patches: const [
          RfpDeliveryPatch(patchId: 'p1', patchLabel: 'P1', weightKg: 10.0),
        ],
        description: 'P1 Fresh harvest',
      ),
      RfpDelivery(
        id: 'del_02',
        weekNumber: 4,
        date: DateTime.now().add(const Duration(days: 3)),
        status: 'upcoming',
        dayOfWeek: 'Monday',
        patches: const [
          RfpDeliveryPatch(patchId: 'p1', patchLabel: 'P1', weightKg: 10.0),
        ],
        description: 'Week 4 scheduled drop',
      ),
    ],
  );

  group('RfpProgressCard dynamic rendering', () {
    testWidgets('renders computed week and remaining time dynamically', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RfpProgressCard(booking: testBooking, df: df),
          ),
        ),
      );

      // Verify dynamic text computed from dates/deliveries
      expect(find.text('Week 4 of 12'), findsOneWidget);
      expect(find.text('8 weeks remaining'), findsOneWidget);
      expect(find.textContaining('Monday'), findsOneWidget);
      expect(find.textContaining('Standard 12-Week Plan • 10.0 KG'), findsOneWidget);
    });
  });

  group('RfpSubscriptionSummary dynamic dates', () {
    testWidgets('renders formatted batch start and end dates', (tester) async {
      final batch = RfpBatch(
        id: 'batch_01',
        batchNumber: 1,
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 12, 23),
        totalWeeks: 12,
        currentWeek: 1,
        status: 'active',
        progressPercent: 0.1,
      );

      final batchState = RfpBatchState(
        selectedBatch: batch,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RfpSubscriptionSummary(batchState: batchState),
          ),
        ),
      );

      expect(find.text('SUBSCRIPTION PLAN'), findsOneWidget);
      expect(find.text('Batch #1'), findsOneWidget);
      expect(find.text('01 Oct - 23 Dec'), findsOneWidget);
    });
  });

  group('RfpStorefrontPlanCard', () {
    final samplePlan = RfpPlan(
      id: 'plan_01',
      name: 'Ritu Thali',
      tier: 'premium',
      badge: 'Curated Staple',
      description: 'Essential Seasonal Greens & Roots',
      totalPrice: 21600,
      bookingAmount: 2000,
      remainingAmount: 19600,
      features: const ['Weekly harvest'],
      availableVegetables: const [
        RfpVegetable(id: 'v1', name: 'Carrots', description: '', season: ''),
        RfpVegetable(id: 'v2', name: 'Spinach', description: '', season: ''),
        RfpVegetable(id: 'v3', name: 'Methi', description: '', season: ''),
      ],
      pricings: const [
        RfpPlanPricing(id: 1, variantName: 'SMALL', weightKg: 2.5, frequencyPerWeek: 1, pricePerDelivery: 1800),
      ],
    );

    testWidgets('renders plan name, badge, and CONFIGURE & ADD CTA when unconfigured', (tester) async {
      bool configureTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RfpStorefrontPlanCard(
              plan: samplePlan,
              isSelected: false,
              isConfigured: false,
              onToggleSelect: () {},
              onConfigureTap: () => configureTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Ritu Thali'), findsOneWidget);
      expect(find.text('CURATED STAPLE'), findsOneWidget);
      expect(find.text('Essential Seasonal Greens & Roots'), findsOneWidget);
      expect(find.text('Carrots'), findsOneWidget);
      expect(find.text('Spinach'), findsOneWidget);
      expect(find.text('Methi'), findsOneWidget);
      expect(find.text('Configure & Add'), findsOneWidget);

      await tester.tap(find.text('Configure & Add'));
      expect(configureTapped, isTrue);
    });

    testWidgets('renders PLAN SELECTED when selected and configured', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RfpStorefrontPlanCard(
              plan: samplePlan,
              isSelected: true,
              isConfigured: true,
              onToggleSelect: () {},
              onConfigureTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('SELECTED'), findsOneWidget);
      expect(find.text('Customise Veggies'), findsOneWidget);
    });
  });

  group('RfpFreshHarvestLedger & RfpSplitPaymentSection', () {
    final batch = RfpBatch(
      id: 'batch_01',
      batchNumber: 1,
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 11, 24),
      totalWeeks: 12,
      currentWeek: 1,
      status: 'active',
      progressPercent: 0.1,
    );

    final plan = RfpPlan(
      id: 'plan_01',
      name: 'Ritu Thali',
      tier: 'premium',
      description: 'Essential Seasonal Greens',
      totalPrice: 19872,
      originalPrice: 21600,
      bookingAmount: 2000,
      remainingAmount: 17872,
      discountPercent: 8,
      features: const [],
    );

    const variant = RfpPlanPricing(
      id: 1,
      variantName: 'MEDIUM',
      weightKg: 5.0,
      frequencyPerWeek: 2,
      pricePerDelivery: 1800,
    );

    testWidgets('RfpFreshHarvestLedger displays ledger details, weights, and discounts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RfpFreshHarvestLedger(
              plan: plan,
              batch: batch,
              variant: variant,
              frequency: 2,
              deliveryDays: const {1, 4}, // Tue & Fri
            ),
          ),
        ),
      );

      expect(find.text('Fresh Harvest Ledger'), findsOneWidget);
      expect(find.text('12 Weeks Batch'), findsOneWidget);
      expect(find.text('Ritu Thali'), findsOneWidget);
      expect(find.text('5 KG / box'), findsOneWidget);
      expect(find.textContaining('2 Deliveries each week • Tue & Fri'), findsOneWidget);
      expect(find.textContaining('8% Multi-Plan Harvest Voucher'), findsOneWidget);
      expect(find.text('₹19,872'), findsOneWidget);
    });

    testWidgets('RfpSplitPaymentSection displays Due Today and Due by Wk 3 correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RfpSplitPaymentSection(
              plan: plan,
              batch: batch,
            ),
          ),
        ),
      );

      expect(find.text('SPLIT PAYMENT TRANSPARENCY'), findsOneWidget);
      expect(find.text('Due Today'), findsOneWidget);
      expect(find.text('₹2,000'), findsOneWidget);
      expect(find.text('Initial Booking Deposit'), findsOneWidget);
      expect(find.text('Due by Wk 3'), findsOneWidget);
      expect(find.text('₹17,872'), findsOneWidget);
      expect(find.text('Auto-debit on Week 3'), findsOneWidget);
      expect(find.textContaining('Crate Guarantee: Cancel or pause anytime before Wk 3'), findsOneWidget);
    });
  });

  group('RfpBatchCarouselCard', () {
    final testBatch = RfpBatch(
      id: 'batch_01',
      batchNumber: 1,
      seasonLabel: 'Winter Harvest Batch',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 11, 24),
      totalWeeks: 12,
      currentWeek: 1,
      status: 'active',
      progressPercent: 0.1,
      slotsRemaining: 15,
      isFull: false,
      plans: const [
        RfpPlan(
          id: 'p1',
          name: 'Ritu Thali',
          tier: 'premium',
          description: '',
          totalPrice: 15000,
          bookingAmount: 1500,
          remainingAmount: 13500,
          features: [],
        ),
        RfpPlan(
          id: 'p2',
          name: 'Rasoi Base',
          tier: 'standard',
          description: '',
          totalPrice: 12000,
          bookingAmount: 1200,
          remainingAmount: 10800,
          features: [],
        ),
      ],
    );

    testWidgets('renders batch information, duration badge, and thalis bullet points', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                height: 380,
                width: 320,
                child: RfpBatchCarouselCard(
                  batch: testBatch,
                  isActive: true,
                  isDark: false,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('WINTER HARVEST BATCH'), findsOneWidget);
      expect(find.text('BATCH #1 • 12 WEEKS'), findsOneWidget);
      expect(find.text('01 Sep - 24 Nov'), findsOneWidget);
      expect(find.text('SEASONAL THALIS'), findsOneWidget);
      expect(find.text('Ritu Thali'), findsOneWidget);
      expect(find.text('Rasoi Base'), findsOneWidget);
      expect(find.text('Explore Batch & Plans'), findsOneWidget);
    });
  });
}
