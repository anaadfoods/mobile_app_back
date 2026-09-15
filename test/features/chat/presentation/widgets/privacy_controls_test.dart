import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/features/chat/domain/usecases/delete_memory_use_case.dart';
import 'package:grocery_app/features/chat/presentation/screens/health_profile_screen.dart';
import 'package:grocery_app/features/chat/presentation/cubit/health_profile_cubit.dart';
import 'package:grocery_app/features/chat/presentation/cubit/health_profile_state.dart';

class MockDeleteMemoryUseCase extends Mock implements DeleteMemoryUseCase {}
class MockHealthProfileCubit extends MockCubit<HealthProfileState> implements HealthProfileCubit {}

void main() {
  late MockDeleteMemoryUseCase mockDeleteMemoryUseCase;
  late MockHealthProfileCubit mockHealthProfileCubit;

  setUp(() {
    mockDeleteMemoryUseCase = MockDeleteMemoryUseCase();
    mockHealthProfileCubit = MockHealthProfileCubit();
    when(() => mockHealthProfileCubit.state).thenReturn(const HealthProfileInitial());
    when(() => mockHealthProfileCubit.loadHealthProfileData()).thenAnswer((_) async {});

    if (getIt.isRegistered<DeleteMemoryUseCase>()) {
      getIt.unregister<DeleteMemoryUseCase>();
    }
    getIt.registerSingleton<DeleteMemoryUseCase>(mockDeleteMemoryUseCase);
  });

  tearDown(() {
    if (getIt.isRegistered<DeleteMemoryUseCase>()) {
      getIt.unregister<DeleteMemoryUseCase>();
    }
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: HealthProfileScreen(cubit: mockHealthProfileCubit),
    );
  }

  testWidgets('renders AI Memory Header and Actions', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('AI Health Memory'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });

  testWidgets('tapping Delete AI Memory icon shows confirmation dialog', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Delete AI Memory?'), findsOneWidget);
    expect(find.textContaining('This will permanently delete all personalized semantic facts'), findsOneWidget);
  });

  testWidgets('confirming deletion in dialog invokes DeleteMemoryUseCase', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    when(() => mockDeleteMemoryUseCase()).thenAnswer((_) async => true);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Delete inside the dialog
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pump(const Duration(milliseconds: 300));

    verify(() => mockDeleteMemoryUseCase()).called(1);
    expect(find.text('AI memory deleted successfully.'), findsOneWidget);
  });

  testWidgets('cancelling deletion dialog does not call DeleteMemoryUseCase', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 300));

    verifyNever(() => mockDeleteMemoryUseCase());
  });
}
