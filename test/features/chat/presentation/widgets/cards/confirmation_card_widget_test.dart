import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:grocery_app/features/chat/presentation/cubit/chat_state.dart';
import 'package:grocery_app/features/chat/presentation/widgets/cards/confirmation_card_widget.dart';

class MockChatCubit extends Mock implements ChatCubit {}

void main() {
  late MockChatCubit mockChatCubit;

  const testConfirmationData = {
    'action_title': 'Confirm Cart Addition',
    'description': 'Add 2 x A2 desi ghee to cart — ₹900',
    'confirmation_id': 'nonce_12345',
    'api_name': 'post_api_cart_items',
  };

  setUp(() {
    mockChatCubit = MockChatCubit();
    when(() => mockChatCubit.state).thenReturn(const ChatState());
    when(() => mockChatCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockChatCubit.confirmAction(
      confirmationId: any(named: 'confirmationId'),
      message: any(named: 'message'),
    )).thenAnswer((_) async {});
  });

  Widget buildTestWidget({Map<String, dynamic>? data}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: BlocProvider<ChatCubit>.value(
            value: mockChatCubit,
            child: ConfirmationCardWidget(
              confirmationData: data ?? testConfirmationData,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders confirmation title and description', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Confirm Cart Addition'), findsOneWidget);
    expect(find.text('Add 2 x A2 desi ghee to cart — ₹900'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('tapping Confirm calls cubit confirmAction with nonce', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    verify(() => mockChatCubit.confirmAction(
      confirmationId: 'nonce_12345',
      message: 'Add 2 x A2 desi ghee to cart — ₹900',
    )).called(1);
  });

  testWidgets('tapping Cancel does not call confirmAction', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => mockChatCubit.confirmAction(
      confirmationId: any(named: 'confirmationId'),
      message: any(named: 'message'),
    ));
    expect(find.text('Action cancelled.'), findsOneWidget);
  });

  testWidgets('shows loading spinner when isConfirming is true', (tester) async {
    when(() => mockChatCubit.state).thenReturn(
      const ChatState(isConfirming: true),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
