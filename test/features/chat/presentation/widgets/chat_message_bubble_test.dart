import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:grocery_app/features/chat/domain/entities/chat_message.dart';
import 'package:grocery_app/features/chat/domain/entities/health_observation.dart';
import 'package:grocery_app/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:grocery_app/features/chat/presentation/cubit/chat_state.dart';
import 'package:grocery_app/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:grocery_app/features/chat/presentation/widgets/cards/health_observation_card_widget.dart';
import 'package:grocery_app/features/chat/presentation/widgets/cards/thali_card_widget.dart';
import 'package:grocery_app/features/chat/presentation/widgets/cards/error_retry_card_widget.dart';

class MockChatCubit extends Mock implements ChatCubit {}

void main() {
  late MockChatCubit mockChatCubit;

  setUp(() {
    mockChatCubit = MockChatCubit();
    when(() => mockChatCubit.state).thenReturn(const ChatState());
    when(() => mockChatCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildTestWidget(ChatMessageEntity message) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: BlocProvider<ChatCubit>.value(
            value: mockChatCubit,
            child: ChatMessageBubble(
              message: message,
              messageIndex: 0,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders user message content', (tester) async {
    const message = ChatMessageEntity(
      role: ChatRole.user,
      content: 'Hello Anaad AI',
    );

    await tester.pumpWidget(buildTestWidget(message));

    expect(find.text('Hello Anaad AI'), findsOneWidget);
  });

  testWidgets('renders assistant message with HealthObservationCardWidget when healthObservation is present', (tester) async {
    const message = ChatMessageEntity(
      role: ChatRole.assistant,
      content: 'I noted your report',
      healthObservation: HealthObservation(
        type: 'health_observation',
        food: 'Kurkure',
        symptom: 'mild fever',
        causality: 'user_reported_unconfirmed',
        saveRequested: false,
        requiresConsent: true,
        message: 'Reported fever after Kurkure',
      ),
    );

    await tester.pumpWidget(buildTestWidget(message));

    expect(find.byType(HealthObservationCardWidget), findsOneWidget);
  });

  testWidgets('renders ThaliCardWidget when thaliData is present and responseType is thali_suggestion', (tester) async {
    const message = ChatMessageEntity(
      role: ChatRole.assistant,
      content: 'Here is your meal plan',
      responseType: 'thali_suggestion',
      thaliData: {
        'thali_name': 'Ayurvedic Sattvic Thali',
        'meal_type': 'LUNCH',
        'items': ['Wheat Roti', 'Moong Dal', 'A2 Desi Ghee'],
      },
    );

    await tester.pumpWidget(buildTestWidget(message));

    expect(find.byType(ThaliCardWidget), findsOneWidget);
    expect(find.text('Ayurvedic Sattvic Thali'), findsOneWidget);
  });

  testWidgets('renders ErrorRetryCardWidget when responseType is error', (tester) async {
    const message = ChatMessageEntity(
      role: ChatRole.assistant,
      content: 'Network connection failed',
      responseType: 'error',
    );

    await tester.pumpWidget(buildTestWidget(message));

    expect(find.byType(ErrorRetryCardWidget), findsOneWidget);
    expect(find.widgetWithText(ErrorRetryCardWidget, 'Network connection failed'), findsOneWidget);
  });
}
